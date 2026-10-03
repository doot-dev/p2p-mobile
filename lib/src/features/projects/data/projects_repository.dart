import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/project.dart';

/// Talks to the mobile project endpoints (`/api/v1/projects*`).
class ProjectsRepository {
  ProjectsRepository(this._api);

  final ApiClient _api;

  Future<List<Project>> getAll() async {
    final data = await _api.get<Map<String, dynamic>>('/projects');
    final list = (data['projects'] as List?) ?? const [];
    return list
        .map((e) => Project.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<Project> getById(String id) async {
    final data = await _api.get<Map<String, dynamic>>('/projects/$id');
    return Project.fromJson(Map<String, dynamic>.from(data['project'] as Map));
  }

  /// Submit a new project. Returns the generated PTPP id.
  Future<String> create(Map<String, dynamic> body) async {
    final data = await _api.post<Map<String, dynamic>>('/projects', data: body);
    return data['id'] as String? ?? '';
  }
}

final projectsRepositoryProvider = Provider<ProjectsRepository>(
  (ref) => ProjectsRepository(ref.watch(apiClientProvider)),
);

/// Discovery feed for the Projects tab.
final projectsListProvider = FutureProvider<List<Project>>(
  (ref) => ref.watch(projectsRepositoryProvider).getAll(),
);

/// Single project detail by id.
final projectProvider = FutureProvider.family<Project, String>(
  (ref, id) => ref.watch(projectsRepositoryProvider).getById(id),
);
