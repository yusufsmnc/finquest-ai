import 'package:flutter/material.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/scenarios/presentation/scenario_flow.dart';

class AppRoutes {
  static const String onboarding = '/onboarding';
  static const String dashboard = '/dashboard';
  static const String scenarios = '/scenarios';

  AppRoutes._();
}

class AppRouter {
  static const String dashboard = AppRoutes.dashboard;

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.onboarding:
        return _buildRoute(
          settings: settings,
          // The OnboardingNavigator is the entry point for onboarding.
          // We use a placeholder here — the actual widget is wired in main.dart.
          builder: (_) => const _OnboardingPlaceholder(),
        );
      case AppRoutes.dashboard:
        return _buildRoute(
          settings: settings,
          builder: (_) => const DashboardScreen(),
        );
      case AppRoutes.scenarios:
        return _buildRoute(
          settings: settings,
          builder: (_) => const ScenarioFlow(),
        );
      default:
        return _buildRoute(
          settings: settings,
          builder: (_) => const _NotFoundScreen(),
        );
    }
  }

  static PageRouteBuilder<T> _buildRoute<T>({
    required RouteSettings settings,
    required WidgetBuilder builder,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (context, animation, secondaryAnimation) {
        return builder(context);
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final reducedMotion = MediaQuery.of(context).disableAnimations;
        if (reducedMotion) return child;

        final curve = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curve,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.04), // 40px normalized slide up
              end: Offset.zero,
            ).animate(curve),
            child: child,
          ),
        );
      },
    );
  }
}

// Placeholders — real screens are registered via the feature's own navigator.
class _OnboardingPlaceholder extends StatelessWidget {
  const _OnboardingPlaceholder();

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}


class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: Text(
          '404 — Route not found',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: const Color(0xFF64748B),
              ),
        ),
      ),
    );
  }
}