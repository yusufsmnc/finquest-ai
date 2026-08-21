import 'package:flutter/material.dart';
import '../../domain/scenario_model.dart';

class ScenarioRiskIndicator extends StatelessWidget {
  final RiskLevel riskLevel;
  final bool large;

  const ScenarioRiskIndicator({
    super.key,
    required this.riskLevel,
    this.large = false,
  });

  Color get _color {
    switch (riskLevel) {
      case RiskLevel.low:
        return const Color(0xFF16A34A);
      case RiskLevel.medium:
        return const Color(0xFFF59E0B);
      case RiskLevel.high:
        return const Color(0xFFDC2626);
    }
  }

  int get _filledBars {
    switch (riskLevel) {
      case RiskLevel.low:
        return 1;
      case RiskLevel.medium:
        return 2;
      case RiskLevel.high:
        return 3;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (large) return _buildLarge();
    return _buildCompact();
  }

  Widget _buildCompact() {
    return Semantics(
      label: '${riskLevel.label} risk',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: _color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...List.generate(3, (i) => _Bar(filled: i < _filledBars, color: _color, height: 10, spacing: 2)),
            const SizedBox(width: 6),
            Text(
              '${riskLevel.label} Risk',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLarge() {
    return Semantics(
      label: '${riskLevel.label} risk level',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.speed_rounded, color: _color, size: 18),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Financial Risk',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                Text(
                  '${riskLevel.label} Risk',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _color,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              children: List.generate(
                3,
                (i) => _Bar(
                  filled: i < _filledBars,
                  color: _color,
                  height: 20,
                  spacing: 4,
                  width: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final bool filled;
  final Color color;
  final double height;
  final double spacing;
  final double width;

  const _Bar({
    required this.filled,
    required this.color,
    required this.height,
    required this.spacing,
    this.width = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: spacing),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: filled ? color : color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}