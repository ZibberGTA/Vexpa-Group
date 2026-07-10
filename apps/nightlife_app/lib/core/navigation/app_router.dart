import 'package:flutter/material.dart';

import '../../features/auth/screens/auth_gate.dart';
import '../../features/auth/screens/business_login_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/navigation/main_navigation_screen.dart';
import '../../features/splash/screens/splash_screen.dart';

class AppRoutes {
  const AppRoutes._();

  static const splash = '/';
  static const authGate = '/auth-gate';
  static const login = '/login';
  static const register = '/register';
  static const businessLogin = '/business-login';
  static const home = '/home';
}

class AppRouter {
  const AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return _page(const SplashScreen(), settings);
      case AppRoutes.authGate:
        return _page(const AuthGate(), settings);
      case AppRoutes.login:
        return _page(const LoginScreen(), settings);
      case AppRoutes.register:
        return _page(const RegisterScreen(), settings);
      case AppRoutes.businessLogin:
        return _page(const BusinessLoginScreen(), settings);
      case AppRoutes.home:
        return _page(const MainNavigationScreen(), settings);
      default:
        return _page(const SplashScreen(), settings);
    }
  }

  static MaterialPageRoute<dynamic> _page(Widget child, RouteSettings settings) {
    return MaterialPageRoute<dynamic>(
      settings: settings,
      builder: (_) => child,
    );
  }
}
