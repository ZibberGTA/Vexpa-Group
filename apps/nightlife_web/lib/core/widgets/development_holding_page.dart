import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../../shared/components/vexda_logo.dart';
import 'development_preview_sign_in_dialog.dart';

/// Minimal branded screen shown while the private development gate is active.
///
/// No app shell, navigation, or visible login UI — logo and status text only.
/// A hidden preview sign-in dialog is revealed after five logo taps.
class DevelopmentHoldingPage extends StatefulWidget {
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

  /// Original holding-page logo height before the ~500% enlargement.
  static const double _baseLogoHeight = 72;

  @override
  State<DevelopmentHoldingPage> createState() => _DevelopmentHoldingPageState();
}

class _DevelopmentHoldingPageState extends State<DevelopmentHoldingPage> {
  static const int _requiredLogoClicks = 5;
  static const Duration _clickResetWindow = Duration(seconds: 5);

  int _logoClickCount = 0;
  Timer? _clickResetTimer;

  @override
  void dispose() {
    _clickResetTimer?.cancel();
    super.dispose();
  }

  /// Responsive logo footprint — visually dominant on desktop (~400–560px wide).
  Size _holdingLogoSize(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final availableWidth = screenWidth - (AppSpacing.xl * 2);

    if (screenWidth >= 1200) {
      return Size(
        _clampLogoWidth(560, availableWidth),
        DevelopmentHoldingPage._baseLogoHeight * 5,
      );
    }
    if (screenWidth >= 900) {
      return Size(
        _clampLogoWidth(480, availableWidth),
        DevelopmentHoldingPage._baseLogoHeight * 4.5,
      );
    }
    if (screenWidth >= 600) {
      return Size(
        _clampLogoWidth(400, availableWidth),
        DevelopmentHoldingPage._baseLogoHeight * 3.75,
      );
    }

    final mobileWidth = (availableWidth * 0.88).clamp(220.0, 360.0);
    return Size(mobileWidth, mobileWidth * 0.62);
  }

  double _clampLogoWidth(double target, double available) {
    return target > available ? available : target;
  }

  void _handleLogoTap() {
    _clickResetTimer?.cancel();
    final nextCount = _logoClickCount + 1;

    if (kDebugMode) {
      debugPrint('Development logo tapped: $nextCount');
    }

    if (nextCount >= _requiredLogoClicks) {
      _clickResetTimer?.cancel();
      setState(() => _logoClickCount = 0);
      unawaited(_showPreviewSignInDialog());
      return;
    }

    setState(() => _logoClickCount = nextCount);
    _clickResetTimer = Timer(_clickResetWindow, () {
      if (!mounted) return;
      setState(() => _logoClickCount = 0);
    });
  }

  Future<void> _showPreviewSignInDialog() async {
    if (!mounted) return;

    if (kDebugMode) {
      debugPrint('Opening development login dialog');
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const DevelopmentPreviewSignInDialog(),
    );

    if (!mounted) return;
    setState(() => _logoClickCount = 0);
  }

  Widget _buildTappableLogo(BuildContext context) {
    final logoSize = _holdingLogoSize(context);

    return SizedBox(
      width: logoSize.width,
      height: logoSize.height,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => _handleLogoTap(),
        child: Center(
          child: IgnorePointer(
            child: VexdaLogo(
              height: logoSize.height,
              visualScale: 1,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SizedBox.expand(
      child: ColoredBox(
        color: AppColors.background,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTappableLogo(context),
                  const SizedBox(height: AppSpacing.xxl),
                  if (widget.showLoadingIndicator) ...[
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
                        if (widget.accessDeniedMessage != null) ...[
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            widget.accessDeniedMessage!,
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
        ),
      ),
    );
  }
}
