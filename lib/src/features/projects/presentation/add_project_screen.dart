import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../data/projects_repository.dart';

/// Add tab — submit a new project (mirrors web /projects/new).
/// ponytail: image/script PDF upload deferred — scriptUrl is a pasted link,
/// matching current web UX. Wire storage upload when needed.
class AddProjectScreen extends ConsumerStatefulWidget {
  const AddProjectScreen({super.key});

  @override
  ConsumerState<AddProjectScreen> createState() => _AddProjectScreenState();
}

class _AddProjectScreenState extends ConsumerState<AddProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _genre = TextEditingController();
  final _logline = TextEditingController();
  final _language = TextEditingController();
  final _location = TextEditingController();
  final _scriptUrl = TextEditingController();
  final List<String> _roles = [];
  bool _submitting = false;

  @override
  void dispose() {
    for (final c in [_title, _genre, _logline, _language, _location, _scriptUrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final id = await ref.read(projectsRepositoryProvider).create({
        'title': _title.text.trim(),
        'genre': _genre.text.trim(),
        'logline': _logline.text.trim(),
        'language': _language.text.trim(),
        'location': _location.text.trim(),
        'scriptUrl': _scriptUrl.text.trim(),
        'requiredRoles': _roles,
      });
      ref.invalidate(projectsListProvider);
      if (mounted) {
        _formKey.currentState!.reset();
        for (final c in [_title, _genre, _logline, _language, _location, _scriptUrl]) {
          c.clear();
        }
        setState(_roles.clear);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Project $id submitted for script review.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not submit project.')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Submit Project')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          children: [
            const Text(
              'Pitch your script. Approved projects enter the team building stage.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            _field(_title, 'Title', required: true),
            _field(_genre, 'Genre (e.g. Drama, Action)', required: true),
            _field(_logline, 'Logline — one-sentence pitch',
                required: true, maxLines: 3),
            _field(_language, 'Language', required: true),
            _field(_location, 'Location', required: true),
            _field(_scriptUrl, 'Script URL (Drive link)'),
            const SizedBox(height: 8),
            const Text('REQUIRED ROLES',
                style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMuted)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: AppConstants.roles.map((r) {
                final sel = _roles.contains(r);
                return FilterChip(
                  label: Text(r),
                  selected: sel,
                  selectedColor: AppColors.gold.withValues(alpha: 0.2),
                  onSelected: (_) =>
                      setState(() => sel ? _roles.remove(r) : _roles.add(r)),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.onGold))
                  : const Text('SUBMIT FOR REVIEW'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label,
          {bool required = false, int maxLines = 1}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: TextFormField(
          controller: c,
          maxLines: maxLines,
          decoration: InputDecoration(labelText: label),
          validator: required
              ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
              : null,
        ),
      );
}
