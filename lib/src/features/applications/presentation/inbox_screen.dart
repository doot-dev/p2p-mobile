import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../data/applications_repository.dart';

/// Inbox tab — Incoming (creator hiring pipeline) + Sent (my applications).
class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Inbox'),
          bottom: const TabBar(
            indicatorColor: AppColors.gold,
            labelColor: AppColors.gold,
            unselectedLabelColor: AppColors.textMuted,
            tabs: [Tab(text: 'INCOMING'), Tab(text: 'SENT')],
          ),
        ),
        body: const TabBarView(
          children: [
            _ApplicationsList(box: 'incoming'),
            _ApplicationsList(box: 'sent'),
          ],
        ),
      ),
    );
  }
}

class _ApplicationsList extends ConsumerWidget {
  const _ApplicationsList({required this.box});

  final String box;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(applicationsProvider(box));

    return RefreshIndicator(
      color: AppColors.gold,
      onRefresh: () => ref.refresh(applicationsProvider(box).future),
      child: async.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.gold)),
        error: (e, _) => ListView(children: const [
          SizedBox(height: 120),
          Center(
              child: Text("Couldn't load applications.",
                  style: TextStyle(color: AppColors.textSecondary))),
        ]),
        data: (apps) => apps.isEmpty
            ? ListView(children: [
                const SizedBox(height: 120),
                const Icon(Icons.inbox_outlined,
                    size: 56, color: AppColors.textMuted),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    box == 'incoming'
                        ? 'No applications to your projects yet.'
                        : "You haven't applied to any projects yet.",
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ])
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: apps.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) => _ApplicationCard(
                  app: apps[i],
                  isIncoming: box == 'incoming',
                  onStatus: (status) async {
                    await ref
                        .read(applicationsRepositoryProvider)
                        .updateStatus(apps[i].id, status);
                    ref.invalidate(applicationsProvider(box));
                  },
                ),
              ),
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({
    required this.app,
    required this.isIncoming,
    required this.onStatus,
  });

  final Application app;
  final bool isIncoming;
  final Future<void> Function(String status) onStatus;

  @override
  Widget build(BuildContext context) {
    final statusColor = applicationStatusColor(app.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isIncoming ? app.applicantName : app.projectTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(app.status,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusColor)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isIncoming
                ? '${app.desiredRole} · ${app.projectTitle}'
                : 'Role: ${app.desiredRole}',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          if (app.compensation.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Compensation: ${app.compensation}',
                style:
                    const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ],
          if (app.message.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(app.message,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
          ],
          if (isIncoming &&
              app.status != 'Selected' &&
              app.status != 'Rejected') ...[
            const SizedBox(height: 12),
            Row(children: [
              if (app.status == 'Applied')
                OutlinedButton(
                  onPressed: () => onStatus('Shortlisted'),
                  child: const Text('Shortlist'),
                ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => onStatus('Selected'),
                child: const Text('Select'),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => onStatus('Rejected'),
                child: const Text('Reject',
                    style: TextStyle(color: AppColors.statusRejected)),
              ),
            ]),
          ],
        ],
      ),
    );
  }
}
