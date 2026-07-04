# Let's Eat! — Modernization & Refactor Plan

Goal: a maintainable Flutter 3.x / Dart 3 app that builds and ships on current Android (Play, targetSdk 35) and iOS (App Store, iOS 13+). The gap is ~7 years, so this is a **staged rewrite-in-place**, not an incremental `flutter upgrade` (the null-safety and FlutterFire breaks make automatic migration impossible from Dart 2.1).

## Phase 0 — Safety & prerequisites (do first, ~1 day)

- [ ] **Rotate the Yelp API key** (exposed in the public repo) and the **Google Maps key** in `AndroidManifest.xml`. Restrict the new Maps key by package + SHA-1 (Android) and bundle ID (iOS).
- [ ] Audit **Firestore/Realtime DB security rules** in the Firebase console; export them into the repo (`firestore.rules`, `database.rules.json`) and lock them down (per-user access only).
- [ ] Decide key strategy: preferred — proxy Yelp calls through a Cloud Function so no key ships in the binary; minimum — inject via `--dart-define`.
- [ ] Verify access to the Firebase project, Play Console listing (`lets_eat.project`), and upload/signing keys. If the original upload key is lost, plan Play App Signing key reset or a new listing.
- [ ] Tag current `master` (e.g. `v1.1.0-legacy`) so the old code is always retrievable.

## Phase 1 — Toolchain & project scaffolding (1–2 days)

Rather than patching 2019-era `android/` and `ios/` folders, **regenerate the platform shells**:

- [ ] Install current stable Flutter (3.32+ / Dart 3.8+).
- [ ] `flutter create` a fresh project with a proper application ID (keep `lets_eat.project` for Android to preserve the Play listing; pick a real bundle ID for iOS).
- [ ] Copy `lib/` and `assets/` into it; delete generated legacy `android/`, `ios/`, old `pubspec.lock`.
- [ ] Configure Firebase with `flutterfire configure` (generates `firebase_options.dart`, fresh `google-services.json`, and the missing `GoogleService-Info.plist` for iOS).
- [ ] Android: minSdk 23+, target/compileSdk 35, AGP 8.x, Kotlin 2.x, Gradle 8.x, real release `signingConfigs` from `key.properties` (kept out of git).
- [ ] iOS: minimum iOS 13, Firebase pods, `NSLocationWhenInUseUsageDescription` in Info.plist.
- [ ] Add `analysis_options.yaml` with `flutter_lints`.

## Phase 2 — Dependency migration (1–2 days)

| Old | New |
|---|---|
| `firebase_core/auth/analytics/messaging/cloud_firestore/firebase_database` 0.x | current FlutterFire (all 2021+ rewritten APIs: `FirebaseFirestore.instance`, `User`, `authStateChanges()`, `Firebase.initializeApp`) |
| `google_maps_flutter 0.5` | `google_maps_flutter 2.x` |
| `google_sign_in 4.x` | `google_sign_in 7.x` (API fully changed) |
| `location 2.x` | `geolocator` or `location` 8.x (Android 10+ permission model) |
| `http 0.12` | `http 1.x` (or `dio`) |
| `carousel_slider 1.x` | `carousel_slider` 5.x |
| `dbcrypt` | **remove** (Firebase Auth handles credentials) |
| `units`, `keyboard_avoider`, `grouped_buttons`, `flutter_multiselect` | remove/replace — all abandoned, none null-safe. `grouped_buttons`/`flutter_multiselect` → built-in `CheckboxListTile`/`FilterChip`; `keyboard_avoider` → standard `Scaffold` insets |
| `flutter_launcher_icons 0.7` | current version (dev dependency only) |
| `uuid 2.x` | `uuid 4.x` |

## Phase 3 — Code migration & architecture (the bulk: 2–4 weeks)

Migrate feature-by-feature into a layered structure; each screen needs null-safety conversion plus FlutterFire/Maps/Sign-In API rewrites anyway, so restructure as you go:

```
lib/
├── main.dart / app.dart
├── models/        # Restaurant, UserProfile, Group, Message — typed fromJson/toJson
├── services/      # yelp_service.dart (single copy of API logic!), auth_service.dart,
│                  # firestore_service.dart, location_service.dart, notification_service.dart
├── providers/     # state management (Riverpod or Provider) replacing raw setState
└── features/      # auth/, home/, search/, restaurant/, groups/, friends/, maps/, settings/
```

Suggested order (dependency-driven):
1. **Core services + models** — one `YelpService` (kills the 10× duplicated key/header/request code), `AuthService`, typed `Restaurant` model.
2. **Auth flows** (`Accounts/*`) — rebuild on current `firebase_auth` + `google_sign_in`; delete dbcrypt/custom-auth remnants; preserve the Google-merge behavior.
3. **Home + search + instant suggestion** — consolidate the overlapping `search.dart`/`SearchList`/`HomeSearch`/`YelpSearch` screens.
4. **Maps** (`maps.dart`, `MapRestaurant`) on `google_maps_flutter` 2.x.
5. **Saved restaurants, history, delivery.**
6. **Friends & groups** (`ViewGroup` at 1,001 lines needs decomposition into widgets + a provider), group chat, voting.
7. **Push notifications** — `firebase_messaging` current API + Android 13 notification permission.

Cleanup rules throughout: delete all commented-out blocks, fix file naming to `snake_case.dart`, remove `dart:ffi` and other unused imports, `const` constructors, no logic in widgets beyond presentation.

## Phase 4 — Testing & CI (3–5 days, ongoing)

- [ ] Unit tests for services/models (mock Yelp HTTP, `fake_cloud_firestore`).
- [ ] Widget tests for auth and search flows; a couple of integration tests on the critical path (login → search → suggestion).
- [ ] Replace `.github/workflows/dart.yml` with a Flutter workflow: `flutter analyze`, `flutter test`, debug APK build on PRs; release builds on tags.

## Phase 5 — Store readiness (3–5 days)

**Android/Play:** targetSdk 35, app bundle (`.aab`), Play App Signing, data-safety form, privacy policy URL, account-deletion flow (now mandatory since the app has accounts), runtime location-permission rationale UI, adaptive + monochrome launcher icons.

**iOS/App Store:** Apple Developer account, bundle ID + certificates/profiles, Sign in with Apple (**required** because Google Sign-In is offered), privacy manifest (`PrivacyInfo.xcprivacy`), App Tracking Transparency review, purpose strings, App Store screenshots/metadata, TestFlight beta.

**Both:** rewrite the privacy policy to match actual behavior; verify the README's encryption claims or drop them.

## Effort summary

| Phase | Estimate |
|---|---|
| 0 Security/prereqs | 1 day |
| 1 Toolchain/scaffold | 1–2 days |
| 2 Dependencies | 1–2 days |
| 3 Code migration | 2–4 weeks |
| 4 Tests & CI | 3–5 days (overlapping) |
| 5 Store readiness | 3–5 days |
| **Total** | **~4–6 weeks** for one developer |

The single highest-risk unknown is Firebase project state (rules, existing user data, lost signing keys). Verify Phase 0 items before committing to the schedule.
