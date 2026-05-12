import 'package:flutter/material.dart';

/// MentorChatBubble — renders AI mentor feedback messages.
/// Appears with a subtle fade+slide-in animation.
class MentorChatBubble extends StatefulWidget {
  final String message;
  final bool isCorrect;
  final String? mentorName;
  final bool animate;

  const MentorChatBubble({
    super.key,
    required this.message,
    required this.isCorrect,
    this.mentorName = 'AI Mentor',
    this.animate = true,
  });

  @override
  State<MentorChatBubble> createState() => _MentorChatBubbleState();
}

class _MentorChatBubbleState extends State<MentorChatBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    if (widget.animate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final reducedMotion = MediaQuery.of(context).disableAnimations;
          if (reducedMotion) {
            _controller.value = 1;
          } else {
            _controller.forward();
          }
        }
      });
    } else {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.isCorrect
        ? const Color(0xFF16A34A)
        : const Color(0xFF0EA5E9);

    final bgColor = widget.isCorrect
        ? const Color(0xFFF0FDF4)
        : const Color(0xFFF0F9FF);

    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: Semantics(
          label: 'Mentor says: ${widget.message}',
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: accentColor.withOpacity(0.25),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mentor avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accentColor, accentColor.withOpacity(0.7)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.psychology_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            widget.mentorName ?? 'AI Mentor',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: accentColor,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            widget.isCorrect
                                ? Icons.check_circle_rounded
                                : Icons.info_rounded,
                            size: 14,
                            color: accentColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.message,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF0F172A),
                          height: 1.5,
                        ),
                      ),
                    ],
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