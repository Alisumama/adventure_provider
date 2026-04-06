import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'core/bindings/initial_binding.dart';
import 'core/constants/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/views/forgot_password_screen.dart';
import 'features/auth/views/login_screen.dart';
import 'features/auth/views/reset_password_screen.dart';
import 'features/auth/views/signup_screen.dart';
import 'features/auth/views/verify_otp_screen.dart';
import 'features/community/views/community_detail_screen.dart';
import 'features/community/views/community_members_screen.dart';
import 'features/community/views/community_screen.dart';
import 'features/community/views/community_settings_screen.dart';
import 'features/community/views/create_community_screen.dart';
import 'features/profile/views/change_password_screen.dart';
import 'features/profile/views/profile_screen.dart';
import 'features/shell/main_shell_screen.dart';
import 'features/splash/splash_screen.dart';
import 'features/track/views/record_track_screen.dart';

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
          page: () => const MainShellScreen(),
          binding: AppRoutes.bindingHome(),
          transition: Transition.fadeIn,
          transitionDuration: const Duration(milliseconds: 300),
        ),
        GetPage(
          name: AppRoutes.community,
          page: () => const CommunityScreen(),
          binding: AppRoutes.bindingCommunity(),
        ),
        GetPage(
          name: AppRoutes.login,
          page: () => const LoginScreen(),
        ),
        GetPage(
          name: AppRoutes.register,
          page: () => const SignupScreen(),
        ),
        GetPage(
          name: AppRoutes.forgotPassword,
          page: () => const ForgotPasswordScreen(),
        ),
        GetPage(
          name: AppRoutes.verifyOtp,
          page: () => const VerifyOtpScreen(),
        ),
        GetPage(
          name: AppRoutes.resetPassword,
          page: () => const ResetPasswordScreen(),
        ),
        GetPage(
          name: AppRoutes.changePassword,
          page: () => const ChangePasswordScreen(),
          binding: AppRoutes.bindingProfile(),
        ),
        GetPage(
          name: AppRoutes.trackDetailPattern,
          page: () {
            final id = Get.parameters['id'] ?? '';
            return _PlaceholderScreen('${AppRoutes.trackDetail}/$id');
          },
          binding: AppRoutes.bindingTrack(),
        ),
        GetPage(
          name: AppRoutes.recordTrack,
          page: () => const RecordTrackScreen(),
          binding: AppRoutes.bindingTrack(),
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
          page: () => const ProfileScreen(),
          binding: AppRoutes.bindingProfile(),
        ),
        GetPage(
          name: AppRoutes.communityDetailPattern,
          page: () => const CommunityDetailScreen(),
          binding: AppRoutes.bindingCommunity(),
        ),
        GetPage(
          name: AppRoutes.editCommunityPattern,
          page: () {
            final id = Get.parameters['id'] ?? '';
            return _PlaceholderScreen('Edit community $id');
          },
          binding: AppRoutes.bindingCommunity(),
        ),
        GetPage(
          name: AppRoutes.createCommunity,
          page: () => const CreateCommunityScreen(),
          binding: AppRoutes.bindingCommunity(),
        ),
        GetPage(
          name: AppRoutes.communitySettings,
          page: () => const CommunitySettingsScreen(),
          binding: AppRoutes.bindingCommunity(),
        ),
        GetPage(
          name: AppRoutes.communityMembers,
          page: () => const CommunityMembersScreen(),
          binding: AppRoutes.bindingCommunity(),
        ),
      ],
    );
  }
}
