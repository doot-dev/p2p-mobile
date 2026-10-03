import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/user_profile.dart';

/// Result of `GET /api/v1/me`.
class MeResult {
  const MeResult({
    required this.profile,
    required this.needsOnboarding,
    required this.ptpcId,
  });

  final UserProfile? profile;
  final bool needsOnboarding;
  final String? ptpcId;

  factory MeResult.fromJson(Map<String, dynamic> json) {
    final raw = json['profile'];
    return MeResult(
      profile: raw == null
          ? null
          : UserProfile.fromJson(Map<String, dynamic>.from(raw as Map)),
      needsOnboarding: json['needsOnboarding'] as bool? ?? true,
      ptpcId: json['ptpcId'] as String?,
    );
  }
}

/// Talks to the mobile profile endpoints (`/api/v1/me*`).
class ProfileRepository {
  ProfileRepository(this._api);

  final ApiClient _api;

  /// Current user's profile + onboarding state.
  Future<MeResult> getMe() async {
    final data = await _api.get<Map<String, dynamic>>('/me');
    return MeResult.fromJson(data);
  }

  /// Idempotently create the DB profile after first sign-in.
  /// Safe to call on every login.
  Future<UserProfile> ensureProfile({
    String? name,
    String? photoURL,
    String? phoneNumber,
    String? city,
    String? state,
    String? country,
    List<String>? roles,
    String? bio,
  }) async {
    final body = <String, dynamic>{
      'name': ?name,
      'photoURL': ?photoURL,
      'phoneNumber': ?phoneNumber,
      'city': ?city,
      'state': ?state,
      'country': ?country,
      'roles': ?roles,
      'bio': ?bio,
    };
    final data = await _api.post<Map<String, dynamic>>('/me/ensure', data: body);
    return UserProfile.fromJson(
      Map<String, dynamic>.from(data['profile'] as Map),
    );
  }

  /// Patch the caller's own profile (also used to complete onboarding).
  Future<UserProfile> updateProfile(Map<String, dynamic> updates) async {
    final data = await _api.patch<Map<String, dynamic>>('/me', data: updates);
    return UserProfile.fromJson(
      Map<String, dynamic>.from(data['profile'] as Map),
    );
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(apiClientProvider)),
);

/// Current user's profile + onboarding state, for the Profile tab.
final meProvider = FutureProvider<MeResult>(
  (ref) => ref.watch(profileRepositoryProvider).getMe(),
);
