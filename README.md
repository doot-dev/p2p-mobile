# Pitch To Picture — Flutter App (`ptp_app`)

Mobile (iOS + Android) client for the **Pitch To Picture** film-pitch platform.
Mirrors the features of the existing Next.js web app in `../P2P`.

## Architecture

| Concern | Choice |
|---|---|
| Auth | Firebase Auth (email/password + Google) — client SDK |
| Data API | REST endpoints on the Next.js app (`/api/v1/*`), authed with the Firebase ID token |
| State management | Riverpod |
| Routing | go_router |
| HTTP | Dio (auto-attaches `Authorization: Bearer <idToken>`) |

> The web app stores data in **MySQL via Prisma** and exposes it through Next.js
> **Server Actions**, which Flutter cannot call. The plan is to add REST
> endpoints (`/api/v1/*`) to the Next.js app that reuse the same Prisma logic.

## Project layout

```
lib/
  main.dart                     # bootstrap (Firebase init guarded)
  firebase_options.dart         # PLACEHOLDER — run `flutterfire configure`
  src/
    app.dart                    # MaterialApp.router + theme
    core/
      config/   env.dart, app_status.dart
      constants/ app_colors.dart, app_constants.dart   # roles, statuses, palette
      theme/    app_theme.dart                          # cinematic black/gold
      network/  api_client.dart (Dio + token), api_exception.dart
      router/   app_router.dart
    features/
      auth/        data | domain | presentation
      profile/     ...
      projects/    ...
      applications/...
      messages/    ...
      pitch_guide/ ...
      admin/       ...
    shared/  models | widgets
```

## Setup (before running with real auth)

1. Install the FlutterFire CLI and configure the Firebase project:
   ```bash
   dart pub global activate flutterfire_cli
   cd ptp-app
   flutterfire configure --project=<firebase-project-id>
   ```
   This regenerates `lib/firebase_options.dart` and adds the native config
   files (`google-services.json`, `GoogleService-Info.plist`). Use the same
   Firebase project as the web app (see `../P2P/.env`).
2. Point the app at your API:
   ```bash
   flutter run --dart-define=API_BASE_URL=https://pitchtopicture.in
   # Android emulator against a local Next.js dev server:
   # --dart-define=API_BASE_URL=http://10.0.2.2:9002
   ```

Until step 1 is done the app boots in "Firebase not configured" preview mode so
the theme/UI can still be developed.

## Commands

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

## Roadmap (next steps)

- [ ] Add `/api/v1/*` REST endpoints to the Next.js app (Firebase ID-token auth)
- [ ] Models + JSON serialization (User, Project, Application, Message, NDA)
- [ ] Auth flows: signup, onboarding, password reset
- [ ] Projects: list, detail, submit, dashboard, status lifecycle
- [ ] Team building: NDA → apply → manage applications
- [ ] Inbox / messaging
- [ ] AI Pitch Prep guide
- [ ] Trailer submission + show lifecycle + payments
- [ ] Admin panel
```
