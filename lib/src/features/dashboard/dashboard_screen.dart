// Creator dashboard (P2P-website/src/app/dashboard/page.tsx): my projects, incoming applications
// (shortlist / hire / reject / message) and the applications I sent.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api.dart';
import '../../core/data.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../ui/icons.dart';
import '../../ui/kit.dart';
import '../../ui/sheets.dart';
import '../auth/session.dart';
import '../inbox/open_chat.dart';

const _projectsPath = '$ptp/projects/mine';
const _incomingPath = '$ptp/applications/incoming';
const _sentPath = '$ptp/applications/sent';

const _tabs = ['projects', 'incoming', 'sent'];

List<Json> _list(dynamic d, String key) => ((d as Json?)?[key] as List? ?? const []).cast<Json>();

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key, this.tab});

  /// Initial tab: 'projects' | 'incoming' | 'sent'.
  final String? tab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Counts for the tab labels (the lists below share the same cached reads).
    int count(String path, String key) => _list(ref.watch(apiGet(path)).value, key).length;
    final projects = count(_projectsPath, 'projects');
    final incoming = count(_incomingPath, 'applications');
    final sent = count(_sentPath, 'applications');
    final name = ref.watch(sessionProvider.select((s) => s.profile?['name'] ?? s.account?.name));

    return DefaultTabController(
      length: _tabs.length,
      initialIndex: _tabs.indexOf(tab ?? '').clamp(0, _tabs.length - 1),
      child: Scaffold(
        appBar: AppHeader(
          title: 'CREATOR DASHBOARD',
          subtitle: name == null ? null : 'Welcome back, $name.',
          large: true,
          actions: [
            CircleIconButton(icon: PhosphorIconsRegular.pencilSimple, onTap: () => context.push('/edit-profile')),
            const SizedBox(width: S.sm),
            CircleIconButton(icon: PhosphorIconsRegular.plus, background: C.brand3, onTap: () => context.push('/project/new')),
          ],
        ),
        body: Column(children: [
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: C.brand,
            labelColor: C.brand,
            unselectedLabelColor: C.muted,
            dividerColor: C.divider,
            labelStyle: T.label.semi,
            tabs: [
              Tab(text: 'My projects ($projects)'),
              Tab(text: 'Incoming ($incoming)'),
              Tab(text: 'Sent ($sent)'),
            ],
          ),
          const Expanded(child: TabBarView(children: [_ProjectsTab(), _IncomingTab(), _SentTab()])),
        ]),
      ),
    );
  }
}

/// Pull-to-refresh list over one cached read; [empty] when the list has no items.
class _TabList extends ConsumerWidget {
  const _TabList({required this.path, required this.keyName, required this.item, required this.empty});
  final String path;
  final String keyName;
  final Widget Function(Json) item;
  final Widget empty;

  @override
  Widget build(BuildContext context, WidgetRef ref) => RefreshIndicator(
        color: C.brand,
        onRefresh: () => ref.refresh(apiGet(path).future),
        child: ApiView(
          path: path,
          loading: const Padding(padding: EdgeInsets.all(S.lg), child: Column(children: [CardSkeleton(), SizedBox(height: S.md), CardSkeleton()])),
          builder: (d) {
            final items = _list(d, keyName);
            if (items.isEmpty) return ListView(children: [empty]);
            return ListView.separated(
              padding: const EdgeInsets.all(S.lg),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: S.md),
              itemBuilder: (_, i) => Constrained(child: item(items[i])),
            );
          },
        ),
      );
}

/// Card frame shared by the three tabs.
class _Card extends StatelessWidget {
  const _Card({required this.child, this.onTap, this.highlight = false});
  final Widget child;
  final VoidCallback? onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) => Material(
        color: C.surface2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(R.md),
          side: BorderSide(color: highlight ? C.brand.withValues(alpha: 0.6) : C.border, width: highlight ? 1 : 0.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.all(S.lg), child: child)),
      );
}

// ───── My projects ─────

class _ProjectsTab extends StatelessWidget {
  const _ProjectsTab();

  @override
  Widget build(BuildContext context) => _TabList(
        path: _projectsPath,
        keyName: 'projects',
        item: (p) => _ProjectRow(p),
        empty: EmptyState(
          icon: PhosphorIconsRegular.filmSlate,
          title: 'No projects yet',
          message: 'Post your script to get it reviewed and start building your team.',
          ctaLabel: 'Post a project',
          onCta: () => context.push('/project/new'),
        ),
      );
}

class _ProjectRow extends StatelessWidget {
  const _ProjectRow(this.p);
  final Json p;

