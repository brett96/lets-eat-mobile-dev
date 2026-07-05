import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'features/auth/login_screen.dart';
import 'features/home/home_screen.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';

class LetsEatApp extends StatelessWidget {
  const LetsEatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Let's Eat!",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: context.read<AuthService>().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final user = snapshot.data;
        if (user == null) return const LoginScreen();
        // Register for push notifications once we know who the user is.
        context.read<NotificationService>().registerForUser(user.uid);
        return const HomeScreen();
      },
    );
  }
}
