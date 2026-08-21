import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'application/gamification_overlay_notifier.dart';
import 'domain/gamification_overlay_state.dart';

final gamificationOverlayProvider =
    NotifierProvider<GamificationOverlayNotifier, GamificationOverlayState>(
  GamificationOverlayNotifier.new,
);