// AI pitch preparation guide for a project (P2P-website/src/ai/flows/ai-generated-pitch-guide.ts, served by POST /pitch-guide).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api.dart';
import '../../core/data.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../ui/icons.dart';
import '../../ui/kit.dart';

class PitchGuideScreen extends ConsumerStatefulWidget {
  const PitchGuideScreen(this.id, {super.key});
  final String id;

  @override
  ConsumerState<PitchGuideScreen> createState() => _PitchGuideScreenState();
}

class _PitchGuideScreenState extends ConsumerState<PitchGuideScreen> {
  String? _guide;
  var _loading = false;

  /// The server answers 503 when no AI key is configured.
  var _unavailable = false;

  Future<void> _generate(Json p) async {
    setState(() => _loading = true);
    try {
      final res = await ref.read(apiClientProvider).post('$ptp/pitch-guide', {
        'projectTitle': '${p['title'] ?? ''}',
        'logline': '${p['logline'] ?? ''}',
        'genre': '${p['genre'] ?? ''}',
      }) as Json;
      if (mounted) setState(() => _guide = '${res['guideContent'] ?? ''}');
    } on ApiException catch (e) {
      if (e.statusCode == 503) {
        if (mounted) setState(() => _unavailable = true);
      } else if (mounted) {
        toast(context, e.message, tone: Tone.error);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppHeader(
          title: 'Pitch guide',
          actions: [
            if (_guide != null)
              CircleIconButton(
                icon: PhosphorIconsRegular.copy,
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: _guide!));
                  if (context.mounted) toast(context, 'Pitch guide copied', tone: Tone.success);
                },
              ),
          ],
        ),
        body: ApiView(
          path: '$ptp/projects/${widget.id}',
          builder: (d) {
            final p = (d as Json)['project'] as Json;
            return ListView(padding: const EdgeInsets.all(S.lg), children: [
              Constrained(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Container(
                    padding: const EdgeInsets.all(S.xl),
                    decoration: BoxDecoration(
                      color: C.brand.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(R.md),
                      border: Border.all(color: C.brand.withValues(alpha: 0.2)),
                    ),
                    child: Column(children: [
                      const Icon(PhosphorIconsFill.sparkle, size: 40, color: C.brand),
                      const SizedBox(height: S.md),
                      Text('AI PITCH PREPARATION', textAlign: TextAlign.center, style: T.display.size(20)),
                      const SizedBox(height: S.xs),
                      Text('${p['title'] ?? ''}'.toUpperCase(), textAlign: TextAlign.center, style: T.caption.gold.copyWith(letterSpacing: 1.2)),
                      const SizedBox(height: S.sm),
                      Text(
                        _unavailable
                            ? "Pitch guide isn't available yet. We're still setting it up — please check back soon."
                            : 'A customised guide for the Pitch To Picture show: pitch structure, timing, how to introduce your story and characters, your vision, and stage presence.',
                        textAlign: TextAlign.center,
                        style: T.body.muted,
                      ),
                      if (!_unavailable) ...[
                        const SizedBox(height: S.lg),
                        AppButton(
                          _loading ? 'Generating…' : (_guide == null ? 'Generate pitch guide' : 'Regenerate'),
                          fullWidth: false,
                          loading: _loading,
                          variant: _guide == null ? BtnVariant.primary : BtnVariant.outline,
                          icon: Icon(_guide == null ? PhosphorIconsRegular.sparkle : PhosphorIconsRegular.arrowsClockwise, size: 18, color: _guide == null ? C.onBrand : C.onSurface),
                          onPressed: () => _generate(p),
                        ),
                      ],
                    ]),
                  ),
                  if (_guide != null) ...[
                    const SizedBox(height: S.xl),
                    MarkdownBody(data: _guide!, selectable: true, styleSheet: _markdownStyle),
                    const SizedBox(height: S.xl),
                    AppButton(
                      'Copy guide',
                      variant: BtnVariant.secondary,
                      icon: const Icon(PhosphorIconsRegular.copy, size: 18, color: C.onSurface),
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: _guide!));
                        if (context.mounted) toast(context, 'Pitch guide copied', tone: Tone.success);
                      },
                    ),
                  ],
                  SizedBox(height: MediaQuery.paddingOf(context).bottom + S.lg),
                ]),
              ),
            ]);
          },
        ),
      );
}

final _markdownStyle = MarkdownStyleSheet(
  p: T.body.copyWith(height: 1.65, color: C.onSurface2),
  h1: T.display.size(22).gold,
  h2: T.title.size(18).gold,
  h3: T.subtitle,
  h4: T.body.semi,
  strong: const TextStyle(fontWeight: FontWeight.w700, fontVariations: [FontVariation.weight(700)], color: C.onSurface),
  em: const TextStyle(fontStyle: FontStyle.italic),
  listBullet: T.body.gold,
  a: T.body.gold.copyWith(decoration: TextDecoration.underline),
  code: T.caption.copyWith(fontFamily: 'monospace', backgroundColor: C.surface3),
  blockquote: T.body.muted.copyWith(fontStyle: FontStyle.italic),
  blockquoteDecoration: BoxDecoration(color: C.surface2, border: const Border(left: BorderSide(color: C.brand, width: 3)), borderRadius: BorderRadius.circular(R.sm)),
  horizontalRuleDecoration: const BoxDecoration(border: Border(top: BorderSide(color: C.divider))),
  h1Padding: const EdgeInsets.only(top: S.md),
  h2Padding: const EdgeInsets.only(top: S.lg),
  h3Padding: const EdgeInsets.only(top: S.md),
  blockSpacing: S.md,
);
