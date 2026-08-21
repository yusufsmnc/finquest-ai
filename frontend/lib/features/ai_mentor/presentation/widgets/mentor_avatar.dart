import 'package:flutter/material.dart';
import '../../domain/mentor_message.dart';

class MentorAvatar extends StatefulWidget {
  final MentorMood mood;
  final double size;
  final bool animate;

  const MentorAvatar({
    super.key,
    required this.mood,
    this.size = 64,
    this.animate = true,
  });

  @override
  State<MentorAvatar> createState() => _MentorAvatarState();
}

class _MentorAvatarState extends State<MentorAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _pulse = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (widget.animate) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(MentorAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mood != widget.mood) {
      _pulseController.reset();
      if (widget.animate) _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gradients = widget.mood.gradient;
    final iconSize = widget.size * 0.44;

    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, child) => Transform.scale(
        scale: _pulse.value,
        child: child,
      ),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: gradients,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: gradients.first.withValues(alpha: 0.35),
              blurRadius: widget.size * 0.25,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(widget.mood.icon, color: Colors.white, size: iconSize),
      ),
    );
  }
}

class MentorMoodChip extends StatelessWidget {
  final MentorMood mood;

  const MentorMoodChip({super.key, required this.mood});

  @override
  Widget build(BuildContext context) {
    final color = mood.gradient.first;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(mood),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              mood.label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}