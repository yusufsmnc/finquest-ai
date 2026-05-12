import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../scenario_providers.dart';
import '../../../../shared/widgets/xp_float_indicator.dart';

class ScenarioXpFloatOverlay extends ConsumerWidget {
  const ScenarioXpFloatOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showXpFloat = ref.watch(scenarioNotifierProvider.select((s) => s.showXpFloat));
    final lastXpGained = ref.watch(scenarioNotifierProvider.select((s) => s.lastXpGained));

    return XPFloatOverlay(
      xpAmount: lastXpGained,
      visible: showXpFloat,
    );
  }
}