import 'package:flutter/material.dart';

class StreakFeedbackOverlay extends StatefulWidget {
  final int streak;
  final VoidCallback onDismiss;

  const StreakFeedbackOverlay({
    super.key,
    required this.streak,
    required this.onDismiss,
  });

  @override
  State<StreakFeedbackOverlay> createState() => _StreakFeedbackOverlayState();
}

class _StreakFeedbackOverlayState extends State<StreakFeedbackOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    // Bounce: overshoot to 1.15 then settle at 1.0
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.3, end: 1.15)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.15, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 40,
      ),
    ]).animate(_controller);
    _fade = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 1.0), weight: 30),
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 1.0), weight: 50),
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_controller);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.of(context).disableAnimations) {
        _controller.value = 1.0;
        widget.onDismiss();
        return;
      }
      _controller.forward().then((_) {
        if (mounted) widget.onDismiss();
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => FadeTransition(
            opacity: _fade,
            child: Transform.scale(scale: _scale.value, child: child),
          ),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 36)),
                const SizedBox(height: 6),
                Text(
                  '${widget.streak} Day Streak!',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFD97706),
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'You\'re on fire — keep going!',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: Color(0xFFF59E0B),
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