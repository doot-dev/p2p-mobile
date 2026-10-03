// Public profile, my profile tab, edit profile, settings — ported from P2P-website/src/app/profile/[id]/page.tsx
// and profile/edit/page.tsx; Settings mirrors the Portfolio app.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/data.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../ui/icons.dart';
import '../../ui/kit.dart';
import '../../ui/sheets.dart';
import '../auth/auth_screens.dart';
import '../auth/session.dart';
import '../inbox/open_chat.dart';

/// Stored links may be bare ("instagram.com/x", "@x"); make them openable.
String _href(String v) => v.startsWith('http')
    ? v
    : v.startsWith('@')
        ? 'https://instagram.com/${v.substring(1)}'
        : 'https://$v';

void _share(String? id) => SharePlus.instance.share(ShareParams(text: 'https://pitchtopicture.in/profile/$id'));

// ───── Public profile ─────

class PublicProfileScreen extends ConsumerWidget {
  const PublicProfileScreen(this.id, {super.key});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = '$ptp/profiles/$id';
    final async = ref.watch(apiGet(path));
    final p = (async.value as Json?)?['profile'] as Json?;
    return Scaffold(
      appBar: AppHeader(
        title: p?['name'] as String?,
        onBack: () => context.popOr('/creators'),
        actions: [CircleIconButton(icon: PhosphorIconsRegular.shareNetwork, onTap: () => _share(id))],
      ),
      body: p == null
          ? (async.hasError
              ? EmptyState(icon: PhosphorIconsRegular.user, title: 'Profile not found', message: '${async.error}', ctaLabel: 'Retry', onCta: () => ref.invalidate(apiGet(path)))
              : const Center(child: CircularProgressIndicator()))
          : RefreshIndicator(
              color: C.brand,
              onRefresh: () => ref.refresh(apiGet(path).future),
              child: ListView(padding: const EdgeInsets.only(bottom: S.x2), children: [Constrained(child: _ProfileBody(p))]),
            ),
    );
  }
}

// ───── My profile (tab) ─────

