// Post a project: details, optional cover, required script PDF (P2P-website/src/app/projects/new/page.tsx).
import 'package:file_selector/file_selector.dart';
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

/// Tags as typed ("a, b, c"): trimmed, de-duplicated, max 5 like the website.
List<String> parseTags(String input) => input.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toSet().take(5).toList();

class NewProjectScreen extends ConsumerStatefulWidget {
  const NewProjectScreen({super.key});

  @override
  ConsumerState<NewProjectScreen> createState() => _NewProjectScreenState();
}

class _NewProjectScreenState extends ConsumerState<NewProjectScreen> {
  final _title = TextEditingController();
  final _tags = TextEditingController();
  final _logline = TextEditingController();
  final _language = TextEditingController(text: 'English');
  final _location = TextEditingController();
  var _genre = '';
  final _roles = <String>[];
  String? _imageUrl;
  String? _scriptValue;
  String? _scriptName;
  var _uploadingImage = false;
  var _uploadingScript = false;
  var _saving = false;

  @override
  void dispose() {
    for (final c in [_title, _tags, _logline, _language, _location]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    setState(() => _uploadingImage = true);
    final url = await pickAndUpload(context, ref, kind: 'projectImage');
    if (!mounted) return;
    setState(() {
      _uploadingImage = false;
      if (url != null) _imageUrl = url;
    });
  }

  Future<void> _pickScript() async {
    const pdf = XTypeGroup(label: 'PDF', extensions: ['pdf'], mimeTypes: ['application/pdf'], uniformTypeIdentifiers: ['com.adobe.pdf']);
    final file = await openFile(acceptedTypeGroups: [pdf]);
    if (file == null || !mounted) return;
    if (await file.length() > 20 * 1024 * 1024) {
      if (mounted) toast(context, 'Script PDF must be under 20 MB.', tone: Tone.error);
      return;
    }
    setState(() => _uploadingScript = true);
    final value = mounted ? await runAction(context, ref, () => ref.read(apiClientProvider).upload(file, kind: 'script'), refresh: false) : null;
    if (!mounted) return;
    setState(() {
      _uploadingScript = false;
      if (value != null) {
        _scriptValue = value;
        _scriptName = file.name;
      }
    });
  }

  Future<void> _submit() async {
    final missing = [
      if (_title.text.trim().isEmpty) 'title',
      if (_genre.isEmpty) 'genre',
      if (_logline.text.trim().isEmpty) 'logline',
      if (_language.text.trim().isEmpty) 'language',
      if (_location.text.trim().isEmpty) 'shoot location',
    ];
    if (missing.isNotEmpty) return toast(context, 'Please add the ${missing.join(', ')}.', tone: Tone.error);
    if (_scriptValue == null) return toast(context, 'Please upload your script PDF to continue.', tone: Tone.error);

    setState(() => _saving = true);
    final done = await runAction(
      context,
      ref,
      () => ref.read(apiClientProvider).post('$ptp/projects', {
        'title': _title.text.trim(),
        'genre': _genre,
        'logline': _logline.text.trim(),
        'tags': parseTags(_tags.text),
        'requiredRoles': _roles,
        'language': _language.text.trim(),
        'location': _location.text.trim(),
        'projectImageUrl': _imageUrl ?? '',
        'scriptUrl': _scriptValue,
      }),
      success: 'Project submitted for review',
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (done != null) context.go('/dashboard?tab=projects');
  }

  @override
  Widget build(BuildContext context) {
    final tags = parseTags(_tags.text);
    return Scaffold(
      appBar: const AppHeader(title: 'Post your project'),
      body: ListView(padding: const EdgeInsets.all(S.lg), children: [
        Constrained(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('POST YOUR PROJECT', style: T.display.gold),
            Text('Submit your script to begin the journey to the big screen.', style: T.body.muted),
            const SizedBox(height: S.xl),
            const SectionLabel('Project details'),
            AppInput(label: 'Project title', controller: _title, hint: 'e.g. Ek Tha Safar', capitalization: TextCapitalization.words, maxLength: 191),
            const SizedBox(height: S.md),
            SelectorField(
              label: 'Genre',
              placeholder: 'Select genre',
              value: _genre,
              onTap: () async {
                final pick = await showSelectSheet(context, title: 'Genre', options: genres, selected: [if (_genre.isNotEmpty) _genre], searchable: false);
                if (pick != null && pick.isNotEmpty) setState(() => _genre = pick.first);
              },
            ),
            const SizedBox(height: S.md),
            AppInput(
              label: 'Tags (optional)',
              controller: _tags,
              hint: 'e.g. revenge, college, mafia, village, love story',
              capitalization: TextCapitalization.none,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: S.xs),
            Text('Separate tags with commas. Max 5 tags.', style: T.caption.size(11).muted),
            if (tags.isNotEmpty) ...[
              const SizedBox(height: S.sm),
              Wrap(spacing: S.sm, runSpacing: S.sm, children: [for (final t in tags) AppChip('#$t', small: true, selected: true)]),
            ],
            const SizedBox(height: S.md),
            AppInput(label: 'Logline (summary)', controller: _logline, hint: 'Mumbai ki galiyoin mein…', multiline: true, maxLength: 5000),
            const SizedBox(height: S.lg),
            Text('Required roles (optional)', style: T.label.col(C.onSurface3)),
            const SizedBox(height: S.xs),
            Text('Select only the roles you want applicants for. If none selected, all roles stay open.', style: T.caption.size(11).muted),
            const SizedBox(height: S.sm),
            RolePicker(selected: _roles, onToggle: (r) => setState(() => _roles.contains(r) ? _roles.remove(r) : _roles.add(r))),
            const SizedBox(height: S.lg),
            AppInput(label: 'Language', controller: _language, hint: 'e.g. Hindi', capitalization: TextCapitalization.words, maxLength: 191),
            const SizedBox(height: S.md),
            AppInput(label: 'Primary shoot location', controller: _location, hint: 'e.g. Mumbai, Maharashtra', capitalization: TextCapitalization.words, maxLength: 191),
            const SizedBox(height: S.xl),
            const SectionLabel('Script & media'),
            Text('Project image (optional)', style: T.label.col(C.onSurface3)),
            const SizedBox(height: S.xs),
            _imageUrl != null
                ? Stack(children: [
                    ClipRRect(borderRadius: BorderRadius.circular(R.md), child: AspectRatio(aspectRatio: 16 / 9, child: NetImage(_imageUrl))),
                    Positioned(
                      top: S.sm,
                      right: S.sm,
                      child: Row(children: [
                        CircleIconButton(icon: PhosphorIconsRegular.pencilSimple, size: 34, background: C.overlay, onTap: _uploadingImage ? null : _pickImage),
                        const SizedBox(width: S.sm),
                        CircleIconButton(icon: PhosphorIconsRegular.trash, size: 34, background: C.overlay, onTap: () => setState(() => _imageUrl = null)),
                      ]),
                    ),
                  ])
                : _DropZone(
                    icon: PhosphorIconsRegular.imageSquare,
                    title: 'Upload project image',
                    message: 'Optional cover image for your project listing and detail page.',
                    hint: 'JPEG / PNG / WEBP, max 5 MB',
                    busy: _uploadingImage,
                    onTap: _pickImage,
                  ),
            const SizedBox(height: S.lg),
            Text('Script (PDF)', style: T.label.col(C.onSurface3)),
            const SizedBox(height: S.xs),
            _DropZone(
              icon: _scriptName != null ? PhosphorIconsFill.checkCircle : PhosphorIconsRegular.uploadSimple,
              iconColor: _scriptName != null ? const Color(0xFF22C55E) : C.brand,
              title: _scriptName ?? 'Upload script (PDF)',
              message: _scriptName != null ? 'Tap to change file' : 'Tap to browse',
              hint: 'Max size: 20 MB',
              busy: _uploadingScript,
              onTap: _pickScript,
            ),
            const SizedBox(height: S.lg),
            Container(
              padding: const EdgeInsets.all(S.lg),
              decoration: BoxDecoration(color: C.brand.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(R.md), border: Border.all(color: C.brand.withValues(alpha: 0.25))),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(PhosphorIconsRegular.warningCircle, size: 18, color: C.brand),
                const SizedBox(width: S.md),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Important', style: T.body.semi.gold),
                    Text(
                      'Your full script will only be visible to Pitch To Picture administrators. Submitting will notify our team for review.',
                      style: T.caption.col(C.onSurface3),
                    ),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: S.xl),
            AppButton('Create project', loading: _saving, onPressed: _uploadingImage || _uploadingScript ? null : _submit),
            SizedBox(height: MediaQuery.paddingOf(context).bottom + S.lg),
          ]),
        ),
      ]),
    );
  }
}

