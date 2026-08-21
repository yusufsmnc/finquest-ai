import 'package:flutter/material.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../core/theme/app_colors.dart';

class ScenarioXpSummary extends StatefulWidget {
  final int xpGained;
  final bool isCorrect;
  final int streak;

  const ScenarioXpSummary({
    super.key,
    required this.xpGained,
    required this.isCorrect,
    required this.streak,
  });

  @override
  State<ScenarioXpSummary> createState() => _ScenarioXpSummaryState();
}

class _ScenarioXpSummaryState extends State<ScenarioXpSummary>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final reduced = MediaQuery.of(context).disableAnimations;
        if (reduced) {
          _controller.value = 1;
        } else {
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted) _controller.forward();
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _streakMessage {
    if (widget.streak >= 5) return '🔥🔥 ${widget.streak} in a row — Unstoppable!';
    if (widget.streak >= 3) return '🔥 ${widget.streak} correct — Hot streak!';
    return '🔥 2 in a row — Keep it up!';
  }

  Color get _streakGlowColor {
    if (widget.streak >= 5) return AppColors.error;
    if (widget.streak >= 3) return AppColors.xpGold;
    return AppColors.xpGold;
  }

  @override
  Widget build(BuildContext context) {
    final showStreak = widget.isCorrect && widget.streak >= 2;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => FadeTransition(
        opacity: _fade,
        child: Transform.scale(scale: _scale.value, child: child),
      ),
      child: CardContainer(
        glowColor: showStreak ? _streakGlowColor : null,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'XP Earned',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                _XpChip(amount: widget.xpGained),
              ],
            ),
            if (widget.isCorrect) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.stars_rounded, color: AppColors.success, size: 14),
                    SizedBox(width: 6),
                    Text(
                      'Correct Decision Bonus +50 XP',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (showStreak) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _streakGlowColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: _streakGlowColor.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: _streakGlowColor.withValues(alpha: 0.15),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Text(
                  _streakMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _streakGlowColor,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _XpChip extends StatelessWidget {
  final int amount;
  const _XpChip({required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.xpGold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.xpGold.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt_rounded, color: AppColors.xpGold, size: 16),
          const SizedBox(width: 4),
          Text(
            '+$amount XP',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.xpGold,
            ),
          ),
        ],
      ),
    );
  }
}