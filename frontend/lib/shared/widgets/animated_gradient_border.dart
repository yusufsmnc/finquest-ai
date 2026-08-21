import 'dart:math' show pi;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

// Wraps its child with a continuously rotating sweep gradient border.
// Colors cycle through indigo â†’ cyan â†’ purple â†’ light indigo.
class AnimatedGradientBorder extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final double borderWidth;
  final Duration duration;

  const AnimatedGradientBorder({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.borderWidth = 2.5,
    this.duration = const Duration(seconds: 4),
  });

  @override
  State<AnimatedGradientBorder> createState() => _AnimatedGradientBorderState();
}

class _AnimatedGradientBorderState extends State<AnimatedGradientBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Stack(
        children: [
          child!,
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _GradientBorderPainter(
                  angle: _controller.value,
                  radius: widget.borderRadius,
                  borderWidth: widget.borderWidth,
                ),
              ),
            ),
          ),
        ],
      ),
      child: widget.child,
    );
  }
}

class _GradientBorderPainter extends CustomPainter {
  final double angle;
  final double radius;
  final double borderWidth;

  static const _colors = [
    AppColors.primary,
    AppColors.cyan,
    AppColors.purple,
    AppColors.primaryLight,
    AppColors.primary,
  ];

  const _GradientBorderPainter({
    required this.angle,
    required this.radius,
    required this.borderWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final inset = borderWidth / 2;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      size.width - inset * 2,
      size.height - inset * 2,
    );
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final startAngle = angle * 2 * pi;

    final glowPaint = Paint()
      ..shader = SweepGradient(
        colors: _colors,
        startAngle: startAngle,
        endAngle: startAngle + 2 * pi,
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth * 4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawRRect(rrect, glowPaint);

    final borderPaint = Paint()
      ..shader = SweepGradient(
        colors: _colors,
        startAngle: startAngle,
        endAngle: startAngle + 2 * pi,
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;
    canvas.drawRRect(rrect, borderPaint);
  }

  @override
  bool shouldRepaint(_GradientBorderPainter old) => old.angle != angle;
}

