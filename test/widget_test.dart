// Basic smoke test for the Pitch To Picture app shell.
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ptp_app/src/app.dart';

void main() {
  testWidgets('App boots to the login screen when not authenticated',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PtpApp()));
    await tester.pump();

    // Unauthenticated users are redirected to the login screen.
    expect(find.text('Log in'), findsOneWidget);
  });
}
