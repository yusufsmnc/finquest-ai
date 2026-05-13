import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../ai_mentor_providers.dart';
import 'widgets/mentor_notification_prompt.dart';

class AiMentorOverlayWrapper extends ConsumerWidget {
  final Widget child;

  const AiMentorOverlayWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showNotification = ref.watch(
      aiMentorProvider.select((s) => s.showNotification),
    );
    final currentMessage = ref.watch(
      aiMentorProvider.select((s) => s.currentMessage),
    );

    return Stack(
      children: [
        child,
        if (showNotification && currentMessage != null)
          Positioned(
            right: 16,
            bottom: 100,
            child: MentorNotificationPrompt(
              key: ValueKey(currentMessage.id),
              message: currentMessage,
              onDismiss: () =>
                  ref.read(aiMentorProvider.notifier).dismissNotification(),
            ),
          ),
      ],
    );
  }
}