// Owner-only hiring editor: required roles + open/closed per role (P2P-website/src/app/projects/[id]/edit/page.tsx).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api.dart';
import '../../core/data.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../ui/icons.dart';
import '../../ui/kit.dart';
import '../auth/session.dart';
import 'new_project_screen.dart';

class HiringEditorScreen extends ConsumerStatefulWidget {
  const HiringEditorScreen(this.id, {super.key});
  final String id;

  @override
  ConsumerState<HiringEditorScreen> createState() => _HiringEditorScreenState();
}

class _HiringEditorScreenState extends ConsumerState<HiringEditorScreen> {
  /// Null until the project loads; then the editable copy.
  List<String>? _roles;
  final _open = <String, bool>{};
  var _saving = false;

  void _toggle(String role) => setState(() {
        if (_roles!.remove(role)) {
          _open.remove(role);
        } else {
          _roles!.add(role);
          _open[role] = true;
        }
      });

  Future<void> _save() async {
    setState(() => _saving = true);
    final ok = await runAction(context, ref, () async {
      await ref.read(apiClientProvider).patch('$ptp/projects/${widget.id}/hiring', {
        'requiredRoles': _roles,
        'roleAvailability': {for (final r in _roles!) r: _open[r] ?? true},
      });
      return true;
    }, success: 'Hiring settings saved');
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok == true) context.popOr('/project/${widget.id}');
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    return Scaffold(
      appBar: const AppHeader(title: 'Edit hiring'),
      body: ApiView(
        path: '$ptp/projects/${widget.id}',
        builder: (d) {
          final p = (d as Json)['project'] as Json;
          if (session.account?.id != p['creatorUid']) {
            return const EmptyState(icon: PhosphorIconsRegular.lockSimple, title: 'Not your project', message: 'You can only edit projects you created.');
          }
          if (isRejected(p)) {
            return const EmptyState(icon: PhosphorIconsRegular.prohibit, title: 'Read-only', message: 'This project is read-only and cannot be edited.');
          }
          if (_roles == null) {
            _roles = strList(p['requiredRoles']);
            for (final r in _roles!) {
              _open[r] = roleOpen(p, r);
            }
          }
          final selected = _roles!;
          return Column(children: [
            Expanded(
              child: ListView(padding: const EdgeInsets.all(S.lg), children: [
                Constrained(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Text('EDIT PROJECT HIRING', style: T.display.gold),
                    Text('${p['title'] ?? ''}', style: T.subtitle),
                    Text('Choose optional required roles and mark each role open or closed.', style: T.body.muted),
                    const SizedBox(height: S.xl),
                    const SectionLabel('Required roles (optional)'),
                    Text('Select only roles you are actively hiring for. If none selected, all roles are treated as open.', style: T.caption.muted),
                    const SizedBox(height: S.md),
                    RolePicker(selected: selected, onToggle: _toggle),
                    if (selected.isNotEmpty) ...[
                      const SizedBox(height: S.xl),
                      const SectionLabel('Role open / closed status'),
                      Text('Close a role when you no longer want applications for that role.', style: T.caption.muted),
                      const SizedBox(height: S.md),
                      for (final r in selected)
                        Container(
                          margin: const EdgeInsets.only(bottom: S.sm),
                          padding: const EdgeInsets.only(left: S.lg, right: S.sm),
                          decoration: BoxDecoration(color: C.surface2, borderRadius: BorderRadius.circular(R.md), border: Border.all(color: C.border, width: 0.5)),
                          child: Row(children: [
                            Expanded(child: Text(r, style: T.body.medium)),
                            Text(_open[r] ?? true ? 'OPEN' : 'CLOSED', style: T.caption.size(11).semi.col(_open[r] ?? true ? C.brand : C.muted)),
                            Switch(value: _open[r] ?? true, onChanged: (v) => setState(() => _open[r] = v)),
                          ]),
                        ),
                    ],
                  ]),
                ),
              ]),
            ),
            Container(
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: C.divider, width: 0.5))),
              padding: const EdgeInsets.fromLTRB(S.lg, S.md, S.lg, S.md),
              child: SafeArea(top: false, child: Constrained(child: AppButton('Save hiring settings', loading: _saving, onPressed: _save))),
            ),
          ]);
        },
      ),
    );
  }
}
