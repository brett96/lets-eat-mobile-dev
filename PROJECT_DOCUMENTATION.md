# Let's Eat! — Project Documentation & Analysis

_Last analyzed: July 2026. Codebase last meaningfully touched: ~July 2020 (Flutter 1.x era)._

## 1. What the app is

"Let's Eat!" is a restaurant-decision app: users tell it what they're in the mood for, it queries the **Yelp Fusion API** for nearby restaurants and suggests one. Social features let users add friends, form groups, vote on restaurants, and chat in real time. It was previously published on Google Play as `lets_eat.project`. An iOS release was planned but never shipped.

## 2. Tech stack (as committed)

| Layer | Technology | Version in repo | Status today |
|---|---|---|---|
| Framework | Flutter | 1.x (`.metadata` rev `20e59316`, ~v1.12, Feb 2020) | ~14 major versions behind; pre-null-safety |
| Language | Dart | SDK constraint `>=2.1.0 <3.0.0` | Pre-null-safety; won't compile on Dart 3 |
| Backend | Firebase (Auth, Cloud Firestore, Realtime DB, Analytics, Messaging) | `firebase_*` 0.x plugin era | All plugin APIs long removed/rewritten |
| Restaurant data | Yelp Fusion REST API | via `http ^0.12` | API still exists; key handling is the problem (see §6) |
| Maps | `google_maps_flutter ^0.5.28` | pre-1.0 | Current is 2.x |
| Sign-in | `google_sign_in ^4.4.4` + email/password | Current is 7.x with a very different API |
| Android build | Gradle 5.4.1, AGP 3.3.2, Kotlin 1.3.10, compile/targetSdk 28, minSdk 16 | Won't build with any modern JDK/Android Studio; Play Store now requires targetSdk 35 |
| iOS | MinimumOSVersion 8.0, old Xcode project format, no `GoogleService-Info.plist` | Never completed; App Store requires iOS 13+ minimum and Xcode 16+ |
| CI | `.github/workflows/dart.yml` | Uses the retired `google/dart` image and `pub run test`; broken (and there are no tests) |

## 3. Repository structure

```
lets-eat-mobile-dev/
├── android/                 # Android host (AGP 3.3.2, Gradle 5.4.1 — obsolete)
│   └── app/google-services.json   # Firebase config (committed)
├── ios/                     # iOS host, incomplete (no GoogleService-Info.plist)
├── assets/                  # Images: logos, star ratings, backgrounds, screenshots
├── lib/                     # All Dart code — flat, screen-per-file, no layering
│   ├── main.dart            # Entry point; MaterialApp with /home and /login routes
│   ├── Home.dart            # Main landing screen
│   ├── HomeSearch.dart, search.dart, SearchList.dart, YelpSearch.dart
│   │                        # Search flows (overlapping responsibilities)
│   ├── YelpRepository.dart  # Yelp API calls — implemented as a StatefulWidget (!)
│   ├── Restaurants.dart, RestaurantData.dart, RestaurantInfo.dart
│   ├── maps.dart, MapRestaurant.dart          # Google Maps screens
│   ├── InstantSuggestion.dart                 # "Pick for me" feature
│   ├── Group.dart, CreateGroup.dart, ViewGroup.dart (1001 lines),
│   │   GroupChat.dart, GroupVotePage.dart, GroupRestaurant.dart
│   ├── Friends.dart, FriendsPage.dart
│   ├── History.dart, ShowSavedRestaurants.dart, Delivery.dart, About.dart
│   └── Accounts/            # Auth: LoginSignUp, signUpPage, signUp2, userAuth,
│                            #   authentication, PasswordReset, AccountManagement,
│                            #   updateUser, updateUName, UserYelpPreferences, ...
├── pubspec.yaml             # 15 dependencies, all 2019-2020 era
└── .github/workflows/dart.yml   # Broken CI
```

~12,400 lines of Dart across 39 files. No `test/` directory — **zero tests**.

## 4. Architecture (as-is)

