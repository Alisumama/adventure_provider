import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const int _iconDurationMs = 800;
  static const int _appNameDelayMs = 300;
  static const int _appNameDurationMs = 400;
  static const int _taglineDelayMs = 200;
  static const int _taglineDurationMs = 300;

  late AnimationController _controller;
  late Animation<double> _iconFade;
  late Animation<Offset> _iconSlide;
  late Animation<double> _appNameFade;
  late Animation<double> _appNameScale;
  late Animation<double> _taglineFade;

  @override
  void initState() {
    super.initState();
    // Icon 0–800ms, app name starts 300ms after icon (1100ms), tagline 200ms after app name (1500ms)
    final totalMs = _iconDurationMs + _appNameDelayMs + _appNameDurationMs +
        _taglineDelayMs + _taglineDurationMs;
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: totalMs),
    );

    final iconEnd = _iconDurationMs / totalMs;
    final appNameStart = (_iconDurationMs + _appNameDelayMs) / totalMs;
    final appNameEnd = (_iconDurationMs + _appNameDelayMs + _appNameDurationMs) / totalMs;
    final taglineStart = (_iconDurationMs + _appNameDelayMs + _appNameDurationMs + _taglineDelayMs) / totalMs;
    const taglineEnd = 1.0;

    _iconFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0, iconEnd, curve: Curves.easeOut),
      ),
    );
    _iconSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0, iconEnd, curve: Curves.easeOut),
      ),
    );
    _appNameFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(appNameStart, appNameEnd, curve: Curves.easeOut),
      ),
    );
    _appNameScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(appNameStart, appNameEnd, curve: Curves.easeOut),
      ),
    );
    _taglineFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(taglineStart, taglineEnd, curve: Curves.easeOut),
      ),
    );

    // Defer animation start to after first frame to avoid "System UI not responding" on slow emulators
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.forward();
    });

    // Navigation is handled by AuthController auto-login.
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryDark,
              AppColors.primary,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          return FadeTransition(
                            opacity: _iconFade,
                            child: SlideTransition(
                              position: _iconSlide,
                              child: child,
                            ),
                          );
                        },
                        child: const SizedBox(
                          width: 72,
                          height: 72,
                          child: Icon(
                            Icons.terrain,
                            size: 72,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          return FadeTransition(
                            opacity: _appNameFade,
                            child: ScaleTransition(
                              scale: _appNameScale,
                              child: child,
                            ),
                          );
                        },
                        child: Text(
                          'Adventure Providers',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          return FadeTransition(
                            opacity: _taglineFade,
                            child: child,
                          );
                        },
                        child: Text(
                          'EXPLORE. TRACK. SHARE.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: AppColors.primaryLight,
                            letterSpacing: 3.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 48),
                child: Center(
                  child: SizedBox(
                    width: 80,
                    height: 2,
                    child: LinearProgressIndicator(
                      minHeight: 2,
                      color: AppColors.primaryLight,
                      backgroundColor: Colors.transparent,
                    ),
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
