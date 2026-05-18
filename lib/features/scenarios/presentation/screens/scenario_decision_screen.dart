import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../scenario_providers.dart';
import '../../domain/scenario_model.dart';
import '../widgets/scenario_risk_indicator.dart';
import '../../../../core/theme/app_colors.dart';

class ScenarioDecisionScreen extends ConsumerStatefulWidget {
  const ScenarioDecisionScreen({super.key});

  @override
  ConsumerState<ScenarioDecisionScreen> createState() =>
      _ScenarioDecisionScreenState();
}

class _ScenarioDecisionScreenState
    extends ConsumerState<ScenarioDecisionScreen> with TickerProviderStateMixin {
  late AnimationController _blob1Controller;
  late AnimationController _blob2Controller;
  late Animation<double> _blob1Top;
  late Animation<double> _blob1Left;
  late Animation<double> _blob1Opacity;
  late Animation<double> _blob2Bottom;
  late Animation<double> _blob2Right;
  late Animation<double> _blob2Opacity;

  @override
  void initState() {
    super.initState();

    _blob1Controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _blob2Controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 11),
    )..repeat(reverse: true);

    final curve1 = CurvedAnimation(parent: _blob1Controller, curve: Curves.easeInOut);
    final curve2 = CurvedAnimation(parent: _blob2Controller, curve: Curves.easeInOut);

    _blob1Top     = Tween<double>(begin: -80, end: -50).animate(curve1);
    _blob1Left    = Tween<double>(begin: -80, end: -48).animate(curve1);
    _blob1Opacity = Tween<double>(begin: 0.13, end: 0.22).animate(curve1);

    _blob2Bottom  = Tween<double>(begin: -60, end: -32).animate(curve2);
    _blob2Right   = Tween<double>(begin: -60, end: -88).animate(curve2);
    _blob2Opacity = Tween<double>(begin: 0.10, end: 0.18).animate(curve2);
  }

  @override
  void dispose() {
    _blob1Controller.dispose();
    _blob2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scenario = ref.watch(scenarioNotifierProvider.select((s) => s.activeScenario));
    final selectedOptionId = ref.watch(scenarioNotifierProvider.select((s) => s.selectedOptionId));
    final isCorrect = ref.watch(scenarioNotifierProvider.select((s) => s.isCorrect));
    final currentStreak = ref.watch(scenarioNotifierProvider.select((s) => s.currentStreak));
    final dispatcher = ref.read(scenarioDispatcherProvider);

    if (scenario == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => dispatcher.onBackToList(),
        ),
        title: Text(
          scenario.category,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        centerTitle: false,
      ),
      body: Stack(
        children: [
          // Animated background glow blobs
          AnimatedBuilder(
            animation: Listenable.merge([_blob1Controller, _blob2Controller]),
            builder: (context, _) => Stack(
              children: [
                Positioned(
                  top: _blob1Top.value,
                  left: _blob1Left.value,
                  child: IgnorePointer(
                    child: Container(
                      width: 380,
                      height: 380,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: _blob1Opacity.value),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: _blob2Bottom.value,
                  right: _blob2Right.value,
                  child: IgnorePointer(
                    child: Container(
                      width: 320,
                      height: 320,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.cyan.withValues(alpha: _blob2Opacity.value),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Main content
          LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ScenarioRiskIndicator(riskLevel: scenario.riskLevel, large: true),
                    const SizedBox(height: 20),
                    _ScenarioEventCard(scenario: scenario),
                    const SizedBox(height: 16),
                    _StakesBar(
                      xpCorrect: scenario.xpCorrect,
                      xpParticipation: scenario.xpParticipation,
                      streak: currentStreak,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'What would you do?',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...scenario.options.asMap().entries.map((entry) {
                      final selected = selectedOptionId == entry.value.id;
                      return _OptionCard(
                        option: entry.value,
                        index: entry.key,
                        isSelected: selected,
                        isLocked: selectedOptionId != null,
                        wasCorrect: selected ? isCorrect : null,
                        onTap: selectedOptionId == null
                            ? () => dispatcher.onDecisionMade(
                                  scenario.id,
                                  entry.value.id,
                                  entry.value.isCorrect,
                                  entry.value.isCorrect
                                      ? scenario.xpCorrect
                                      : scenario.xpParticipation,
                                )
                            : null,
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StakesBar extends StatelessWidget {
  final int xpCorrect;
  final int xpParticipation;
  final int streak;

  const _StakesBar({
    required this.xpCorrect,
    required this.xpParticipation,
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.xpGold.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: AppColors.xpGold.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.xpGold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.bolt_rounded, color: AppColors.xpGold, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '+$xpCorrect XP if correct',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.xpGold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '+$xpParticipation XP for participating',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (streak > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 4),
                  Text(
                    '$streak streak',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ScenarioEventCard extends StatelessWidget {
  final Scenario scenario;
  const _ScenarioEventCard({required this.scenario});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: AppColors.primaryGlow(0.08),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.event_note_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Financial Scenario',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            scenario.title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            scenario.description,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionCard extends StatefulWidget {
  final ScenarioOption option;
  final int index;
  final bool isSelected;
  final bool isLocked;
  final bool? wasCorrect;
  final VoidCallback? onTap;

  const _OptionCard({
    required this.option,
    required this.index,
    required this.isSelected,
    required this.isLocked,
    required this.wasCorrect,
    required this.onTap,
  });

  static const _labels = ['A', 'B', 'C', 'D'];

  @override
  State<_OptionCard> createState() => _OptionCardState();
}

class _OptionCardState extends State<_OptionCard>
    with TickerProviderStateMixin {
  late AnimationController _pressController;
  late AnimationController _popController;
  late AnimationController _shakeController;

  late Animation<double> _pressAnim;
  late Animation<double> _popAnim;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();

    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
    );
    _pressAnim = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );

    _popController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _popAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.06), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.06, end: 0.97), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.97, end: 1.0), weight: 35),
    ]).animate(CurvedAnimation(parent: _popController, curve: Curves.easeOut));

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -9.0), weight: 12),
      TweenSequenceItem(tween: Tween(begin: -9.0, end: 9.0), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 9.0, end: -6.0), weight: 25),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 6.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: 0.0), weight: 18),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.linear));
  }

  @override
  void didUpdateWidget(_OptionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isLocked && widget.isLocked && widget.isSelected) {
      if (widget.wasCorrect == true) {
        _popController.forward(from: 0);
      } else if (widget.wasCorrect == false) {
        _shakeController.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _pressController.dispose();
    _popController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.index < _OptionCard._labels.length
        ? _OptionCard._labels[widget.index]
        : '${widget.index + 1}';

    Color borderColor;
    Color bgColor;
    Color labelBg;
    Color labelFg;
    List<BoxShadow> shadows;

    if (!widget.isLocked) {
      borderColor = AppColors.border;
      bgColor = AppColors.surface;
      labelBg = AppColors.surfaceUp;
      labelFg = AppColors.textSecondary;
      shadows = [
        BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 2)),
      ];
    } else if (widget.isSelected && widget.wasCorrect == true) {
      borderColor = AppColors.success;
      bgColor = AppColors.success.withValues(alpha: 0.08);
      labelBg = AppColors.success;
      labelFg = Colors.white;
      shadows = [
        BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2)),
        BoxShadow(
            color: AppColors.successGlow(0.3),
            blurRadius: 20,
            offset: const Offset(0, 4)),
      ];
    } else if (widget.isSelected && widget.wasCorrect == false) {
      borderColor = AppColors.error;
      bgColor = AppColors.error.withValues(alpha: 0.08);
      labelBg = AppColors.error;
      labelFg = Colors.white;
      shadows = [
        BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2)),
        BoxShadow(
            color: AppColors.error.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 4)),
      ];
    } else {
      borderColor = AppColors.border;
      bgColor = AppColors.surface;
      labelBg = AppColors.surfaceUp;
      labelFg = AppColors.textMuted;
      shadows = [
        BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2)),
      ];
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AnimatedBuilder(
        animation:
            Listenable.merge([_pressController, _popController, _shakeController]),
        builder: (context, child) => Transform.translate(
          offset: Offset(_shakeAnim.value, 0),
          child: Transform.scale(
            scale: _pressAnim.value * _popAnim.value,
            child: child,
          ),
        ),
        child: Semantics(
          button: true,
          label: 'Option $label: ${widget.option.text}',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) {
              if (widget.onTap != null) _pressController.forward();
            },
            onTapUp: (_) {
              _pressController.reverse();
              widget.onTap?.call();
            },
            onTapCancel: () => _pressController.reverse(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: borderColor, width: widget.isSelected ? 1.5 : 1),
                boxShadow: shadows,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: labelBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: labelFg,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        widget.option.text,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: widget.isLocked && !widget.isSelected
                              ? AppColors.textMuted
                              : AppColors.textPrimary,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}