import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// OnboardingProgressDots — shows which of the 5 steps is active.
class OnboardingProgressDots extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const OnboardingProgressDots({
    super.key,
    required this.currentStep,
    this.totalSteps = 5,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Step $currentStep of $totalSteps',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(totalSteps, (index) {
          final step = index + 1;
          final isActive = step == currentStep;
          final isCompleted = step < currentStep;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isActive ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: isCompleted || isActive
                  ? AppColors.primary
                  : AppColors.border,
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: AppColors.primaryGlow(0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
          );
        }),
      ),
    );
  }
}