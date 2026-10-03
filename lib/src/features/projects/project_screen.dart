// Project detail: hero, logline, hiring roles + 2-step apply (NDA → role & message), creator card,
// owner tools. Ported from P2P-website/src/app/projects/[id]/page.tsx.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/api.dart';
import '../../core/data.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../ui/icons.dart';
import '../../ui/kit.dart';
import '../../ui/sheets.dart';
import '../auth/session.dart';
import '../inbox/open_chat.dart';
import 'project_card.dart';

class ProjectScreen extends ConsumerWidget {
  const ProjectScreen(this.id, {super.key});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(apiGet('$ptp/projects/$id'));
    final p = (async.value as Json?)?['project'] as Json?;
    if (p != null) return Scaffold(body: _Detail(p: p));

    final notFound = async.error is ApiException && (async.error as ApiException).statusCode == 404;
    return Scaffold(
      appBar: const AppHeader(),
      body: !async.hasError
          ? const Center(child: CircularProgressIndicator())
          : notFound
              ? EmptyState(
                  icon: PhosphorIconsRegular.filmSlate,
                  title: 'PROJECT NOT FOUND',
                  message: 'This script may have been removed or archived.',
                  ctaLabel: 'Browse all projects',
                  onCta: () => context.go('/projects'),
                )
              : EmptyState(
                  icon: PhosphorIconsRegular.warningCircle,
                  title: 'Could not load',
                  message: '${async.error}',
                  ctaLabel: 'Retry',
                  onCta: () => ref.invalidate(apiGet('$ptp/projects/$id')),
                ),
    );
  }
}

class _Detail extends ConsumerWidget {
  const _Detail({required this.p});
  final Json p;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final id = '${p['id']}';
    final isOwner = session.signedIn && session.account?.id == p['creatorUid'];
    final readOnly = isRejected(p);
    final roleList = projectRoles(p);
    final openRoles = roleList.where((r) => roleOpen(p, r)).toList();
    final hasApplied = session.signedIn && !isOwner && (ref.watch(apiGet('$ptp/projects/$id/applied')).value as Json?)?['hasApplied'] == true;
    final canApply = !isOwner && !hasApplied && !readOnly && openRoles.isNotEmpty;

    void apply([String? role]) {
      if (!session.signedIn) {
        context.push('/login');
        return;
      }
      showApplySheet(context, p, openRoles: openRoles, role: role);
    }

    final topInset = MediaQuery.paddingOf(context).top;
    final scriptUrl = '${p['scriptUrl'] ?? ''}';

