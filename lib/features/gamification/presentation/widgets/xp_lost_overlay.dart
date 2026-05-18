import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class XpLostOverlay extends StatefulWidget {
  final int amount;
  final VoidCallback onDismiss;

  const XpLostOverlay({
    super.key,
    required this.amount,
    required this.onDismiss,
  });

  @override
  State<XpLostOverlay> createState() => _XpLostOverlayState();
}

class _XpLostOverlayState extends State<XpLostOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideIn;
  late Animation<double> _opacity;
  late Animation<double> _shake;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideIn = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.3, curve: Curves.easeOut),
      ),
    );
    // Shake: oscillate between -8 and +8 px, 3 cycles in the mid section
    _shake = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0, end: -8), weight: 10),
      TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 8, end: -8), weight: 10),
      TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 8, end: 0), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 0, end: 0), weight: 20),
    ]).animate(_controller);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.of(context).disableAnimations) {
        _controller.value = 1.0;
      } else {
        _controller.forward();
      }
      Future.delayed(const Duration(milliseconds: 1500), () {
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
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 20,
      right: 20,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => SlideTransition(
          position: _slideIn,
          child: FadeTransition(
            opacity: _opacity,
            child: Transform.translate(
              offset: Offset(_shake.value, 0),
              child: child,
            ),
          ),
        ),
        child: Semantics(
          label: '-${widget.amount} XP lost',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.error.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.trending_down_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  '-${widget.amount} XP',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
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