# iOS Firebase setup

The legacy project never shipped an iOS build, so there is **no iOS app
registered in the Firebase project** and no `GoogleService-Info.plist`. The
code is wired so that iOS works the moment those two console steps are done —
no Dart changes required.

## What's already configured in this repo

- **Bundle identifier:** `com.letseat.app` (Runner) / `com.letseat.app.RunnerTests`.
  Use this exact ID when registering the iOS app in Firebase.
- **Deployment target:** iOS 13.0 (`project.pbxproj` + `Podfile`), the minimum
  the current Firebase SDK supports.
- **Podfile:** pins `platform :ios, '13.0'` and forces it on all pods.
- **Firebase init:** `lib/main.dart` calls `DefaultFirebaseOptions.currentPlatform`
  and, on iOS (which throws `UnsupportedError`), falls back to
  `Firebase.initializeApp()` — which reads the native `GoogleService-Info.plist`
  from the app bundle.
- **Location + notification** usage strings are in `Info.plist`.
- **Google Sign-In URL scheme** placeholder (`REVERSED_CLIENT_ID`) is in
  `Info.plist` and must be replaced (step 3 below).

## Manual steps (require the Firebase console + a Mac with Xcode)

1. **Register the iOS app.** Firebase console → project `lets-eat-18b7b` →
   Add app → iOS → bundle ID `com.letseat.app`. Download the generated
   `GoogleService-Info.plist`.

2. **Add the plist to Xcode.** Drag `GoogleService-Info.plist` into the
   `Runner` target in Xcode (so it's copied into the app bundle). Do **not**
   commit it if the repo is public — it's git-ignored by default here.

3. **Wire up Google Sign-In.** Open `GoogleService-Info.plist`, copy the
   `REVERSED_CLIENT_ID` value, and replace the `REVERSED_CLIENT_ID` string in
   `ios/Runner/Info.plist` → `CFBundleURLTypes`.

4. **(Optional) Regenerate Dart options.** Run `flutterfire configure` to add
   an `ios` entry to `firebase_options.dart`. Not required — the native plist
   fallback already works — but keeps all platforms symmetric.

5. **Push notifications (APNs).** In the Apple Developer portal create an APNs
   auth key (.p8) and upload it under Firebase console → Project settings →
   Cloud Messaging → Apple app configuration. Enable the **Push Notifications**
   and **Background Modes → Remote notifications** capabilities on the Runner
   target in Xcode. Without this, `NotificationService` silently no-ops on iOS
   (by design — see its try/catch).

6. **Sign in with Apple (required by App Store review).** Because the app
   offers Google Sign-In, Apple requires Sign in with Apple as an option too.
   Add the *Sign in with Apple* capability and implement it via
   `sign_in_with_apple` before submitting. Tracked in REFACTOR_PLAN.md Phase 5.

## Build

```
cd ios && pod install       # after `flutter pub get`
open Runner.xcworkspace      # build/run from Xcode, or:
flutter build ios --dart-define=YELP_API_KEY=... --dart-define=... 
```
