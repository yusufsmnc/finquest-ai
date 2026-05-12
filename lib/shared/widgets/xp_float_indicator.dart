import 'package:flutter/material.dart';

/// XPFloatIndicator — floats up 40px over 600ms when XP_GAINED fires.
/// Triggered by calling show() on the key.
class XPFloatIndicator extends StatefulWidget {
  final int amount;
  final bool visible;

  const XPFloatIndicator({
    super.key,
    required this.amount,
    this.visible = false,
  });

  @override
  State<XPFloatIndicator> createState() => XPFloatIndicatorState();
}

class XPFloatIndicatorState extends State<XPFloatIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _offsetY;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _offsetY = Tween<double>(begin: 0, end: -40).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    // Spec: FadeIn 0→1 (first 200ms of 600ms), hold, FadeOut 1→0 (last 200ms of 600ms)
    // 200/600 ≈ 33 weight each
    _opacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: 1),
        weight: 33,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1, end: 1),
        weight: 34,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1, end: 0),
        weight: 33,
      ),
    ]).animate(_controller);

    if (widget.visible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _playAnimation();
      });
    }
  }

  @override
  void didUpdateWidget(XPFloatIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.visible && widget.visible) {
      _playAnimation();
    }
  }

  void _playAnimation() {
    final reducedMotion = MediaQuery.of(context).disableAnimations;
    if (reducedMotion) return;
    _controller.forward(from: 0);
  }

  void show() {
    _playAnimation();
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
      builder: (context, _) {
        return Transform.translate(
          offset: Offset(0, _offsetY.value),
          child: Opacity(
            opacity: _opacity.value.clamp(0.0, 1.0),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withOpacity(0.5),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bolt_rounded,
                      color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '+${widget.amount} XP',
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
          ),
        );
      },
    );
  }
}

/// XPFloatOverlay — positions the float indicator at the center of the screen.
class XPFloatOverlay extends StatelessWidget {
  final int xpAmount;
  final bool visible;

  const XPFloatOverlay({
    super.key,
    required this.xpAmount,
    required this.visible,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    return Positioned(
      left: 0,
      right: 0,
      top: MediaQuery.of(context).size.height * 0.4,
      child: Center(
        child: XPFloatIndicator(
          amount: xpAmount,
          visible: visible,
        ),
      ),
    );
  }
}