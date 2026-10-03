/// Build flavors. Selected by the entrypoint (`main_dev.dart` / `main_prod.dart`)
/// and the matching `--flavor` passed to `flutter run`/`build`.
enum AppFlavor { dev, prod }

/// Per-flavor runtime configuration, initialised once during bootstrap before
/// `runApp`. Read [instance] anywhere after that (e.g. from `Env`).
class FlavorConfig {
  FlavorConfig._({
    required this.flavor,
    required this.apiBaseUrl,
    required this.appTitle,
  });

  final AppFlavor flavor;

  /// Base URL of the Next.js backend (without the `/api/v1` prefix).
  final String apiBaseUrl;

  /// Window/app title shown in the OS task switcher.
  final String appTitle;

  static FlavorConfig? _instance;

  /// The active flavor config. Throws if accessed before [initialize].
  static FlavorConfig get instance {
    final value = _instance;
    if (value == null) {
      throw StateError(
        'FlavorConfig.initialize() must be called before use (see main_*.dart).',
      );
    }
    return value;
  }

  static bool get isDev => instance.flavor == AppFlavor.dev;

  /// Initialise the active flavor. Called once from `bootstrap()`.
  static void initialize(AppFlavor flavor) {
    _instance = switch (flavor) {
      AppFlavor.dev => FlavorConfig._(
        flavor: AppFlavor.dev,
        apiBaseUrl: 'http://192.168.1.3:9002',
        appTitle: 'PTP Dev',
      ),
      AppFlavor.prod => FlavorConfig._(
        flavor: AppFlavor.prod,
        apiBaseUrl: 'https://pitchtopicture.in',
        appTitle: 'Pitch To Picture',
      ),
    };
  }
}
