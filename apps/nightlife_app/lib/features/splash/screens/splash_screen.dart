import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/navigation/app_router.dart';
import '../../../core/widgets/drinkspot_splash_background_data.dart';
import '../../startup/services/startup_data_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _introController;
  late final Animation<double> _fadeIn;
  late final Animation<double> _slideUp;
  late final Uint8List _backgroundBytes;

  static const _logoAsset = 'assets/vexda_logo.png';

  Timer? _messageTimer;
  int _messageIndex = 0;
  String? _warningText;
  String? _statusOverride;

  final List<String> _messages = const [
    'Looking for events...',
    'Finding deals...',
    'Finding venues...',
    'Checking happy hours...',
    'Discovering live music...',
    'Loading nightlife...',
  ];

  String get _statusText =>
      _statusOverride ?? _messages[_messageIndex % _messages.length];

  @override
  void initState() {
    super.initState();

    _backgroundBytes = base64Decode(
      drinkSpotSplashBackgroundBase64.replaceAll(RegExp(r'\s+'), ''),
    );

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _fadeIn = CurvedAnimation(
      parent: _introController,
      curve: Curves.easeOut,
    );

    _slideUp = Tween<double>(begin: 16, end: 0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: Curves.easeOutCubic,
      ),
    );

    _messageTimer = Timer.periodic(const Duration(milliseconds: 1400), (_) {
      if (!mounted) return;
      setState(() {
        _statusOverride = null;
        _messageIndex++;
      });
    });

    _startApp();
  }

  Future<void> _startApp() async {
    final minimumSplashTime = Future<void>.delayed(
      const Duration(milliseconds: 2600),
    );

    var route = AppRoutes.authGate;

    try {
      final user = await FirebaseAuth.instance.authStateChanges().first.timeout(
            const Duration(seconds: 5),
            onTimeout: () => FirebaseAuth.instance.currentUser,
          );

      if (user != null) {
        await user.reload();
        await StartupDataService.load(
          onStatus: (message) => _replaceCurrentMessage(message),
        );
      } else {
        _replaceCurrentMessage('Getting login ready...');
      }
    } catch (_) {
      _warningText = 'Startup took longer than expected. You can still continue.';
      route = AppRoutes.authGate;
    }

    await minimumSplashTime;

    if (!mounted) return;

    if (_warningText != null) {
      _showWarningThenContinue(route);
      return;
    }

    Navigator.of(context).pushReplacementNamed(route);
  }

  void _replaceCurrentMessage(String message) {
    if (!mounted) return;
    setState(() {
      _statusOverride = message;
    });
  }

  Future<void> _showWarningThenContinue(String route) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Still loading'),
        content: Text(
          _warningText ??
              'Some startup data could not load. The app will refresh after opening.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(route);
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _introController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05000D),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.memory(
              _backgroundBytes,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              gaplessPlayback: true,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.08),
                    Colors.transparent,
                    Colors.black.withOpacity(0.12),
                  ],
                  stops: const [0, 0.55, 1],
                ),
              ),
            ),
          ),
          SafeArea(
            child: AnimatedBuilder(
              animation: _introController,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeIn.value,
                  child: Transform.translate(
                    offset: Offset(0, _slideUp.value),
                    child: child,
                  ),
                );
              },
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final logoWidth = (constraints.maxWidth * 0.68).clamp(250.0, 380.0);
                  return Stack(
                    children: [
                      Align(
                        alignment: const Alignment(0, -0.40),
                        child: Image.asset(
                          _logoAsset,
                          width: logoWidth,
                          fit: BoxFit.contain,
                          gaplessPlayback: true,
                        ),
                      ),
                      Align(
                        alignment: const Alignment(0, 0.20),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: _RotatingStatusText(statusText: _statusText),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RotatingStatusText extends StatelessWidget {
  const _RotatingStatusText({required this.statusText});

  final String statusText;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width - 48,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF05000D).withOpacity(0.62),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9D28FF).withOpacity(0.22),
            blurRadius: 30,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.28),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const _LoadingDots(),
          const SizedBox(width: 12),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.28),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: Text(
                statusText,
                key: ValueKey(statusText),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.90),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.15,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const _LoadingDots(),
        ],
      ),
    );
  }
}

class _LoadingDots extends StatefulWidget {
  const _LoadingDots();

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final phase = (_controller.value + (index * 0.18)) % 1;
            final opacity = phase < 0.5 ? 0.35 + phase : 0.85 - (phase - 0.5);
            return Container(
              width: 9,
              height: 9,
              margin: EdgeInsets.only(right: index == 2 ? 0 : 6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF9D28FF).withOpacity(opacity.clamp(0.35, 0.9).toDouble()),
              ),
            );
          }),
        );
      },
    );
  }
}
