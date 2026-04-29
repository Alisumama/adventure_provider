import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

import '../bindings/community_binding.dart';
import '../bindings/main_binding.dart';
import '../bindings/profile_binding.dart';
import '../bindings/track_binding.dart';
import '../bindings/track_follow_binding.dart';

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

  /// Full-screen map for one track (polyline + flags).
  static const String trackMapViewPattern = '/track-map/:id';

  static String trackMapViewNamed(String id) => '/track-map/$id';

  /// Edit track (`Get.parameters['id']`). Placeholder until editor is implemented.
  static const String editTrackPattern = '/edit-track/:id';

  static String editTrackNamed(String id) => '/edit-track/$id';
  static const String recordTrack = '/record-track';
  /// Live OSM map while recording (Socket.io + draft track).
  static const String liveMapRecording = '/live-map-recording';

  /// Full-screen Google Map while following a published track; pass `TrackModel` as [Get.arguments].
  static const String followTrack = '/follow-track';
  static const String liveSession = '/live-session';
  static const String groups = '/groups';
  static const String events = '/events';
  static const String profile = '/profile';

  /// Community tab / list (same screen as embedded in shell; also used with [community] GetPage).
  static const String community = '/community';

  /// Base path for community detail (use [communityDetailNamed] or [communityDetailPattern] for routing).
  static const String communityDetail = '/community-detail';

  /// Community detail (`Get.parameters['id']`).
  static const String communityDetailPattern = '$communityDetail/:id';

  static String communityDetailNamed(String id) => '$communityDetail/$id';

  /// Create community (full-screen form).
  static const String createCommunity = '/create-community';

  /// Base path for edit community (use [editCommunityNamed] or [editCommunityPattern] for routing).
  static const String editCommunity = '/edit-community';

  /// Edit community (`Get.parameters['id']`).
  static const String editCommunityPattern = '$editCommunity/:id';

  static String editCommunityNamed(String id) => '$editCommunity/$id';

  /// Community settings (admin/moderator tools).
  static const String communitySettings = '/community-settings';

  /// Full member list for a community.
  static const String communityMembers = '/community-members';

  /// Post comments screen (expects Get.arguments { postId, communityId }).
  static const String postComments = '/post-comments';

  /// Image gallery viewer (expects Get.arguments { images: List<String>, initialIndex: int }).
  static const String imageGallery = '/image-gallery';

  /// Create community event screen (expects Get.arguments communityId).
  static const String createCommunityEvent = '/create-community-event';

  /// Edit rules screen (expects Get.arguments communityId).
  static const String editRules = '/edit-rules';

  /// Group detail (`Get.parameters['id']`).
  static const String groupDetail = '/group-detail';
  static const String groupDetailPattern = '$groupDetail/:id';
  static String groupDetailNamed(String id) => '$groupDetail/$id';

  /// Full-screen explore map showing user location and nearby tracks.
  static const String exploreMap = '/explore-map';

  /// Live group tracking screen (expects Get.arguments groupId).
  static const String liveGroupTracking = '/live-group-tracking';

  /// [GetPage.binding] for [home]: [NavigationController], [TrackRepository], [TrackController].
  static Bindings bindingHome() => MainBinding();

  /// [GetPage.binding] for track flows ([trackDetail], [recordTrack], …).
  static Bindings bindingTrack() => TrackBinding();

  /// [GetPage.binding] for profile flows.
  static Bindings bindingProfile() => ProfileBinding();

  /// [GetPage.binding] for community flows.
  static Bindings bindingCommunity() => CommunityBinding();

  /// [GetPage.binding] for [followTrack] (Google Map follow session).
  static Bindings bindingFollowTrack() => BindingsBuilder(() {
        if (!Get.isRegistered<Connectivity>()) {
          Get.put<Connectivity>(Connectivity(), permanent: true);
        }
        TrackFollowBinding().dependencies();
      });
}
