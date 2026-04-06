import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/controllers/navigation_controller.dart';
import '../../core/theme/app_colors.dart';
import '../community/views/community_screen.dart';
import '../home/views/home_screen.dart';
import '../profile/views/profile_screen.dart';
import '../track/views/track_list_screen.dart';
import 'widgets/main_bottom_nav_bar.dart';
import 'widgets/sos_fab_overlay.dart';

class MainShellScreen extends StatelessWidget {
  const MainShellScreen({super.key});

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
            SizedBox.expand(child: CommunityScreen()),
            SizedBox.expand(child: ProfileScreen()),
          ],
        ),
      ),
      bottomNavigationBar: const MainBottomNavBar(),
    );
  }
}
