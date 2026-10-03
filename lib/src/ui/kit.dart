// UI kit ported from the original app's components (src/components/ui/*).
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/api.dart';
import '../core/data.dart';
import '../core/format.dart';
import '../core/theme.dart';

// ───── Button ─────

enum BtnVariant { primary, secondary, outline, ghost, danger }

class AppButton extends StatelessWidget {
  const AppButton(
    this.title, {
    super.key,
    this.onPressed,
    this.variant = BtnVariant.primary,
    this.small = false,
    this.loading = false,
    this.icon,
    this.fullWidth = true,
  });

  final String title;
  final VoidCallback? onPressed;
  final BtnVariant variant;
  final bool small;
  final bool loading;
  final Widget? icon;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (variant) {
      BtnVariant.primary => (C.brand, C.onBrand),
      BtnVariant.secondary => (C.surface3, C.onSurface),
      BtnVariant.outline => (Colors.transparent, C.onSurface),
      BtnVariant.ghost => (Colors.transparent, C.brand),
      BtnVariant.danger => (C.error, C.onSurface),
    };
    final disabled = onPressed == null || loading;
    final child = loading
        ? SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2, color: fg))
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ?icon,
              if (icon != null && title.isNotEmpty) const SizedBox(width: S.sm),
              if (title.isNotEmpty) Text(title, style: T.body.semi.size(small ? 13 : 15).col(fg)),
            ],
          );
    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(R.md),
          side: variant == BtnVariant.outline ? const BorderSide(color: C.borderStrong) : BorderSide.none,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(R.md),
          onTap: disabled ? null : onPressed,
          child: Container(
            width: fullWidth ? double.infinity : null,
            padding: EdgeInsets.symmetric(vertical: small ? 8 : 13, horizontal: small ? S.md : S.lg),
            alignment: fullWidth ? Alignment.center : null,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Round icon button used in headers (back, bell, messages).
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({super.key, required this.icon, this.onTap, this.size = 38, this.background = C.surface2});
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final Color background;

  @override
  Widget build(BuildContext context) => Material(
        color: background,
        shape: const CircleBorder(side: BorderSide(color: C.border, width: 0.5)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox.square(dimension: size, child: Icon(icon, size: 20, color: C.onSurface)),
        ),
      );
}

// ───── Input ─────

class AppInput extends StatefulWidget {
  const AppInput({
    super.key,
    this.label,
    this.controller,
    this.hint,
    this.obscure = false,
    this.keyboardType,
    this.capitalization = TextCapitalization.sentences,
    this.multiline = false,
    this.onTap,
    this.onChanged,
    this.onSubmitted,
    this.autofillHints,
    this.maxLength,
  });

  final String? label;
  final TextEditingController? controller;
  final String? hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextCapitalization capitalization;
  final bool multiline;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;
  final int? maxLength;

  @override
  State<AppInput> createState() => _AppInputState();
}

class _AppInputState extends State<AppInput> {
  late bool _hidden = widget.obscure;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(borderRadius: BorderRadius.circular(R.md), borderSide: const BorderSide(color: C.border));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.label != null) ...[Text(widget.label!, style: T.label.col(C.onSurface3)), const SizedBox(height: S.xs)],
        TextField(
          controller: widget.controller,
          obscureText: _hidden,
          keyboardType: widget.multiline ? TextInputType.multiline : widget.keyboardType,
          textCapitalization: widget.capitalization,
          autocorrect: false,
          minLines: widget.multiline ? 3 : 1,
          maxLines: widget.multiline ? 6 : 1,
          maxLength: widget.maxLength,
          readOnly: widget.onTap != null,
          onTap: widget.onTap,
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
          autofillHints: widget.autofillHints,
          style: T.body.size(15),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: T.body.size(15).muted,
            filled: true,
            fillColor: C.surface3,
            counterText: '',
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: S.md, vertical: 14),
            enabledBorder: border,
            border: border,
            focusedBorder: border.copyWith(borderSide: const BorderSide(color: C.brand)),
            suffixIcon: widget.obscure
                ? IconButton(
                    icon: Icon(_hidden ? PhosphorIconsRegular.eyeSlash : PhosphorIconsRegular.eye, size: 20, color: C.muted),
                    onPressed: () => setState(() => _hidden = !_hidden),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

/// Tap-to-pick field (opens a SelectSheet), like the original "Selector".
class SelectorField extends StatelessWidget {
  const SelectorField({super.key, this.label, required this.placeholder, required this.value, required this.onTap});
  final String? label;
  final String placeholder;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (label != null) ...[Text(label!, style: T.label.col(C.onSurface3)), const SizedBox(height: S.xs)],
          Material(
            color: C.surface3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(R.md), side: const BorderSide(color: C.border, width: 0.5)),
            child: InkWell(
              borderRadius: BorderRadius.circular(R.md),
              onTap: onTap,
              child: SizedBox(
                height: 50,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: S.md),
                  child: Row(children: [
                    Expanded(
                      child: Text(value.isEmpty ? placeholder : value, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.body.size(15).col(value.isEmpty ? C.muted : C.onSurface)),
                    ),
                    const Icon(PhosphorIconsRegular.caretRight, size: 16, color: C.muted),
                  ]),
                ),
              ),
            ),
          ),
        ],
      );
}

