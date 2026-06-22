/// Mutable runtime flags set once during bootstrap (see `main.dart`).
abstract class AppStatus {
  /// True once `Firebase.initializeApp` has succeeded. Until `flutterfire
  /// configure` has been run this stays false so the UI can still be previewed.
  static bool firebaseReady = false;
}
