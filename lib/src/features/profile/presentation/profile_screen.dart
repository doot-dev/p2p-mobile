import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/data/auth_repository.dart';
import '../data/profile_repository.dart';
import '../domain/user_profile.dart';

/// Profile tab — shows the signed-in creator's profile with an Edit action.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meAsync = ref.watch(meProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      body: meAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.gold)),
        error: (e, _) => _Retry(onRetry: () => ref.invalidate(meProvider)),
        data: (me) {
          final p = me.profile;
          if (p == null) {
            return const Center(
              child: Text('No profile yet.',
                  style: TextStyle(color: AppColors.textSecondary)),
            );
          }
          return RefreshIndicator(
            color: AppColors.gold,
            onRefresh: () => ref.refresh(meProvider.future),
            child: _ProfileBody(profile: p),
          );
        },
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
      children: [
        Center(child: _Avatar(profile: profile)),
        const SizedBox(height: 16),
        Center(
          child: Text(profile.name,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
        ),
        Center(
          child: Text(profile.id,
              style: const TextStyle(
                  color: AppColors.gold, letterSpacing: 2, fontSize: 12)),
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => EditProfileScreen(profile: profile),
          )),
          icon: const Icon(Icons.edit_outlined, size: 18),
          label: const Text('EDIT PROFILE'),
        ),
        const SizedBox(height: 24),
        if (profile.roles.isNotEmpty) ...[
          const _SectionLabel('ROLES'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: profile.roles
                .map((r) => Chip(
                      label: Text(r),
                      backgroundColor: AppColors.gold.withValues(alpha: 0.12),
                      side: BorderSide(
                          color: AppColors.gold.withValues(alpha: 0.4)),
                    ))
                .toList(),
          ),
          const SizedBox(height: 20),
        ],
        if (profile.bio.isNotEmpty) ...[
          const _SectionLabel('BIO'),
          Text(profile.bio,
              style: const TextStyle(color: AppColors.textSecondary, height: 1.5)),
          const SizedBox(height: 20),
        ],
        if (_location(profile).isNotEmpty) ...[
          const _SectionLabel('LOCATION'),
          _InfoRow(Icons.place_outlined, _location(profile)),
        ],
        if (profile.experience.isNotEmpty)
          _InfoRow(Icons.work_outline, profile.experience),
        if (profile.phoneNumber.isNotEmpty)
          _InfoRow(Icons.phone_outlined, profile.phoneNumber),
        const SizedBox(height: 12),
        ..._links(profile).entries.map((e) => _LinkRow(label: e.key, url: e.value)),
      ],
    );
  }

  static String _location(UserProfile p) =>
      [p.city, p.state, p.country].where((s) => s.isNotEmpty).join(', ');

  static Map<String, String> _links(UserProfile p) => {
        if (p.portfolioUrl.isNotEmpty) 'Portfolio': p.portfolioUrl,
        if (p.showreelUrl.isNotEmpty) 'Showreel': p.showreelUrl,
        if (p.instagramUrl.isNotEmpty) 'Instagram': p.instagramUrl,
        if (p.websiteUrl.isNotEmpty) 'Website': p.websiteUrl,
      };
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final initials = profile.name.isNotEmpty
        ? profile.name.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase()
        : '?';
    return CircleAvatar(
      radius: 48,
      backgroundColor: AppColors.gold.withValues(alpha: 0.15),
      backgroundImage: profile.profilePhoto.isNotEmpty
          ? CachedNetworkImageProvider(profile.profilePhoto)
          : null,
      child: profile.profilePhoto.isNotEmpty
          ? null
          : Text(initials,
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gold)),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(
                fontSize: 11,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
                color: AppColors.textMuted)),
      );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 10),
          Expanded(
              child: Text(text,
                  style: const TextStyle(color: AppColors.textSecondary))),
        ]),
      );
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({required this.label, required this.url});
  final String label;
  final String url;

  @override
  Widget build(BuildContext context) => ListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.link, color: AppColors.gold),
        title: Text(label),
        subtitle: Text(url,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textMuted)),
        onTap: () {
          final uri = Uri.tryParse(url);
          if (uri != null) launchUrl(uri, mode: LaunchMode.externalApplication);
        },
      );
}

class _Retry extends StatelessWidget {
  const _Retry({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text("Couldn't load profile.",
              style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ]),
      );
}

// ─── Edit ──────────────────────────────────────────────────────────────────

/// Edit form. PATCHes `/api/v1/me`. Photo upload + languages deferred.
/// ponytail: photo needs firebase_storage; add when upload UX is wired.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key, required this.profile});

  final UserProfile profile;

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _c;
  late List<String> _roles;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _c = {
      'name': TextEditingController(text: p.name),
      'phoneNumber': TextEditingController(text: p.phoneNumber),
      'city': TextEditingController(text: p.city),
      'state': TextEditingController(text: p.state),
      'country': TextEditingController(text: p.country),
      'experience': TextEditingController(text: p.experience),
      'bio': TextEditingController(text: p.bio),
      'portfolioUrl': TextEditingController(text: p.portfolioUrl),
      'showreelUrl': TextEditingController(text: p.showreelUrl),
      'instagramUrl': TextEditingController(text: p.instagramUrl),
      'websiteUrl': TextEditingController(text: p.websiteUrl),
    };
    _roles = [...p.roles];
  }

  @override
  void dispose() {
    for (final ctrl in _c.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(profileRepositoryProvider).updateProfile({
        for (final e in _c.entries) e.key: e.value.text.trim(),
        'roles': _roles,
      });
      ref.invalidate(meProvider);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not update profile.')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          children: [
            _field('name', 'Full name', required: true),
            _field('phoneNumber', 'Phone'),
            _field('city', 'City'),
            _field('state', 'State'),
            _field('country', 'Country'),
            _field('experience', 'Experience (e.g. 5 Years in Cinema)'),
            _field('bio', 'Bio', maxLines: 4),
            const SizedBox(height: 8),
            const _SectionLabel('ROLES'),
            Wrap(
              spacing: 8,
              children: AppConstants.roles.map((r) {
                final sel = _roles.contains(r);
                return FilterChip(
                  label: Text(r),
                  selected: sel,
                  selectedColor: AppColors.gold.withValues(alpha: 0.2),
                  onSelected: (_) => setState(
                      () => sel ? _roles.remove(r) : _roles.add(r)),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            _field('portfolioUrl', 'Portfolio URL'),
            _field('showreelUrl', 'Showreel URL'),
            _field('instagramUrl', 'Instagram'),
            _field('websiteUrl', 'Website'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.onGold))
                  : const Text('SAVE PROFILE'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String key, String label,
          {int maxLines = 1, bool required = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: TextFormField(
          controller: _c[key],
          maxLines: maxLines,
          decoration: InputDecoration(labelText: label),
          validator: required
              ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
              : null,
        ),
      );
}