- **No architecture layer.** Every screen is a large `StatefulWidget` that mixes UI, Firestore/Realtime-DB reads and writes, Yelp HTTP calls, and navigation. State management is raw `setState`.
- **`YelpRepository.dart` is a `StatefulWidget`**, not a repository class — data access is entangled with the widget tree, and other screens duplicate its logic instead of calling it.
- **Massive duplication:** the Yelp `API_KEY` + auth header and request-building code are copy-pasted into 10+ files (`Home`, `maps`, `InstantSuggestion`, `HomeSearch`, `MapRestaurant`, `ShowSavedRestaurants`, `ViewGroup`, `Delivery`, `RestaurantInfo`, `YelpRepository`, …).
- **Firestore accessed directly from widgets** (24 files use `Firestore.instance`); document shapes are implicit, no model classes with serialization for most data.
- **Dead code everywhere:** large commented-out blocks in `main.dart`, `android/app/build.gradle` (entire duplicate file commented at the bottom), `authentication.dart`, etc.
- Naming is inconsistent (`Home.dart` vs `maps.dart` vs `signUpPage.dart`), imports are case-sensitive-fragile (`main.dart` imports both `home.dart` and defines route to `Home` from `Home.dart`), and `dart:ffi` is imported in `YelpRepository.dart` for no reason.

## 5. Feature inventory

1. **Auth:** email/password + Google Sign-In (Firebase Auth); account merge logic for Google sign-in over existing email accounts; password reset; username/profile updates.
2. **Restaurant search:** by cuisine/keyword/location via Yelp; list + map results; instant single suggestion; per-user Yelp preference profile (`UserYelpPreferences`).
3. **Saved restaurants & history.**
4. **Friends:** add/manage friends (Firestore).
5. **Groups:** create groups, group restaurant voting, real-time group chat (Firestore/RTDB), push notifications (`firebase_messaging`).
6. **Delivery:** hand-off to delivery/ordering via `url_launcher`.
7. **Maps:** Google Maps with restaurant pins; offline-map fallback when location is unavailable.

## 6. Security findings (from code review — must fix before any release)

1. **Yelp API key hardcoded** and duplicated in 10+ Dart files, committed to a public repo. It ships in every APK. → Revoke/rotate the key; move calls behind a proxy (e.g., Cloud Functions) or at minimum inject via `--dart-define` and rely on Yelp key restrictions.
2. **Google Maps API key hardcoded in `AndroidManifest.xml`.** → Rotate and restrict by package name + SHA-1; inject from `local.properties`/secrets at build time.
3. **`google-services.json` committed.** Low sensitivity by itself, but combined with (likely) permissive Firestore rules it's a risk. **Firestore/RTDB security rules are not in the repo and must be audited** — widgets read/write user documents directly, so rules are the only server-side enforcement.
4. **`dbcrypt` client-side password hashing** appears in imports (mostly commented out) alongside Firebase Auth — suggests a legacy custom-auth path. Any client-side hashing scheme should be removed entirely in favor of Firebase Auth.
5. Release builds are **signed with the debug key** (`signingConfig signingConfigs.debug` in `android/app/build.gradle`); the real signing config is commented out.
6. README privacy claims ("all data encrypted", "location never logged") are unverified by the code and must be re-validated before republishing; both stores now require a privacy policy, data-safety forms, and account-deletion support.

## 7. Why it won't build or ship today

- Dart 2.1 / pre-null-safety code cannot compile on any supported Flutter SDK (3.x requires Dart 3).
- All `firebase_*` 0.x plugin APIs (`Firestore.instance`, `FirebaseUser`, `onAuthStateChanged`, etc.) were removed in the 2021 FlutterFire rewrite.
- AGP 3.3.2 + Gradle 5.4.1 won't run on modern JDKs; `jcenter()` is shut down; `android.support`/Jetifier era dependencies.
- targetSdk 28 is far below Play's current requirement (35); no runtime-permission flow updates, no privacy declarations.
- iOS project targets iOS 8, lacks Firebase config, and predates required Xcode/privacy-manifest tooling.
- CI workflow uses a retired Docker image and runs tests that don't exist.

## 8. Modernization plan

See **REFACTOR_PLAN.md** for the phased plan to bring the app to current Flutter/Dart, Firebase, and store requirements.
