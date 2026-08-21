import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/animated_gradient_border.dart';
import '../../../shared/widgets/aurora_background.dart';
import '../auth_providers.dart';

/// Login / register screen. Rendered by the AuthGate whenever the session is
/// unauthenticated. All auth work goes through [authProvider].
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isRegister = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    final notifier = ref.read(authProvider.notifier);
    if (_isRegister) {
      await notifier.register(email, password);
    } else {
      await notifier.login(email, password);
    }
  }

  String _errorText(Object error) {
    if (error is DioException) {
      final code = error.response?.statusCode;
      if (code == 401) return 'Incorrect email or password.';
      if (code == 409) return 'That email is already registered.';
      if (code == 422) return 'Please enter a valid email and 8+ char password.';
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout) {
        return 'Cannot reach the server. Is the backend running?';
      }
    }
    return 'Something went wrong. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;
    final error = authState is AsyncError ? authState.error : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const Positioned.fill(child: AuroraBackground()),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: AnimatedGradientBorder(
                    borderRadius: 24,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _Header(isRegister: _isRegister),
                            const SizedBox(height: 24),
                            _EmailField(controller: _emailCtrl),
                            const SizedBox(height: 16),
                            _PasswordField(controller: _passwordCtrl),
                            if (error != null) ...[
                              const SizedBox(height: 16),
                              _ErrorBanner(message: _errorText(error)),
                            ],
                            const SizedBox(height: 24),
                            _SubmitButton(
                              isLoading: isLoading,
                              isRegister: _isRegister,
                              onPressed: isLoading ? null : _submit,
                            ),
                            const SizedBox(height: 12),
                            _ModeToggle(
                              isRegister: _isRegister,
                              onToggle: isLoading
                                  ? null
                                  : () => setState(
                                      () => _isRegister = !_isRegister),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final bool isRegister;
  const _Header({required this.isRegister});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.cyan],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryGlow(0.4),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.trending_up_rounded,
              color: Colors.white, size: 30),
        ),
        const SizedBox(height: 16),
        Text(
          isRegister ? 'Create your account' : 'Welcome back',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isRegister
              ? 'Start building your financial instincts.'
              : 'Your progress is waiting for you.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _EmailField extends StatelessWidget {
  final TextEditingController controller;
  const _EmailField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      autocorrect: false,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: _inputDecoration('Email', Icons.mail_outline_rounded),
      validator: (v) {
        final value = v?.trim() ?? '';
        if (value.isEmpty) return 'Email is required';
        if (!value.contains('@') || !value.contains('.')) {
          return 'Enter a valid email';
        }
        return null;
      },
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  const _PasswordField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: true,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: _inputDecoration('Password', Icons.lock_outline_rounded),
      validator: (v) {
        final value = v ?? '';
        if (value.isEmpty) return 'Password is required';
        if (value.length < 8) return 'At least 8 characters';
        return null;
      },
    );
  }
}

InputDecoration _inputDecoration(String label, IconData icon) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: AppColors.textSecondary),
    prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
    filled: true,
    fillColor: AppColors.surfaceUp,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.error),
    ),
  );
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.errorLight, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                color: AppColors.errorLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final bool isLoading;
  final bool isRegister;
  final VoidCallback? onPressed;

  const _SubmitButton({
    required this.isLoading,
    required this.isRegister,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.4, color: Colors.white),
              )
            : Text(
                isRegister ? 'Create account' : 'Log in',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  final bool isRegister;
  final VoidCallback? onToggle;

  const _ModeToggle({required this.isRegister, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onToggle,
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
          children: [
            TextSpan(
              text: isRegister
                  ? 'Already have an account? '
                  : "Don't have an account? ",
            ),
            TextSpan(
              text: isRegister ? 'Log in' : 'Sign up',
              style: const TextStyle(
                color: AppColors.primaryLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}