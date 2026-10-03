// On-device SQLite (drift): the app's offline copy of chats and API reads, kept in sync with P2P-backend.
// Works on Android, iOS and web (web runs SQLite as wasm in a worker: web/sqlite3.wasm + web/drift_worker.js).
import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'format.dart';

/// Message delivery state on this device.
abstract final class MsgStatus {
  static const sent = 'sent'; // on the server
  static const pending = 'pending'; // in the outbox, not sent yet
  static const failed = 'failed'; // the server refused it; tap to retry
}

// ponytail: raw SQL with no code generation — two small tables don't earn a build_runner step.
const _schema = [
  '''CREATE TABLE IF NOT EXISTS api_cache (
       path TEXT PRIMARY KEY,
       body TEXT NOT NULL,
       saved_at INTEGER NOT NULL
     )''',
  '''CREATE TABLE IF NOT EXISTS messages (
       id TEXT PRIMARY KEY,
       conversation_id TEXT NOT NULL,
       sender_id TEXT NOT NULL,
       text TEXT NOT NULL,
       read INTEGER NOT NULL DEFAULT 0,
       created_at TEXT NOT NULL,
       status TEXT NOT NULL DEFAULT 'sent'
     )''',
  'CREATE INDEX IF NOT EXISTS messages_by_conversation ON messages (conversation_id, created_at)',
];

class LocalDb extends GeneratedDatabase {
  LocalDb([QueryExecutor? executor])
      : super(executor ??
            driftDatabase(
              name: 'ptp_app',
              web: DriftWebOptions(sqlite3Wasm: Uri.parse('sqlite3.wasm'), driftWorker: Uri.parse('drift_worker.js')),
            ));

  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => const [];

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(onCreate: (_) async {
        for (final sql in _schema) {
          await customStatement(sql);
        }
      });

  /// Conversation ids whose local messages changed (the chat screen re-reads on these).
  final _changes = StreamController<String>.broadcast();
  Stream<String> get changes => _changes.stream;

  // ───── API read cache (offline fallback for every screen) ─────

  Future<void> cachePut(String path, Object? body) => customStatement(
        'INSERT OR REPLACE INTO api_cache (path, body, saved_at) VALUES (?, ?, ?)',
        [path, jsonEncode(body), DateTime.now().millisecondsSinceEpoch],
      );

  Future<Object?> cacheGet(String path) async {
    final row = await customSelect('SELECT body FROM api_cache WHERE path = ?', variables: [Variable(path)]).getSingleOrNull();
    return row == null ? null : jsonDecode(row.read<String>('body'));
  }

  // ───── messages ─────

  static Json _row(QueryRow r) => {
        'id': r.read<String>('id'),
        'conversation_id': r.read<String>('conversation_id'),
        'sender_id': r.read<String>('sender_id'),
        'text': r.read<String>('text'),
        'read': r.read<int>('read') == 1,
        'created_at': r.read<String>('created_at'),
        'status': r.read<String>('status'),
      };

  /// Oldest first, outbox included.
  Future<List<Json>> messages(String conversationId) async => (await customSelect(
        'SELECT * FROM messages WHERE conversation_id = ? ORDER BY created_at, id',
        variables: [Variable(conversationId)],
      ).get())
          .map(_row)
          .toList();

  /// Server messages (API shape), inserted or updated.
  Future<void> upsertMessages(List<Json> list) async {
    if (list.isEmpty) return;
    await transaction(() async {
      for (final m in list) {
        await customStatement(
          'INSERT OR REPLACE INTO messages (id, conversation_id, sender_id, text, read, created_at, status) VALUES (?, ?, ?, ?, ?, ?, ?)',
          [m['id'], m['conversation_id'], m['sender_id'], m['text'], m['read'] == true ? 1 : 0, m['created_at'], MsgStatus.sent],
        );
      }
    });
    for (final c in {for (final m in list) '${m['conversation_id']}'}) {
      _changes.add(c);
    }
  }

  /// Newest message the server has confirmed — the `?after=` cursor for catching up.
  Future<String?> lastSyncedId(String conversationId) async => (await customSelect(
        'SELECT id FROM messages WHERE conversation_id = ? AND status = ? ORDER BY created_at DESC, id DESC LIMIT 1',
        variables: [Variable(conversationId), const Variable(MsgStatus.sent)],
      ).getSingleOrNull())
          ?.read<String>('id');

  /// The other side read everything I sent in this conversation.
  Future<void> markReadBy(String conversationId, String readerId) async {
    await customStatement('UPDATE messages SET read = 1 WHERE conversation_id = ? AND sender_id != ?', [conversationId, readerId]);
    _changes.add(conversationId);
  }

  // ───── outbox (messages written offline or still sending) ─────

  Future<Json> addPending(String conversationId, String senderId, String text) async {
    final m = {
      'id': 'local-${DateTime.now().microsecondsSinceEpoch}',
      'conversation_id': conversationId,
      'sender_id': senderId,
      'text': text,
      'read': false,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'status': MsgStatus.pending,
    };
    await customStatement(
      'INSERT INTO messages (id, conversation_id, sender_id, text, read, created_at, status) VALUES (?, ?, ?, ?, 0, ?, ?)',
      [m['id'], conversationId, senderId, text, m['created_at'], MsgStatus.pending],
    );
    _changes.add(conversationId);
    return m;
  }

  /// The server accepted an outbox message: swap the local copy for the real one.
  Future<void> confirmPending(String localId, Json serverMessage) async {
    await customStatement('DELETE FROM messages WHERE id = ?', [localId]);
    await upsertMessages([serverMessage]);
  }

  Future<void> setStatus(String id, String conversationId, String status) async {
    await customStatement('UPDATE messages SET status = ? WHERE id = ?', [status, id]);
    _changes.add(conversationId);
  }

  /// Everything still waiting to be sent, oldest first.
  Future<List<Json>> outbox() async =>
      (await customSelect('SELECT * FROM messages WHERE status = ? ORDER BY created_at', variables: [const Variable(MsgStatus.pending)]).get())
          .map(_row)
          .toList();

  /// Signing out wipes this device's copy (another person may sign in next).
  Future<void> clearAll() async {
    await customStatement('DELETE FROM api_cache');
    await customStatement('DELETE FROM messages');
  }
}

final localDbProvider = Provider<LocalDb>((ref) {
  final db = LocalDb();
  ref.onDispose(db.close);
  return db;
});
