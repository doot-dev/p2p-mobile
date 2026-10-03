import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';
import 'src/core/router.dart';
import 'src/core/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase project studio-5552739494-fac85: push (FCM) and the Google sign-in bridge on Android/iOS.
  // ponytail: web skips Firebase until web push / Google sign-in on web are added.
  if (!kIsWeb) await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: App()));
}

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
        title: 'Pitch To Picture',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        routerConfig: ref.watch(routerProvider),
      );
}
