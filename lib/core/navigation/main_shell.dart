import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/scenarios/presentation/scenario_flow.dart';
import '../../features/ai_mentor/presentation/ai_mentor_screen.dart';
import '../../features/achievements/presentation/achievements_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../theme/app_colors.dart';
import 'shell_providers.dart';
import '../../shared/widgets/aurora_background.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  static const _tabs = [
    DashboardScreen(),
    ScenarioFlow(),
    AiMentorScreen(),
    AchievementsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(shellTabIndexProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const Positioned.fill(child: AuroraBackground()),
          IndexedStack(
            index: currentIndex,
            children: _tabs,
          ),
        ],
      ),
      bottomNavigationBar: _PremiumTabBar(
        currentIndex: currentIndex,
        onTap: (i) => ref.read(shellTabIndexProvider.notifier).state = i,
      ),
    );
  }
}

// ── Tab definitions ────────────────────────────────────────────────────────────

const _kTabs = [
  _TabDef(Icons.home_rounded, Icons.home_outlined, 'Home', AppColors.primary),
  _TabDef(Icons.psychology_alt_rounded, Icons.psychology_alt_outlined, 'Scenarios', AppColors.cyan),
  _TabDef(Icons.auto_awesome_rounded, Icons.auto_awesome_outlined, 'Mentor', AppColors.purple),
  _TabDef(Icons.emoji_events_rounded, Icons.emoji_events_outlined, 'Achievements', AppColors.xpGold),
  _TabDef(Icons.person_rounded, Icons.person_outline_rounded, 'Profile', AppColors.primary),
];

class _TabDef {
  final IconData selectedIcon;
  final IconData unselectedIcon;
  final String label;
  final Color color;
  const _TabDef(this.selectedIcon, this.unselectedIcon, this.label, this.color);
}

// ── Premium tab bar ────────────────────────────────────────────────────────────

class _PremiumTabBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _PremiumTabBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.border, width: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final tabWidth = constraints.maxWidth / _kTabs.length;
              return Stack(
                children: [
                  // Sliding pill indicator
                  _SlidingPill(
                    currentIndex: currentIndex,
                    tabWidth: tabWidth,
                    color: _kTabs[currentIndex].color,
                  ),
                  // Tab items
                  Row(
                    children: List.generate(_kTabs.length, (i) {
                      return _TabItem(
                        def: _kTabs[i],
                        isSelected: currentIndex == i,
                        onTap: () => onTap(i),
                        width: tabWidth,
                      );
                    }),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ── Sliding pill ───────────────────────────────────────────────────────────────

class _SlidingPill extends StatefulWidget {
  final int currentIndex;
  final double tabWidth;
  final Color color;

  const _SlidingPill({
    required this.currentIndex,
    required this.tabWidth,
    required this.color,
  });

  @override
  State<_SlidingPill> createState() => _SlidingPillState();
}

class _SlidingPillState extends State<_SlidingPill>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _position;
  late Animation<Color?> _color;
  double _fromIndex = 0;

  @override
  void initState() {
    super.initState();
    _fromIndex = widget.currentIndex.toDouble();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _position = Tween<double>(
      begin: _fromIndex,
      end: _fromIndex,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutCubic));
    _color = ColorTween(
      begin: widget.color,
      end: widget.color,
    ).animate(_ctrl);
  }

  @override
  void didUpdateWidget(_SlidingPill old) {
    super.didUpdateWidget(old);
    if (old.currentIndex != widget.currentIndex ||
        old.color != widget.color) {
      _fromIndex = _position.value;
      _position = Tween<double>(
        begin: _fromIndex,
        end: widget.currentIndex.toDouble(),
      ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutCubic));
      _color = ColorTween(
        begin: old.color,
        end: widget.color,
      ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutCubic));
      _ctrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const pillW = 56.0;
    const pillH = 36.0;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final left = _position.value * widget.tabWidth +
            (widget.tabWidth - pillW) / 2;
        final c = _color.value ?? widget.color;
        return Positioned(
          top: (64 - pillH) / 2,
          left: left,
          child: Container(
            width: pillW,
            height: pillH,
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: c.withValues(alpha: 0.3), width: 0.5),
              boxShadow: [
                BoxShadow(
                  color: c.withValues(alpha: 0.30),
                  blurRadius: 14,
                  spreadRadius: 0,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Tab item ───────────────────────────────────────────────────────────────────

class _TabItem extends StatelessWidget {
  final _TabDef def;
  final bool isSelected;
  final VoidCallback onTap;
  final double width;

  const _TabItem({
    required this.def,
    required this.isSelected,
    required this.onTap,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: width,
        height: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.18 : 1.0,
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutBack,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  isSelected ? def.selectedIcon : def.unselectedIcon,
                  key: ValueKey(isSelected),
                  size: 22,
                  color: isSelected ? def.color : AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? def.color : AppColors.textMuted,
              ),
              child: Text(def.label),
            ),
          ],
        ),
      ),
    );
  }
}