    return Column(children: [
      Expanded(
        child: ListView(padding: EdgeInsets.zero, children: [
          SizedBox(
            height: 280 + topInset,
            child: Stack(fit: StackFit.expand, children: [
              ProjectCover(p, titleSize: 30),
              const Scrim(to: C.surface),
              Positioned(
                top: topInset + S.sm,
                left: S.lg,
                right: S.lg,
                child: Row(children: [
                  CircleIconButton(icon: PhosphorIconsBold.caretLeft, background: C.overlay, onTap: () => context.popOr('/projects')),
                  const Spacer(),
                  CircleIconButton(
                    icon: PhosphorIconsRegular.shareNetwork,
                    background: C.overlay,
                    onTap: () => SharePlus.instance.share(ShareParams(
                      text: 'Pitch To Picture: ${p['title']}\n${p['logline'] ?? ''}\nhttps://pitchtopicture.in/projects/$id',
                    )),
                  ),
                ]),
              ),
            ]),
          ),
          Constrained(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(S.lg, 0, S.lg, S.xl),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Wrap(spacing: S.sm, runSpacing: S.sm, children: [ProjectStatusBadge(p['status'] as String?), StatusBadge(id)]),
                const SizedBox(height: S.sm),
                Text('${p['title'] ?? ''}'.toUpperCase(), style: T.display.size(28)),
                const SizedBox(height: S.sm),
                Wrap(spacing: S.lg, runSpacing: S.xs, children: [
                  if ('${p['genre'] ?? ''}'.isNotEmpty) _iconText(PhosphorIconsRegular.filmSlate, '${p['genre']}'),
                  if ('${p['language'] ?? ''}'.isNotEmpty) _iconText(PhosphorIconsRegular.translate, '${p['language']}'),
                  if ('${p['location'] ?? ''}'.isNotEmpty) _iconText(PhosphorIconsRegular.mapPin, '${p['location']}'),
                ]),
                if (isOwner && readOnly) ...[
                  const SizedBox(height: S.md),
                  _Notice(
                    icon: PhosphorIconsRegular.prohibit,
                    color: C.error,
                    title: 'NOT APPROVED',
                    text: "This script wasn't approved. Only you can see this project, and it can't be edited.",
                  ),
                ],
                const SizedBox(height: S.xl),
                const SectionLabel('Story logline'),
                Text('"${p['logline'] ?? ''}"', style: T.body.size(17).muted.copyWith(fontStyle: FontStyle.italic, height: 1.6)),
                if (strList(p['tags']).isNotEmpty) ...[
                  const SizedBox(height: S.md),
                  Wrap(spacing: S.sm, runSpacing: S.sm, children: [for (final t in strList(p['tags'])) AppChip('#$t', small: true)]),
                ],
                if (isOwner) ...[
                  const SizedBox(height: S.xl),
                  const SectionLabel('Your project'),
                  _ToolTile(PhosphorIconsRegular.pencilSimple, 'Edit hiring', readOnly ? null : () => context.push('/project/$id/hiring')),
                  _ToolTile(PhosphorIconsRegular.tray, 'Applications', () => context.push('/dashboard?tab=incoming')),
                  if (scriptUrl.isNotEmpty) _ToolTile(PhosphorIconsRegular.filePdf, 'View script', () => openExternal(scriptUrl)),
                ],
                const SizedBox(height: S.xl),
                const SectionLabel('Hiring'),
                if (openRoles.isEmpty)
                  Padding(padding: const EdgeInsets.only(bottom: S.sm), child: Text('All roles are filled.', style: T.body.muted)),
                for (final role in roleList)
                  _RoleCard(
                    role: role,
                    open: roleOpen(p, role),
                    // Owners and people who already applied see the status only.
                    onApply: isOwner || hasApplied ? null : (readOnly || !roleOpen(p, role) ? null : () => apply(role)),
                    showButton: !isOwner && !hasApplied,
                  ),
                const SizedBox(height: S.lg),
                const SectionLabel('Creator'),
                _CreatorCard(p: p, isOwner: isOwner),
                const SizedBox(height: S.lg),
                const _Notice(
                  icon: PhosphorIconsRegular.lockSimple,
                  color: C.error,
                  title: 'NDA REQUIRED',
                  text: 'Full project details and script access require a signed Non-Disclosure Agreement. '
                      'Accepting an NDA records your identity for legal verification.',
                ),
                const SizedBox(height: S.lg),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(PhosphorIconsRegular.shieldCheck, size: 13, color: C.muted),
                  const SizedBox(width: 5),
                  Text('PTP ADMIN APPROVED', style: T.caption.size(10).muted.copyWith(letterSpacing: 1.2)),
                ]),
              ]),
            ),
          ),
        ]),
      ),
      if (!isOwner)
        Container(
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: C.divider, width: 0.5))),
          padding: const EdgeInsets.fromLTRB(S.lg, S.md, S.lg, S.md),
          child: SafeArea(
            top: false,
            child: Constrained(
              child: AppButton(
                hasApplied
                    ? 'Application sent'
                    : readOnly
                        ? 'Not accepting applications'
                        : openRoles.isEmpty
                            ? 'Roles closed'
                            : 'Apply for role',
                variant: canApply ? BtnVariant.primary : BtnVariant.secondary,
                icon: hasApplied ? const Icon(PhosphorIconsBold.check, size: 18, color: C.onSurface) : null,
                onPressed: canApply ? apply : null,
              ),
            ),
          ),
        ),
    ]);
  }
}

