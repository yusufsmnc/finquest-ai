import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'application/profile_notifier.dart';
import 'domain/profile_state.dart';

final profileNotifierProvider =
    NotifierProvider<ProfileNotifier, ProfileState>(
  ProfileNotifier.new,
);