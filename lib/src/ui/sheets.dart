// Bottom sheets + overlays (select sheet, image lightbox, confirm dialog).
import 'package:flutter/material.dart';
import 'icons.dart';

import '../core/theme.dart';
import 'kit.dart';

/// Pick one (closes on tap) or many (Done button) from `options`. Returns null if dismissed.
Future<List<String>?> showSelectSheet(
  BuildContext context, {
  required String title,
  required List<String> options,
  List<String> selected = const [],
  bool multi = false,
  bool searchable = true,
  Map<String, String>? labels,
}) {
  final chosen = [...selected];
  var query = '';
  return showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => StatefulBuilder(builder: (ctx, setState) {
      final filtered = query.isEmpty ? options : options.where((o) => (labels?[o] ?? o).toLowerCase().contains(query.toLowerCase())).toList();
      return Padding(
        padding: EdgeInsets.fromLTRB(S.lg, 0, S.lg, MediaQuery.viewInsetsOf(ctx).bottom + S.md),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.8),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(child: Text(title, style: T.subtitle)),
              IconButton(icon: const Icon(PhosphorIconsRegular.x, size: 22), onPressed: () => Navigator.pop(ctx, multi ? chosen : null)),
            ]),
            if (searchable) ...[
              AppInput(hint: 'Search', capitalization: TextCapitalization.none, onChanged: (v) => setState(() => query = v)),
              const SizedBox(height: S.sm),
            ],
            Flexible(
              child: filtered.isEmpty
                  ? Padding(padding: const EdgeInsets.all(S.xl), child: Text('No matches', style: T.body.muted, textAlign: TextAlign.center))
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const Divider(),
                      itemBuilder: (_, i) {
                        final o = filtered[i];
                        final on = chosen.contains(o);
                        return InkWell(
                          onTap: () {
                            if (!multi) return Navigator.pop(ctx, [o]);
                            setState(() => on ? chosen.remove(o) : chosen.add(o));
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Row(children: [
                              Expanded(child: Text(labels?[o] ?? o, style: T.body.size(15).col(on ? C.brand : C.onSurface).copyWith(fontWeight: on ? FontWeight.w600 : FontWeight.w400))),
                              if (on) const Icon(PhosphorIconsBold.check, size: 18, color: C.brand),
                            ]),
                          ),
                        );
                      },
                    ),
            ),
            if (multi) ...[
              const SizedBox(height: S.sm),
              AppButton(chosen.isEmpty ? 'Done' : 'Done (${chosen.length})', onPressed: () => Navigator.pop(ctx, chosen)),
            ],
          ]),
        ),
      );
    }),
  );
}

/// Report a profile / organisation / opportunity. Resolution happens in the future Admin Panel.
Future<void> showLightbox(BuildContext context, List<String> images, int index) {
  var current = index;
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black,
    builder: (ctx) => StatefulBuilder(builder: (ctx, setState) {
      return Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(children: [
          PageView.builder(
            controller: PageController(initialPage: index),
            itemCount: images.length,
            onPageChanged: (i) => setState(() => current = i),
            itemBuilder: (_, i) => InteractiveViewer(child: Center(child: NetImage(images[i], fit: BoxFit.contain))),
          ),
          Positioned(
            top: MediaQuery.paddingOf(ctx).top + 8,
            right: 16,
            child: CircleIconButton(icon: PhosphorIconsBold.x, size: 40, background: const Color(0x26FFFFFF), onTap: () => Navigator.pop(ctx)),
          ),
          if (images.length > 1)
            Positioned(
              bottom: MediaQuery.paddingOf(ctx).bottom + 20,
              left: 0,
              right: 0,
              child: Text('${current + 1} / ${images.length}', textAlign: TextAlign.center, style: T.body.col(Colors.white)),
            ),
        ]),
      );
    }),
  );
}

Future<bool> confirmDialog(BuildContext context, {required String title, required String message, String confirm = 'Delete'}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: C.surface2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(R.md), side: const BorderSide(color: C.border, width: 0.5)),
      title: Text(title, style: T.subtitle),
      content: Text(message, style: T.body.muted),
      actions: [
        Row(children: [
          Expanded(child: AppButton('Cancel', variant: BtnVariant.secondary, onPressed: () => Navigator.pop(ctx, false))),
          const SizedBox(width: S.md),
          Expanded(child: AppButton(confirm, onPressed: () => Navigator.pop(ctx, true))),
        ]),
      ],
    ),
  );
  return ok ?? false;
}

