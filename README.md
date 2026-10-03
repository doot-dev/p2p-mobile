# Pitch To Picture — mobile app (Flutter)

The pitchtopicture.in website as an app for iOS, Android and web: submit a script, build your team, pitch on the show.

## How it works

- **Backend:** [P2P-backend](../P2P-backend) — `/api/auth` (the shared P2P account: email + password, Google via
  Firebase) and `/api/ptp/v1` (profiles, projects, NDA + applications, messages, uploads, pitch guide, contact).
  The `ptp` database is the website's existing schema.
- **API URL:** release builds use `https://api.pitchtopicture.in`; debug builds use `http://localhost:4000`
  (`10.0.2.2:4000` on the Android emulator). Override with `--dart-define=API_BASE_URL=…`.
- **Live chat:** P2P-backend's WebSocket (`/ws`, `ptp:*` events); messages are kept in on-device SQLite, so chats
  open offline and messages written offline send themselves when the connection is back.
- **Push:** Firebase Cloud Messaging (project `studio-5552739494-fac85`), registered with the backend as app `ptp`.
- **Uploads:** profile photos, project covers and script PDFs go straight to MinIO with presigned POSTs. Scripts are
  private (only the creator and the Pitch To Picture team can open them).

## Screens (mirrors the website)

| Area | Screens |
|------|---------|
| Account | Login, sign up (website password rules), verify email, forgot password, complete your profile, Google sign-in (mobile) |
| Home | Hero, official sponsor, latest projects, how it works, creators, CTA |
| Projects | Feed with search + genre filter, project detail (hiring by role, creator, share), NDA → apply, post a project (cover + script PDF), hiring editor, AI pitch guide (owner) |
| Dashboard | My projects, incoming applications (shortlist / hire / reject / message), sent applications |
| Inbox | Conversations with unread counts, new applications, live chat with read ticks |
| Creators | Directory with search + role filter, public profile with contact details |
| Profile | My profile, edit profile, settings (change password, delete account), terms, privacy, rules, contact (sends email), the show |

Guests can browse Home, Projects, Creators, profiles and the info pages; everything else asks them to sign in.

## Run

```bash
flutter pub get
flutter run                              # iOS simulator / Android emulator (backend on localhost:4000)
flutter run -d chrome --web-port 5050    # web
flutter test
```

## Release

| | |
|---|---|
| Android | `com.pitchtopicture.app` — `flutter build apk --release` / `appbundle`; signing from `android/key.properties` (falls back to the debug key) |
| iOS | `in.pitchtopicture.ptpApp` — `flutter build ipa --release` |
| Version | `version:` in `pubspec.yaml` |
