import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../gamification_providers.dart';
import 'widgets/level_up_modal.dart';
import 'widgets/xp_lost_overlay.dart';
import 'widgets/streak_feedback_overlay.dart';
import 'widgets/achievement_unlock_overlay.dart';
import 'widgets/gamification_toast_queue.dart';

class GamificationOverlayManager extends ConsumerStatefulWidget {
  final Widget child;

  const GamificationOverlayManager({super.key, required this.child});

  @override
  ConsumerState<GamificationOverlayManager> createState() =>
      _GamificationOverlayManagerState();
}

class _GamificationOverlayManagerState
    extends ConsumerState<GamificationOverlayManager> {
  @override
  void initState() {
    super.initState();
    // XP Lost auto-dismiss is handled by the widget itself
    // Level Up is dismissed by user tap
    // Streak feedback dismisses itself via animation completion
    // Achievement dismisses itself after 2.5s
    // Toast queue advances via onAdvance callback
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gamificationOverlayProvider);
    final notifier = ref.read(gamificationOverlayProvider.notifier);

    return Stack(
      children: [
        widget.child,

        // Streak feedback — above content but below level-up modal
        if (state.showStreakFeedback)
          Positioned.fill(
            child: IgnorePointer(
              child: StreakFeedbackOverlay(
                key: ValueKey('streak_${state.streakValue}'),
                streak: state.streakValue,
                onDismiss: notifier.dismissStreakFeedback,
              ),
            ),
          ),

        // XP Lost banner
        if (state.showXpLost)
          XpLostOverlay(
            key: ValueKey('xplost_${state.xpLostAmount}'),
            amount: state.xpLostAmount,
            onDismiss: notifier.dismissXpLost,
          ),

        // Toast queue (bottom)
        if (state.toastQueue.isNotEmpty)
          GamificationToastQueue(
            toasts: state.toastQueue,
            onAdvance: notifier.advanceToastQueue,
          ),

        // Achievement unlock (bottom, above toast)
        if (state.showAchievementUnlock)
          AchievementUnlockOverlay(
            key: ValueKey('achievement_${state.achievementName}'),
            achievementName: state.achievementName,
            onDismiss: notifier.dismissAchievementUnlock,
          ),

        // Level Up modal — topmost, blocks interaction
        if (state.showLevelUp)
          Positioned.fill(
            child: LevelUpModal(
              key: ValueKey('levelup_${state.levelUpValue}'),
              level: state.levelUpValue,
              onDismiss: notifier.dismissLevelUp,
            ),
          ),
      ],
    );
  }
}