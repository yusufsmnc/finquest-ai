import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import 'widgets/profile_identity_card.dart';
import 'widgets/profile_xp_section.dart';
import 'widgets/profile_streak_section.dart';
import 'widgets/profile_achievements_showcase.dart';
import 'widgets/profile_stats_section.dart';
import 'widgets/profile_activity_timeline.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
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
    _fadeIn = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );
    _slideIn = Tween<Offset>(
      begin: const Offset(0, 0.04),
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FadeTransition(
        opacity: _fadeIn,
        child: SlideTransition(
          position: _slideIn,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _ProfileAppBar(),
              const SliverToBoxAdapter(child: ProfileIdentityCard()),
              const SliverToBoxAdapter(child: ProfileXpSection()),
              const SliverToBoxAdapter(child: ProfileStreakSection()),
              const SliverToBoxAdapter(child: ProfileAchievementsShowcase()),
              const SliverToBoxAdapter(child: ProfileStatsSection()),
              const SliverToBoxAdapter(child: ProfileActivityTimeline()),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      pinned: true,
      leading: Navigator.of(context).canPop()
          ? GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.textPrimary,
                size: 22,
              ),
            )
          : null,
      title: const Text(
        'Profile',
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}