import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/main_shell.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/aurora_background.dart';
import '../../onboarding/presentation/onboarding_navigator.dart';
import '../auth_providers.dart';
import '../domain/auth_state.dart';
import 'login_screen.dart';

/// Root gate that decides what the app shows based on the auth session:
///
/// - first-run startup (validating a stored token) → splash
/// - unauthenticated (or auth error) → [LoginScreen]
/// - authenticated → the onboarding tutorial (first time) or the [MainShell]
class AuthGate extends ConsumerWidget {
  final bool onboardingDone;

  const AuthGate({super.key, required this.onboardingDone});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    // Only the very first token validation shows the splash (no value yet).
    if (auth.isLoading && !auth.hasValue) {
      return const _SplashScreen();
    }

    final AuthState? state = auth.valueOrNull;
    if (state == null || !state.isAuthenticated) {
      return const LoginScreen();
    }

    return onboardingDone ? const MainShell() : const OnboardingNavigator();
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(child: AuroraBackground()),
          Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}