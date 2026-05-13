import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// AnimatedButton — provides press-scale feedback on every tap.
/// Scale: 1.0 → 0.97 → 1.0 (80ms press + 80ms release).
/// Respects MediaQuery.disableAnimations for reduced motion.
class AnimatedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String semanticLabel;
  final EdgeInsetsGeometry padding;
  final BoxDecoration? decoration;
  final double minHeight;

  const AnimatedButton({
    super.key,
    required this.child,
    required this.semanticLabel,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    this.decoration,
    this.minHeight = 52,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 80),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (widget.onTap == null) return;
    HapticFeedback.lightImpact();
    final reducedMotion = MediaQuery.of(context).disableAnimations;
    if (!reducedMotion) {
      await _controller.forward();
      await _controller.reverse();
    }
    widget.onTap!();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticLabel,
      button: true,
      enabled: widget.onTap != null,
      child: GestureDetector(
        onTap: _handleTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _scale,
          builder: (context, child) => Transform.scale(
            scale: _scale.value,
            child: child,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: widget.minHeight),
            child: Container(
              padding: widget.padding,
              decoration: widget.decoration ??
                  BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(14),
                  ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

/// PrimaryButton — standard full-width CTA button.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedButton(
      semanticLabel: label,
      onTap: isLoading ? null : onTap,
      decoration: BoxDecoration(
        color: onTap == null
            ? const Color(0xFF2563EB).withValues(alpha: 0.5)
            : const Color(0xFF2563EB),
        borderRadius: BorderRadius.circular(14),
        boxShadow: onTap == null
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Center(
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
      ),
    );
  }
}

/// SecondaryButton — outlined variant.
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const SecondaryButton({
    super.key,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedButton(
      semanticLabel: label,
      onTap: onTap,
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: const Color(0xFF2563EB), width: 1.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2563EB),
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}