/// Mirrors the backend `UserProfileRow` (`/api/v1/me`). Hand-written JSON to
/// avoid a codegen step; keep field names in sync with the Prisma `UserProfile`.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.authUid,
    required this.name,
    this.email,
    this.phoneNumber = '',
    this.city = '',
    this.state = '',
    this.country = '',
    this.bio = '',
    this.profilePhoto = '',
    this.experience = '',
    this.portfolioUrl = '',
    this.showreelUrl = '',
    this.instagramUrl = '',
    this.websiteUrl = '',
    this.publicProfileLink = '',
    this.isAdmin = false,
    this.roles = const [],
    this.languages = const [],
    this.createdAt,
    this.updatedAt,
  });

  /// PTPC id (e.g. `PTPC1234`).
  final String id;
  final String authUid;
  final String name;
  final String? email;
  final String phoneNumber;
  final String city;
  final String state;
  final String country;
  final String bio;
  final String profilePhoto;
  final String experience;
  final String portfolioUrl;
  final String showreelUrl;
  final String instagramUrl;
  final String websiteUrl;
  final String publicProfileLink;
  final bool isAdmin;
  final List<String> roles;
  final List<String> languages;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  static List<String> _stringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return const [];
  }

  static DateTime? _date(dynamic value) {
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    return null;
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String? ?? '',
      authUid: json['authUid'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String?,
      phoneNumber: json['phoneNumber'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      country: json['country'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      profilePhoto: json['profilePhoto'] as String? ?? '',
      experience: json['experience'] as String? ?? '',
      portfolioUrl: json['portfolioUrl'] as String? ?? '',
      showreelUrl: json['showreelUrl'] as String? ?? '',
      instagramUrl: json['instagramUrl'] as String? ?? '',
      websiteUrl: json['websiteUrl'] as String? ?? '',
      publicProfileLink: json['publicProfileLink'] as String? ?? '',
      isAdmin: json['isAdmin'] as bool? ?? false,
      roles: _stringList(json['roles']),
      languages: _stringList(json['languages']),
      createdAt: _date(json['createdAt']),
      updatedAt: _date(json['updatedAt']),
    );
  }
}
