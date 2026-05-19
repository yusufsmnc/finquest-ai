import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

// Reusable aurora background: deep navy radial gradient + 3 drifting color blobs.
// Designed to be placed as the bottom layer of a Stack with Positioned.fill.
class AuroraBackground extends StatefulWidget {
  const AuroraBackground({super.key});

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with TickerProviderStateMixin {
  late AnimationController _blob1Controller;
  late AnimationController _blob2Controller;
  late AnimationController _blob3Controller;

  late Animation<double> _b1Top;
  late Animation<double> _b1Left;
  late Animation<double> _b1Opacity;

  late Animation<double> _b2Bottom;
  late Animation<double> _b2Left;
  late Animation<double> _b2Opacity;

  late Animation<double> _b3Top;
  late Animation<double> _b3Right;
  late Animation<double> _b3Opacity;

  @override
  void initState() {
    super.initState();

    _blob1Controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat(reverse: true);

    _blob2Controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 13),
    )..repeat(reverse: true);

    _blob3Controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 17),
    )..repeat(reverse: true);

    final c1 = CurvedAnimation(parent: _blob1Controller, curve: Curves.easeInOut);
    final c2 = CurvedAnimation(parent: _blob2Controller, curve: Curves.easeInOut);
    final c3 = CurvedAnimation(parent: _blob3Controller, curve: Curves.easeInOut);

    _b1Top     = Tween<double>(begin: -40,  end:   0).animate(c1);
    _b1Left    = Tween<double>(begin: -60,  end:  40).animate(c1);
    _b1Opacity = Tween<double>(begin: 0.30, end: 0.50).animate(c1);

    _b2Bottom  = Tween<double>(begin: -40,  end:   0).animate(c2);
    _b2Left    = Tween<double>(begin:  30,  end:  90).animate(c2);
    _b2Opacity = Tween<double>(begin: 0.25, end: 0.40).animate(c2);

    _b3Top     = Tween<double>(begin: 100,  end: 180).animate(c3);
    _b3Right   = Tween<double>(begin: -40,  end:  20).animate(c3);
    _b3Opacity = Tween<double>(begin: 0.20, end: 0.35).animate(c3);
  }

  @override
  void dispose() {
    _blob1Controller.dispose();
    _blob2Controller.dispose();
    _blob3Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.4),
                radius: 1.4,
                colors: [
                  AppColors.navyBlue,
                  AppColors.backgroundBlue,
                  AppColors.background,
                ],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
          ),
        ),
        AnimatedBuilder(
          animation: Listenable.merge(
              [_blob1Controller, _blob2Controller, _blob3Controller]),
          builder: (context, _) => Stack(
            children: [
              Positioned(
                top: _b1Top.value,
                left: _b1Left.value,
                child: _AuroraBlob(
                  size: 420,
                  color: AppColors.primary,
                  opacity: _b1Opacity.value,
                ),
              ),
              Positioned(
                bottom: _b2Bottom.value,
                left: _b2Left.value,
                child: _AuroraBlob(
                  size: 360,
                  color: AppColors.purple,
                  opacity: _b2Opacity.value,
                ),
              ),
              Positioned(
                top: _b3Top.value,
                right: _b3Right.value,
                child: _AuroraBlob(
                  size: 300,
                  color: AppColors.indigoDark,
                  opacity: _b3Opacity.value,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AuroraBlob extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const _AuroraBlob({
    required this.size,
    required this.color,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: opacity),
              color.withValues(alpha: opacity * 0.4),
              Colors.transparent,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }
}