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
    const primary = Color(0xFF00E5FF);
    const secondary = Color(0xFF7CFF6B);
    const surface = Color(0xFF0F1720);
    const background = Color(0xFF05070B);
    const onSurface = Color(0xFFE6F1FF);
    const onBackground = Color(0xFFD9E4FF);
    final colorScheme = const ColorScheme.dark(
      primary: primary,
      secondary: secondary,
      surface: surface,
      background: background,
      onSurface: onSurface,
      onBackground: onBackground,
      error: Color(0xFFFF6B6B),
    );
    final baseTextTheme = ThemeData.dark().textTheme.apply(
          fontFamily: 'RobotoMono',
          bodyColor: onBackground,
          displayColor: onBackground,
        );
    return MaterialApp(
      title: 'hiraku',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        textTheme: baseTextTheme.copyWith(
          headlineMedium: baseTextTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
          titleLarge: baseTextTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        scaffoldBackgroundColor: background,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: onSurface,
          centerTitle: false,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: surface.withOpacity(0.9),
          indicatorColor: primary.withOpacity(0.2),
          labelTextStyle: WidgetStateProperty.all(
            baseTextTheme.labelSmall?.copyWith(
              color: onSurface,
              letterSpacing: 0.6,
            ),
          ),
          iconTheme: WidgetStateProperty.resolveWith(
            (states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? primary
                  : onSurface.withOpacity(0.7),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surface.withOpacity(0.7),
          labelStyle: TextStyle(color: onSurface.withOpacity(0.8)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: primary.withOpacity(0.5)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: primary.withOpacity(0.35)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: primary, width: 1.4),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: const Color(0xFF001014),
            textStyle: baseTextTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: onSurface.withOpacity(0.85),
            textStyle: baseTextTheme.labelLarge?.copyWith(
              letterSpacing: 0.6,
            ),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: surface,
          contentTextStyle: baseTextTheme.bodyMedium?.copyWith(
            color: onSurface,
          ),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: primary,
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
