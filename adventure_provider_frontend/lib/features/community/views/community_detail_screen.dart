import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../controllers/community_controller.dart';

/// Loads detail + posts for `Get.parameters['id']`.
class CommunityDetailScreen extends StatefulWidget {
  const CommunityDetailScreen({super.key});

  @override
  State<CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends State<CommunityDetailScreen> {
  @override
  void initState() {
    super.initState();
    final id = Get.parameters['id'];
    if (id != null && id.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final c = Get.find<CommunityController>();
        c.fetchCommunityDetail(id);
        c.fetchPosts(id, refresh: true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<CommunityController>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Obx(() {
          final name = c.selectedCommunity.value?.name ?? 'Community';
          return Text(name);
        }),
      ),
      body: Obx(() {
        if (c.isLoading.value && c.selectedCommunity.value == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final com = c.selectedCommunity.value;
        if (com == null) {
          return const Center(child: Text('Community not found'));
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(com.description ?? '', style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 16),
            Text('Posts: ${c.posts.length}'),
          ],
        );
      }),
    );
  }
}
