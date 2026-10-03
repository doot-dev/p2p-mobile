// Creators directory + the creator card — ported from P2P-website/src/app/creators/page.tsx.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/data.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../ui/icons.dart';
import '../../ui/kit.dart';
import '../auth/session.dart';
import '../inbox/open_chat.dart';

const _path = '$ptp/creators';

class CreatorsScreen extends ConsumerStatefulWidget {
  const CreatorsScreen({super.key});

  @override
  ConsumerState<CreatorsScreen> createState() => _CreatorsScreenState();
}

class _CreatorsScreenState extends ConsumerState<CreatorsScreen> {
  String _q = '';
  String? _role;

  /// Same match as the website: name, PTPC id, state, country or any role; plus the role chip.
  bool _matches(Json c) {
    final rs = strList(c['roles']);
    if (_role != null && !rs.contains(_role)) return false;
    final term = _q.trim().toLowerCase();
    if (term.isEmpty) return true;
    return [c['name'], c['id'], c['state'], c['country'], ...rs].any((v) => '${v ?? ''}'.toLowerCase().contains(term));
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(sessionProvider).ptpcId;
    final async = ref.watch(apiGet(_path));
    return Scaffold(
      body: Column(children: [
        TabHeader(
          title: 'CREATORS',
          caption: 'Discover actors, cinematographers, editors and more',
          bottom: Column(children: [
            AppInput(hint: 'Search by name, role, state, country or PTPC ID', onChanged: (v) => setState(() => _q = v)),
            const SizedBox(height: S.md),
            SizedBox(
              height: 36,
              child: ListView(scrollDirection: Axis.horizontal, children: [
                for (final r in [null, ...roles])
                  Padding(
                    padding: const EdgeInsets.only(right: S.sm),
                    child: AppChip(r ?? 'All', selected: _role == r, onTap: () => setState(() => _role = r)),
                  ),
              ]),
            ),
          ]),
        ),
        Expanded(
          child: RefreshIndicator(
            color: C.brand,
            onRefresh: () => ref.refresh(apiGet(_path).future),
            child: async.when(
              loading: () => ListView(padding: const EdgeInsets.symmetric(horizontal: S.lg), children: List.filled(6, const RowSkeleton())),
              error: (e, _) => ListView(children: [
                EmptyState(icon: PhosphorIconsRegular.warningCircle, title: 'Could not load', message: '$e', ctaLabel: 'Retry', onCta: () => ref.invalidate(apiGet(_path))),
              ]),
              data: (d) {
                // The API leaves you in; the website hides yourself.
                final list = ((d as Json)['creators'] as List? ?? []).cast<Json>().where((c) => c['id'] != me && _matches(c)).toList();
                if (list.isEmpty) {
                  return ListView(children: const [
                    EmptyState(icon: PhosphorIconsRegular.usersThree, title: 'No creators found', message: 'Try a different name, role or place.'),
                  ]);
                }
                return LayoutBuilder(builder: (context, box) {
                  final cols = (box.maxWidth / 420).floor().clamp(1, 3);
                  return GridView.builder(
                    padding: const EdgeInsets.all(S.lg),
                    physics: const AlwaysScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cols, mainAxisSpacing: S.md, crossAxisSpacing: S.md, mainAxisExtent: 196),
                    itemCount: list.length,
                    itemBuilder: (_, i) => CreatorCard(list[i]),
                  );
                });
              },
            ),
          ),
        ),
      ]),
    );
  }
}

/// A creator: avatar, name, PTPC id, roles, location, MESSAGE + PROFILE. `compact` is the Home carousel card.
class CreatorCard extends ConsumerWidget {
  const CreatorCard(this.creator, {super.key, this.compact = false});
  final Json creator;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = creator;
    final rs = strList(c['roles']);
    final shown = rs.take(compact ? 1 : 3).toList();
    final more = rs.length - shown.length;
    final loc = locationOf(c);
    final profile = '/profile/${c['id']}';
    void message() => ref.read(sessionProvider).signedIn ? openChat(context, c) : context.push('/login');

    final chips = Wrap(spacing: S.xs, runSpacing: S.xs, alignment: compact ? WrapAlignment.center : WrapAlignment.start, children: [
      for (final r in shown) AppChip(r, small: true, selected: true),
      if (more > 0) AppChip('+$more', small: true),
    ]);
    final buttons = [
      AppButton(compact ? '' : 'MESSAGE', small: true, variant: BtnVariant.secondary, icon: const Icon(PhosphorIconsRegular.chatCircleText, size: 16), onPressed: message),
      AppButton('PROFILE', small: true, onPressed: () => context.push(profile)),
    ];

    return Material(
      color: C.surface2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(R.md), side: const BorderSide(color: C.border, width: 0.5)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(profile),
        child: compact
            ? SizedBox(
                width: 160,
                child: Padding(
                  padding: const EdgeInsets.all(S.md),
                  child: Column(children: [
                    Avatar(url: c['profilePhoto'] as String?, name: c['name'] as String?, size: 64),
                    const SizedBox(height: S.sm),
                    Text('${c['name'] ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis, style: T.body.semi),
                    Text('${c['id'] ?? ''}', style: T.caption.gold),
                    const SizedBox(height: S.sm),
                    if (shown.isNotEmpty) chips,
                    const SizedBox(height: S.md),
                    Row(children: [SizedBox(width: 44, child: buttons[0]), const SizedBox(width: S.xs), Expanded(child: buttons[1])]),
                  ]),
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(S.lg),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Avatar(url: c['profilePhoto'] as String?, name: c['name'] as String?, size: 52),
                    const SizedBox(width: S.md),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${c['name'] ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis, style: T.subtitle),
                        Text('${c['id'] ?? ''}', style: T.caption.gold),
                        if (loc.isNotEmpty)
                          Row(children: [
                            const Icon(PhosphorIconsRegular.mapPin, size: 12, color: C.muted),
                            const SizedBox(width: S.xs),
                            Expanded(child: Text(loc, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.caption.muted)),
                          ]),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: S.md),
                  SizedBox(height: 30, child: ClipRect(child: chips)), // ponytail: one row of chips, the rest are on the profile
                  const Spacer(),
                  Row(children: [Expanded(child: buttons[0]), const SizedBox(width: S.sm), Expanded(child: buttons[1])]),
                ]),
              ),
      ),
    );
  }
}
