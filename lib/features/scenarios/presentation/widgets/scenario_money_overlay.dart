import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import '../../scenario_providers.dart';

class ScenarioMoneyOverlay extends ConsumerStatefulWidget {
  const ScenarioMoneyOverlay({super.key});

  @override
  ConsumerState<ScenarioMoneyOverlay> createState() =>
      _ScenarioMoneyOverlayState();
}

class _ScenarioMoneyOverlayState extends ConsumerState<ScenarioMoneyOverlay> {
  bool _visible = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _trigger() {
    if (_visible) return;
    setState(() => _visible = true);
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _visible = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      scenarioNotifierProvider.select((s) => s.showXpFloat),
      (prev, next) {
        if (next == true) {
          final isCorrect = ref.read(scenarioNotifierProvider).isCorrect;
          if (isCorrect == true) _trigger();
        }
      },
    );

    if (!_visible) return const SizedBox.shrink();

    return Positioned(
      left: 0,
      right: 0,
      bottom: 80,
      child: IgnorePointer(
        child: Center(
          child: Lottie.asset(
            'assets/animations/money.json',
            width: 260,
            height: 260,
            fit: BoxFit.contain,
            repeat: false,
          ),
        ),
      ),
    );
  }
}