// ───── Chip / Badge ─────

class AppChip extends StatelessWidget {
  const AppChip(this.label, {super.key, this.selected = false, this.onTap, this.onRemove, this.small = false});
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? C.onBrand3 : C.onSurface3;
    return Material(
      color: selected ? C.brand3 : C.surface3,
      shape: StadiumBorder(side: BorderSide(color: selected ? C.brand : C.border)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap ?? onRemove,
        child: Container(
          height: small ? 30 : 36,
          padding: EdgeInsets.symmetric(horizontal: small ? S.md : S.lg),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(label, style: T.body.size(small ? 12 : 13).col(fg).copyWith(fontWeight: selected ? FontWeight.w600 : FontWeight.w500)),
            if (onRemove != null) Padding(padding: const EdgeInsets.only(left: 6), child: Text('×', style: T.body.size(15).col(selected ? C.onBrand3 : C.muted))),
          ]),
        ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.label, {super.key, this.tone = Tone.muted});
  final String label;
  final Tone tone;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      Tone.info => (const Color(0x2E4A6E8C), const Color(0xFF7FA8C9)),
      Tone.success => (const Color(0x2E3E7D59), const Color(0xFF6FB58C)),
      Tone.warning => (const Color(0x33B8860B), C.brand),
      Tone.error => (const Color(0x339E3C3C), const Color(0xFFC97676)),
      Tone.muted => (C.surface3, C.onSurface3),
      Tone.brand => (C.brand3, C.onBrand3),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: S.sm, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(R.sm)),
      child: Text(label.toUpperCase(), style: T.caption.size(11).semi.col(fg).copyWith(letterSpacing: 0.3)),
    );
  }
}

/// Application status badge (Applied / Shortlisted / Hired / Not selected).
Widget applicationBadge(String? status) {
  final s = applicationStatuses[status];
  return StatusBadge(s?.$1 ?? '${status ?? ''}', tone: s?.$2 ?? Tone.muted);
}

/// Project lifecycle badge in the website's colours.
class ProjectStatusBadge extends StatelessWidget {
  const ProjectStatusBadge(this.status, {super.key});
  final String? status;

  @override
  Widget build(BuildContext context) {
    final color = Color(projectStatuses[status] ?? 0xFFB3B3B3);
    final solid = status == 'Show Confirmed';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: S.sm, vertical: 4),
      decoration: BoxDecoration(
        color: solid ? color : color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(R.sm),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 0.5),
      ),
      child: Text((status ?? '').toUpperCase(), style: T.caption.size(10.5).semi.col(solid ? C.onBrand : color).copyWith(letterSpacing: 0.3)),
    );
  }
}

// ───── Images ─────

class NetImage extends StatelessWidget {
  const NetImage(this.url, {super.key, this.fit = BoxFit.cover, this.width, this.height});
  final String? url;
  final BoxFit fit;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(color: C.surface3, width: width, height: height);
    if (url == null || url!.isEmpty) return placeholder;
    return CachedNetworkImage(
      imageUrl: url!,
      fit: fit,
      width: width,
      height: height,
      fadeInDuration: const Duration(milliseconds: 150),
      placeholder: (_, _) => placeholder,
      errorWidget: (_, _, _) => placeholder,
    );
  }
}

/// Transparent → surface scrim so text over imagery stays readable.
class Scrim extends StatelessWidget {
  const Scrim({super.key, this.from = Colors.transparent, this.to = const Color(0xE60A0A0A)});
  final Color from;
  final Color to;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [from, to]))),
      );
}

