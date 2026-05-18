import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../../../core/theme/app_colors.dart';

class LevelUpModal extends StatefulWidget {
  final int level;
  final VoidCallback onDismiss;

  const LevelUpModal({
    super.key,
    required this.level,
    required this.onDismiss,
  });

  @override
  State<LevelUpModal> createState() => _LevelUpModalState();
}

class _LevelUpModalState extends State<LevelUpModal>
    with TickerProviderStateMixin {
  late AnimationController _burstController;
  late AnimationController _cardController;
  late AnimationController _ringController;

  late Animation<double> _overlayFade;
  late Animation<double> _cardScale;
  late Animation<double> _cardFade;
  late Animation<double> _ring1Scale;
  late Animation<double> _ring1Opacity;
  late Animation<double> _ring2Scale;
  late Animation<double> _ring2Opacity;

  @override
  void initState() {
    super.initState();

    _burstController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _overlayFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _burstController, curve: const Interval(0.0, 0.4, curve: Curves.easeOut)),
    );

    _cardScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeOutBack),
    );
    _cardFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeOut),
    );

    _ring1Scale = Tween<double>(begin: 0.6, end: 2.2).animate(
      CurvedAnimation(parent: _ringController, curve: Curves.easeOut),
    );
    _ring1Opacity = Tween<double>(begin: 0.5, end: 0.0).animate(
      CurvedAnimation(parent: _ringController, curve: Curves.easeIn),
    );
    _ring2Scale = Tween<double>(begin: 0.6, end: 2.2).animate(
      CurvedAnimation(
        parent: _ringController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );
    _ring2Opacity = Tween<double>(begin: 0.5, end: 0.0).animate(
      CurvedAnimation(
        parent: _ringController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.of(context).disableAnimations) {
        _burstController.value = 1.0;
        _cardController.value = 1.0;
        return;
      }
      _burstController.forward().then((_) {
        if (!mounted) return;
        _ringController.repeat();
        _cardController.forward();
      });
    });
  }

  @override
  void dispose() {
    _burstController.dispose();
    _cardController.dispose();
    _ringController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Dark overlay — fades in with burst
          AnimatedBuilder(
            animation: _overlayFade,
            builder: (context, _) => Opacity(
              opacity: _overlayFade.value,
              child: Container(
                width: size.width,
                height: size.height,
                color: Colors.black.withValues(alpha: 0.88),
              ),
            ),
          ),
          // Lottie confetti — full-screen, non-interactive
          Positioned.fill(
            child: IgnorePointer(
              child: Lottie.asset(
                'assets/animations/confetti.json',
                fit: BoxFit.cover,
                repeat: false,
              ),
            ),
          ),
            // Pulsing rings behind card
            Center(
              child: AnimatedBuilder(
                animation: _ringController,
                builder: (context, _) => Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform.scale(
                      scale: _ring1Scale.value,
                      child: Opacity(
                        opacity: _ring1Opacity.value,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Transform.scale(
                      scale: _ring2Scale.value,
                      child: Opacity(
                        opacity: _ring2Opacity.value,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.cyan,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Card
            Center(
              child: AnimatedBuilder(
                animation: _cardController,
                builder: (context, child) => Transform.scale(
                  scale: _cardScale.value,
                  child: Opacity(opacity: _cardFade.value, child: child),
                ),
                child: _buildCard(),
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildCard() {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 48,
            spreadRadius: 4,
          ),
          BoxShadow(
            color: AppColors.cyan.withValues(alpha: 0.15),
            blurRadius: 80,
            spreadRadius: 8,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LevelBurst(level: widget.level),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.xpGold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.xpGold.withValues(alpha: 0.3),
              ),
            ),
            child: const Text(
              'LEVEL UP!',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.xpGold,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [AppColors.primary, AppColors.cyan],
            ).createShader(bounds),
            child: Text(
              'Level ${widget.level}',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 52,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'You reached Level ${widget.level}!',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onDismiss,
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.cyan],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGlow(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'Continue',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelBurst extends StatelessWidget {
  final int level;
  const _LevelBurst({required this.level});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 108,
          height: 108,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withValues(alpha: 0.08),
          ),
        ),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withValues(alpha: 0.14),
          ),
        ),
        Container(
          width: 60,
          height: 60,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.cyan],
            ),
          ),
          child: Center(
            child: Text(
              '$level',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
