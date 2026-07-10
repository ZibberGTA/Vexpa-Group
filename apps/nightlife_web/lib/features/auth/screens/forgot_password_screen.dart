import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/components/drinkspot_button.dart';
import '../../../shared/layouts/public_page_shell.dart';
import '../../../shared/widgets/glass_container.dart';
import '../services/auth_service.dart';

/// Password reset request via Firebase Auth email.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _sent = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _sent = false;
    });

    try {
      await AuthService.sendPasswordResetEmail(email: _emailController.text);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _sent = true;
      });
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = AuthService.messageForAuthException(error);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Could not send reset email. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PublicPageShell(
      navActiveRoute: AppRouter.forgotPassword,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xxxl,
            ),
            child: GlassContainer(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      AppStrings.forgotPasswordTitle,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Text(
                      AppStrings.forgotPasswordSubtitle,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14.5,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'you@example.com',
                      ),
                      validator: (value) {
                        final email = (value ?? '').trim();
                        if (email.isEmpty) return 'Enter your email address.';
                        if (!email.contains('@')) {
                          return 'Enter a valid email address.';
                        }
                        return null;
                      },
                    ),
                    if (_sent) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.primaryPurple.withValues(
                            alpha: 0.16,
                          ),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                          border: Border.all(
                            color: AppColors.primaryPurple.withValues(
                              alpha: 0.35,
                            ),
                          ),
                        ),
                        child: const Text(
                          'If an account exists for that email, a reset link has been sent.',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 13.5,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                    if (_errorMessage != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.primaryPink.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                          border: Border.all(
                            color: AppColors.primaryPink.withValues(
                              alpha: 0.35,
                            ),
                          ),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 13.5,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    DrinkSpotButton(
                      label: _isLoading ? 'Sending…' : 'Send reset link',
                      icon: _isLoading ? null : Icons.mail_outline_rounded,
                      onPressed: _isLoading ? null : _submit,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DrinkSpotButton(
                      label: 'Back to sign in',
                      variant: DrinkSpotButtonVariant.ghost,
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.pushReplacementNamed(
                              context,
                              AppRouter.login,
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
