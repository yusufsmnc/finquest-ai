import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../onboarding_providers.dart';
import '../../data/onboarding_constants.dart';
import '../../application/onboarding_animation_handler.dart';
import '../widgets/onboarding_progress_dots.dart';
import '../../../../core/theme/app_colors.dart';

/// S3 — Decision Screen.
/// Shows the tutorial scenario (CR-001) and the two decision options.
class OnboardingDecisionScreen extends ConsumerStatefulWidget {
  const OnboardingDecisionScreen({super.key});

  @override
  ConsumerState<OnboardingDecisionScreen> createState() =>
      _OnboardingDecisionScreenState();
}

class _OnboardingDecisionScreenState
    extends ConsumerState<OnboardingDecisionScreen>
    with TickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnim;
  late AnimationController _correctController;
  late Animation<double> _correctScale;
  late AnimationController _redFlashController;
  late Animation<double> _redFlash;

  String? _tappedOptionId;

  @override
  void initState() {
    super.initState();
    _shakeController = OnboardingAnimationHandler.createShakeController(this);
    _shakeAnim = OnboardingAnimationHandler.buildShakeAnimation(_shakeController);

    _correctController = OnboardingAnimationHandler.createCorrectController(this);
    _correctScale = OnboardingAnimationHandler.buildCorrectScaleAnimation(_correctController);

    _redFlashController = OnboardingAnimationHandler.createRedFlashController(this);
    _redFlash = OnboardingAnimationHandler.buildRedFlashAnimation(_redFlashController);
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _correctController.dispose();
    _redFlashController.dispose();
    super.dispose();
  }

  Future<void> _onOptionTapped(String optionId) async {
    if (ref.read(onboardingNotifierProvider).decisionMade) return;

    setState(() => _tappedOptionId = optionId);
    final isCorrect = optionId == OnboardingConstants.optionAId;

    if (isCorrect) {
      await OnboardingAnimationHandler.playCorrect(context, _correctController);
    } else {
      OnboardingAnimationHandler.playRedFlash(context, _redFlashController);
      await OnboardingAnimationHandler.playShake(context, _shakeController);
    }

    if (!mounted) return;
    ref.read(onboardingDispatcherProvider).onDecisionMade(optionId);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingNotifierProvider);

    return PopScope(
      canPop: false,
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: AppColors.background,
            body: SafeArea(
              child: AnimatedBuilder(
                animation: _shakeAnim,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(_shakeAnim.value, 0),
                    child: child,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      const OnboardingProgressDots(currentStep: 3),
                      const SizedBox(height: 24),
                      _ScenarioCard(
                        isCorrectSelected: state.isCorrect,
                        tappedOptionId: _tappedOptionId,
                        correctScale: _correctScale,
                      ),
                      const SizedBox(height: 24),
                      _OptionButton(
                        optionId: OnboardingConstants.optionAId,
                        label: OnboardingConstants.optionAText,
                        isSelected: _tappedOptionId == OnboardingConstants.optionAId,
                        isDisabled: state.decisionMade,
                        isCorrect: true,
                        onTap: state.decisionMade
                            ? null
                            : () => _onOptionTapped(OnboardingConstants.optionAId),
                      ),
                      const SizedBox(height: 12),
                      _OptionButton(
                        optionId: OnboardingConstants.optionBId,
                        label: OnboardingConstants.optionBText,
                        isSelected: _tappedOptionId == OnboardingConstants.optionBId,
                        isDisabled: state.decisionMade,
                        isCorrect: false,
                        onTap: state.decisionMade
                            ? null
                            : () => _onOptionTapped(OnboardingConstants.optionBId),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.15)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.lightbulb_outline_rounded,
                                size: 14, color: AppColors.primary),
                            SizedBox(width: 6),
                            Text(
                              'There are no wrong answers — only learning opportunities',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Red flash overlay
          AnimatedBuilder(
            animation: _redFlash,
            builder: (context, _) {
              return Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: AppColors.error
                        .withValues(alpha: _redFlash.value.clamp(0.0, 1.0)),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ScenarioCard extends StatelessWidget {
  final bool? isCorrectSelected;
  final String? tappedOptionId;
  final Animation<double> correctScale;

  const _ScenarioCard({
    this.isCorrectSelected,
    this.tappedOptionId,
    required this.correctScale,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: correctScale,
      builder: (context, child) {
        return Transform.scale(
          scale: isCorrectSelected == true ? correctScale.value : 1.0,
          child: child,
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.xpGold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.xpGold.withValues(alpha: 0.2)),
                  ),
                  child: const Text(
                    '⚡ Tutorial',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.xpGold,
                    ),
                  ),
                ),
                const Spacer(),
                _RiskBadge(level: OnboardingConstants.riskLevel),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              OnboardingConstants.scenarioTitle,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              OnboardingConstants.scenarioDescription,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RiskBadge extends StatelessWidget {
  final String level;

  const _RiskBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    final Color color;
    switch (level.toLowerCase()) {
      case 'low':
        color = AppColors.success;
        break;
      case 'high':
        color = AppColors.error;
        break;
      default:
        color = AppColors.xpGold;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.speed_rounded, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            '$level Risk',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionButton extends StatefulWidget {
  final String optionId;
  final String label;
  final bool isSelected;
  final bool isDisabled;
  final bool isCorrect;
  final VoidCallback? onTap;

  const _OptionButton({
    required this.optionId,
    required this.label,
    required this.isSelected,
    required this.isDisabled,
    required this.isCorrect,
    this.onTap,
  });

  @override
  State<_OptionButton> createState() => _OptionButtonState();
}

class _OptionButtonState extends State<_OptionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _pressScale;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 80),
    );
    _pressScale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  Color get _borderColor {
    if (!widget.isSelected) return AppColors.border;
    return widget.isCorrect ? AppColors.success : AppColors.error;
  }

  Color get _bgColor {
    if (!widget.isSelected) return AppColors.surface;
    return widget.isCorrect
        ? AppColors.success.withValues(alpha: 0.08)
        : AppColors.error.withValues(alpha: 0.08);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Option ${widget.optionId}: ${widget.label}',
      button: true,
      enabled: !widget.isDisabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: widget.isDisabled ? null : (_) => _pressController.forward(),
        onTapUp: widget.isDisabled ? null : (_) => _pressController.reverse(),
        onTapCancel:
            widget.isDisabled ? null : () => _pressController.reverse(),
        onTap: widget.isDisabled ? null : widget.onTap,
        child: AnimatedBuilder(
          animation: _pressScale,
          builder: (context, child) {
            return Transform.scale(scale: _pressScale.value, child: child);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(18),
            constraints: const BoxConstraints(minHeight: 64),
            decoration: BoxDecoration(
              color: _bgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _borderColor,
                width: widget.isSelected ? 2 : 1.5,
              ),
              boxShadow: widget.isSelected
                  ? [
                      BoxShadow(
                        color: _borderColor.withValues(alpha: 0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.isSelected
                        ? (widget.isCorrect ? AppColors.success : AppColors.error)
                        : AppColors.surfaceHigh,
                  ),
                  child: Center(
                    child: widget.isSelected
                        ? Icon(
                            widget.isCorrect
                                ? Icons.check_rounded
                                : Icons.close_rounded,
                            color: Colors.white,
                            size: 16,
                          )
                        : Text(
                            widget.optionId,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: widget.isSelected
                          ? (widget.isCorrect ? AppColors.success : AppColors.error)
                          : AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}