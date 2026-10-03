/// Mirrors backend `ProjectRow` (`/api/v1/projects`). Hand-written JSON.
class Project {
  const Project({
    required this.id,
    required this.creatorUid,
    required this.creatorPtpcId,
    required this.title,
    required this.projectImageUrl,
    required this.genre,
    required this.logline,
    required this.language,
    required this.location,
    required this.status,
    this.scriptUrl = '',
    this.tags = const [],
    this.requiredRoles = const [],
    this.roleAvailability = const {},
  });

  final String id;
  final String creatorUid;
  final String creatorPtpcId;
  final String title;
  final String projectImageUrl;
  final String genre;
  final String logline;
  final String language;
  final String location;
  final String status;
  final String scriptUrl;
  final List<String> tags;
  final List<String> requiredRoles;
  final Map<String, bool> roleAvailability;

  static List<String> _strList(dynamic v) =>
      v is List ? v.map((e) => e.toString()).toList() : const [];

  factory Project.fromJson(Map<String, dynamic> j) => Project(
        id: j['id'] as String? ?? '',
        creatorUid: j['creatorUid'] as String? ?? '',
        creatorPtpcId: j['creatorPtpcId'] as String? ?? '',
        title: j['title'] as String? ?? '',
        projectImageUrl: j['projectImageUrl'] as String? ?? '',
        genre: j['genre'] as String? ?? '',
        logline: j['logline'] as String? ?? '',
        language: j['language'] as String? ?? '',
        location: j['location'] as String? ?? '',
        status: j['status'] as String? ?? '',
        scriptUrl: j['scriptUrl'] as String? ?? '',
        tags: _strList(j['tags']),
        requiredRoles: _strList(j['requiredRoles']),
        roleAvailability: (j['roleAvailability'] as Map?)
                ?.map((k, v) => MapEntry(k.toString(), v == true)) ??
            const {},
      );
}
