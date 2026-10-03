import 'main_common.dart';
import 'src/core/config/flavor.dart';

/// Default entrypoint (IDE "run" / `flutter run --flavor prod`). Prefer the
/// flavor-specific entrypoints:
///   flutter run --flavor dev  -t lib/main_dev.dart
///   flutter run --flavor prod -t lib/main_prod.dart
void main() => bootstrap(AppFlavor.prod);
