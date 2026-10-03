// Home: the website's landing page (hero, sponsor, how it works, CTA) + live projects and creators.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/data.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../ui/icons.dart';
import '../../ui/kit.dart';
import '../auth/session.dart';
import '../people/creators_screen.dart';
import '../projects/project_card.dart';

const _heroImage = 'https://images.unsplash.com/photo-1478720568477-152d9b164e26?crop=entropy&cs=srgb&fm=jpg&w=1200&q=80';

/// "The Pipeline — How it works" (website copy).
const _steps = <(IconData, String, String)>[
  (PhosphorIconsRegular.fileText, 'Submit script', 'Upload your script and project details for review by the Pitch To Picture team.'),
  (PhosphorIconsRegular.listChecks, 'Script review', 'Our team evaluates submissions and approves projects that are eligible to move forward.'),
  (PhosphorIconsRegular.usersThree, 'Build your team', 'Approved creators can build their team by hiring from the platform or adding registered members.'),
  (PhosphorIconsRegular.filmStrip, 'Create your trailer', 'Once the team is complete, creators produce a short trailer for their film project.'),
  (PhosphorIconsRegular.playCircle, 'Trailer screening', 'Submitted trailers are screened by the platform to select projects for the show.'),
  (PhosphorIconsRegular.megaphone, 'Pitch on the show', 'Selected creators appear on the show and pitch their film live in front of judges.'),
];

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final signedIn = session.signedIn;
    final projects = ref.watch(apiGet('$ptp/projects'));
    final creators = ref.watch(apiGet('$ptp/creators'));
    final me = session.ptpcId;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(apiGet('$ptp/projects'));
          ref.invalidate(apiGet('$ptp/creators'));
        },
        child: ListView(padding: EdgeInsets.zero, children: [
          _Hero(signedIn: signedIn, name: session.profile?['name'] as String?),
          const _Sponsor(),
          _Section(
            title: 'Latest projects',
            action: 'See all',
            onAction: () => context.go('/projects'),
            child: projects.when(
              data: (d) {
                final list = ((d as Json)['projects'] as List).cast<Json>().take(8).toList();
                if (list.isEmpty) return Padding(padding: const EdgeInsets.symmetric(horizontal: S.lg), child: Text('No projects yet — be the first to submit one.', style: T.body.muted));
                return HList(height: 330, children: [for (final p in list) ProjectCard(p, compact: true)]);
              },
              loading: () => const HList(height: 330, children: [SizedBox(width: 260, child: CardSkeleton()), SizedBox(width: 260, child: CardSkeleton())]),
              error: (e, _) => Padding(padding: const EdgeInsets.symmetric(horizontal: S.lg), child: Text('$e', style: T.body.muted)),
            ),
          ),
          const _Pipeline(),
          _Section(
            title: 'Meet the creators',
            action: 'Directory',
            onAction: () => context.go('/creators'),
            child: creators.when(
              data: (d) {
                final list = ((d as Json)['creators'] as List).cast<Json>().where((c) => c['id'] != me).take(10).toList();
                if (list.isEmpty) return Padding(padding: const EdgeInsets.symmetric(horizontal: S.lg), child: Text('Creators will appear here.', style: T.body.muted));
                return HList(height: 236, children: [for (final c in list) CreatorCard(c, compact: true)]);
              },
              loading: () => const SizedBox(height: 236, child: Center(child: CircularProgressIndicator())),
              error: (e, _) => const SizedBox.shrink(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(S.lg, S.lg, S.lg, 0),
            child: ClipRRect(borderRadius: BorderRadius.circular(R.md), child: Image.asset('assets/branding/ads_banner.png', fit: BoxFit.cover)),
          ),
          _Cta(signedIn: signedIn),
          const _Footer(),
        ]),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.signedIn, this.name});
  final bool signedIn;
  final String? name;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 460,
        child: Stack(fit: StackFit.expand, children: [
          const NetImage(_heroImage),
          const Scrim(from: Color(0x660A0A0A), to: C.surface),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(S.xl),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const BrandMark(size: 32),
                  const Spacer(),
                  if (!signedIn) TextButton(onPressed: () => context.push('/login'), child: Text('Log in', style: T.body.gold.semi)),
                ]),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: S.md, vertical: 6),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(99), border: Border.all(color: C.brand.withValues(alpha: 0.5)), color: C.brand3.withValues(alpha: 0.6)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(PhosphorIconsFill.sparkle, size: 14, color: C.brand),
                    const SizedBox(width: 6),
                    Text('WHERE VISION MEETS SCREENS', style: T.caption.size(11).gold.semi.copyWith(letterSpacing: 1.2)),
                  ]),
                ),
                const SizedBox(height: S.md),
                Text.rich(TextSpan(style: T.hero.size(40), children: [const TextSpan(text: 'PITCH TO '), TextSpan(text: 'PICTURE', style: T.hero.size(40).gold)])),
                const SizedBox(height: S.sm),
                Text(
                  signedIn && (name ?? '').isNotEmpty
                      ? 'Welcome back, ${name!.split(' ').first}. Submit scripts, assemble your team and compete for a spot on the show.'
                      : "The elite ecosystem for creators to submit scripts, assemble award-winning teams, and compete for a spot on the world's biggest filmmaking stage.",
                  style: T.body.size(15).col(C.onSurface3),
                ),
                const SizedBox(height: S.lg),
                Row(children: [
                  Expanded(
                    child: signedIn
                        ? AppButton('Submit a script', onPressed: () => context.push('/project/new'))
                        : AppButton('Start your project', onPressed: () => context.push('/signup')),
                  ),
                  const SizedBox(width: S.md),
                  Expanded(
                    child: signedIn
                        ? AppButton('Dashboard', variant: BtnVariant.outline, onPressed: () => context.push('/dashboard'))
                        : AppButton('Explore projects', variant: BtnVariant.outline, onPressed: () => context.go('/projects')),
                  ),
                ]),
              ]),
            ),
          ),
        ]),
      );
}

