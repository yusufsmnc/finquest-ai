import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../dashboard_providers.dart';
import '../../domain/dashboard_state.dart';
import '../../../../shared/widgets/card_container.dart';

class DashboardLearningSection extends ConsumerWidget {
  const DashboardLearningSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories =
        ref.watch(dashboardNotifierProvider.select((s) => s.categories));

    return CardContainer(
      child: Column(
        children: List.generate(categories.length, (i) {
          return Column(
            children: [
              _CategoryRow(
                category: categories[i],
                animationDelay: 500 + i * 150,
              ),
              if (i < categories.length - 1) const SizedBox(height: 14),
            ],
          );
        }),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final DashboardCategory category;
  final int animationDelay;
  const _CategoryRow({required this.category, this.animationDelay = 0});

  @override
  Widget build(BuildContext context) {
    final pct = (category.progress * 100).round();
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: category.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(category.icon, color: category.color, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                category.name,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            Text(
              '$pct%',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: category.color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _AnimatedCategoryBar(
          progress: category.progress,
          color: category.color,
          delayMs: animationDelay,
        ),
      ],
    );
  }
}

class _AnimatedCategoryBar extends StatefulWidget {
  final double progress;
  final Color color;
  final int delayMs;

  const _AnimatedCategoryBar({
    required this.progress,
    required this.color,
    this.delayMs = 0,
  });

  @override
  State<_AnimatedCategoryBar> createState() => _AnimatedCategoryBarState();
}

class _AnimatedCategoryBarState extends State<_AnimatedCategoryBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _anim = Tween<double>(begin: 0, end: widget.progress).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final reduced = MediaQuery.of(context).disableAnimations;
      if (reduced) {
        _controller.value = 1;
      } else {
        Future.delayed(Duration(milliseconds: widget.delayMs), () {
          if (mounted) _controller.forward();
        });
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
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Stack(
            children: [
              Container(height: 6, color: const Color(0xFFE2E8F0)),
              FractionallySizedBox(
                widthFactor: _anim.value.clamp(0.0, 1.0),
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: widget.color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}