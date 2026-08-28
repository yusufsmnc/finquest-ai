import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/dtos/progress_dto.dart';
import '../auth_providers.dart';

/// Authoritative XP / level / streak, loaded from the backend. This is the
/// single source of truth the UI renders — it never computes these values.
class ProgressNotifier extends AsyncNotifier<ProgressDto> {
  @override
  Future<ProgressDto> build() async {
    return ref.read(progressRepositoryProvider).getProgress();
  }

  /// Replace progress with a fresh authoritative snapshot (e.g. the value
  /// returned by `POST /scenarios/{id}/decision`).
  void setProgress(ProgressDto progress) {
    state = AsyncData(progress);
  }

  /// Re-fetch from the backend.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(progressRepositoryProvider).getProgress(),
    );
  }

  /// Current snapshot if loaded, else null (used to diff old vs new).
  ProgressDto? get currentOrNull => state.valueOrNull;
}
