import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../dashboard_providers.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import 'widgets/dashboard_xp_hero_card.dart';
import 'widgets/dashboard_stats_row.dart';
import 'widgets/dashboard_challenges_section.dart';
import 'widgets/dashboard_portfolio_card.dart';
import 'widgets/dashboard_learning_section.dart';
import 'widgets/dashboard_achievements_section.dart';
import 'widgets/dashboard_mentor_card.dart';
import 'widgets/market_events_feed_section.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideIn;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeIn = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOut),
    );
    _slideIn = Tween<Offset>(
      begin: const Offset(0, 0.03),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final reduced = MediaQuery.of(context).disableAnimations;
        if (reduced) {
          _entryController.value = 1;
        } else {
          _entryController.forward();
        }
      }
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Auto-dismiss XP float after it's shown
    ref.listen(dashboardNotifierProvider.select((s) => s.showXpFloat),
        (_, show) {
      if (show) {
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            ref.read(dashboardDispatcherProvider).onXpFloatDismissed();
          }
        });
      }
    });

    // Auto-dismiss streak pulse
    ref.listen(dashboardNotifierProvider.select((s) => s.streakPulse),
        (_, pulse) {
      if (pulse) {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) {
            ref.read(dashboardDispatcherProvider).onStreakPulseDismissed();
          }
        });
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'fab_profile',
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.profile),
            backgroundColor: AppColors.surfaceHigh,
            child: const Icon(Icons.person_rounded,
                color: AppColors.textPrimary, size: 18),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'fab_achievements',
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.achievements),
            backgroundColor: AppColors.purple,
            child: const Icon(Icons.emoji_events_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: 'fab_scenarios',
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.scenarios),
            backgroundColor: AppColors.primary,
            icon: const Icon(Icons.psychology_alt_rounded,
                color: Colors.white, size: 20),
            label: const Text(
              'Scenarios',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeIn,
        child: SlideTransition(
          position: _slideIn,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _DashboardAppBar(),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 8),
                    const DashboardXpHeroCard(),
                    const SizedBox(height: 16),
                    const DashboardStatsRow(),
                    const SizedBox(height: 24),
                  ]),
                ),
              ),
              const SliverToBoxAdapter(
                child: _ChallengesSectionHeader(),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              const SliverToBoxAdapter(child: DashboardChallengesSection()),
              SliverToBoxAdapter(
                child: _SectionHeader(
                  title: 'Market Events',
                  trailing: 'LIVE',
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              const SliverToBoxAdapter(child: MarketEventsFeedSection()),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 24),
                    const _SectionHeaderInline(title: 'Portfolio'),
                    const SizedBox(height: 12),
                    const DashboardPortfolioCard(),
                    const SizedBox(height: 24),
                    const _SectionHeaderInline(title: 'Learning Progress'),
                    const SizedBox(height: 12),
                    const DashboardLearningSection(),
                    const SizedBox(height: 24),
                  ]),
                ),
              ),
              SliverToBoxAdapter(
                child: _SectionHeader(title: 'Achievements', trailing: null),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              const SliverToBoxAdapter(child: DashboardAchievementsSection()),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 24),
                    const _SectionHeaderInline(title: 'AI Mentor'),
                    const SizedBox(height: 12),
                    const DashboardMentorCard(),
                    const SizedBox(height: 40),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

class _ChallengesSectionHeader extends ConsumerWidget {
  const _ChallengesSectionHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeCount = ref
        .watch(dashboardNotifierProvider.select((s) => s.challenges))
        .where((c) => !c.isComplete)
        .length;

    return _SectionHeader(
      title: 'Active Challenges',
      trailing: '$activeCount active',
    );
  }
}

class _DashboardAppBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final level =
        ref.watch(dashboardNotifierProvider.select((s) => s.currentLevel));

    return SliverAppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      floating: true,
      pinned: false,
      toolbarHeight: 64,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome back!',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            'Level $level · Keep learning',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(
            Icons.notifications_outlined,
            color: AppColors.textSecondary,
            size: 22,
          ),
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? trailing;

  const _SectionHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          if (trailing != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
              ),
              child: Text(
                trailing!,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.error,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionHeaderInline extends StatelessWidget {
  final String title;
  const _SectionHeaderInline({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}