  @override
  Widget build(BuildContext context) {
    final rejected = isRejected(p);
    return _Card(
      onTap: () => context.push('/project/${p['id']}'),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(R.sm),
          child: Container(
            width: 56,
            height: 56,
            color: C.surface3,
            child: '${p['projectImageUrl'] ?? ''}'.isEmpty
                ? const Icon(PhosphorIconsRegular.filmSlate, color: C.muted)
                : NetImage(p['projectImageUrl'] as String, width: 56, height: 56),
          ),
        ),
        const SizedBox(width: S.md),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${p['title'] ?? 'Untitled'}'.toUpperCase(), maxLines: 2, overflow: TextOverflow.ellipsis, style: T.subtitle),
            const SizedBox(height: 2),
            Text(joinNonEmpty([p['id'], p['genre'], if (shortDate(p['createdAt'] as String?).isNotEmpty) 'Created ${shortDate(p['createdAt'] as String?)}'], ' · '),
                style: T.caption.muted),
            const SizedBox(height: S.sm),
            Wrap(spacing: S.sm, runSpacing: S.xs, children: [
              ProjectStatusBadge(p['status'] as String?),
              if (p['deletedAt'] != null) const StatusBadge('Removed', tone: Tone.error),
            ]),
            if (rejected) ...[
              const SizedBox(height: S.sm),
              Text('Only you can see this project, and it can no longer be edited.', style: T.caption.col(C.error)),
            ],
          ]),
        ),
        const Icon(PhosphorIconsRegular.caretRight, size: 18, color: C.muted),
      ]),
    );
  }
}

// ───── Incoming applications ─────

class _IncomingTab extends StatelessWidget {
  const _IncomingTab();

  @override
  Widget build(BuildContext context) => _TabList(
        path: _incomingPath,
        keyName: 'applications',
        item: (a) => _IncomingCard(a, key: ValueKey(a['id'])),
        empty: EmptyState(
          icon: PhosphorIconsRegular.usersThree,
          title: 'No applications yet',
          message: 'When people apply to your projects, they show up here.',
          ctaLabel: 'Post a project',
          onCta: () => context.push('/project/new'),
        ),
      );
}

class _IncomingCard extends ConsumerStatefulWidget {
  const _IncomingCard(this.a, {super.key});
  final Json a;

  @override
  ConsumerState<_IncomingCard> createState() => _IncomingCardState();
}

class _IncomingCardState extends ConsumerState<_IncomingCard> {
  bool _expanded = false;
  bool _busy = false;

  Json get a => widget.a;

  bool get _unread => a['creatorRead'] != true;

  /// Seeing (or acting on) an application marks it read; best effort.
  Future<void> _markRead() async {
    if (!_unread) return;
    try {
      await ref.read(apiClientProvider).patch('$ptp/applications/${a['id']}/read', {});
      ref.invalidate(apiGet(_incomingPath));
    } on ApiException {
      // Stays "new" until the next open.
    }
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _markRead();
  }