Widget _iconText(IconData icon, String text) => Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 15, color: C.brand),
      const SizedBox(width: 5),
      Flexible(child: Text(text, style: T.body.size(13).muted)),
    ]);

class _ToolTile extends StatelessWidget {
  const _ToolTile(this.icon, this.label, this.onTap);
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: S.sm),
        child: Opacity(
          opacity: onTap == null ? 0.5 : 1,
          child: Material(
            color: C.surface2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(R.md), side: const BorderSide(color: C.border, width: 0.5)),
            child: InkWell(
              borderRadius: BorderRadius.circular(R.md),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: S.lg, vertical: 14),
                child: Row(children: [
                  Icon(icon, size: 20, color: C.brand),
                  const SizedBox(width: S.md),
                  Expanded(child: Text(label, style: T.body.medium)),
                  const Icon(PhosphorIconsRegular.caretRight, size: 16, color: C.muted),
                ]),
              ),
            ),
          ),
        ),
      );
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({required this.role, required this.open, required this.onApply, required this.showButton});
  final String role;
  final bool open;
  final VoidCallback? onApply;
  final bool showButton;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: S.sm),
        padding: const EdgeInsets.all(S.lg),
        decoration: BoxDecoration(color: C.surface2, borderRadius: BorderRadius.circular(R.md), border: Border.all(color: C.border, width: 0.5)),
        child: Row(children: [
          Icon(PhosphorIconsRegular.users, size: 20, color: open ? C.brand : C.muted),
          const SizedBox(width: S.md),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(role.toUpperCase(), style: T.body.semi),
              Text(open ? 'OPEN FOR APPLICATIONS' : 'CURRENTLY CLOSED', style: T.caption.size(10).col(open ? C.brand : C.muted).copyWith(letterSpacing: 1)),
            ]),
          ),
          if (showButton && open) AppButton('Apply', small: true, fullWidth: false, variant: BtnVariant.outline, onPressed: onApply),
          if (showButton && !open) const StatusBadge('Closed'),
        ]),
      );
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.color, required this.title, required this.text});
  final IconData icon;
  final Color color;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(S.lg),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(R.md),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(title, style: T.caption.size(11).semi.col(color).copyWith(letterSpacing: 1.2))),
            Icon(icon, size: 16, color: color),
          ]),
          const SizedBox(height: S.xs),
          Text(text, style: T.caption.muted),
        ]),
      );
}

/// Creator name/photo from their public profile; falls back to "Verified Creator" while loading.
class _CreatorCard extends ConsumerWidget {
  const _CreatorCard({required this.p, required this.isOwner});
  final Json p;
  final bool isOwner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ptpcId = p['creatorPtpcId'] as String?;
    final profile = ptpcId == null ? null : (ref.watch(apiGet('$ptp/profiles/$ptpcId')).value as Json?)?['profile'] as Json?;
    final name = '${profile?['name'] ?? ''}'.trim().isEmpty ? 'Verified Creator' : '${profile!['name']}';
    final sub = joinNonEmpty([strList(profile?['roles']).join(', '), locationOf(profile ?? const {})], ' · ');

