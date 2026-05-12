import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../dashboard_providers.dart';
import '../../../../shared/widgets/card_container.dart';

class DashboardPortfolioCard extends ConsumerWidget {
  const DashboardPortfolioCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portfolio =
        ref.watch(dashboardNotifierProvider.select((s) => s.portfolio));

    final changeColor = portfolio.isPositive
        ? const Color(0xFF16A34A)
        : const Color(0xFFDC2626);
    final changeIcon = portfolio.isPositive
        ? Icons.arrow_upward_rounded
        : Icons.arrow_downward_rounded;
    final changeSign = portfolio.isPositive ? '+' : '';

    return CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Simulated Portfolio',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${portfolio.value.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: changeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(changeIcon, color: changeColor, size: 14),
                    const SizedBox(width: 2),
                    Text(
                      '$changeSign${portfolio.changePercent.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: changeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 60,
            child: CustomPaint(
              painter: _SparklinePainter(
                data: portfolio.sparkline,
                isPositive: portfolio.isPositive,
              ),
              size: const Size(double.infinity, 60),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Simulation only — not real money',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final bool isPositive;

  const _SparklinePainter({required this.data, required this.isPositive});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final lineColor =
        isPositive ? const Color(0xFF16A34A) : const Color(0xFFDC2626);

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    final minVal = data.reduce(min);
    final maxVal = data.reduce(max);
    final range = maxVal == minVal ? 1.0 : maxVal - minVal;
    final xStep = size.width / (data.length - 1);

    double yFor(double v) =>
        size.height - ((v - minVal) / range) * size.height * 0.85 -
        size.height * 0.075;

    final linePath = Path();
    final fillPath = Path();

    for (int i = 0; i < data.length; i++) {
      final x = i * xStep;
      final y = yFor(data[i]);
      if (i == 0) {
        linePath.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        linePath.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(linePath, linePaint);

    // Last point dot
    final lastX = (data.length - 1) * xStep;
    final lastY = yFor(data.last);
    canvas.drawCircle(
      Offset(lastX, lastY),
      4,
      Paint()..color = lineColor,
    );
  }

  @override
  bool shouldRepaint(_SparklinePainter old) => old.data != data;
}