class MeScreen extends ConsumerWidget {
  const MeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(sessionProvider).profile;
    if (p == null) return const SizedBox.shrink();
    const menu = <(IconData, String, String)>[
      (PhosphorIconsRegular.squaresFour, 'Creator dashboard', '/dashboard'),
      (PhosphorIconsRegular.plus, 'Post a project', '/project/new'),
      (PhosphorIconsRegular.pencilSimple, 'Edit profile', '/edit-profile'),
      (PhosphorIconsRegular.gearSix, 'Settings', '/settings'),
    ];
    const about = <(IconData, String, String)>[
      (PhosphorIconsRegular.filmReel, 'The Show', '/show'),
      (PhosphorIconsRegular.gavel, 'Rules', '/legal/rules'),
      (PhosphorIconsRegular.envelopeSimple, 'Contact us', '/contact'),
    ];
    return Scaffold(
      body: Column(children: [
        TabHeader(
          title: 'PROFILE',
          trailing: [
            CircleIconButton(icon: PhosphorIconsRegular.shareNetwork, onTap: () => _share(p['id'] as String?)),
            const SizedBox(width: S.sm),
            CircleIconButton(icon: PhosphorIconsRegular.gearSix, onTap: () => context.push('/settings')),
          ],
        ),
        Expanded(
          child: RefreshIndicator(
            color: C.brand,
            onRefresh: () async {
              ref.invalidate(apiGet);
              await ref.read(sessionProvider.notifier).reload();
            },
            child: ListView(padding: const EdgeInsets.only(bottom: S.x2), children: [
              Constrained(child: _ProfileBody(p, isSelf: true)),
              Constrained(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: S.lg),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    _Menu(menu),
                    const SizedBox(height: S.xl),
                    const SectionLabel('Pitch To Picture'),
                    _Menu(about),
                  ]),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _Menu extends StatelessWidget {
  const _Menu(this.items);
  final List<(IconData, String, String)> items;

  @override
  Widget build(BuildContext context) => _Card([
        for (final (icon, label, route) in items) _Row(label, icon: icon, onTap: () => context.push(route)),
      ]);
}

/// Bordered surface card with dividers between its rows.
class _Card extends StatelessWidget {
  const _Card(this.children);
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: C.surface2, borderRadius: BorderRadius.circular(R.md), border: Border.all(color: C.border, width: 0.5)),
        child: Column(children: [
          for (final (i, c) in children.indexed) ...[if (i > 0) const Divider(), c],
        ]),
      );
}

class _Row extends StatelessWidget {
  const _Row(this.label, {this.icon, this.onTap, this.color, this.trailing});
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final Color? color;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(S.lg),
          child: Row(children: [
            if (icon != null) ...[Icon(icon, size: 20, color: color ?? C.onSurface2), const SizedBox(width: S.md)],
            Expanded(child: Text(label, style: T.body.col(color ?? C.onSurface))),
            trailing ?? (onTap == null ? const SizedBox() : const Icon(PhosphorIconsRegular.caretRight, size: 16, color: C.muted)),
          ]),
        ),
      );
}

// ───── Shared profile view ─────

class _ProfileBody extends ConsumerWidget {
  const _ProfileBody(this.p, {this.isSelf = false});
  final Json p;
  final bool isSelf;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final self = isSelf || (session.ptpcId != null && session.ptpcId == p['id']);
    final rs = strList(p['roles']);
    final langs = strList(p['languages']);
    final loc = locationOf(p);
    final bio = '${p['bio'] ?? ''}'.trim();
    final exp = '${p['experience'] ?? ''}'.trim();
    final links = [
      (PhosphorIconsRegular.playCircle, 'Showreel', p['showreelUrl']),
      (PhosphorIconsRegular.briefcase, 'Portfolio', p['portfolioUrl']),
      (PhosphorIconsRegular.instagramLogo, 'Instagram', p['instagramUrl']),
      (PhosphorIconsRegular.globe, 'Website', p['websiteUrl']),
    ].where((l) => '${l.$3 ?? ''}'.trim().isNotEmpty).toList();

    Widget meta(IconData icon, String text) => Padding(
          padding: const EdgeInsets.only(top: S.xs),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 14, color: C.muted),
            const SizedBox(width: S.xs),
            Flexible(child: Text(text, style: T.body.muted)),
          ]),
        );

    return Padding(
      padding: const EdgeInsets.all(S.lg),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Center(child: Avatar(url: p['profilePhoto'] as String?, name: p['name'] as String?, size: 112)),
        const SizedBox(height: S.md),
        Text('${p['name'] ?? ''}'.toUpperCase(), textAlign: TextAlign.center, style: T.display),
        const SizedBox(height: S.sm),
        Center(child: StatusBadge('${p['id'] ?? ''}', tone: Tone.brand)),
        if (rs.isNotEmpty) ...[
          const SizedBox(height: S.md),
          Wrap(alignment: WrapAlignment.center, spacing: S.xs, runSpacing: S.xs, children: [for (final r in rs) AppChip(r, small: true, selected: true)]),
        ],
        const SizedBox(height: S.sm),
        Column(children: [
          if (loc.isNotEmpty) meta(PhosphorIconsRegular.mapPin, loc),
          if (exp.isNotEmpty) meta(PhosphorIconsRegular.briefcase, 'Experience: $exp'),
          if (langs.isNotEmpty) meta(PhosphorIconsRegular.translate, langs.join(', ')),
        ]),
        const SizedBox(height: S.lg),
        if (self)
          AppButton('Edit profile', variant: BtnVariant.secondary, icon: const Icon(PhosphorIconsRegular.pencilSimple, size: 18), onPressed: () => context.push('/edit-profile'))
        else
          Row(children: [
            Expanded(
              child: AppButton(
                'Message',
                icon: const Icon(PhosphorIconsRegular.chatCircleText, size: 18, color: C.onBrand),
                onPressed: () => session.signedIn ? openChat(context, p) : context.push('/login'),
              ),
            ),
            const SizedBox(width: S.md),
            Expanded(child: AppButton('Contact info', variant: BtnVariant.secondary, onPressed: () => _showContact(context, p, signedIn: session.signedIn))),
          ]),
        const SizedBox(height: S.xl),
        const SectionLabel('About'),
        Text(bio.isEmpty ? (self ? 'Add a short bio so people know your work.' : 'No bio yet.') : bio, style: bio.isEmpty ? T.body.muted : T.body),
        if (links.isNotEmpty) ...[
          const SizedBox(height: S.xl),
          const SectionLabel('Links'),
          _Card([
            for (final (icon, label, url) in links)
              _Row(label, icon: icon, onTap: () => openExternal(_href('$url'.trim())), trailing: const Icon(PhosphorIconsRegular.arrowSquareOut, size: 16, color: C.muted)),
          ]),
        ],
      ]),
    );
  }
}

