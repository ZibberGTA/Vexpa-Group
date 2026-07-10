import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'vexda_background.dart';

/// Compact hero fallback when a page section has no image of its own.
class AtmosphericPageBackground extends StatelessWidget {
  const AtmosphericPageBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surface.withValues(alpha: 0.72),
    );
  }
}

/// Legacy alias — prefer the root [VexdaGlobalBackground] shell.
@Deprecated('Global background is applied by VexdaAppShell.')
class NightlifeBackground extends StatelessWidget {
  const NightlifeBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const VexdaGlobalBackground();
  }
}
