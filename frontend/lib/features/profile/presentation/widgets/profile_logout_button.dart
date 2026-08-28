import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/auth_providers.dart';

/// The sign-out action in the Profile app bar.
///
/// A widget of its own rather than a closure inside the app bar so it can be
/// pumped on its own in a test: the full Profile screen runs pulse animations
/// that never settle, which makes it a poor thing to drive from a widget test.
class ProfileLogoutButton extends ConsumerWidget {
  const ProfileLogoutButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.logout_rounded, color: AppColors.textPrimary),
      tooltip: 'Log out',
      onPressed: () => _confirmLogout(context, ref),
    );
  }

  /// Signing out drops the session on this device; ask first, because the only
  /// way back is typing the password again.
  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Log out?',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: const Text(
          'Your progress is saved on the server. You will need to sign in '
          'again to get back to it.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      // AuthGate watches the session and swaps in the login screen on its own,
      // so there is no navigation to do here.
      await ref.read(authProvider.notifier).logout();
    }
  }
}
