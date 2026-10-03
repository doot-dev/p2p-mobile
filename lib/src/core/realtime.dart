// Live updates from P2P-backend's WebSocket (/ws) + keeping the on-device chat copy in sync.
// A PTP conversation is "me + one other person", so the local conversation id is the other person's
// account id (authUid).
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'api.dart';
import 'data.dart';
import 'format.dart';
import 'local_db.dart';

/// API message → local row. [me] decides which side is "the other person".
Json localMessage(Json m, String me) => {
      'id': m['id'],
      'conversation_id': m['senderId'] == me ? m['receiverId'] : m['senderId'],
      'sender_id': m['senderId'],
      'text': m['content'],
      'read': m['isRead'] == true,
      'created_at': m['createdAt'],
    };

/// Inbox + unread badge + per-person thread are all derived from these reads.
void invalidateInbox(Ref ref) => ref.invalidate(apiGet('$ptp/messages/threads'));

/// Chat sync: the server is the source of truth, [LocalDb] is what the screen shows.
class ChatStore {
  ChatStore(this._ref);
  final Ref _ref;
  Timer? _retryOutbox;

  LocalDb get _db => _ref.read(localDbProvider);
  ApiClient get _api => _ref.read(apiClientProvider);

  /// Pull the whole conversation into the local copy (also refreshes read ticks).
  /// Returns the other person (`{authUid, name, id, profilePhoto}`); offline, the copy saved last time.
  Future<Json?> sync(String me, String other) async {
    try {
      final res = await _api.get('$ptp/messages?with=$other') as Json;
      final list = (res['messages'] as List).cast<Json>();
      await _db.upsertMessages([for (final m in list) localMessage(m, me)]);
      final person = list.isEmpty ? null : (list.last['senderId'] == other ? list.last['sender'] : list.last['receiver']) as Json?;
      if (person != null) await _db.cachePut('chat-other/$other', person);
      return person ?? await _db.cacheGet('chat-other/$other') as Json?;
    } on ApiException catch (e) {
      if (e.statusCode != null) rethrow;
      return await _db.cacheGet('chat-other/$other') as Json?;
    }
  }

  /// Everything the other person sent me is now read (they see it live).
  Future<void> markRead(String other) async {
    try {
      final res = await _api.patch('$ptp/messages/read', {'with': other}) as Json;
      if ((res['count'] as num? ?? 0) > 0) invalidateInbox(_ref);
    } on ApiException {
      // Best effort; the next open marks them again.
    }
  }

  /// Shows at once (pending), then sends. Offline it stays in the outbox until the socket reconnects.
  Future<void> send(String other, String me, String text) async => _deliver(await _db.addPending(other, me, text));

  Future<void> retry(Json message) async {
    await _db.setStatus('${message['id']}', '${message['conversation_id']}', MsgStatus.pending);
    await _deliver(message);
  }

  Future<void> flushOutbox() async {
    _retryOutbox?.cancel();
    _retryOutbox = null;
    for (final m in await _db.outbox()) {
      await _deliver(m);
    }
  }

  Future<void> _deliver(Json local) async {
    final other = '${local['conversation_id']}';
    try {
      final saved = await _api.post('$ptp/messages', {'receiverId': other, 'content': local['text']}) as Json;
      await _db.confirmPending('${local['id']}', {...local, 'id': saved['id'], 'created_at': DateTime.now().toUtc().toIso8601String()});
      invalidateInbox(_ref);
    } on ApiException catch (e) {
      // Refused (recipient gone, too long…): mark failed. Offline: keep it pending and try again shortly
      // (the socket reconnecting also sends the outbox).
      if (e.statusCode != null) {
        await _db.setStatus('${local['id']}', other, MsgStatus.failed);
      } else {
        _retryOutbox ??= Timer(const Duration(seconds: 10), flushOutbox);
      }
    }
  }
}

final chatStoreProvider = Provider<ChatStore>(ChatStore.new);

/// Messages with one person from the local database, re-read whenever that conversation changes.
final chatMessagesProvider = StreamProvider.autoDispose.family<List<Json>, String>((ref, other) async* {
  final db = ref.watch(localDbProvider);
  yield await db.messages(other);
  await for (final changed in db.changes) {
    if (changed == other) yield await db.messages(other);
  }
});

/// The live socket. Reconnects with backoff while signed in; each (re)connect sends the outbox
/// and refreshes the inbox, so nothing is missed while the app was offline.
class Realtime {
  Realtime(this._ref);
  final Ref _ref;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  Timer? _retry;
  int _attempt = 0;
  bool _wanted = false;
  String _me = '';

  ApiClient get _api => _ref.read(apiClientProvider);
  LocalDb get _db => _ref.read(localDbProvider);

  /// [me] = the signed-in account id.
  void start(String me) {
    _me = me;
    if (_wanted) return;
    _wanted = true;
    _connect();
  }

  Future<void> stop() async {
    _wanted = false;
    _retry?.cancel();
    await _sub?.cancel();
    await _channel?.sink.close();
    _channel = null;
  }

  Future<void> _connect() async {
    if (!_wanted) return;
    try {
      // Any signed-in call first, so an expired access token is refreshed before the handshake.
      await _api.get('$ptp/messages/threads');
      invalidateInbox(_ref);
      if (!_wanted) return;
      final base = Uri.parse(Env.apiBaseUrl);
      final uri = base.replace(scheme: base.scheme == 'https' ? 'wss' : 'ws', path: '/ws', queryParameters: {'token': _api.tokens.access});
      final channel = WebSocketChannel.connect(uri);
      await channel.ready;
      _channel = channel;
      _attempt = 0;
      _sub = channel.stream.listen(_onEvent, onDone: _reconnectLater, onError: (_) => _reconnectLater());
      unawaited(_ref.read(chatStoreProvider).flushOutbox());
    } catch (_) {
      _reconnectLater();
    }
  }

  void _reconnectLater() {
    _sub?.cancel();
    _channel = null;
    if (!_wanted) return;
    _retry?.cancel();
    _retry = Timer(Duration(seconds: min(30, 1 << min(_attempt++, 5))), _connect);
  }

  void _onEvent(dynamic raw) {
    final Json event;
    try {
      event = jsonDecode(raw as String) as Json;
    } catch (_) {
      return;
    }
    final data = event['data'];
    switch (event['type']) {
      // The socket is shared with the other P2P apps; only ptp:* events are ours.
      case 'ptp:message:new':
        final m = (data as Json)['message'] as Json;
        // My own sends are confirmed by ChatStore; the echo matters only for my other devices.
        unawaited(_db.upsertMessages([localMessage(m, _me)]));
        invalidateInbox(_ref);
      case 'ptp:message:read':
        // The other person read what I sent them.
        if ((data as Json)['readerId'] != _me) unawaited(_db.markReadBy('${data['readerId']}', '${data['readerId']}'));
        invalidateInbox(_ref);
      case 'ptp:application':
        _ref.invalidate(apiGet('$ptp/applications/incoming'));
        _ref.invalidate(apiGet('$ptp/applications/sent'));
    }
  }
}

final realtimeProvider = Provider<Realtime>((ref) {
  final realtime = Realtime(ref);
  ref.onDispose(realtime.stop);
  return realtime;
});
