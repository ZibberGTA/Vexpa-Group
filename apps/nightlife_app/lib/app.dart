import 'package:flutter/material.dart';
import 'core/navigation/app_router.dart';
import 'core/theme/app_theme.dart';

class NightlifeApp extends StatelessWidget {
  const NightlifeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DrinkSpot',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,

      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}