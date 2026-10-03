import 'main_common.dart';
import 'src/core/config/flavor.dart';

/// Prod flavor entrypoint → https://pitchtopicture.in
///   flutter run --flavor prod -t lib/main_prod.dart
void main() => bootstrap(AppFlavor.prod);
