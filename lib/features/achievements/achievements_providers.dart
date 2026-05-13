import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'application/achievements_notifier.dart';
import 'domain/achievements_state.dart';

final achievementsNotifierProvider =
    NotifierProvider<AchievementsNotifier, AchievementsState>(
  AchievementsNotifier.new,
);