/// Website's "Contact info" dialog: each row copies, and opens with mailto: / tel: / the link.
/// The API strips email + phone for signed-out viewers.
Future<void> _showContact(BuildContext context, Json p, {required bool signedIn}) {
  String v(String k) => '${p[k] ?? ''}'.trim();
  final rows = [
    (PhosphorIconsRegular.envelopeSimple, 'Email', v('email'), 'mailto:${v('email')}'),
    (PhosphorIconsRegular.phone, 'Phone', v('phoneNumber'), 'tel:${v('phoneNumber').replaceAll(' ', '')}'),
    (PhosphorIconsRegular.briefcase, 'Portfolio', v('portfolioUrl'), _href(v('portfolioUrl'))),
    (PhosphorIconsRegular.instagramLogo, 'Instagram', v('instagramUrl'), _href(v('instagramUrl'))),
    (PhosphorIconsRegular.globe, 'Website', v('websiteUrl'), _href(v('websiteUrl'))),
  ].where((r) => r.$3.isNotEmpty).toList();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(S.lg, 0, S.lg, S.lg),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text("${p['name'] ?? ''}'s contact info", style: T.subtitle),
        const SizedBox(height: S.lg),
        if (!signedIn) ...[
          Text('Sign in to see contact details.', style: T.body.muted),
          const SizedBox(height: S.md),
          AppButton('Sign in', onPressed: () {
            Navigator.pop(ctx);
            context.push('/login');
          }),
          const SizedBox(height: S.lg),
        ],
        if (rows.isEmpty && signedIn) Text('No contact details shared yet.', style: T.body.muted),
        for (final (icon, label, value, href) in rows)
          Container(
            margin: const EdgeInsets.only(bottom: S.sm),
            padding: const EdgeInsets.symmetric(horizontal: S.md, vertical: S.sm),
            decoration: BoxDecoration(color: C.surface2, borderRadius: BorderRadius.circular(R.md), border: Border.all(color: C.border, width: 0.5)),
            child: Row(children: [
              Icon(icon, size: 20, color: C.brand),
              const SizedBox(width: S.md),
              Expanded(
                child: InkWell(
                  onTap: () => openExternal(href),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(label, style: T.caption.muted),
                    Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.body),
                  ]),
                ),
              ),
              IconButton(
                tooltip: 'Copy',
                icon: const Icon(PhosphorIconsRegular.copy, size: 18, color: C.muted),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: value));
                  if (ctx.mounted) toast(ctx, '$label copied', tone: Tone.success);
                },
              ),
              IconButton(tooltip: 'Open', icon: const Icon(PhosphorIconsRegular.arrowSquareOut, size: 18, color: C.muted), onPressed: () => openExternal(href)),
            ]),
          ),
      ]),
    ),
  );
}

// ───── Edit profile ─────

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const AppHeader(title: 'Edit Profile'),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(S.lg),
          child: Constrained(
            maxWidth: 560,
            child: ProfileForm(
              submitLabel: 'Save changes',
              onSaved: () {
                toast(context, 'Profile updated', tone: Tone.success);
                context.popOr('/me');
              },
            ),
          ),
        ),
      );
}

