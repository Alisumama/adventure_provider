import 'package:get/get.dart';

import '../bindings/community_binding.dart';
import '../bindings/main_binding.dart';
import '../bindings/profile_binding.dart';
import '../bindings/track_binding.dart';

class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  /// Main app shell (bottom navigation + tabs).
  static const String home = '/home';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String verifyOtp = '/verify-otp';
  static const String resetPassword = '/reset-password';
  static const String changePassword = '/change-password';
  /// Named route pattern for [GetPage] (use [trackDetailNamed] to navigate).
  static const String trackDetailPattern = '/track-detail/:id';

  /// Backward-compatible path base (avoid for navigation; prefer [trackDetailNamed]).
  static const String trackDetail = '/track-detail';

  static String trackDetailNamed(String id) => '/track-detail/$id';
  static const String recordTrack = '/record-track';
  static const String liveSession = '/live-session';
  static const String groups = '/groups';
  static const String events = '/events';
  static const String profile = '/profile';

  /// Named route pattern for community detail.
  static const String communityDetailPattern = '/community-detail/:id';
  static const String communityDetail = '/community-detail';
  static String communityDetailNamed(String id) => '/community-detail/$id';

  static const String createCommunity = '/create-community';

  /// [GetPage.binding] for [home]: [NavigationController], [TrackRepository], [TrackController].
  static Bindings bindingHome() => MainBinding();

  /// [GetPage.binding] for track flows ([trackDetail], [recordTrack], …).
  static Bindings bindingTrack() => TrackBinding();

  /// [GetPage.binding] for profile flows.
  static Bindings bindingProfile() => ProfileBinding();

  /// [GetPage.binding] for community flows.
  static Bindings bindingCommunity() => CommunityBinding();
}
