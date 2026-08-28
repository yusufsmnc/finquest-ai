import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Global tab index — any screen can switch tabs via:
/// ref.read(shellTabIndexProvider.notifier).state = ShellTab.aiMentor;
final shellTabIndexProvider = StateProvider<int>((ref) => 0);

abstract class ShellTab {
  static const int dashboard = 0;
  static const int scenarios = 1;
  static const int aiMentor = 2;
  static const int achievements = 3;
  static const int profile = 4;
}
