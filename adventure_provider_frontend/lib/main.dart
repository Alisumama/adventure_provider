import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'core/bindings/auth_binding.dart';
import 'core/bindings/initial_binding.dart';
import 'core/constants/app_routes.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/views/forgot_password_screen.dart';
import 'features/auth/views/login_screen.dart';
import 'features/auth/views/reset_password_screen.dart';
import 'features/auth/views/signup_screen.dart';
import 'features/auth/views/verify_otp_screen.dart';
import 'features/splash/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen(this.routeName);

  final String routeName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(routeName),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Adventure Providers',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      initialBinding: InitialBinding(),
      home: const SplashScreen(),
      defaultTransition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
      getPages: [
        GetPage(
          name: AppRoutes.splash,
          page: () => const SplashScreen(),
        ),
        GetPage(
          name: AppRoutes.home,
          page: () => _PlaceholderScreen(AppRoutes.home),
        ),
        GetPage(
          name: AppRoutes.login,
          page: () => const LoginScreen(),
          binding: AuthBinding(),
        ),
        GetPage(
          name: AppRoutes.register,
          page: () => const SignupScreen(),
          binding: AuthBinding(),
        ),
        GetPage(
          name: AppRoutes.forgotPassword,
          page: () => const ForgotPasswordScreen(),
          binding: AuthBinding(),
        ),
        GetPage(
          name: AppRoutes.verifyOtp,
          page: () => const VerifyOtpScreen(),
          binding: AuthBinding(),
        ),
        GetPage(
          name: AppRoutes.resetPassword,
          page: () => const ResetPasswordScreen(),
          binding: AuthBinding(),
        ),
        GetPage(
          name: AppRoutes.trackDetail,
          page: () => _PlaceholderScreen(AppRoutes.trackDetail),
        ),
        GetPage(
          name: AppRoutes.recordTrack,
          page: () => _PlaceholderScreen(AppRoutes.recordTrack),
        ),
        GetPage(
          name: AppRoutes.liveSession,
          page: () => _PlaceholderScreen(AppRoutes.liveSession),
        ),
        GetPage(
          name: AppRoutes.groups,
          page: () => _PlaceholderScreen(AppRoutes.groups),
        ),
        GetPage(
          name: AppRoutes.events,
          page: () => _PlaceholderScreen(AppRoutes.events),
        ),
        GetPage(
          name: AppRoutes.profile,
          page: () => _PlaceholderScreen(AppRoutes.profile),
        ),
      ],
    );
  }
}
