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
import '../services/user_role_service.dart';

/// Email/password login connected to the shared Firebase Auth project.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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

    User? user;

    try {
      await AuthService.login(
        email: _emailController.text,
        password: _passwordController.text,
      );
      user = AuthService.currentUser;
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = AuthService.messageForAuthException(error);
          _isLoading = false;
        });
      }
      return;
    }

    if (user == null) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Signed in, but the session could not be confirmed. Please try again.';
          _isLoading = false;
        });
      }
      return;
    }

    final navigation = await UserRoleService.resolvePostLoginNavigation(user);

    if (!mounted) return;

    setState(() => _isLoading = false);
    Navigator.pushNamedAndRemoveUntil(context, navigation.route, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return PublicPageShell(
      navActiveRoute: AppRouter.login,
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
                      AppStrings.loginTitle,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Text(
                      AppStrings.loginSubtitle,
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
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'you@example.com',
                      ),
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        if (email.isEmpty) return 'Enter your email address.';
                        if (!email.contains('@')) {
                          return 'Enter a valid email address.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      autofillHints: const [AutofillHints.password],
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return 'Enter your password.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.pushNamed(
                                context,
                                AppRouter.forgotPassword,
                              ),
                        child: const Text('Forgot password?'),
                      ),
                    ),
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
                      label: _isLoading ? 'Signing in…' : AppStrings.login,
                      icon: _isLoading ? null : Icons.login_rounded,
                      onPressed: _isLoading ? null : _submit,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DrinkSpotButton(
                      label: AppStrings.createAccount,
                      variant: DrinkSpotButtonVariant.secondary,
                      icon: Icons.person_add_alt_1_rounded,
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.pushNamed(
                              context,
                              AppRouter.register,
                            ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DrinkSpotButton(
                      label: 'Back to home',
                      variant: DrinkSpotButtonVariant.ghost,
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.pushNamedAndRemoveUntil(
                              context,
                              AppRouter.home,
                              (_) => false,
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
