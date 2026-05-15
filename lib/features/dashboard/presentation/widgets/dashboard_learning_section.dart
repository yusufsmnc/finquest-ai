import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../dashboard_providers.dart';
import '../../domain/dashboard_state.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../core/theme/app_colors.dart';

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
                animationDelay: 400 + i * 120,
              ),
              if (i < categories.length - 1)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Container(
                    height: 1,
                    color: AppColors.border,
                  ),
                ),
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
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: category.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: category.color.withValues(alpha: 0.2),
                ),
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
                  color: AppColors.textPrimary,
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
        _GlowCategoryBar(
          progress: category.progress,
          color: category.color,
          delayMs: animationDelay,
        ),
      ],
    );
  }
}

class _GlowCategoryBar extends StatefulWidget {
  final double progress;
  final Color color;
  final int delayMs;

  const _GlowCategoryBar({
    required this.progress,
    required this.color,
    this.delayMs = 0,
  });

  @override
  State<_GlowCategoryBar> createState() => _GlowCategoryBarState();
}

class _GlowCategoryBarState extends State<_GlowCategoryBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
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
              Container(height: 6, color: AppColors.surfaceUp),
              FractionallySizedBox(
                widthFactor: _anim.value.clamp(0.0, 1.0),
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: widget.color,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: widget.color.withValues(alpha: 0.5),
                        blurRadius: 6,
                      ),
                    ],
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