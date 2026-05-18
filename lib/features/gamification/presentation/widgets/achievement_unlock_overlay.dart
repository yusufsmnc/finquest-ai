import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../../../core/theme/app_colors.dart';

class AchievementUnlockOverlay extends StatefulWidget {
  final String achievementName;
  final VoidCallback onDismiss;

  const AchievementUnlockOverlay({
    super.key,
    required this.achievementName,
    required this.onDismiss,
  });

  @override
  State<AchievementUnlockOverlay> createState() =>
      _AchievementUnlockOverlayState();
}

class _AchievementUnlockOverlayState extends State<AchievementUnlockOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideIn;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
      reverseDuration: const Duration(milliseconds: 300),
    );
    _slideIn = Tween<Offset>(
      begin: const Offset(0, 1.5),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _controller, curve: const Interval(0, 0.4)),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.of(context).disableAnimations) {
        _controller.value = 1.0;
      } else {
        _controller.forward();
      }
      Future.delayed(const Duration(milliseconds: 2500), _dismiss);
    });
  }

  void _dismiss() {
    if (!mounted) return;
    _controller.reverse().then((_) {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 40,
      left: 20,
      right: 20,
      child: SlideTransition(
        position: _slideIn,
        child: FadeTransition(
          opacity: _fade,
          child: Semantics(
            label: 'Achievement unlocked: ${widget.achievementName}',
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: Lottie.asset(
                      'assets/animations/trophy.json',
                      repeat: false,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Achievement Unlocked!',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.xpGold,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.achievementName,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _dismiss,
                    child: const Icon(Icons.close_rounded,
                        color: AppColors.textMuted, size: 18),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}