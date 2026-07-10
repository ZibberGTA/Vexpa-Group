import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import '../../core/constants/app_strings.dart';

class VexdaLogo extends StatelessWidget {
  const VexdaLogo({
    super.key,
    required this.height,
    this.visualScale = 1.18,
  });

  final double height;

  /// Compensates for transparent padding baked into the PNG export.
  ///
  /// TODO: Re-export `assets/images/vexda_logo.png` with tighter crop so this
  /// scale factor can be reduced or removed.
  final double visualScale;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppStrings.appName,
      image: true,
      child: SizedBox(
        height: height,
        child: ClipRect(
          child: Center(
            child: Transform.scale(
              scale: visualScale,
              child: Image.asset(
                AppAssets.vexdaLogo,
                height: height,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
