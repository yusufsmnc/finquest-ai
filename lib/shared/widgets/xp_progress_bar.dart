import 'package:flutter/material.dart';

/// XPProgressBar — animates XP fill in response to XP_GAINED events.
/// Fill animation: 600ms easeOutCubic.
/// Respects MediaQuery.disableAnimations.
class XPProgressBar extends StatefulWidget {
  final double progress; // 0.0 to 1.0
  final int currentXP;
  final int maxXP;
  final double height;
  final bool showLabel;

  const XPProgressBar({
    super.key,
    required this.progress,
    required this.currentXP,
    required this.maxXP,
    this.height = 10,
    this.showLabel = true,
  });

  @override
  State<XPProgressBar> createState() => _XPProgressBarState();
}

class _XPProgressBarState extends State<XPProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  double _previousProgress = 0;

  @override
  void initState() {
    super.initState();
    _previousProgress = widget.progress;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _progressAnimation = Tween<double>(
      begin: widget.progress,
      end: widget.progress,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void didUpdateWidget(XPProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      final reducedMotion = MediaQuery.of(context).disableAnimations;
      if (reducedMotion) {
        setState(() {
          _previousProgress = widget.progress;
        });
        return;
      }
      _progressAnimation = Tween<double>(
        begin: _previousProgress,
        end: widget.progress,
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller.forward(from: 0);
      _previousProgress = widget.progress;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showLabel) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'XP',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFF59E0B),
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                '${widget.currentXP} / ${widget.maxXP}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],
        Semantics(
          label: 'XP progress: ${widget.currentXP} of ${widget.maxXP}',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.height / 2),
            child: AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, _) {
                return Stack(
                  children: [
                    // Track
                    Container(
                      height: widget.height,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius:
                            BorderRadius.circular(widget.height / 2),
                      ),
                    ),
                    // Fill
                    FractionallySizedBox(
                      widthFactor:
                          _progressAnimation.value.clamp(0.0, 1.0),
                      child: Container(
                        height: widget.height,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFF59E0B),
                              Color(0xFFFFBB3B),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(
                              widget.height / 2),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  const Color(0xFFF59E0B).withValues(alpha: 0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}