import 'dart:math';
import 'package:flutter/material.dart';

class LevelUpModal extends StatefulWidget {
  final int level;
  final VoidCallback onDismiss;

  const LevelUpModal({
    super.key,
    required this.level,
    required this.onDismiss,
  });

  @override
  State<LevelUpModal> createState() => _LevelUpModalState();
}

class _LevelUpModalState extends State<LevelUpModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _cardScale;
  late Animation<double> _fade;
  late Animation<double> _confettiProgress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _cardScale = Tween<double>(begin: 0.72, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _confettiProgress = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.of(context).disableAnimations) {
        _controller.value = 1.0;
      } else {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Material(
      color: Colors.transparent,
      child: AnimatedBuilder(
        animation: _fade,
        builder: (context, child) => Opacity(opacity: _fade.value, child: child),
        child: Container(
          color: Colors.black.withValues(alpha: 0.78),
          width: size.width,
          height: size.height,
          child: Stack(
            children: [
              // Confetti dots
              ...List.generate(
                12,
                (i) => _ConfettiDot(
                  animation: _confettiProgress,
                  index: i,
                  screenSize: size,
                ),
              ),
              // Modal card
              Center(
                child: AnimatedBuilder(
                  animation: _cardScale,
                  builder: (context, child) =>
                      Transform.scale(scale: _cardScale.value, child: child),
                  child: _buildCard(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LevelBurst(level: widget.level),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'LEVEL UP!',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFFD97706),
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Level ${widget.level}',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 48,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              height: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'You reached Level ${widget.level}!',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onDismiss,
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Text(
                  'Continue',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelBurst extends StatelessWidget {
  final int level;
  const _LevelBurst({required this.level});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF2563EB).withValues(alpha: 0.08),
          ),
        ),
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF2563EB).withValues(alpha: 0.12),
          ),
        ),
        Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2563EB), Color(0xFF0EA5E9)],
            ),
          ),
          child: Center(
            child: Text(
              '$level',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ConfettiDot extends StatelessWidget {
  final Animation<double> animation;
  final int index;
  final Size screenSize;

  const _ConfettiDot({
    required this.animation,
    required this.index,
    required this.screenSize,
  });

  static const _colors = [
    Color(0xFFF59E0B), Color(0xFF2563EB), Color(0xFF16A34A),
    Color(0xFFDC2626), Color(0xFF7C3AED), Color(0xFF0EA5E9),
    Color(0xFFF97316), Color(0xFF06B6D4), Color(0xFFEC4899),
    Color(0xFF84CC16), Color(0xFFEF4444), Color(0xFF8B5CF6),
  ];

  @override
  Widget build(BuildContext context) {
    final angle = (index / 12) * 2 * pi - pi / 2;
    const radius = 160.0;
    final color = _colors[index % _colors.length];

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final progress = animation.value;
        final dx = cos(angle) * radius * progress;
        final dy = sin(angle) * radius * progress;
        final opacity = (progress * (1.0 - progress) * 4).clamp(0.0, 1.0);

        return Positioned(
          left: screenSize.width / 2 + dx - 6,
          top: screenSize.height / 2 + dy - 6,
          child: Opacity(
            opacity: opacity,
            child: Transform.rotate(
              angle: angle + progress * pi,
              child: Container(
                width: 12,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}