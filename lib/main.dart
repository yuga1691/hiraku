import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/onboarding_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const HirakuApp());
}

class HirakuApp extends StatelessWidget {
  const HirakuApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(seedColor: const Color(0xFF1B5E20));
    return MaterialApp(
      title: 'hiraku',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        appBarTheme: AppBarTheme(
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.onSurface,
        ),
      ),
      home: const RootGate(),
    );
  }
}

class RootGate extends StatefulWidget {
  const RootGate({super.key});

  @override
  State<RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<RootGate> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final OnboardingService _onboardingService = OnboardingService();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initialize(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('初期化に失敗しました: ${snapshot.error}'),
            ),
          );
        }
        return FutureBuilder<bool>(
          future: _onboardingService.isCompleted(),
          builder: (context, onboardingSnapshot) {
            if (onboardingSnapshot.connectionState != ConnectionState.done) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            final done = onboardingSnapshot.data ?? false;
            if (done) {
              return const HomeScreen();
            }
            return const OnboardingScreen();
          },
        );
      },
    );
  }

  Future<void> _initialize() async {
    final user = await _authService.ensureSignedIn();
    await _firestoreService.ensureUserDoc(user.uid);
  }
}
