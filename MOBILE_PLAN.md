# Pitch To Picture — Flutter App Implementation Plan

Bringing every web feature into the Flutter app (`ptp-app`) by calling the
Next.js backend (`../P2P-website`). This document is the single source of truth for the
mobile build-out.

- **Production base URL:** `https://pitchtopicture.in`
- **Local dev base URL:** `http://192.168.1.5:9002` (Next.js `next dev -p 9002`)
- **Mobile API prefix:** `/api/v1` (new, mobile-facing REST routes)
- **Bundle id:** `com.pitchtopicture.app` (prod) / `com.pitchtopicture.app.dev` (dev)
- **Flavors:** `dev`, `prod`

---

## 1. Architecture: why we need a new `/api/v1` REST layer

The web app does **not** expose a reusable REST API for its core domain. Data
flows through **Next.js Server Actions** (`src/app/actions/*.ts`), which are an
internal RPC mechanism (encrypted action ids, `next/cache` revalidation) and are
**not callable from a Flutter/Dio HTTP client**. The only existing REST routes
(`src/app/api/admin/*`) are admin-only and authenticated with an HMAC cookie.

Data + auth split in the backend:

| Concern | Implementation |
| --- | --- |
| Authentication | **Firebase Auth** (email/password + Google) |
| Data store | **Prisma + MySQL** (`UserProfile`, `Project`, `Application`, `Message`, `NdaRecord`, `AdminAccount`) |
| Business logic | Next.js **server actions** (not REST) |

**Plan:** the Flutter app authenticates directly with **Firebase Auth** (already
wired) and then calls **new mobile REST endpoints under `/api/v1`** that we add
to the Next.js app. Each route:

1. Reads the `Authorization: Bearer <Firebase ID token>` header.
2. Verifies it with **`firebase-admin`** (already a dependency, v13.4.0).
3. Resolves the caller's `UserProfile` (by `authUid`) for authorization.
4. Delegates to the **existing server-action functions** (we reuse the Prisma
   logic verbatim — the routes are thin HTTP wrappers, no logic duplication).
5. Returns JSON.

This keeps a single backend brain (Prisma logic) shared by web (actions) and
mobile (REST), and the Flutter `ApiClient` already attaches the Firebase ID
token on every request — so the client side is ready.

---

## 2. Backend work — new mobile REST routes (in `../P2P-website`)

### 2.1 Shared helper — `src/lib/mobile-auth.ts`
Verify the Firebase ID token and load the caller profile. Mirrors the shape of
`admin-auth.ts` but for Firebase users.

```ts
// Pseudocode
import { getApps, initializeApp, cert } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";

export async function requireUser(req: Request): Promise<{ authUid: string; profile: UserProfileRow | null }>
// - parse "Authorization: Bearer <token>"
// - getAuth().verifyIdToken(token) -> decoded.uid
// - prisma.userProfile.findUnique({ where: { authUid } })
// - throw 401 on missing/invalid token
```
Service-account credentials: reuse the existing admin SDK init in the web app if
present, otherwise read `FIREBASE_SERVICE_ACCOUNT` / GOOGLE_APPLICATION_CREDENTIALS
from env (document in `.env`).

### 2.2 Endpoint map (`/api/v1/*`)
Each row maps to existing server-action logic so there is no new business logic.

| Method & Path | Backs (server action) | Purpose |
| --- | --- | --- |
| `GET  /api/v1/me` | `getProfileByUid`, `getOnboardingStatus` | Current user profile + onboarding flag |
| `POST /api/v1/me/ensure` | `ensureUserProfile` | Idempotent profile creation after first sign-in |
| `PATCH /api/v1/me` | `updateProfile` | Edit profile / complete onboarding |
| `GET  /api/v1/profiles/:ptpcId` | `getProfileById` | Public creator profile |
| `GET  /api/v1/creators` | `getAllProfiles` | Creator directory |
| `GET  /api/v1/projects` | `getAllProjects` | Public project discovery feed |
| `POST /api/v1/projects` | `createProjectRecord` | Submit a new project |
| `GET  /api/v1/projects/:id` | `getProjectById` (viewer-aware) | Project detail |
| `GET  /api/v1/projects/mine` | `getProjectsByCreator` | "My projects" (dashboard) |
| `PATCH /api/v1/projects/:id/hiring` | `updateProjectHiringConfig` | Required roles + availability |
| `POST /api/v1/projects/:id/nda` | `recordNda` | Record NDA acceptance |
| `POST /api/v1/projects/:id/apply` | `submitApplication` | Apply to a role |
| `GET  /api/v1/projects/:id/applied` | `checkHasApplied` | Has the caller applied? |
| `GET  /api/v1/applications/incoming` | `getIncomingApplications` | Creator hiring inbox |
| `GET  /api/v1/applications/sent` | `getSentApplications` | Applicant's sent applications |
| `PATCH /api/v1/applications/:id/status` | `updateApplicationStatus` | Shortlist / select / reject |
| `PATCH /api/v1/applications/:id/read` | `markApplicationAsRead` | Mark application read |
| `GET  /api/v1/messages` | `getMessages` | Inbox threads / a conversation |
| `POST /api/v1/messages` | `sendMessage` | Send a message |
| `PATCH /api/v1/messages/:id/read` | `markMessageAsRead` | Mark message read |
| `POST /api/v1/pitch-guide` | `generatePitchPrepGuide` (AI flow) | Generative pitch-prep guide |
| `POST /api/v1/uploads` *(optional)* | Firebase Storage | Image/script/trailer upload signed URL or proxy |

