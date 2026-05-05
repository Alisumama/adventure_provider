import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/controllers/navigation_controller.dart';
import '../../core/theme/app_colors.dart';
import '../community/views/community_screen.dart';
import '../groups/views/groups_screen.dart';
import '../home/views/home_screen.dart';
import '../profile/views/profile_screen.dart';
import '../track/views/track_list_screen.dart';
import 'widgets/main_bottom_nav_bar.dart';
import 'widgets/sos_fab_overlay.dart';

/// Shell with green headers under the status bar (no cream “gap”).
class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  Worker? _chromeWorker;

  /// Transparent status bar + light icons so time/battery stay readable on green.
  static void _applyShellSystemUi() {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
  }

  @override
  void initState() {
    super.initState();
    final nav = Get.find<NavigationController>();
    _chromeWorker = ever(nav.currentIndex, (_) => _applyShellSystemUi());
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyShellSystemUi());
  }

  @override
  void dispose() {
    _chromeWorker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nav = Get.find<NavigationController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: const SosFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Obx(
        () => IndexedStack(
          index: nav.currentIndex.value,
          sizing: StackFit.expand,
          children: const [
            SizedBox.expand(child: HomeScreen()),
            SizedBox.expand(child: TrackListScreen()),
            SizedBox.expand(child: GroupsScreen()),
            SizedBox.expand(child: CommunityScreen()),
            SizedBox.expand(child: ProfileScreen()),
          ],
        ),
      ),
      bottomNavigationBar: const MainBottomNavBar(),
    );
  }
}
