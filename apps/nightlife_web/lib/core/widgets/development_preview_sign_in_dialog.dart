import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../features/auth/services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../../shared/components/drinkspot_button.dart';
import '../../shared/widgets/glass_container.dart';

/// Discreet preview sign-in surfaced from the holding page logo interaction.
class DevelopmentPreviewSignInDialog extends StatefulWidget {
  const DevelopmentPreviewSignInDialog({super.key});

  static const String genericErrorMessage =
      'Sign-in failed. Please check your details and try again.';

  @override
  State<DevelopmentPreviewSignInDialog> createState() =>
      _DevelopmentPreviewSignInDialogState();
}

class _DevelopmentPreviewSignInDialogState
    extends State<DevelopmentPreviewSignInDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AuthService.login(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } on FirebaseAuthException {
      if (!mounted) return;
      setState(() {
        _errorMessage = DevelopmentPreviewSignInDialog.genericErrorMessage;
        _isLoading = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _errorMessage = DevelopmentPreviewSignInDialog.genericErrorMessage;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xxl,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: GlassContainer(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Preview sign-in',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      tooltip: 'Close',
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  textInputAction: TextInputAction.next,
                  enabled: !_isLoading,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter your email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  autofillHints: const [AutofillHints.password],
                  textInputAction: TextInputAction.done,
                  enabled: !_isLoading,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      onPressed: _isLoading
                          ? null
                          : () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter your password';
                    }
                    return null;
                  },
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: AppColors.primaryPink,
                      fontSize: 13.5,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                Center(
                  child: DrinkSpotButton(
                    label: _isLoading ? 'Signing in…' : 'Sign in',
                    onPressed: _isLoading ? null : _submit,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