// ───── Settings ─────

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(sessionProvider).account;
    return Scaffold(
      appBar: const AppHeader(title: 'Settings'),
      body: ListView(padding: const EdgeInsets.all(S.lg), children: [
        Constrained(
          maxWidth: 560,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SectionLabel('Account'),
            _Card([
              _Row('Email', trailing: Text(account?.email ?? '', style: T.body.muted)),
              if (account?.hasPassword ?? false) _Row('Change Password', icon: PhosphorIconsRegular.key, onTap: () => _showChangePassword(context, ref)),
            ]),
            const SizedBox(height: S.xl),
            const SectionLabel('Legal'),
            _Card([
              for (final (label, kind) in const [('Terms of Use', 'terms'), ('Privacy Policy', 'privacy'), ('Rules', 'rules')])
                _Row(label, icon: PhosphorIconsRegular.fileText, onTap: () => context.push('/legal/$kind')),
            ]),
            const SizedBox(height: S.md),
            _Card([_Row('Contact us', icon: PhosphorIconsRegular.envelopeSimple, onTap: () => context.push('/contact'))]),
            const SizedBox(height: S.xl),
            OutlinedButton.icon(
              onPressed: () async {
                final ok = await confirmDialog(context, title: 'Log out?', message: 'You can sign back in any time.', confirm: 'Log Out');
                if (ok) await ref.read(sessionProvider.notifier).logout();
              },
              icon: const Icon(PhosphorIconsRegular.signOut, size: 18, color: C.error),
              label: Text('Log Out', style: T.body.col(C.error)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                side: const BorderSide(color: C.border, width: 0.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(R.md)),
              ),
            ),
            const SizedBox(height: S.md),
            _Card([_Row('Delete Account', icon: PhosphorIconsRegular.trashSimple, color: C.error, onTap: () => _showDeleteAccount(context, ref))]),
            const SizedBox(height: S.xl),
            Text('Pitch To Picture 1.0.0', textAlign: TextAlign.center, style: T.caption.muted),
          ]),
        ),
      ]),
    );
  }
}

Future<void> _showChangePassword(BuildContext context, WidgetRef ref) {
  final current = TextEditingController();
  final next = TextEditingController();
  var saving = false;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => StatefulBuilder(builder: (ctx, setState) {
      Future<void> submit() async {
        if (next.text.length < 8) return toast(ctx, 'New password must be at least 8 characters', tone: Tone.error);
        setState(() => saving = true);
        final ok = await runAction(ctx, ref, () async {
          await ref.read(sessionProvider.notifier).changePassword(current.text, next.text);
          return true;
        }, success: 'Password changed', refresh: false);
        if (ok == true && ctx.mounted) Navigator.pop(ctx);
        if (ctx.mounted) setState(() => saving = false);
      }

      return Padding(
        padding: EdgeInsets.fromLTRB(S.lg, 0, S.lg, MediaQuery.viewInsetsOf(ctx).bottom + S.lg),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Change Password', style: T.subtitle),
          const SizedBox(height: S.xs),
          Text('Applies to your P2P account in every P2P app. Other devices will be signed out.', style: T.caption.muted),
          const SizedBox(height: S.lg),
          AppInput(label: 'Current Password', controller: current, obscure: true),
          const SizedBox(height: S.md),
          AppInput(label: 'New Password', controller: next, obscure: true, hint: 'At least 8 characters'),
          const SizedBox(height: S.lg),
          AppButton('Update Password', loading: saving, onPressed: submit),
        ]),
      );
    }),
  );
}

/// Delete the whole P2P account (store requirement). Asks for the password, or for "DELETE" if the
/// account has no password (imported without one).
Future<void> _showDeleteAccount(BuildContext context, WidgetRef ref) {
  final hasPassword = ref.read(sessionProvider).account?.hasPassword ?? true;
  final input = TextEditingController();
  var busy = false;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => StatefulBuilder(builder: (ctx, setState) {
      return SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(S.lg, 0, S.lg, MediaQuery.viewInsetsOf(ctx).bottom + S.lg),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Delete your account', style: T.subtitle.col(C.error)),
          const SizedBox(height: S.sm),
          Text(
            'This removes your P2P account in every P2P app, along with your Pitch To Picture profile, projects and applications. '
            'Messages you sent stay in other people\'s chats as "Deleted user". This cannot be undone.',
            style: T.body.muted,
          ),
          const SizedBox(height: S.lg),
          AppInput(
            label: hasPassword ? 'Your password' : 'Type DELETE to confirm',
            controller: input,
            obscure: hasPassword,
            capitalization: TextCapitalization.none,
          ),
          const SizedBox(height: S.lg),
          AppButton('Delete my account', loading: busy, variant: BtnVariant.danger, onPressed: () async {
            if (!hasPassword && input.text.trim() != 'DELETE') return toast(ctx, 'Type DELETE to confirm', tone: Tone.error);
            setState(() => busy = true);
            final done = await runAction(ctx, ref, () async {
              await ref.read(sessionProvider.notifier).deleteAccount(password: hasPassword ? input.text : null);
              return true;
            });
            if (ctx.mounted) setState(() => busy = false);
            if (done != null && ctx.mounted) Navigator.pop(ctx);
          }),
        ]),
      );
    }),
  );
}
