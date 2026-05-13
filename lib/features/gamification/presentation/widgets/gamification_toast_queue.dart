import 'package:flutter/material.dart';
import '../../domain/gamification_overlay_state.dart';

class GamificationToastQueue extends StatelessWidget {
  final List<GamificationToastData> toasts;
  final VoidCallback onAdvance;

  const GamificationToastQueue({
    super.key,
    required this.toasts,
    required this.onAdvance,
  });

  @override
  Widget build(BuildContext context) {
    if (toasts.isEmpty) return const SizedBox.shrink();

    return Positioned(
      bottom: 40,
      left: 20,
      right: 20,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0),
            end: Offset.zero,
          ).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        ),
        child: _GamificationToast(
          key: ValueKey(toasts.first.id + toasts.length.toString()),
          toast: toasts.first,
          onDismiss: onAdvance,
        ),
      ),
    );
  }
}

class _GamificationToast extends StatefulWidget {
  final GamificationToastData toast;
  final VoidCallback onDismiss;

  const _GamificationToast({
    super.key,
    required this.toast,
    required this.onDismiss,
  });

  @override
  State<_GamificationToast> createState() => _GamificationToastState();
}

class _GamificationToastState extends State<_GamificationToast> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${widget.toast.title}: ${widget.toast.message}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: widget.toast.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                widget.toast.icon,
                color: widget.toast.color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.toast.title,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: widget.toast.color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.toast.message,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: widget.onDismiss,
              child: const Icon(Icons.close_rounded,
                  color: Color(0xFF475569), size: 16),
            ),
          ],
        ),
      ),
    );
  }
}