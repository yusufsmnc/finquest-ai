import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../scenario_providers.dart';
import '../../../../shared/widgets/reward_toast.dart';

class ScenarioRewardToastOverlay extends ConsumerWidget {
  const ScenarioRewardToastOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showRewardToast = ref.watch(scenarioNotifierProvider.select((s) => s.showRewardToast));
    final dispatcher = ref.read(scenarioDispatcherProvider);

    if (!showRewardToast) return const SizedBox.shrink();

    return Positioned(
      left: 0,
      right: 0,
      bottom: 32,
      child: RewardToast(
        rewardId: 'streak_reward',
        label: 'Streak Reward — Keep it up!',
        visible: showRewardToast,
        onDismiss: dispatcher.onRewardToastDismissed,
      ),
    );
  }
}