    return Container(
      padding: const EdgeInsets.all(S.lg),
      decoration: BoxDecoration(color: C.surface2, borderRadius: BorderRadius.circular(R.md), border: Border.all(color: C.border, width: 0.5)),
      child: Column(children: [
        InkWell(
          onTap: ptpcId == null ? null : () => context.push('/profile/$ptpcId'),
          child: Row(children: [
            Avatar(url: profile?['profilePhoto'] as String?, name: name, size: 48),
            const SizedBox(width: S.md),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: T.body.semi),
                Text(sub.isEmpty ? (ptpcId ?? '') : sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.caption.muted),
              ]),
            ),
            const Icon(PhosphorIconsRegular.caretRight, size: 16, color: C.muted),
          ]),
        ),
        if (!isOwner) ...[
          const SizedBox(height: S.md),
          AppButton(
            'Message',
            small: true,
            variant: BtnVariant.outline,
            icon: const Icon(PhosphorIconsRegular.chatCircleText, size: 16, color: C.onSurface),
            onPressed: () => ref.read(sessionProvider).signedIn
                ? openChat(context, {'authUid': p['creatorUid'], 'name': profile?['name'] ?? '', 'id': ptpcId, 'profilePhoto': profile?['profilePhoto']})
                : context.push('/login'),
          ),
        ],
      ]),
    );
  }
}

// ───── Apply ─────

/// Website NDA text, verbatim.
const _ndaClauses = [
  'I shall keep all project related information completely confidential at all times.',
  'I shall not copy, screenshot, photograph, record, download, reproduce, store, publish, leak, distribute, forward, sell, discuss, or share any project material or information in any form, whether digitally, verbally, physically, or through third parties.',
  'I shall not use any part of the project, including ideas, scenes, dialogues, concepts, characters, plot structures, visual styles, or creative elements for personal benefit, commercial use, external submissions, AI training, content creation, or any unauthorized purpose.',
  'I shall not upload, submit, or expose any project material to AI tools, public platforms, cloud storage, social media, messaging applications, or third party software or services.',
  'I understand that all materials remain the exclusive intellectual property of the Project Owner and that access to such materials does not provide me with any ownership, license, adaptation, reproduction, or usage rights.',
  'I agree that my confidentiality obligations shall continue even if I am not selected, removed, rejected, or voluntarily leave the project.',
  'I understand that any unauthorized disclosure, misuse, imitation, reproduction, or leakage of confidential material may cause serious financial and creative damage to the Project Owner.',
  'I acknowledge that violations may result in immediate legal action, monetary claims, recovery of damages, injunctions, permanent platform suspension, and civil or criminal proceedings wherever applicable under law.',
];

Widget _ndaText() {
  final s = T.caption.size(12).col(C.onSurface3).copyWith(height: 1.55);
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('NON DISCLOSURE AGREEMENT', style: s.semi),
    const SizedBox(height: S.xs),
    Text('APPLICANT NON DISCLOSURE AND CONFIDENTIALITY AGREEMENT', style: s.semi),
    const SizedBox(height: S.sm),
    Text(
      'By applying for this role, I acknowledge that I may gain access to confidential, private, and unreleased creative materials belonging to the Project Owner, including but not limited to scripts, storylines, concepts, dialogues, characters, casting information, production discussions, visual references, trailers, audition materials, business information, and other intellectual property.',
      style: s,
    ),
    const SizedBox(height: S.sm),
    Text('I legally agree that:', style: s),
    for (final c in _ndaClauses)
      Padding(
        padding: const EdgeInsets.only(top: S.sm),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('•  ', style: s), Expanded(child: Text(c, style: s))]),
      ),
    const SizedBox(height: S.sm),
    Text(
      'By clicking "I Agree" and applying for this role, I confirm that I have read, understood, and voluntarily accepted this legally binding confidentiality agreement.',
      style: s,
    ),
  ]);
}

