import 'package:flutter/material.dart';

/// AchievementBadge — displays an achievement with ScaleIn elasticOut animation.
/// Used on S5 (Level Up screen) and reward reveal screens.
class AchievementBadge extends StatefulWidget {
  final String badgeId;
  final String label;
  final String description;
  final double size;
  final bool animate;
  final VoidCallback? onTap;

  const AchievementBadge({
    super.key,
    required this.badgeId,
    required this.label,
    this.description = '',
    this.size = 140,
    this.animate = true,
    this.onTap,
  });

  @override
  State<AchievementBadge> createState() => _AchievementBadgeState();
}

class _AchievementBadgeState extends State<AchievementBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    // Spec: ScaleIn elasticOut 600ms, delay 400ms
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scale = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.3, curve: Curves.easeIn),
      ),
    );

    if (widget.animate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final reducedMotion = MediaQuery.of(context).disableAnimations;
          if (reducedMotion) {
            _controller.value = 1;
          } else {
            Future.delayed(const Duration(milliseconds: 400), () {
              if (mounted) _controller.forward();
            });
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

  IconData _iconForBadge(String badgeId) {
    switch (badgeId) {
      case 'badge_novice':
        return Icons.military_tech_rounded;
      case 'badge_investor':
        return Icons.trending_up_rounded;
      case 'badge_expert':
        return Icons.workspace_premium_rounded;
      default:
        return Icons.emoji_events_rounded;
    }
  }

  String _labelForBadge(String badgeId) {
    switch (badgeId) {
      case 'badge_novice':
        return 'Novice Investor';
      case 'badge_investor':
        return 'Investor';
      case 'badge_expert':
        return 'Expert';
      default:
        return widget.label;
    }
  }

  @override
  Widget build(BuildContext context) {
    final badgeLabel = _labelForBadge(widget.badgeId);

    return Semantics(
      label: 'Achievement badge: $badgeLabel',
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _opacity.value.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: _scale.value,
                child: child,
              ),
            );
          },
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer glow ring
                Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFF59E0B).withValues(alpha: 0.15),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                // Inner badge circle
                Container(
                  width: widget.size * 0.78,
                  height: widget.size * 0.78,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFF59E0B),
                        Color(0xFFD97706),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _iconForBadge(widget.badgeId),
                        color: Colors.white,
                        size: widget.size * 0.3,
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          badgeLabel,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: widget.size * 0.085,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.1,
                          ),
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