class Avatar extends StatelessWidget {
  const Avatar({super.key, this.url, this.name, this.size = 48});
  final String? url;
  final String? name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final ini = initials(name);
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(shape: BoxShape.circle, color: C.surface3, border: Border.all(color: C.border, width: 0.5)),
      alignment: Alignment.center,
      child: url != null && url!.isNotEmpty
          ? NetImage(url, width: size, height: size)
          : ini.isNotEmpty
              ? Text(ini, style: T.body.semi.size(size * 0.36).col(C.onSurface3))
              : Icon(PhosphorIconsRegular.user, size: size * 0.5, color: C.muted),
    );
  }
}

// ───── Header / layout ─────

/// Screen header: circular back button, centered title, optional right actions; `large` shows a display title.
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({super.key, this.title, this.subtitle, this.actions = const [], this.showBack = true, this.large = false, this.onBack});
  final String? title;
  final String? subtitle;
  final List<Widget> actions;
  final bool showBack;
  final bool large;
  final VoidCallback? onBack;

  @override
  Size get preferredSize => Size.fromHeight(large ? 120 : 56);

  @override
  Widget build(BuildContext context) {
    final back = showBack
        ? CircleIconButton(icon: PhosphorIconsBold.caretLeft, onTap: onBack ?? () => context.popOr('/home'))
        : const SizedBox(width: 38);
    return Container(
      decoration: const BoxDecoration(color: C.surface, border: Border(bottom: BorderSide(color: C.divider, width: 0.5))),
      child: SafeArea(
        bottom: false,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
            height: 56,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: S.lg),
              child: Row(children: [
                back,
                Expanded(
                  child: large || title == null
                      ? const SizedBox()
                      : Text(title!, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.subtitle),
                ),
                Row(mainAxisSize: MainAxisSize.min, children: actions.isEmpty ? [const SizedBox(width: 38)] : actions),
              ]),
            ),
          ),
          if (large && title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(S.lg, 0, S.lg, S.sm),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title!, style: T.display),
                if (subtitle != null) Text(subtitle!, style: T.caption.muted),
              ]),
            ),
        ]),
      ),
    );
  }
}

/// Header used by the tab screens: display title + optional caption and trailing widgets.
class TabHeader extends StatelessWidget {
  const TabHeader({super.key, required this.title, this.eyebrow, this.caption, this.bottom, this.trailing = const []});
  final String title;

  /// Small line above the title (e.g. "Welcome back").
  final String? eyebrow;
  final String? caption;
  final Widget? bottom;
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: C.divider, width: 0.5))),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(S.lg, S.sm, S.lg, S.md),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (eyebrow != null) Text(eyebrow!, style: T.caption.muted),
                    Text(title, style: T.display, maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (caption != null) Text(caption!, style: T.caption.muted),
                  ]),
                ),
                ...trailing,
              ]),
              if (bottom != null) ...[const SizedBox(height: S.md), bottom!],
            ]),
          ),
        ),
      );
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.bottom = S.sm});
  final String text;
  final double bottom;

  @override
  Widget build(BuildContext context) =>
      Padding(padding: EdgeInsets.only(bottom: bottom), child: Text(text.toUpperCase(), style: T.label.muted.copyWith(letterSpacing: 1.2)));
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, this.icon, required this.title, this.message, this.ctaLabel, this.onCta});
  final IconData? icon;
  final String title;
  final String? message;
  final String? ctaLabel;
  final VoidCallback? onCta;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: S.x3, horizontal: S.xl),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null)
            Container(
              width: 72,
              height: 72,
              margin: const EdgeInsets.only(bottom: S.md),
              decoration: BoxDecoration(color: C.surface2, borderRadius: BorderRadius.circular(R.lg), border: Border.all(color: C.border, width: 0.5)),
              child: Icon(icon, size: 32, color: C.muted),
            ),
          Text(title, style: T.subtitle, textAlign: TextAlign.center),
          if (message != null) ...[
            const SizedBox(height: S.sm),
            ConstrainedBox(constraints: const BoxConstraints(maxWidth: 300), child: Text(message!, style: T.body.muted, textAlign: TextAlign.center)),
          ],
          if (ctaLabel != null && onCta != null) ...[
            const SizedBox(height: S.lg),
            AppButton(ctaLabel!, onPressed: onCta, fullWidth: false),
          ],
        ]),
      );
}

// ───── Skeletons ─────

class Skeleton extends StatefulWidget {
  const Skeleton({super.key, this.width, required this.height, this.radius = R.sm});
  final double? width;
  final double height;
  final double radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: Tween(begin: 0.4, end: 1.0).animate(_c),
        child: Container(width: widget.width, height: widget.height, decoration: BoxDecoration(color: C.surface3, borderRadius: BorderRadius.circular(widget.radius))),
      );
}

