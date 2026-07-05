import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/location_service.dart';
import 'services/user_service.dart';
import 'services/yelp_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => AuthService()),
        Provider(create: (_) => UserService()),
        Provider(create: (_) => YelpService()),
        Provider(create: (_) => LocationService()),
      ],
      child: const LetsEatApp(),
    ),
  );
}
