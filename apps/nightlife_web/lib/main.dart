import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'core/constants/app_assets.dart';
import 'core/firebase/vexda_firebase.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/development_gate.dart';

Future<void> main() async {
  usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();
  await VexdaFirebase.initialize();
  runApp(const VexdaWebApp());
}

class VexdaWebApp extends StatefulWidget {
  const VexdaWebApp({super.key});

  @override
  State<VexdaWebApp> createState() => _VexdaWebAppState();
}

class _VexdaWebAppState extends State<VexdaWebApp> {
  var _backgroundPrecached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_backgroundPrecached) return;
    _backgroundPrecached = true;
    precacheImage(AppAssets.homeBackgroundImage, context).catchError((_) {
      // Homepage falls back to solid dark canvas via [VexdaBackground.errorBuilder].
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vexda',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      onGenerateRoute: AppRouter.onGenerateRoute,
      initialRoute: AppRouter.home,
      builder: (context, child) {
        return DevelopmentGate(
          appChild: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
