import 'package:flutter_test/flutter_test.dart';
import 'package:ptp_app/src/core/format.dart';
import 'package:ptp_app/src/core/router.dart';
import 'package:ptp_app/src/features/auth/session.dart';

Session signedIn({bool verified = true, bool onboarded = true}) => Session(
      SessionStatus.signedIn,
      account: Account(id: 'a1', email: 'a@b.c', name: 'A', emailVerified: verified),
      profile: {'id': 'PTPC1234', 'onboardingCompleted': onboarded},
    );

void main() {
  group('redirectFor', () {
    test('guests can browse projects, creators, profiles and info pages, not the rest', () {
      const out = Session(SessionStatus.signedOut);
      for (final p in ['/home', '/projects', '/creators', '/project/PTPP501', '/profile/PTPC1234', '/legal/terms', '/contact', '/show', '/login']) {
        expect(redirectFor(out, p), isNull, reason: p);
      }
      for (final p in ['/inbox', '/me', '/dashboard', '/project/new', '/project/PTPP501/hiring', '/chat/x', '/edit-profile']) {
        expect(redirectFor(out, p), '/login', reason: p);
      }
    });

    test('verify email, then onboarding, then the app', () {
      expect(redirectFor(signedIn(verified: false), '/projects'), '/verify-email');
      expect(redirectFor(signedIn(onboarded: false), '/projects'), '/onboarding');
      expect(redirectFor(signedIn(), '/login'), '/home');
      expect(redirectFor(signedIn(), '/dashboard'), isNull);
    });

    test('loading shows the splash', () {
      expect(redirectFor(const Session(SessionStatus.loading), '/projects'), '/');
    });
  });

  test('hiring helpers: no required roles means every preset role; closed roles are not open', () {
    expect(projectRoles({'requiredRoles': []}), roles);
    final p = {'requiredRoles': ['Actor', 'Editor'], 'roleAvailability': {'Editor': false}};
    expect(projectRoles(p), ['Actor', 'Editor']);
    expect(roleOpen(p, 'Actor'), isTrue);
    expect(roleOpen(p, 'Editor'), isFalse);
  });
}
