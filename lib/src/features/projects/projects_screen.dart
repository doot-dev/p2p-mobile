// Projects tab: public feed with search + genre filter (P2P-website/src/app/projects/page.tsx).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/data.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../ui/icons.dart';
import '../../ui/kit.dart';
import '../auth/session.dart';
import 'project_card.dart';

/// Client-side search over the feed: every word must appear in the title, logline, genre, tags,
/// location, language or ID. (The website's search box did nothing.)
bool projectMatches(Json p, String query) {
  final words = query.toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
  if (words.isEmpty) return true;
  final hay = [p['id'], p['title'], p['logline'], p['genre'], p['location'], p['language'], ...strList(p['tags'])].join(' ').toLowerCase();
  return words.every(hay.contains);
}

class ProjectsScreen extends ConsumerStatefulWidget {
  const ProjectsScreen({super.key});

  @override
  ConsumerState<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends ConsumerState<ProjectsScreen> {
  static const _path = '$ptp/projects';
  var _query = '';
  String? _genre;

  void _newProject() => context.push(ref.read(sessionProvider).signedIn ? '/project/new' : '/login');

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(apiGet(_path));
    final all = (((async.value as Json?)?['projects'] as List?) ?? const []).cast<Json>();
    final shown = all.where((p) => (_genre == null || p['genre'] == _genre) && projectMatches(p, _query)).toList();

    final Widget content;
    if (async.isLoading && async.value == null) {
      content = ListView(padding: const EdgeInsets.all(S.lg), children: [
        for (var i = 0; i < 3; i++) const Padding(padding: EdgeInsets.only(bottom: S.lg), child: CardSkeleton()),
      ]);
    } else if (async.hasError && async.value == null) {
      content = ListView(children: [
        EmptyState(icon: PhosphorIconsRegular.warningCircle, title: 'Could not load', message: '${async.error}', ctaLabel: 'Retry', onCta: () => ref.invalidate(apiGet(_path))),
      ]);
    } else if (all.isEmpty) {
      content = ListView(children: [
        EmptyState(
          icon: PhosphorIconsRegular.filmSlate,
          title: 'NO SCRIPTS SUBMITTED',
          message: 'The archive is currently empty. Be the first creator to pitch your vision to the world.',
          ctaLabel: 'Submit your script',
          onCta: _newProject,
        ),
      ]);
    } else if (shown.isEmpty) {
      content = ListView(children: const [
        EmptyState(icon: PhosphorIconsRegular.magnifyingGlass, title: 'No matching projects', message: 'Try another keyword or genre.'),
      ]);
    } else {
      content = LayoutBuilder(builder: (context, box) {
        final cols = (box.maxWidth / 380).floor().clamp(1, 4);
        final rows = (shown.length / cols).ceil();
        return ListView.separated(
          padding: const EdgeInsets.all(S.lg),
          itemCount: rows,
          separatorBuilder: (_, _) => const SizedBox(height: S.lg),
          itemBuilder: (_, r) {
            if (cols == 1) return ProjectCard(shown[r]);
            // Stretch each row to its tallest card so the footers line up.
            return IntrinsicHeight(
              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                for (var c = 0; c < cols; c++) ...[
                  if (c > 0) const SizedBox(width: S.lg),
                  Expanded(child: r * cols + c < shown.length ? ProjectCard(shown[r * cols + c]) : const SizedBox()),
                ],
              ]),
            );
          },
        );
      });
    }

    return Scaffold(
      body: Column(children: [
        TabHeader(
          title: 'PROJECTS',
          caption: 'Film projects looking for talent',
          trailing: [CircleIconButton(icon: PhosphorIconsRegular.plus, onTap: _newProject)],
          bottom: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            AppInput(hint: 'Search by title, keyword, genre or ID', capitalization: TextCapitalization.none, onChanged: (v) => setState(() => _query = v)),
            const SizedBox(height: S.md),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: genres.length + 1,
                separatorBuilder: (_, _) => const SizedBox(width: S.sm),
                itemBuilder: (_, i) {
                  final g = i == 0 ? null : genres[i - 1];
                  return AppChip(g ?? 'All', selected: _genre == g, onTap: () => setState(() => _genre = g));
                },
              ),
            ),
          ]),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref.refresh(apiGet(_path).future),
            child: content,
          ),
        ),
      ]),
    );
  }
}
