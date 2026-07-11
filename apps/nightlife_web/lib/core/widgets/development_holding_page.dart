import 'package:flutter/material.dart';

import '../constants/app_strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../../shared/components/vexda_logo.dart';
import 'development_preview_sign_in_dialog.dart';

/// Minimal branded screen shown while the private development gate is active.
///
/// Logo, status text, and a subtle Login action that opens the preview sign-in
/// dialog. No app shell or navigation.
class DevelopmentHoldingPage extends StatelessWidget {
  const DevelopmentHoldingPage({
    super.key,
    this.showLoadingIndicator = false,
    this.accessDeniedMessage,
  });

  const DevelopmentHoldingPage.loading({super.key})
    : showLoadingIndicator = true,
      accessDeniedMessage = null;

  final bool showLoadingIndicator;
  final String? accessDeniedMessage;

  static const String statusText = 'Vexda Coming Soon';

  @override
  Widget build(BuildContext context) {
    // [DevelopmentGate] replaces the app navigator while gated, so this page
    // needs its own navigator to present the preview sign-in dialog.
    return Navigator(
      onGenerateRoute: (_) => MaterialPageRoute<void>(
        builder: (routeContext) => _DevelopmentHoldingPageView(
          showLoadingIndicator: showLoadingIndicator,
          accessDeniedMessage: accessDeniedMessage,
        ),
      ),
    );
  }
}

class _DevelopmentHoldingPageView extends StatelessWidget {
  const _DevelopmentHoldingPageView({
    required this.showLoadingIndicator,
    required this.accessDeniedMessage,
  });

  final bool showLoadingIndicator;
  final String? accessDeniedMessage;

  /// Original holding-page logo height before the ~500% enlargement.
  static const double _baseLogoHeight = 72;

  /// Responsive logo footprint — visually dominant on desktop (~400–560px wide).
  Size _holdingLogoSize(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final availableWidth = screenWidth - (AppSpacing.xl * 2);

    if (screenWidth >= 1200) {
      return Size(_clampLogoWidth(560, availableWidth), _baseLogoHeight * 5);
    }
    if (screenWidth >= 900) {
      return Size(_clampLogoWidth(480, availableWidth), _baseLogoHeight * 4.5);
    }
    if (screenWidth >= 600) {
      return Size(_clampLogoWidth(400, availableWidth), _baseLogoHeight * 3.75);
    }

    final mobileWidth = (availableWidth * 0.88).clamp(220.0, 360.0);
    return Size(mobileWidth, mobileWidth * 0.62);
  }

  double _clampLogoWidth(double target, double available) {
    return target > available ? available : target;
  }

  Future<void> _showPreviewSignInDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const DevelopmentPreviewSignInDialog(),
    );
  }

  Widget _buildLoginAction(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return TextButton(
      onPressed: () => _showPreviewSignInDialog(context),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.textSecondary,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: Colors.transparent,
        overlayColor: AppColors.textSecondary.withValues(alpha: 0.08),
      ),
      child: Text(
        AppStrings.login,
        style: textTheme.labelLarge?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    final logoSize = _holdingLogoSize(context);

    return SizedBox(
      width: logoSize.width,
      height: logoSize.height,
      child: Center(child: VexdaLogo(height: logoSize.height, visualScale: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SizedBox.expand(
      child: ColoredBox(
        color: AppColors.background,
        child: SafeArea(
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: _buildLoginAction(context),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildLogo(context),
                      const SizedBox(height: AppSpacing.xxl),
                      if (showLoadingIndicator) ...[
                        const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.primaryPink,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                      ],
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              DevelopmentHoldingPage.statusText,
                              textAlign: TextAlign.center,
                              style: textTheme.titleMedium?.copyWith(
                                color: AppColors.textSecondary,
                                letterSpacing: 0.4,
                              ),
                            ),
                            if (accessDeniedMessage != null) ...[
                              const SizedBox(height: AppSpacing.lg),
                              Text(
                                accessDeniedMessage!,
                                textAlign: TextAlign.center,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: AppColors.primaryPink,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
