// Inbox tab — the website's Collaboration hub (P2P-website/src/app/inbox/page.tsx): new applications
// on my projects, then my conversations (newest first).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/data.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../ui/icons.dart';
import '../../ui/kit.dart';
import '../auth/session.dart';
import 'open_chat.dart';

const _threadsPath = '$ptp/messages/threads';
const _incomingPath = '$ptp/applications/incoming';

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  String _query = '';

  bool _matches(Object? name) => _query.isEmpty || '${name ?? ''}'.toLowerCase().contains(_query);

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(sessionProvider.select((s) => s.account?.id));
    final incoming = ref.watch(apiGet(_incomingPath)).value as Json?;
    final newApps = [
      for (final a in (incoming?['applications'] as List? ?? const []).cast<Json>())
        if (a['creatorRead'] != true && _matches(a['applicantName'])) a,
    ];

    return Scaffold(
      body: Column(children: [
        TabHeader(
          title: 'INBOX',
          caption: 'Collaboration hub',
          bottom: TextField(
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            style: T.body.size(15),
            decoration: InputDecoration(
              hintText: 'Search by name',
              hintStyle: T.body.size(15).muted,
              prefixIcon: const Icon(PhosphorIconsRegular.magnifyingGlass, size: 18, color: C.muted),
              filled: true,
              fillColor: C.surface3,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: S.md, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(R.md), borderSide: BorderSide.none),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: C.brand,
            onRefresh: () => Future.wait([ref.refresh(apiGet(_threadsPath).future), ref.refresh(apiGet(_incomingPath).future)]),
            child: ApiView(
              path: _threadsPath,
              loading: const Padding(
                padding: EdgeInsets.symmetric(horizontal: S.lg),
                child: Column(children: [RowSkeleton(), RowSkeleton(), RowSkeleton()]),
              ),
              builder: (d) {
                final threads = [
                  for (final t in ((d as Json)['threads'] as List? ?? const []).cast<Json>())
                    if (_matches((t['other'] as Json?)?['name'])) t,
                ];
                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: S.lg),
                  children: [
                    if (newApps.isNotEmpty) ...[
                      const SizedBox(height: S.lg),
                      Constrained(child: SectionLabel('New applications (${newApps.length})')),
                      for (final a in newApps) Constrained(child: _NewApplicationRow(a)),
                      const SizedBox(height: S.lg),
                      const Constrained(child: SectionLabel('Conversations')),
                    ],
                    if (threads.isEmpty)
                      _query.isNotEmpty
                          ? EmptyState(icon: PhosphorIconsRegular.magnifyingGlass, title: 'No matches', message: 'Nobody named "$_query" in your inbox.')
                          : EmptyState(
                              icon: PhosphorIconsRegular.chatCircleDots,
                              title: 'No active discussions',
                              message: 'Browse the creator community or open projects to start a professional collaboration.',
                              ctaLabel: 'Find collaborators',
                              onCta: () => context.go('/creators'),
                            ),
                    for (final t in threads) Constrained(child: _ThreadRow(t, me: me)),
                    const SizedBox(height: S.x2),
                  ],
                );
              },
            ),
          ),
        ),
      ]),
    );
  }
}

class _NewApplicationRow extends StatelessWidget {
  const _NewApplicationRow(this.a);
  final Json a;

  @override
  Widget build(BuildContext context) {
    final applicant = a['applicant'] as Json?;
    return InkWell(
      onTap: () => context.push('/dashboard?tab=incoming'),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: S.md),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: C.divider, width: 0.5))),
        child: Row(children: [
          Avatar(url: applicant?['profilePhoto'] as String?, name: a['applicantName'] as String?, size: 44),
          const SizedBox(width: S.md),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text.rich(
                TextSpan(style: T.body, children: [
                  TextSpan(text: '${a['applicantName'] ?? 'Someone'}', style: T.body.semi),
                  TextSpan(text: ' applied as ${a['desiredRole'] ?? ''}'),
                ]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text('${a['projectTitle'] ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis, style: T.caption.muted),
            ]),
          ),
          Text('NEW', style: T.caption.size(10).bold.gold),
          const SizedBox(width: S.xs),
          const Icon(PhosphorIconsRegular.caretRight, size: 16, color: C.muted),
        ]),
      ),
    );
  }
}

class _ThreadRow extends StatelessWidget {
  const _ThreadRow(this.t, {required this.me});
  final Json t;
  final String? me;

  @override
  Widget build(BuildContext context) {
    final other = (t['other'] as Json?) ?? const {};
    final last = t['lastMessage'] as Json?;
    final unread = (t['unread'] as num? ?? 0).toInt();
    final preview = last == null ? 'Start the conversation' : '${last['senderId'] == me ? 'You: ' : ''}${last['content'] ?? ''}';

    return InkWell(
      onTap: () => openChat(context, other),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: S.md),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: C.divider, width: 0.5))),
        child: Row(children: [
          Avatar(url: other['profilePhoto'] as String?, name: other['name'] as String?, size: 52),
          const SizedBox(width: S.md),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text('${other['name'] ?? 'Unknown'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: T.body.semi.size(15))),
                Text(formatTime(last?['createdAt'] as String?), style: unread > 0 ? T.caption.size(11).gold : T.caption.size(11).muted),
              ]),
              const SizedBox(height: 2),
              Row(children: [
                Expanded(
                  child: Text(preview, maxLines: 1, overflow: TextOverflow.ellipsis, style: unread > 0 ? T.caption.medium : T.caption.muted),
                ),
                if (unread > 0) ...[
                  const SizedBox(width: S.sm),
                  Container(
                    constraints: const BoxConstraints(minWidth: 20),
                    height: 20,
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: C.brand, borderRadius: BorderRadius.circular(10)),
                    child: Text(unread > 99 ? '99+' : '$unread', style: T.caption.size(11).bold.col(C.onBrand)),
                  ),
                ],
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}