class CardSkeleton extends StatelessWidget {
  const CardSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: C.surface2, borderRadius: BorderRadius.circular(R.md), border: Border.all(color: C.border, width: 0.5)),
        child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Skeleton(height: 150, radius: 0),
          Padding(
            padding: EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              FractionallySizedBox(widthFactor: 0.7, child: Skeleton(height: 16)),
              SizedBox(height: 8),
              FractionallySizedBox(widthFactor: 0.4, child: Skeleton(height: 12)),
            ]),
          ),
        ]),
      );
}

class RowSkeleton extends StatelessWidget {
  const RowSkeleton({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: Row(children: [
          Skeleton(width: 52, height: 52, radius: 26),
          SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              FractionallySizedBox(widthFactor: 0.6, child: Skeleton(height: 15)),
              SizedBox(height: 8),
              FractionallySizedBox(widthFactor: 0.4, child: Skeleton(height: 12)),
            ]),
          ),
        ]),
      );
}

// ───── Async data ─────

/// Loads `path` through the shared cache and renders loading / error / data.
class ApiView extends ConsumerWidget {
  const ApiView({super.key, required this.path, required this.builder, this.loading});
  final String path;
  final Widget Function(dynamic data) builder;
  final Widget? loading;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref.watch(apiGet(path)).when(
        data: builder,
        loading: () => loading ?? const Padding(padding: EdgeInsets.all(S.x3), child: Center(child: CircularProgressIndicator())),
        error: (e, _) => EmptyState(
          icon: PhosphorIconsRegular.warningCircle,
          title: 'Could not load',
          message: '$e',
          ctaLabel: 'Retry',
          onCta: () => ref.invalidate(apiGet(path)),
        ),
      );
}

// ───── Toast + actions ─────

void toast(BuildContext context, String message, {Tone tone = Tone.muted}) {
  final color = switch (tone) { Tone.success => C.success, Tone.error => C.error, Tone.info => C.info, _ => C.surface3 };
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      backgroundColor: C.surface2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(R.md), side: BorderSide(color: color, width: 0.5)),
      content: Row(children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: S.md),
        Expanded(child: Text(message, style: T.body.medium)),
      ]),
    ));
}

/// Runs a mutation: toast on success/error, then refreshes cached data (like invalidateQueries()).
Future<V?> runAction<V>(BuildContext context, WidgetRef ref, Future<V> Function() action, {String? success, bool refresh = true}) async {
  try {
    final result = await action();
    if (refresh) ref.invalidate(apiGet);
    if (success != null && context.mounted) toast(context, success, tone: Tone.success);
    return result;
  } on ApiException catch (e) {
    if (context.mounted) toast(context, e.message, tone: Tone.error);
    return null;
  }
}

/// Pick one image from the library and upload it; returns the URL to save (null if cancelled/failed).
/// kind: 'profilePhoto' | 'projectImage'.
Future<String?> pickAndUpload(BuildContext context, WidgetRef ref, {String kind = 'projectImage', double maxWidth = 1280}) async {
  final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: maxWidth, imageQuality: 80);
  if (file == null || !context.mounted) return null;
  return runAction(context, ref, () => ref.read(apiClientProvider).upload(file, kind: kind), refresh: false);
}

Future<void> openExternal(String url) => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

/// Horizontal carousel used on Home.
class HList extends StatelessWidget {
  const HList({super.key, required this.children, this.height});
  final List<Widget> children;
  final double? height;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: S.lg),
          itemCount: children.length,
          separatorBuilder: (_, _) => const SizedBox(width: S.md),
          itemBuilder: (_, i) => children[i],
        ),
      );
}

/// Caps content width so screens read well on web/tablets.
class Constrained extends StatelessWidget {
  const Constrained({super.key, required this.child, this.maxWidth = 720});
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(alignment: Alignment.topCenter, child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth), child: child));
}

extension PopOr on BuildContext {
  /// Back, or [fallback] when there's nothing to go back to (web deep link or refresh).
  void popOr(String fallback) => canPop() ? pop() : go(fallback);
}

/// The Pitch To Picture film-strip mark (same artwork as the app icon and splash).
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 56});
  final double size;

  @override
  Widget build(BuildContext context) =>
      Image.asset('assets/branding/logo_mark.png', width: size, height: size, fit: BoxFit.contain, semanticLabel: 'Pitch To Picture');
}
