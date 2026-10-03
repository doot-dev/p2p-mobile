import 'main_common.dart';
import 'src/core/config/flavor.dart';

/// Dev flavor entrypoint → http://192.168.1.5:9002
///   flutter run --flavor dev -t lib/main_dev.dart
void main() => bootstrap(AppFlavor.dev);
