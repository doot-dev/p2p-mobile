// One-to-one chat (P2P-website/src/components/conversation-dialog.tsx).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/local_db.dart';
import '../../core/realtime.dart';
import '../../core/theme.dart';
import '../../ui/icons.dart';
import '../../ui/kit.dart';
import '../auth/session.dart';

/// "Today" / "Yesterday" / "3 Oct 2026" for the day separators.
String _dayLabel(DateTime d) {
  final now = DateTime.now();
  final days = DateTime(now.year, now.month, now.day).difference(DateTime(d.year, d.month, d.day)).inDays;
  return days == 0 ? 'Today' : days == 1 ? 'Yesterday' : shortDate(d.toIso8601String());
}

DateTime? _local(Json m) => DateTime.tryParse('${m['created_at']}')?.toLocal();

bool _sameDay(DateTime? a, DateTime? b) => a != null && b != null && a.year == b.year && a.month == b.month && a.day == b.day;

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen(this.uid, {super.key});

  /// The other person's account id (authUid).
  final String uid;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

/// Messages come from the on-device database: they show instantly (even offline), new ones arrive over
/// the WebSocket, and sends go through the outbox so nothing is lost without a connection.
class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _text = TextEditingController();
  final _scroll = ScrollController();
  Json? _other;

  /// Last incoming message we told the server about, so each new one is marked read once.
  Object? _lastMarked;

  String get _me => ref.read(sessionProvider).account?.id ?? '';

  @override
  void initState() {
    super.initState();
    _sync();
    // While the chat is open, anything new from them is read straight away.
    ref.listenManual(chatMessagesProvider(widget.uid), (_, next) {
      final list = next.value;
      final last = list == null || list.isEmpty ? null : list.last;
      if (last != null && last['sender_id'] == widget.uid && last['read'] != true && last['id'] != _lastMarked) {
        _lastMarked = last['id'];
        ref.read(chatStoreProvider).markRead(widget.uid);
      }
    });
  }

  Future<void> _sync() async {
    final store = ref.read(chatStoreProvider);
    final other = await runAction(context, ref, () => store.sync(_me, widget.uid), refresh: false);
    if (mounted && other != null) setState(() => _other = other);
    await store.markRead(widget.uid);
  }

  @override
  void dispose() {
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final t = _text.text.trim();
    if (t.isEmpty) return;
    _text.clear();
    if (_scroll.hasClients) _scroll.jumpTo(0);
    await ref.read(chatStoreProvider).send(widget.uid, _me, t);
  }

  @override
  Widget build(BuildContext context) {
    // Before the first sync (or for a brand-new conversation) the header comes from the link.
    final q = GoRouterState.of(context).uri.queryParameters;
    final name = '${_other?['name'] ?? q['name'] ?? ''}';
    final photo = (_other?['profilePhoto'] ?? q['photo']) as String?;
    final ptpc = '${_other?['id'] ?? q['ptpc'] ?? ''}';
    void openProfile() => ptpc.isEmpty ? null : context.push('/profile/$ptpc');

    final messages = ref.watch(chatMessagesProvider(widget.uid)).value ?? const <Json>[];

    return Scaffold(
      appBar: AppHeader(
        title: name.isEmpty ? 'Chat' : name,
        onBack: () => context.popOr('/inbox'),
        actions: [GestureDetector(onTap: openProfile, child: Avatar(url: photo, name: name, size: 34))],
      ),
      body: Column(children: [
        Expanded(
          child: messages.isEmpty
              ? Center(child: Text('No messages yet. Start the conversation!', style: T.body.muted))
              // Reversed so the newest message sits at the bottom and new ones stay in view.
              : ListView.builder(
                  controller: _scroll,
                  reverse: true,
                  padding: const EdgeInsets.all(S.lg),
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final k = messages.length - 1 - i;
                    final m = messages[k];
                    final at = _local(m);
                    final newDay = k == 0 || !_sameDay(_local(messages[k - 1]), at);
                    return Column(children: [
                      if (newDay && at != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: S.md),
                          child: Text(_dayLabel(at).toUpperCase(), style: T.caption.size(10.5).muted.copyWith(letterSpacing: 1)),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(top: S.sm),
                        child: _Bubble(m, mine: m['sender_id'] == _me, onRetry: () => ref.read(chatStoreProvider).retry(m)),
                      ),
                    ]);
                  },
                ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(S.lg, S.sm, S.lg, S.sm),
          decoration: const BoxDecoration(
            color: C.surface,
            border: Border(top: BorderSide(color: C.divider, width: 0.5)),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _text,
                    minLines: 1,
                    maxLines: 5,
                    maxLength: 5000,
                    textCapitalization: TextCapitalization.sentences,
                    style: T.body.size(15),
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      hintStyle: T.body.size(15).muted,
                      counterText: '',
                      filled: true,
                      fillColor: C.surface3,
                      contentPadding: const EdgeInsets.symmetric(horizontal: S.md, vertical: 11),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(R.lg), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: S.sm),
                ValueListenableBuilder(
                  valueListenable: _text,
                  builder: (_, v, _) {
                    final empty = v.text.trim().isEmpty;
                    return Opacity(
                      opacity: empty ? 0.5 : 1,
                      child: Material(
                        color: C.brand,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: empty ? null : _send,
                          child: const SizedBox.square(dimension: 44, child: Icon(PhosphorIconsFill.paperPlaneRight, size: 20, color: C.onBrand)),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble(this.m, {required this.mine, required this.onRetry});
  final Json m;
  final bool mine;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Align(
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: S.md, vertical: S.sm),
            decoration: BoxDecoration(
              color: mine ? C.brand3 : C.surface2,
              border: Border.all(color: mine ? C.brand.withValues(alpha: 0.35) : C.border, width: 0.5),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(R.md),
                topRight: const Radius.circular(R.md),
                bottomLeft: Radius.circular(mine ? R.md : 4),
                bottomRight: Radius.circular(mine ? 4 : R.md),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                SelectableText('${m['text']}', style: T.body),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(formatTime(m['created_at'] as String?), style: T.caption.size(10).muted),
                    if (mine) ...[
                      const SizedBox(width: 3),
                      _DeliveryIcon(m, onRetry: onRetry),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}

/// ⏱ waiting to send · ⚠ failed (tap to retry) · ✓ sent · ✓✓ read (gold)
class _DeliveryIcon extends StatelessWidget {
  const _DeliveryIcon(this.message, {required this.onRetry});
  final Json message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => switch (message['status']) {
        MsgStatus.pending => const Icon(PhosphorIconsRegular.clock, size: 12, color: C.muted),
        MsgStatus.failed => GestureDetector(onTap: onRetry, child: const Icon(PhosphorIconsRegular.warningCircle, size: 14, color: C.error)),
        _ => message['read'] == true
            ? const Icon(PhosphorIconsRegular.checks, size: 13, color: C.brand)
            : const Icon(PhosphorIconsRegular.check, size: 13, color: C.muted),
      };
}
