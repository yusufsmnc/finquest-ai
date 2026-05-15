import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../onboarding_providers.dart';
import '../widgets/onboarding_progress_dots.dart';
import '../widgets/onboarding_mentor_intro.dart';
import '../../../../shared/widgets/animated_button.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../core/theme/app_colors.dart';

/// S1 — Welcome Screen.
/// Entry point of onboarding. Introduces the app and the AI mentor.
class OnboardingWelcomeScreen extends ConsumerWidget {
  const OnboardingWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dispatcher = ref.read(onboardingDispatcherProvider);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 24),
                const OnboardingProgressDots(currentStep: 1),
                const Spacer(),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: const [
                    _FeaturePill(icon: Icons.bolt_rounded, label: 'Earn XP'),
                    _FeaturePill(icon: Icons.emoji_events_rounded, label: 'Level Up'),
                    _FeaturePill(icon: Icons.psychology_rounded, label: 'AI Mentor'),
                  ],
                ),
                const SizedBox(height: 40),
                OnboardingMentorIntro(
                  headline: 'Welcome to\nFinQuest AI',
                  subtext:
                      'Learn to make smart financial decisions through '
                      'real-world scenarios — guided by your personal AI mentor.',
                ),
                const Spacer(),
                const _BenefitsRow(),
                const SizedBox(height: 32),
                PrimaryButton(
                  label: 'Get Started',
                  onTap: () => dispatcher.onWelcomeContinued(),
                ),
                const SizedBox(height: 16),
                Semantics(
                  label: 'Already have an account? Sign in',
                  child: GestureDetector(
                    onTap: () {},
                    child: const Text(
                      'Already have an account? Sign in',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeaturePill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _BenefitsRow extends StatelessWidget {
  const _BenefitsRow();

  @override
  Widget build(BuildContext context) {
    return CardContainer(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: const [
          _BenefitItem(value: '50+', label: 'Scenarios', icon: Icons.movie_filter_rounded),
          _Divider(),
          _BenefitItem(value: 'AI', label: 'Mentor', icon: Icons.psychology_rounded),
          _Divider(),
          _BenefitItem(value: '10K+', label: 'Learners', icon: Icons.people_rounded),
        ],
      ),
    );
  }
}

class _BenefitItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _BenefitItem({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      color: AppColors.border,
    );
  }
}