  Future<void> _setStatus(String status, String done) async {
    setState(() => _busy = true);
    await runAction(context, ref, () async {
      await _markRead();
      await ref.read(apiClientProvider).patch('$ptp/applications/${a['id']}/status', {'status': status});
    }, success: done);
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _hire() async {
    final ok = await confirmDialog(
      context,
      title: 'Hire ${a['applicantName']}?',
      message: 'Hire ${a['applicantName']} as ${a['desiredRole']}? This closes the role on ${a['projectTitle']}.',
      confirm: 'Hire',
    );
    if (ok) await _setStatus('Selected', '${a['applicantName']} is hired');
  }

  Future<void> _reject() async {
    final ok = await confirmDialog(
      context,
      title: 'Reject application?',
      message: '${a['applicantName']} will be told they were not selected for ${a['desiredRole']}.',
      confirm: 'Reject',
    );
    if (ok) await _setStatus('Rejected', 'Application rejected');
  }

  void _message() {
    _markRead();
    openChat(context, (a['applicant'] as Json?) ?? {'authUid': a['applicantId'], 'name': a['applicantName'], 'id': a['applicantPtpcId']});
  }

  @override
  Widget build(BuildContext context) {
    final status = a['status'] as String?;
    final open = status == 'Applied' || status == 'Shortlisted';
    final applicant = a['applicant'] as Json?;
    final name = '${a['applicantName'] ?? applicant?['name'] ?? 'Applicant'}';
    final message = '${a['message'] ?? ''}'.trim();

    return _Card(
      onTap: _toggle,
      highlight: _unread,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          GestureDetector(
            onTap: () => context.push('/profile/${a['applicantPtpcId']}'),
            child: Avatar(url: applicant?['profilePhoto'] as String?, name: name, size: 44),
          ),
          const SizedBox(width: S.md),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(
                  child: GestureDetector(
                    onTap: () => context.push('/profile/${a['applicantPtpcId']}'),
                    child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.subtitle),
                  ),
                ),
                if (_unread) ...[
                  const SizedBox(width: S.sm),
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: C.brand, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Text('NEW', style: T.caption.size(10).bold.gold),
                ],
              ]),
              Text('${a['desiredRole'] ?? ''}'.toUpperCase(), style: T.caption.muted.copyWith(letterSpacing: 1)),
            ]),
          ),
          applicationBadge(status),
        ]),
        const SizedBox(height: S.md),
        GestureDetector(
          onTap: () => context.push('/project/${a['projectId']}'),
          child: Text.rich(TextSpan(style: T.body.muted, children: [
            const TextSpan(text: 'Applied to '),
            TextSpan(text: '${a['projectTitle'] ?? a['projectId']}', style: T.body.semi),
          ])),
        ),
        if ('${a['compensation'] ?? ''}'.isNotEmpty) Text('${a['compensation']}', style: T.body.semi.gold),
        if (message.isNotEmpty) ...[
          const SizedBox(height: S.sm),
          Container(
            padding: const EdgeInsets.only(left: S.md),
            decoration: BoxDecoration(border: Border(left: BorderSide(color: C.brand.withValues(alpha: 0.3), width: 2))),
            child: Text(
              '"$message"',
              maxLines: _expanded ? null : 2,
              overflow: _expanded ? null : TextOverflow.ellipsis,
              style: T.caption.muted.copyWith(fontStyle: FontStyle.italic),
            ),
          ),
        ],
        if (_expanded) ...[
          const SizedBox(height: S.sm),
          Text(
            joinNonEmpty(['Applied ${shortDate(a['createdAt'] as String?)}', if (a['ndaAccepted'] == true) 'NDA accepted'], ' · '),
            style: T.caption.muted,
          ),
        ],
        const SizedBox(height: S.md),
        Wrap(spacing: S.sm, runSpacing: S.sm, children: [
          if (status == 'Applied')
            AppButton('Shortlist', small: true, fullWidth: false, variant: BtnVariant.outline, loading: _busy, onPressed: () => _setStatus('Shortlisted', '$name is shortlisted')),
          if (open) AppButton('Hire', small: true, fullWidth: false, loading: _busy, onPressed: _hire),
          if (open) AppButton('Reject', small: true, fullWidth: false, variant: BtnVariant.secondary, loading: _busy, onPressed: _reject),
          AppButton('Message',
              small: true, fullWidth: false, variant: BtnVariant.ghost, icon: const Icon(PhosphorIconsRegular.chatCircleText, size: 16, color: C.brand), onPressed: _message),
        ]),
      ]),
    );
  }
}

// ───── Sent applications ─────

/// What each status means for the applicant.
const _sentHints = {
  'Applied': 'Waiting for the creator to review your application.',
  'Shortlisted': "You're on the shortlist. The creator may reach out soon.",
  'Selected': "You're hired! The creator will be in touch about next steps.",
  'Rejected': 'The creator went with someone else this time.',
};

class _SentTab extends StatelessWidget {
  const _SentTab();

  @override
  Widget build(BuildContext context) => _TabList(
        path: _sentPath,
        keyName: 'applications',
        item: (a) => _Card(
          onTap: () => context.push('/project/${a['projectId']}'),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${a['projectTitle'] ?? a['projectId']}'.toUpperCase(), maxLines: 2, overflow: TextOverflow.ellipsis, style: T.subtitle),
                  Text('Role: ${a['desiredRole'] ?? ''}'.toUpperCase(), style: T.caption.muted.copyWith(letterSpacing: 1)),
                ]),
              ),
              applicationBadge(a['status'] as String?),
            ]),
            const SizedBox(height: S.sm),
            if (_sentHints[a['status']] != null) Text(_sentHints[a['status']]!, style: T.body.muted),
            Row(children: [
              Expanded(child: Text('Applied ${shortDate(a['createdAt'] as String?)}', style: T.caption.muted)),
              if (a['creator'] is Json)
                AppButton(
                  'Message creator',
                  small: true,
                  fullWidth: false,
                  variant: BtnVariant.ghost,
                  icon: const Icon(PhosphorIconsRegular.chatCircle, size: 16, color: C.brand),
                  onPressed: () => openChat(context, a['creator'] as Json),
                ),
            ]),
          ]),
        ),
        empty: EmptyState(
          icon: PhosphorIconsRegular.paperPlaneRight,
          title: "You haven't applied yet",
          message: 'Browse open scripts and apply for a role on a project you love.',
          ctaLabel: 'Browse projects',
          onCta: () => context.go('/projects'),
        ),
      );
}
