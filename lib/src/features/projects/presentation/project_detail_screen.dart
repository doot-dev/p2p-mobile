import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../data/projects_repository.dart';
import '../domain/project.dart';

/// Project detail — opened from a project card. Mirrors the web project page
/// (hero, logline, hiring roles, creator). Apply/NDA flow lands next phase.
class ProjectDetailScreen extends ConsumerWidget {
  const ProjectDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(projectProvider(id));

    return Scaffold(
      body: async.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.gold)),
        error: (e, _) => _NotFound(id: id),
        data: (p) => _Detail(project: p),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final roles =
        project.requiredRoles.isNotEmpty ? project.requiredRoles : AppConstants.roles;
    final openRoles = roles
        .where((r) => project.roleAvailability[r] ?? true)
        .toList();

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 280,
          pinned: true,
          backgroundColor: AppColors.background,
          flexibleSpace: FlexibleSpaceBar(
            background: _Hero(project: project),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _StatusPill(status: project.status),
                    const SizedBox(width: 8),
                    _IdPill(id: project.id),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  project.title.toUpperCase(),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 18,
                  runSpacing: 8,
                  children: [
                    _meta(Icons.movie_outlined, project.genre),
                    _meta(Icons.language, project.language),
                    _meta(Icons.place_outlined, project.location),
                  ],
                ),
                const SizedBox(height: 28),
                const _Label('STORY LOGLINE'),
                Text(
                  '"${project.logline}"',
                  style: const TextStyle(
                    fontSize: 18,
                    height: 1.5,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 28),
                const _Label('HIRING'),
                ...roles.map((r) => _RoleTile(
                      role: r,
                      open: project.roleAvailability[r] ?? true,
                    )),
                const SizedBox(height: 24),
                const _Label('CREATOR'),
                _CreatorCard(ptpcId: project.creatorPtpcId),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    // ponytail: NDA + apply flow next phase
                    onPressed: openRoles.isEmpty ? null : () => _soon(context),
                    child: Text(openRoles.isEmpty
                        ? 'ROLES CLOSED'
                        : 'APPLY FOR ROLE'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _soon(BuildContext context) => ScaffoldMessenger.of(context)
      .showSnackBar(const SnackBar(content: Text('Apply flow coming next.')));

  Widget _meta(IconData icon, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.gold),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: AppColors.textSecondary)),
        ],
      );
}

class _Hero extends StatelessWidget {
  const _Hero({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (project.projectImageUrl.isNotEmpty)
          CachedNetworkImage(
            imageUrl: project.projectImageUrl,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => _fallback(),
          )
        else
          _fallback(),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, AppColors.background],
              stops: [0.4, 1],
            ),
          ),
        ),
      ],
    );
  }

  Widget _fallback() => const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF18181B), Color(0xFF27272A), Color(0xFF0B0B0B)],
          ),
        ),
      );
}

class _RoleTile extends StatelessWidget {
  const _RoleTile({required this.role, required this.open});
  final String role;
  final bool open;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          Icon(Icons.group_outlined,
              size: 20, color: open ? AppColors.gold : AppColors.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Text(role,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Text(
            open ? 'OPEN' : 'CLOSED',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1,
              fontWeight: FontWeight.bold,
              color: open ? AppColors.statusApproved : AppColors.textMuted,
            ),
          ),
        ]),
      );
}

class _CreatorCard extends StatelessWidget {
  const _CreatorCard({required this.ptpcId});
  final String ptpcId;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.gold.withValues(alpha: 0.15),
            child: const Icon(Icons.person, color: AppColors.gold),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Verified Creator',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(ptpcId,
                  style: const TextStyle(
                      color: AppColors.textMuted,
                      letterSpacing: 1,
                      fontSize: 12)),
            ],
          ),
        ]),
      );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = projectStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(status,
          style: const TextStyle(
              color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

class _IdPill extends StatelessWidget {
  const _IdPill({required this.id});
  final String id;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(id,
            style: const TextStyle(
                color: AppColors.textMuted, fontSize: 10, letterSpacing: 1)),
      );
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(children: [
          Container(width: 3, height: 14, color: AppColors.gold),
          const SizedBox(width: 8),
          Text(text,
              style: const TextStyle(
                  fontSize: 12,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold)),
        ]),
      );
}

class _NotFound extends StatelessWidget {
  const _NotFound({required this.id});
  final String id;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Text('Project not found.',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
}
