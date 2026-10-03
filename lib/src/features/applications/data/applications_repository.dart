import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

/// Mirrors backend `ApplicationRow` (`/api/v1/applications`).
class Application {
  const Application({
    required this.id,
    required this.projectId,
    required this.projectTitle,
    required this.applicantId,
    required this.applicantName,
    required this.desiredRole,
    required this.compensation,
    required this.message,
    required this.status,
    this.creatorRead = false,
    this.applicantPhoto = '',
    this.createdAt,
  });

  final String id;
  final String projectId;
  final String projectTitle;
  final String applicantId;
  final String applicantName;
  final String desiredRole;
  final String compensation;
  final String message;
  final String status;
  final bool creatorRead;
  final String applicantPhoto;
  final DateTime? createdAt;

  factory Application.fromJson(Map<String, dynamic> j) => Application(
        id: j['id'] as String? ?? '',
        projectId: j['projectId'] as String? ?? '',
        projectTitle: j['projectTitle'] as String? ?? '',
        applicantId: j['applicantId'] as String? ?? '',
        applicantName: j['applicantName'] as String? ?? '',
        desiredRole: j['desiredRole'] as String? ?? '',
        compensation: j['compensation'] as String? ?? '',
        message: j['message'] as String? ?? '',
        status: j['status'] as String? ?? '',
        creatorRead: j['creatorRead'] as bool? ?? false,
        applicantPhoto:
            (j['applicant'] as Map?)?['profilePhoto'] as String? ?? '',
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? ''),
      );
}

class ApplicationsRepository {
  ApplicationsRepository(this._api);

  final ApiClient _api;

  Future<List<Application>> getBox(String box) async {
    final data = await _api
        .get<Map<String, dynamic>>('/applications', query: {'box': box});
    final list = (data['applications'] as List?) ?? const [];
    return list
        .map((e) => Application.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> updateStatus(String id, String status) =>
      _api.patch<Map<String, dynamic>>('/applications/$id',
          data: {'status': status});
}

final applicationsRepositoryProvider = Provider<ApplicationsRepository>(
  (ref) => ApplicationsRepository(ref.watch(apiClientProvider)),
);

/// box: 'incoming' | 'sent'
final applicationsProvider =
    FutureProvider.family<List<Application>, String>(
  (ref, box) => ref.watch(applicationsRepositoryProvider).getBox(box),
);
