// Project card for the feed and Home carousels (P2P-website/src/app/projects/page.tsx).
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../ui/icons.dart';
import '../../ui/kit.dart';

class ProjectCard extends StatelessWidget {
  const ProjectCard(this.project, {super.key, this.compact = false});
  final Json project;

  /// Narrower card for Home carousels.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = project;
    final meta = joinNonEmpty([p['genre'], p['location']], ' · ');
    final card = Material(
      color: C.surface2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(R.md), side: const BorderSide(color: C.border, width: 0.5)),
      child: InkWell(
        onTap: () => context.push('/project/${p['id']}'),
        // spaceBetween only kicks in when a grid row stretches the card; in a list the column is as tall as its content.
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(fit: StackFit.expand, children: [
                ProjectCover(p, titleSize: compact ? 18 : 22),
                Positioned(top: S.sm, right: S.sm, child: ProjectStatusBadge(p['status'] as String?)),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, S.md, 14, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${p['title'] ?? ''}'.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: T.display.size(compact ? 16 : 19)),
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: S.xs),
                  Row(children: [
                    const Icon(PhosphorIconsRegular.filmSlate, size: 13, color: C.muted),
                    const SizedBox(width: 5),
                    Expanded(child: Text(meta.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: T.caption.size(11).muted.copyWith(letterSpacing: 1))),
                  ]),
                ],
                const SizedBox(height: S.sm),
                Text('${p['logline'] ?? ''}', maxLines: 2, overflow: TextOverflow.ellipsis, style: T.body.size(13).muted.copyWith(fontStyle: FontStyle.italic)),
              ]),
            ),
          ]),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, S.sm, 14, S.md),
            child: Row(children: [
              const Icon(PhosphorIconsRegular.usersThree, size: 15, color: C.brand),
              const SizedBox(width: 6),
              Expanded(child: Text('${projectRoles(p).where((r) => roleOpen(p, r)).length} OPEN ROLES', style: T.caption.size(11).semi.gold)),
              Text('VIEW DETAILS', style: T.caption.size(11).semi.copyWith(letterSpacing: 0.8)),
              const Icon(PhosphorIconsRegular.caretRight, size: 13, color: C.onSurface),
            ]),
          ),
        ]),
      ),
    );
    return compact ? SizedBox(width: 260, child: card) : card;
  }
}

/// Cover image, or the title on a dark-gold gradient when the project has none (as on the website).
class ProjectCover extends StatelessWidget {
  const ProjectCover(this.project, {super.key, this.titleSize = 22});
  final Json project;
  final double titleSize;

  @override
  Widget build(BuildContext context) {
    final url = project['projectImageUrl'] as String?;
    if (url != null && url.isNotEmpty) return NetImage(url);
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [C.brand3, C.surface3, C.surface])),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: S.lg),
          child: Text(
            '${project['title'] ?? ''}'.toUpperCase(),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: T.display.size(titleSize).col(C.onBrand3.withValues(alpha: 0.9)),
          ),
        ),
      ),
    );
  }
}