class _DropZone extends StatelessWidget {
  const _DropZone({required this.icon, required this.title, required this.message, required this.hint, required this.busy, required this.onTap, this.iconColor = C.brand});
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String hint;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: C.surface2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(R.md), side: const BorderSide(color: C.borderStrong)),
        child: InkWell(
          borderRadius: BorderRadius.circular(R.md),
          onTap: busy ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: S.lg, vertical: S.xl),
            child: Column(children: [
              busy ? const SizedBox.square(dimension: 28, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(icon, size: 28, color: iconColor),
              const SizedBox(height: S.sm),
              Text(busy ? 'Uploading…' : title, textAlign: TextAlign.center, style: T.body.semi),
              Text(message, textAlign: TextAlign.center, style: T.caption.muted),
              const SizedBox(height: S.sm),
              Text(hint.toUpperCase(), style: T.caption.size(10).muted.copyWith(letterSpacing: 1)),
            ]),
          ),
        ),
      );
}

/// Preset roles + any custom ones as toggle chips, with a field to add a custom role.
/// Shared by the new-project form and the hiring editor.
class RolePicker extends StatefulWidget {
  const RolePicker({super.key, required this.selected, required this.onToggle});
  final List<String> selected;
  final ValueChanged<String> onToggle;

  @override
  State<RolePicker> createState() => _RolePickerState();
}

class _RolePickerState extends State<RolePicker> {
  final _custom = TextEditingController();

  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  void _add() {
    final typed = _custom.text.trim();
    if (typed.isEmpty) return;
    // Reuse the preset spelling when someone types "actor".
    final role = roles.firstWhere((r) => r.toLowerCase() == typed.toLowerCase(), orElse: () => typed);
    if (!widget.selected.contains(role)) widget.onToggle(role);
    _custom.clear();
  }

  @override
  Widget build(BuildContext context) {
    final options = {...roles, ...widget.selected};
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Wrap(spacing: S.sm, runSpacing: S.sm, children: [
        for (final r in options) AppChip(r, small: true, selected: widget.selected.contains(r), onTap: () => widget.onToggle(r)),
      ]),
      const SizedBox(height: S.sm),
      Row(children: [
        Expanded(child: AppInput(controller: _custom, hint: 'Add a custom role', capitalization: TextCapitalization.words, maxLength: 60, onSubmitted: (_) => _add())),
        const SizedBox(width: S.sm),
        AppButton('Add', small: true, fullWidth: false, variant: BtnVariant.secondary, onPressed: _add),
      ]),
    ]);
  }
}