/// Two steps: (1) read + accept the NDA (recorded via POST /nda), (2) role, compensation, message.
/// Unlike the website, the NDA step is never skipped — even when opened from a role card.
Future<void> showApplySheet(BuildContext context, Json p, {required List<String> openRoles, String? role}) {
  final compensation = TextEditingController();
  final message = TextEditingController();
  var step = 1;
  var agreed = false;
  var busy = false;
  var selected = role ?? (openRoles.length == 1 ? openRoles.first : null);
  final path = '$ptp/projects/${p['id']}';

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => Consumer(builder: (ctx, ref, _) {
      final api = ref.read(apiClientProvider);
      return StatefulBuilder(builder: (ctx, setState) {
        Future<void> acceptNda() async {
          setState(() => busy = true);
          final ok = await runAction(ctx, ref, () async {
            await api.post('$path/nda');
            return true;
          }, refresh: false);
          if (!ctx.mounted) return;
          setState(() {
            busy = false;
            if (ok == true) step = 2;
          });
        }

        Future<void> submit() async {
          if (selected == null) return toast(ctx, 'Choose the role you want to apply for.', tone: Tone.error);
          if (message.text.trim().isEmpty) return toast(ctx, 'Add a message to the creator.', tone: Tone.error);
          setState(() => busy = true);
          final ok = await runAction(ctx, ref, () async {
            await api.post('$path/apply', {
              'desiredRole': selected,
              'message': message.text.trim(),
              'compensation': compensation.text.trim(),
              'ndaAccepted': true,
            });
            return true;
          });
          if (!ctx.mounted) return;
          setState(() => busy = false);
          if (ok == true) {
            Navigator.pop(ctx);
            if (context.mounted) toast(context, 'Application submitted. Successfully applied as $selected.', tone: Tone.success);
          }
        }

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(S.lg, 0, S.lg, MediaQuery.viewInsetsOf(ctx).bottom + S.lg),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('PROJECT APPLICATION', style: T.display.size(20)),
            Text(step == 1 ? 'Step 1 of 2 · Non-Disclosure Agreement' : 'Step 2 of 2 · Role & negotiation', style: T.caption.muted),
            const SizedBox(height: S.lg),
            if (step == 1) ...[
              Container(
                constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.4),
                decoration: BoxDecoration(color: C.surface3, borderRadius: BorderRadius.circular(R.md), border: Border.all(color: C.border, width: 0.5)),
                child: Scrollbar(child: SingleChildScrollView(padding: const EdgeInsets.all(S.lg), child: _ndaText())),
              ),
              const SizedBox(height: S.md),
              InkWell(
                onTap: () => setState(() => agreed = !agreed),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Checkbox(value: agreed, onChanged: (v) => setState(() => agreed = v ?? false)),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        'I have read, understood, and agree to this Applicant Non Disclosure and Confidentiality Agreement.',
                        style: T.caption.col(C.onSurface3),
                      ),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: S.lg),
              AppButton('I agree', loading: busy, onPressed: agreed ? acceptNda : null),
            ] else ...[
              SelectorField(
                label: 'Desired role',
                placeholder: openRoles.isEmpty ? 'No open roles available' : 'Select a role…',
                value: selected ?? '',
                onTap: () async {
                  final pick = await showSelectSheet(ctx, title: 'Desired role', options: openRoles, selected: [?selected], searchable: false);
                  if (pick != null && pick.isNotEmpty) setState(() => selected = pick.first);
                },
              ),
              const SizedBox(height: S.md),
              AppInput(label: 'Expected compensation (optional)', controller: compensation, hint: 'e.g. 5000/Day or Project Basis', maxLength: 191),
              const SizedBox(height: S.xs),
              Text('Define your day-pay or project fee expectations.', style: T.caption.size(11).muted),
              const SizedBox(height: S.md),
              AppInput(label: 'Message to creator', controller: message, hint: 'Describe your interest and experience…', multiline: true, maxLength: 5000),
              const SizedBox(height: S.lg),
              Row(children: [
                Expanded(child: AppButton('Back', variant: BtnVariant.ghost, onPressed: busy ? null : () => setState(() => step = 1))),
                const SizedBox(width: S.md),
                Expanded(flex: 2, child: AppButton('Submit application', loading: busy, onPressed: submit)),
              ]),
            ],
          ]),
        );
      });
    }),
  );
}
