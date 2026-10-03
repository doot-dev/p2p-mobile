import 'flavor.dart';

/// Build-time / flavor configuration.
///
/// The base URL is driven by the active [FlavorConfig] (dev → local Next.js,
/// prod → pitchtopicture.in). For one-off testing (e.g. an ngrok tunnel) you can
/// still override it without changing flavor:
///   flutter run --flavor dev -t lib/main_dev.dart \
///     --dart-define=API_BASE_URL=https://abc.ngrok.io
///
/// During local development the Android emulator reaches the host machine at
/// 10.0.2.2; a physical device on the same LAN uses the host IP (192.168.1.5).
abstract class Env {
  /// Optional explicit override; empty unless `--dart-define=API_BASE_URL=` set.
  static const String _override = String.fromEnvironment('API_BASE_URL');

  /// Base URL of the Next.js app exposing the REST API (`/api/...`).
  static String get apiBaseUrl =>
      _override.isNotEmpty ? _override : FlavorConfig.instance.apiBaseUrl;

  /// Common prefix for the mobile REST endpoints we add to Next.js.
  static const String apiPrefix = '/api/v1';

  /// Whether to log network traffic. On by default in dev, off in prod (unless
  /// forced with `--dart-define=NETWORK_LOGGING=true`).
  static const bool _loggingOverride = bool.fromEnvironment(
    'NETWORK_LOGGING',
    defaultValue: false,
  );

  static bool get enableNetworkLogging => _loggingOverride || FlavorConfig.isDev;
}