Notes:
- **Authorization** is enforced server-side: e.g. `projects/mine` filters by the
  caller's `authUid`; `applications/:id/status` checks `projectCreatorId` matches
  the caller; `messages` only returns threads the caller participates in. The
  existing actions already take the relevant uid as a parameter — the route
  supplies it from the verified token instead of trusting the client.
- **Uploads:** the web app currently stores image/script/trailer URLs (Google
  Drive links / Firebase Storage URLs). Mobile will either (a) upload to Firebase
  Storage directly via the `firebase_storage` plugin, or (b) accept a pasted URL
  (matches current web UX for trailers/scripts). Decide per-field; start with
  pasted URLs + Storage for profile/project images.

---

## 3. Flutter feature map

Folder convention (already started): `lib/src/features/<feature>/{data,domain,presentation}`.
Models use `json_serializable` (already a dependency). State via Riverpod.

| Feature | Screens | Repository → endpoints |
| --- | --- | --- |
| **Auth** | Login *(done)*, Signup, Forgot-password | Firebase Auth (`AuthRepository`, done) + `POST /me/ensure` |
| **Onboarding** | Onboarding form (name, roles, location, bio, photo) | `GET /me`, `PATCH /me` |
| **Profile** | My profile, Edit profile, Public profile `:id` | `GET /me`, `PATCH /me`, `GET /profiles/:id` |
| **Creators** | Creator directory + search | `GET /creators` |
| **Projects (discovery)** | Project feed, Project detail | `GET /projects`, `GET /projects/:id` |
| **Projects (create/manage)** | New project, Edit hiring config | `POST /projects`, `PATCH /projects/:id/hiring` |
| **Applications / Hiring** | NDA gate, Apply sheet, Incoming (creator), Sent (applicant) | `POST /:id/nda`, `POST /:id/apply`, `GET /applications/incoming`, `GET /applications/sent`, `PATCH /applications/:id/status` |
| **Dashboard** | Tabbed hub: My Projects, Incoming, Sent | `GET /projects/mine` + applications endpoints |
| **Inbox / Messaging** | Threads list, Conversation | `GET /messages`, `POST /messages`, `PATCH /messages/:id/read` |
| **Pitch guide (AI)** | Generate + render markdown guide | `POST /pitch-guide` (renders with `flutter_markdown`, already a dep) |
| **Show / lifecycle** | Show info, trailer submission, status timeline | project status + trailer URL fields |
| **Static** | Rules, Terms, Privacy, Contact | static screens (mirror web copy) |

Shared infra already present and reused: `ApiClient` (Dio + token), `Env`,
`AppConstants` (roles, statuses, status colours), `AppTheme` (cinematic gold/black),
`PtpLogo`.

### 3.1 Client data layer to add
- `lib/src/features/*/domain/*.dart` — model classes (`UserProfile`, `Project`,
  `Application`, `Message`, `NdaRecord`) with `fromJson`/`toJson` (json_serializable).
- `lib/src/features/*/data/*_repository.dart` — typed wrappers over `ApiClient`.
- Riverpod providers (FutureProvider/AsyncNotifier) per screen.
- Expand `app_router.dart` with the routes above + an authenticated bottom-nav
  shell (Discover / Dashboard / Inbox / Profile) and onboarding redirect gate.

---

## 4. Flavors & environments

Two flavors, selected at build/run time. Each maps to a base URL and bundle id.

| Flavor | Base URL | Android appId | iOS bundle id | App name |
| --- | --- | --- | --- | --- |
| `dev`  | `http://192.168.1.5:9002` | `com.pitchtopicture.app.dev` | `com.pitchtopicture.app.dev` | PTP Dev |
| `prod` | `https://pitchtopicture.in` | `com.pitchtopicture.app` | `com.pitchtopicture.app` | Pitch To Picture |

### 4.1 Dart side (implemented in this pass)
- `lib/src/core/config/flavor.dart` — `AppFlavor` enum + `FlavorConfig` holding
  `apiBaseUrl` + `appTitle`, initialised once at boot.
