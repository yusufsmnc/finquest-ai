import 'package:flutter/material.dart';

/// OnboardingAnimationHandler — wires GameEvents to widget-level animations.
///
/// This class holds references to animation controllers that individual
/// screens/widgets pass in after mounting. The event dispatcher calls
/// methods here after state updates to trigger the correct animations.
///
/// Rules:
/// - Max 2 concurrent animations
/// - Respects MediaQuery.disableAnimations
/// - No business logic
class OnboardingAnimationHandler {
  OnboardingAnimationHandler._();

  // ── Shake animation (DECISION_WRONG) ──────────────────────────────────
  // ±6px horizontal × 3 cycles, 300ms total
  static AnimationController createShakeController(
    TickerProvider vsync,
  ) {
    return AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 300),
    );
  }

  static Animation<double> buildShakeAnimation(
    AnimationController controller,
  ) {
    return TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 6), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 6, end: -6), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -6, end: 6), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6, end: -6), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -6, end: 0), weight: 1),
    ]).animate(
      CurvedAnimation(parent: controller, curve: Curves.linear),
    );
  }

  // ── Green glow + scale (DECISION_CORRECT) ────────────────────────────
  static AnimationController createCorrectController(
    TickerProvider vsync,
  ) {
    return AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 100),
    );
  }

  static Animation<double> buildCorrectScaleAnimation(
    AnimationController controller,
  ) {
    return Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOut),
    );
  }

  // ── Red flash overlay (DECISION_WRONG) ───────────────────────────────
  // Spec: opacity 0 → 0.15 → 0 over 250ms
  static AnimationController createRedFlashController(
    TickerProvider vsync,
  ) {
    return AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 250),
    );
  }

  static Animation<double> buildRedFlashAnimation(
    AnimationController controller,
  ) {
    return TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.15), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.15, end: 0.0), weight: 70),
    ]).animate(controller);
  }

  // ── Confetti animation (LEVEL_UP / S5) ───────────────────────────────
  static AnimationController createConfettiController(
    TickerProvider vsync,
  ) {
    return AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 2000),
    );
  }

  /// Play shake animation respecting reduced motion.
  static Future<void> playShake(
    BuildContext context,
    AnimationController controller,
  ) async {
    if (MediaQuery.of(context).disableAnimations) return;
    await controller.forward(from: 0);
  }

  /// Play correct feedback animation.
  static Future<void> playCorrect(
    BuildContext context,
    AnimationController controller,
  ) async {
    if (MediaQuery.of(context).disableAnimations) return;
    await controller.forward();
    await controller.reverse();
  }

  /// Play red flash animation.
  static Future<void> playRedFlash(
    BuildContext context,
    AnimationController controller,
  ) async {
    if (MediaQuery.of(context).disableAnimations) return;
    await controller.forward(from: 0);
  }
}