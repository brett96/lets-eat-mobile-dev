import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/group_service.dart';
import 'services/location_service.dart';
import 'services/notification_service.dart';
import 'services/user_service.dart';
import 'services/yelp_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initFirebase();
  final userService = UserService();
  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => AuthService()),
        Provider<UserService>.value(value: userService),
        Provider(create: (_) => YelpService()),
        Provider(create: (_) => LocationService()),
        Provider(create: (_) => GroupService()),
        Provider(
            create: (_) => NotificationService(userService: userService)),
      ],
      child: const LetsEatApp(),
    ),
  );
}

Future<void> _initFirebase() async {
  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
  } on UnsupportedError {
    // No Dart-defined options for this platform (e.g. iOS). iOS reads its
    // configuration natively from the bundled GoogleService-Info.plist, so
    // initialize without explicit options. Run `flutterfire configure` to
    // add Dart options once the iOS app is registered in Firebase.
    await Firebase.initializeApp();
  }
}
