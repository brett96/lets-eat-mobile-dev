// Firebase configuration for the `lets-eat-18b7b` project.
//
// Android values come from the project's `google-services.json`.
// Regenerate this file with `flutterfire configure` when adding platforms —
// in particular, iOS needs an app registered in the Firebase console first.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'No iOS Firebase app is registered yet. Register one in the '
          'Firebase console and run `flutterfire configure`.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB4h0ckdeEwxIzT1qOhP3W8FXakslNlgX4',
    appId: '1:852218951035:android:66590b695af114a85739de',
    messagingSenderId: '852218951035',
    projectId: 'lets-eat-18b7b',
    databaseURL: 'https://lets-eat-18b7b.firebaseio.com',
    storageBucket: 'lets-eat-18b7b.appspot.com',
  );
}
