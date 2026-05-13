import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'features/onboarding/application/onboarding_notifier.dart';
import 'features/onboarding/presentation/onboarding_navigator.dart';
import 'features/gamification/presentation/gamification_overlay_manager.dart';
import 'features/ai_mentor/presentation/ai_mentor_overlay_wrapper.dart';
import 'core/routing/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Check persisted flag before rendering — onboarding never replays after completion.
  final onboardingDone = await loadOnboardingCompleted();

  runApp(
    ProviderScope(
      child: FinQuestApp(skipOnboarding: onboardingDone),
    ),
  );
}

class FinQuestApp extends StatelessWidget {
  final bool skipOnboarding;

  const FinQuestApp({super.key, this.skipOnboarding = false});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FinQuest AI',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      initialRoute: skipOnboarding ? AppRouter.dashboard : null,
      home: skipOnboarding ? null : const OnboardingNavigator(),
      onGenerateRoute: AppRouter.generateRoute,
      builder: (context, child) => GamificationOverlayManager(
        child: AiMentorOverlayWrapper(
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }

  ThemeData _buildTheme() {
    // Base text theme using Google Fonts
    final baseTextTheme = GoogleFonts.interTextTheme();
    final headingTextTheme = GoogleFonts.poppinsTextTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2563EB),
        brightness: Brightness.light,
        surface: const Color(0xFFFFFFFF),
        primary: const Color(0xFF2563EB),
        secondary: const Color(0xFF0EA5E9),
        error: const Color(0xFFDC2626),
        onSurface: const Color(0xFF0F172A),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      textTheme: baseTextTheme.copyWith(
        displayLarge: headingTextTheme.displayLarge?.copyWith(
          color: const Color(0xFF0F172A),
          fontWeight: FontWeight.w700,
        ),
        displayMedium: headingTextTheme.displayMedium?.copyWith(
          color: const Color(0xFF0F172A),
          fontWeight: FontWeight.w700,
        ),
        headlineLarge: headingTextTheme.headlineLarge?.copyWith(
          color: const Color(0xFF0F172A),
          fontWeight: FontWeight.w700,
        ),
        headlineMedium: headingTextTheme.headlineMedium?.copyWith(
          color: const Color(0xFF0F172A),
          fontWeight: FontWeight.w600,
        ),
        titleLarge: headingTextTheme.titleLarge?.copyWith(
          color: const Color(0xFF0F172A),
          fontWeight: FontWeight.w600,
        ),
        titleMedium: headingTextTheme.titleMedium?.copyWith(
          color: const Color(0xFF0F172A),
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: const Color(0xFF0F172A),
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: const Color(0xFF64748B),
        ),
        bodySmall: baseTextTheme.bodySmall?.copyWith(
          color: const Color(0xFF64748B),
        ),
      ),
      // Remove ink splash effects for custom press animations
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      // Card theme
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFFFFFFFF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      // AppBar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF8FAFC),
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF0F172A),
        ),
        iconTheme: IconThemeData(color: Color(0xFF0F172A)),
      ),
    );
  }
}