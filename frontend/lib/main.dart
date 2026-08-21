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
    final baseTextTheme = GoogleFonts.interTextTheme();
    final headingTextTheme = GoogleFonts.poppinsTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6366F1),
        brightness: Brightness.dark,
        surface: const Color(0xFF0D0D1A),
        primary: const Color(0xFF6366F1),
        secondary: const Color(0xFF06B6D4),
        error: const Color(0xFFEF4444),
        onSurface: const Color(0xFFF8FAFC),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFF07070F),
      textTheme: baseTextTheme.copyWith(
        displayLarge: headingTextTheme.displayLarge?.copyWith(
          color: const Color(0xFFF8FAFC),
          fontWeight: FontWeight.w700,
        ),
        displayMedium: headingTextTheme.displayMedium?.copyWith(
          color: const Color(0xFFF8FAFC),
          fontWeight: FontWeight.w700,
        ),
        headlineLarge: headingTextTheme.headlineLarge?.copyWith(
          color: const Color(0xFFF8FAFC),
          fontWeight: FontWeight.w700,
        ),
        headlineMedium: headingTextTheme.headlineMedium?.copyWith(
          color: const Color(0xFFF8FAFC),
          fontWeight: FontWeight.w600,
        ),
        titleLarge: headingTextTheme.titleLarge?.copyWith(
          color: const Color(0xFFF8FAFC),
          fontWeight: FontWeight.w600,
        ),
        titleMedium: headingTextTheme.titleMedium?.copyWith(
          color: const Color(0xFFF8FAFC),
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: const Color(0xFFF8FAFC),
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: const Color(0xFF94A3B8),
        ),
        bodySmall: baseTextTheme.bodySmall?.copyWith(
          color: const Color(0xFF94A3B8),
        ),
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF0D0D1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF1E1E3A)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF07070F),
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFFF8FAFC),
        ),
        iconTheme: IconThemeData(color: Color(0xFFF8FAFC)),
      ),
    );
  }
}