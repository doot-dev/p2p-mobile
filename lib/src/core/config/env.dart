/// Build-time configuration.
///
/// Override per environment with `--dart-define`, e.g.:
///   flutter run --dart-define=API_BASE_URL=https://pitchtopicture.in
///
/// During local development against the Next.js dev server use the host
/// machine IP (Android emulator reaches the host at 10.0.2.2).
abstract class Env {
  /// Base URL of the Next.js app exposing the REST API (`/api/...`).
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://pitchtopicture.in',
  );

  /// Common prefix for the mobile REST endpoints we will add to Next.js.
  static const String apiPrefix = '/api/v1';

  /// Whether to log network traffic (disable in release).
  static const bool enableNetworkLogging = bool.fromEnvironment(
    'NETWORK_LOGGING',
    defaultValue: true,
  );
}
