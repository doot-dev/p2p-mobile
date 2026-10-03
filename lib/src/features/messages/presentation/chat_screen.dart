import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../auth/data/auth_repository.dart';
import '../data/messages_repository.dart';

/// Chat tab — thread list. Tap a thread → conversation.
class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myUid = ref.watch(authRepositoryProvider).currentUser?.uid ?? '';
    final async = ref.watch(allMessagesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: RefreshIndicator(
        color: AppColors.gold,
        onRefresh: () => ref.refresh(allMessagesProvider.future),
        child: async.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.gold)),
          error: (e, _) => ListView(children: const [
            SizedBox(height: 120),
            Center(
                child: Text("Couldn't load messages.",
                    style: TextStyle(color: AppColors.textSecondary))),
          ]),
          data: (messages) {
            final threads = MessagesRepository.threadsFor(myUid, messages);
            if (threads.isEmpty) {
              return ListView(children: const [
                SizedBox(height: 120),
                Icon(Icons.chat_bubble_outline,
                    size: 56, color: AppColors.textMuted),
                SizedBox(height: 12),
                Center(
                    child: Text('No conversations yet.',
                        style: TextStyle(color: AppColors.textSecondary))),
              ]);
            }
            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: threads.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final t = threads[i];
                return ListTile(
                  leading: _avatar(t.otherName, t.otherPhoto),
                  title: Text(t.otherName.isEmpty ? 'Creator' : t.otherName),
                  subtitle: Text(t.lastMessage.content,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textMuted)),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ConversationScreen(
                        otherUid: t.otherUid, otherName: t.otherName),
                  )),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

Widget _avatar(String name, String photo) => CircleAvatar(
      backgroundColor: AppColors.gold.withValues(alpha: 0.15),
      backgroundImage:
          photo.isNotEmpty ? CachedNetworkImageProvider(photo) : null,
      child: photo.isNotEmpty
          ? null
          : Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(color: AppColors.gold)),
    );

/// One-on-one conversation.
class ConversationScreen extends ConsumerStatefulWidget {
  const ConversationScreen(
      {super.key, required this.otherUid, required this.otherName});

  final String otherUid;
  final String otherName;

  @override
  ConsumerState<ConversationScreen> createState() =>
      _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final _input = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ref
          .read(messagesRepositoryProvider)
          .send(receiverId: widget.otherUid, content: text);
      _input.clear();
      ref.invalidate(conversationProvider(widget.otherUid));
      ref.invalidate(allMessagesProvider);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not send message.')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final myUid = ref.watch(authRepositoryProvider).currentUser?.uid ?? '';
    final async = ref.watch(conversationProvider(widget.otherUid));

    return Scaffold(
      appBar: AppBar(
          title:
              Text(widget.otherName.isEmpty ? 'Conversation' : widget.otherName)),
      body: Column(
        children: [
          Expanded(
            child: async.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.gold)),
              error: (e, _) => const Center(
                  child: Text("Couldn't load conversation.",
                      style: TextStyle(color: AppColors.textSecondary))),
              data: (messages) => ListView.builder(
                reverse: true,
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, i) {
                  final m = messages[messages.length - 1 - i];
                  final mine = m.senderId == myUid;
                  return Align(
                    alignment:
                        mine ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75),
                      decoration: BoxDecoration(
                        color: mine
                            ? AppColors.gold.withValues(alpha: 0.9)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(16).copyWith(
                          bottomRight: mine ? const Radius.circular(4) : null,
                          bottomLeft: mine ? null : const Radius.circular(4),
                        ),
                        border:
                            mine ? null : Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        m.content,
                        style: TextStyle(
                            color: mine
                                ? AppColors.onGold
                                : AppColors.textPrimary),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      decoration: const InputDecoration(
                          hintText: 'Message...',
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    style: IconButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: AppColors.onGold),
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
