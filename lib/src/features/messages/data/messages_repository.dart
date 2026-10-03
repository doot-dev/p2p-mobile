import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

/// Mirrors backend `MessageRow` (`/api/v1/messages`).
class Message {
  const Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.isRead,
    this.senderName = '',
    this.receiverName = '',
    this.senderPhoto = '',
    this.receiverPhoto = '',
    this.createdAt,
  });

  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final bool isRead;
  final String senderName;
  final String receiverName;
  final String senderPhoto;
  final String receiverPhoto;
  final DateTime? createdAt;

  factory Message.fromJson(Map<String, dynamic> j) {
    final sender = (j['sender'] as Map?) ?? const {};
    final receiver = (j['receiver'] as Map?) ?? const {};
    return Message(
      id: j['id'] as String? ?? '',
      senderId: j['senderId'] as String? ?? '',
      receiverId: j['receiverId'] as String? ?? '',
      content: j['content'] as String? ?? '',
      isRead: j['isRead'] as bool? ?? false,
      senderName: sender['name'] as String? ?? '',
      receiverName: receiver['name'] as String? ?? '',
      senderPhoto: sender['profilePhoto'] as String? ?? '',
      receiverPhoto: receiver['profilePhoto'] as String? ?? '',
      createdAt: DateTime.tryParse(j['createdAt'] as String? ?? ''),
    );
  }
}

/// One conversation partner derived from the caller's messages.
class Thread {
  const Thread({
    required this.otherUid,
    required this.otherName,
    required this.otherPhoto,
    required this.lastMessage,
  });

  final String otherUid;
  final String otherName;
  final String otherPhoto;
  final Message lastMessage;
}

class MessagesRepository {
  MessagesRepository(this._api);

  final ApiClient _api;

  Future<List<Message>> getMessages({String? withUid}) async {
    final data = await _api.get<Map<String, dynamic>>('/messages',
        query: withUid == null ? null : {'with': withUid});
    final list = (data['messages'] as List?) ?? const [];
    return list
        .map((e) => Message.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> send({required String receiverId, required String content}) =>
      _api.post<Map<String, dynamic>>('/messages',
          data: {'receiverId': receiverId, 'content': content});

  /// Group the caller's messages into threads keyed by counterpart uid.
  static List<Thread> threadsFor(String myUid, List<Message> messages) {
    final map = <String, Message>{};
    for (final m in messages) {
      final other = m.senderId == myUid ? m.receiverId : m.senderId;
      map[other] = m; // messages sorted asc — last write wins.
    }
    return map.entries.map((e) {
      final m = e.value;
      final mine = m.senderId == myUid;
      return Thread(
        otherUid: e.key,
        otherName: mine ? m.receiverName : m.senderName,
        otherPhoto: mine ? m.receiverPhoto : m.senderPhoto,
        lastMessage: m,
      );
    }).toList()
      ..sort((a, b) => (b.lastMessage.createdAt ?? DateTime(0))
          .compareTo(a.lastMessage.createdAt ?? DateTime(0)));
  }
}

final messagesRepositoryProvider = Provider<MessagesRepository>(
  (ref) => MessagesRepository(ref.watch(apiClientProvider)),
);

/// All caller messages (threads view).
final allMessagesProvider = FutureProvider<List<Message>>(
  (ref) => ref.watch(messagesRepositoryProvider).getMessages(),
);

/// One conversation with [otherUid].
final conversationProvider = FutureProvider.family<List<Message>, String>(
  (ref, otherUid) =>
      ref.watch(messagesRepositoryProvider).getMessages(withUid: otherUid),
);