class _Sponsor extends StatelessWidget {
  const _Sponsor();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: S.lg),
        child: Column(children: [
          Text('OFFICIAL SPONSOR', style: T.caption.muted.copyWith(letterSpacing: 2)),
          const SizedBox(height: S.sm),
          Image.asset('assets/branding/sponsor_gsjpl.png', height: 56, semanticLabel: 'GSJPL — official sponsor'),
        ]),
      );
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.action, this.onAction});
  final String title;
  final Widget child;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: S.xl),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(S.lg, 0, S.sm, S.md),
            child: Row(children: [
              Expanded(child: Text(title.toUpperCase(), style: T.display.size(20))),
              if (action != null) TextButton(onPressed: onAction, child: Text(action!, style: T.label.gold)),
            ]),
          ),
          child,
        ]),
      );
}

class _Pipeline extends StatelessWidget {
  const _Pipeline();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(S.lg, S.x2, S.lg, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('THE PIPELINE', style: T.caption.gold.semi.copyWith(letterSpacing: 2)),
          Text('HOW IT WORKS', style: T.display),
          const SizedBox(height: S.md),
          for (var i = 0; i < _steps.length; i++)
            Container(
              margin: const EdgeInsets.only(bottom: S.sm),
              padding: const EdgeInsets.all(S.md),
              decoration: BoxDecoration(color: C.surface2, borderRadius: BorderRadius.circular(R.md), border: Border.all(color: C.border, width: 0.5)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: C.brand3, borderRadius: BorderRadius.circular(R.sm)),
                  child: Icon(_steps[i].$1, color: C.brand, size: 22),
                ),
                const SizedBox(width: S.md),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${i + 1}. ${_steps[i].$2.toUpperCase()}', style: T.subtitle.size(14).copyWith(letterSpacing: 0.5)),
                    const SizedBox(height: 2),
                    Text(_steps[i].$3, style: T.body.muted),
                  ]),
                ),
              ]),
            ),
        ]),
      );
}

class _Cta extends StatelessWidget {
  const _Cta({required this.signedIn});
  final bool signedIn;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.fromLTRB(S.lg, S.xl, S.lg, 0),
        padding: const EdgeInsets.all(S.xl),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(R.lg),
          border: Border.all(color: C.brand.withValues(alpha: 0.4)),
          gradient: const LinearGradient(colors: [Color(0xFF2A2210), C.surface2], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: Column(children: [
          Text(signedIn ? 'CONNECT WITH THE COMMUNITY' : 'READY TO TAKE THE STAGE?', style: T.display.size(22), textAlign: TextAlign.center),
          const SizedBox(height: S.sm),
          Text(
            signedIn
                ? 'Join thousands of creators who are already collaborating and building their cinematic dreams.'
                : 'Your next big project starts with a single logline. Join the elite filmmaking ecosystem today.',
            style: T.body.muted,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: S.lg),
          signedIn
              ? AppButton('Meet other creators', onPressed: () => context.go('/creators'))
              : AppButton('Join the ecosystem', onPressed: () => context.push('/signup')),
        ]),
      );
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(S.lg, S.x2, S.lg, S.x2),
        child: Column(children: [
          Wrap(alignment: WrapAlignment.center, children: [
            for (final (label, path) in const [('The Show', '/show'), ('Rules', '/legal/rules'), ('Terms', '/legal/terms'), ('Privacy', '/legal/privacy'), ('Contact', '/contact')])
              TextButton(onPressed: () => context.push(path), child: Text(label, style: T.label.muted)),
          ]),
          const SizedBox(height: S.sm),
          Text('© 2026 PITCH TO PICTURE PRIVATE LIMITED', style: T.caption.size(11).muted.copyWith(letterSpacing: 1), textAlign: TextAlign.center),
        ]),
      );
}
