# CLAUDE.md

Guidance for AI assistants (and humans) working in this repository.

## What this is

"Let's Eat!" — a Flutter restaurant-suggestion app (Yelp API + Firebase) originally shipped to Google Play in 2020 and untouched since. The codebase is **Flutter 1.x / Dart 2.1, pre-null-safety, and does not build on modern toolchains**. A modernization effort is underway.

Key documents:
- `PROJECT_DOCUMENTATION.md` — full structure, feature inventory, and code-review findings.
- `REFACTOR_PLAN.md` — the phased modernization plan; follow its phase order and target architecture (`models/`, `services/`, `providers/`, `features/`).

## Critical things to know before touching code

1. **Do not assume `flutter pub get` / `flutter build` works.** Legacy code requires a ~2020 Flutter 1.12 SDK. Modernized code targets current stable Flutter 3.x / Dart 3.
2. **Secrets are exposed in legacy code**: a Yelp API key is hardcoded (copy-pasted in 10+ files under `lib/`) and a Google Maps key sits in `android/app/src/main/AndroidManifest.xml`. Never propagate these into new code, docs, or logs. New code must take keys via `--dart-define` or a backend proxy. Never commit new keys, `key.properties`, or keystores.
3. **All legacy Firebase APIs are dead** (`Firestore.instance`, `FirebaseUser`, `onAuthStateChanged`). Use current FlutterFire equivalents in any new/migrated code.
4. **There are no tests.** Any migrated service/model should gain unit tests (`flutter test`).

## Conventions for new/migrated code

- Dart 3, sound null safety, `flutter_lints` clean (`flutter analyze` must pass).
- File names `snake_case.dart`; one screen/widget concern per file.
- No Firestore/HTTP calls inside widgets — go through `services/`; state via provider layer, not raw `setState` for shared state.
- Exactly one implementation of Yelp API access (`services/yelp_service.dart`); never duplicate request/auth code.
- Delete commented-out dead code on sight; don't add more.
- Android application ID must remain `lets_eat.project` (preserves the existing Play listing).

## Repo layout (legacy)

- `lib/` — flat, screen-per-file Dart (~12,400 LOC, 39 files); `lib/Accounts/` holds auth screens.
- `android/`, `ios/` — 2019-era platform shells slated for regeneration (Phase 1 of the plan); don't invest in patching them.
- `assets/` — images referenced by `pubspec.yaml` (`assets/` glob).
- `.github/workflows/dart.yml` — broken CI (retired `google/dart` image); to be replaced with a Flutter workflow.
