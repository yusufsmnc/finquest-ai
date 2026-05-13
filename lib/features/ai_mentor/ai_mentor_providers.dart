import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'application/ai_mentor_notifier.dart';
import 'domain/ai_mentor_state.dart';

final aiMentorProvider =
    NotifierProvider<AiMentorNotifier, AiMentorState>(
  AiMentorNotifier.new,
);