import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';
import 'src/app.dart';
import 'src/core/config/app_status.dart';
import 'src/core/config/flavor.dart';

/// Shared entrypoint for every flavor. The flavor-specific `main_*.dart` files
/// call this with their [AppFlavor].
Future<void> bootstrap(AppFlavor flavor) async {
  WidgetsFlutterBinding.ensureInitialized();

  FlavorConfig.initialize(flavor);

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    AppStatus.firebaseReady = true;
  } catch (e) {
    // Firebase not configured yet — boot in preview mode so the UI/theme can
    // still be developed. Run `flutterfire configure` to enable auth.
    debugPrint('⚠️  Firebase not configured: $e');
  }

  runApp(const ProviderScope(child: PtpApp()));
}
