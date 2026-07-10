import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class PremiumScaffold extends StatelessWidget {
  const PremiumScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.extendBody = false,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool extendBody;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: extendBody,
      backgroundColor: AppColors.background,
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: PremiumBackground(child: body),
    );
  }
}

class PremiumBackground extends StatelessWidget {
  const PremiumBackground({super.key, required this.child});

  static const String defaultBackgroundAsset = 'assets/backgrounds/background.png';

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: ColoredBox(color: AppColors.background),
        ),
        Positioned.fill(
          child: Image.asset(
            defaultBackgroundAsset,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            errorBuilder: (_, __, ___) => const ColoredBox(
              color: AppColors.background,
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.42),
            ),
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}

class PremiumGlassCard extends StatelessWidget {
  const PremiumGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.card.withOpacity(0.86),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.22),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) return content;

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: content,
    );
  }
}

class PremiumEmptyState extends StatelessWidget {
  const PremiumEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: PremiumGlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: AppColors.purple.withOpacity(0.14),
                child: Icon(icon, color: AppColors.purpleSoft, size: 34),
              ),
              const SizedBox(height: 18),
              Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(subtitle, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}