- `lib/main_dev.dart`, `lib/main_prod.dart` — flavor entrypoints calling a shared
  `bootstrap(AppFlavor)` in `lib/main_common.dart`.
- `Env.apiBaseUrl` now resolves from `FlavorConfig` (with an optional
  `--dart-define=API_BASE_URL=` override for one-off testing).

Run commands:
```bash
flutter run --flavor dev  -t lib/main_dev.dart
flutter run --flavor prod -t lib/main_prod.dart
# one-off base URL override (e.g. a tunnel):
flutter run --flavor dev -t lib/main_dev.dart --dart-define=API_BASE_URL=https://abc.ngrok.io
```

### 4.2 Android (implemented in this pass)
- `productFlavors { dev, prod }` on dimension `environment` in
  `android/app/build.gradle.kts`.
- `applicationId = com.pitchtopicture.app`; dev adds `.dev` suffix.
- `resValue("string", "app_name", …)` per flavor; manifest label →
  `@string/app_name`.
- `android/app/src/dev/AndroidManifest.xml` enables `usesCleartextTraffic` so the
  emulator/device can reach `http://192.168.1.5:9002` (prod stays HTTPS-only).

### 4.3 iOS (manual — needs Xcode, steps documented)
Flutter iOS flavors require Xcode build configurations + schemes:
1. In Xcode: duplicate `Debug/Release/Profile` into `Debug-dev`, `Release-dev`,
   `Profile-dev`, `…-prod`.
2. Add `ios/Flutter/dev.xcconfig` / `prod.xcconfig` setting
   `PRODUCT_BUNDLE_IDENTIFIER` and `APP_DISPLAY_NAME` per flavor; reference
   `$(PRODUCT_BUNDLE_IDENTIFIER)` in `project.pbxproj` and `$(APP_DISPLAY_NAME)`
   in `Info.plist` (`CFBundleDisplayName`).
3. Create schemes `dev` and `prod` mapped to those configs.
4. Allow cleartext for dev only via an `Info-dev.plist` `NSAppTransportSecurity`
   exception for `192.168.1.5`.

---

## 5. ⚠️ Firebase re-registration (required for the bundle rename)

The existing Firebase project (`studio-5552739494-fac85`) is registered for
`in.pitchtopicture.ptp_app` (Android) and `in.pitchtopicture.ptpApp` (iOS).
Renaming the bundle to `com.pitchtopicture.app` **will break Google Sign-In and
fail the Android build** (`google-services` plugin: "No matching client found for
package name") until Firebase is updated. Do the following **before** building:

1. Firebase Console → Project settings → **Add app** for each new id:
   - Android `com.pitchtopicture.app` and `com.pitchtopicture.app.dev`
   - iOS `com.pitchtopicture.app` and `com.pitchtopicture.app.dev`
2. Add each Android app's **SHA-1/SHA-256** (debug + release) for Google Sign-In.
3. Re-run **`flutterfire configure`** to regenerate `lib/firebase_options.dart`
   and download the new `google-services.json` / `GoogleService-Info.plist`
   (place per-flavor under `android/app/src/{dev,prod}/` if ids differ).
4. Verify Google Sign-In OAuth client ids match the new bundle ids.

Until this is done, keep using the old ids OR expect auth/build to fail. This is
the one step that can't be automated from the repo.

---

## 6. Phased roadmap

1. **Infra (this pass):** flavors, bundle ids, Env/flavor wiring, dev cleartext,
   this plan. ✅
2. **Backend API:** `mobile-auth.ts` + `/api/v1` routes (§2), deploy to
   `pitchtopicture.in`.
3. **Client foundation:** models + repositories + Riverpod providers + router
   shell (bottom nav + onboarding gate).
4. **Auth & onboarding:** signup, forgot-password, onboarding form, `me/ensure`.
5. **Discovery:** project feed + detail + creator directory.
6. **Create/manage:** new project, hiring config, dashboard "My Projects".
7. **Hiring:** NDA gate, apply, incoming/sent applications, status changes.
8. **Messaging:** inbox + conversation (+ optional polling/refresh).
9. **AI pitch guide**, **show/lifecycle**, **static pages**.
10. **Polish:** error/empty/loading states, image upload, release signing, CI.

---

## 7. Open decisions
- **Uploads:** Firebase Storage direct vs pasted URLs vs backend-proxied upload.
- **Messaging realtime:** poll on interval vs add a lightweight push later.
- **iOS flavors:** confirm whether dev/prod need different bundle ids on iOS
  (side-by-side install) or a single id is fine for now.
- **Service account:** confirm how `firebase-admin` is credentialed in prod
  (App Hosting env vs service-account JSON).

---

*Status of this pass: Section 4 (flavors/bundle) + this plan implemented in the
Flutter repo. Sections 2–3 (API routes + feature screens) are the next phases.*
