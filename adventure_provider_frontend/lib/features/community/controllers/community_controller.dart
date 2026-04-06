import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_routes.dart';
import '../data/models/community_model.dart';
import '../data/models/community_post_model.dart';
import '../data/repositories/community_repository.dart';

class CommunityController extends GetxController {
  CommunityController({required CommunityRepository repository})
      : _repository = repository;

  final CommunityRepository _repository;

  final RxList<CommunityModel> communities = <CommunityModel>[].obs;
  final RxList<CommunityModel> filteredCommunities = <CommunityModel>[].obs;
  final Rxn<CommunityModel> selectedCommunity = Rxn<CommunityModel>();

  final RxList<CommunityPostModel> posts = <CommunityPostModel>[].obs;

  final RxBool isLoading = false.obs;
  final RxBool isPostsLoading = false.obs;
  final RxBool isCreating = false.obs;

  final RxString searchQuery = ''.obs;
  final RxString selectedCategory = ''.obs;

  final RxInt currentPostsPage = 1.obs;
  final RxBool hasMorePosts = true.obs;

  final TextEditingController searchController = TextEditingController();
  final TextEditingController postContentController = TextEditingController();

  String _cleanError(Object e) =>
      e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');

  List<CommunityModel> _parseCommunityList(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .map((e) => CommunityModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> fetchCommunities({bool refresh = false}) async {
    isLoading.value = true;
    try {
      final data = await _repository.getAllCommunities(
        search: searchQuery.value.isEmpty ? null : searchQuery.value,
        category: selectedCategory.value.isEmpty ? null : selectedCategory.value,
      );
      final list = _parseCommunityList(data['communities']);
      communities.assignAll(list);
      filteredCommunities.assignAll(list);
    } catch (e) {
      Get.snackbar('Error', _cleanError(e), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> searchCommunities(String query) async {
    searchQuery.value = query;
    await fetchCommunities();
  }

  Future<void> setCategory(String category) async {
    selectedCategory.value = category;
    await fetchCommunities(refresh: true);
  }

  Future<void> fetchCommunityDetail(String communityId) async {
    isLoading.value = true;
    try {
      final data = await _repository.getCommunityDetail(communityId);
      selectedCommunity.value = CommunityModel.fromDetailResponse(
        Map<String, dynamic>.from(data),
      );
    } catch (e) {
      Get.snackbar('Error', _cleanError(e), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  void _patchCommunityInLists(String communityId, CommunityModel Function(CommunityModel) update) {
    bool applyToList(RxList<CommunityModel> list) {
      final i = list.indexWhere((c) => c.id == communityId);
      if (i < 0) return false;
      list[i] = update(list[i]);
      list.refresh();
      return true;
    }

    applyToList(communities);
    applyToList(filteredCommunities);
  }

  Future<void> joinCommunity(String communityId) async {
    try {
      await _repository.joinCommunity(communityId);
      _patchCommunityInLists(communityId, (c) {
        return c.copyWith(
          isMember: true,
          membersCount: (c.membersCount ?? 0) + 1,
        );
      });
      if (selectedCommunity.value?.id == communityId) {
        await fetchCommunityDetail(communityId);
      }
      Get.snackbar(
        'Success',
        'Joined successfully! 🎉',
        snackPosition: SnackPosition.BOTTOM,
      );
      await Get.toNamed(AppRoutes.communityDetailNamed(communityId));
    } catch (e) {
      Get.snackbar('Error', _cleanError(e), snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> leaveCommunity(String communityId) async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Leave community?'),
        content: const Text('You will no longer see posts in this community.'),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Get.back(result: true), child: const Text('Leave')),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _repository.leaveCommunity(communityId);
      _patchCommunityInLists(communityId, (c) {
        return c.copyWith(
          isMember: false,
          userRole: null,
          membersCount: ((c.membersCount ?? 1) - 1).clamp(0, 1 << 30),
        );
      });
      if (selectedCommunity.value?.id == communityId) {
        selectedCommunity.value = selectedCommunity.value?.copyWith(
          isMember: false,
          userRole: null,
        );
      }
      Get.snackbar('Success', 'You left the community', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', _cleanError(e), snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> createCommunity({
    required String name,
    required String description,
    required String visibility,
    required String category,
    File? imageFile,
  }) async {
    isCreating.value = true;
    try {
      final created = await _repository.createCommunity(
        name: name,
        description: description,
        visibility: visibility,
        category: category,
      );
      var model = CommunityModel.fromJson({
        ...created,
        'isMember': true,
        'userRole': 'admin',
      });

      final id = model.id;
      if (imageFile != null && id != null && id.isNotEmpty) {
        await _repository.updateCommunityImage(id, imageFile);
        final refreshed = await _repository.getCommunityDetail(id);
        model = CommunityModel.fromDetailResponse(Map<String, dynamic>.from(refreshed));
      }

      communities.insert(0, model);
      filteredCommunities.insert(0, model);
      communities.refresh();
      filteredCommunities.refresh();

      Get.snackbar(
        'Success',
        'Community created! 🏔️',
        snackPosition: SnackPosition.BOTTOM,
      );
      Get.back<void>();
    } catch (e) {
      Get.snackbar('Error', _cleanError(e), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isCreating.value = false;
    }
  }

  Future<void> fetchPosts(String communityId, {bool refresh = false}) async {
    if (!refresh && !hasMorePosts.value) return;

    if (refresh) {
      currentPostsPage.value = 1;
      posts.clear();
      hasMorePosts.value = true;
    }

    final pageToFetch = refresh ? 1 : currentPostsPage.value + 1;

    isPostsLoading.value = true;
    try {
      final data = await _repository.getCommunityPosts(
        communityId,
        page: pageToFetch,
      );
      final rawPosts = data['posts'] as List? ?? [];
      final mapped = rawPosts
          .map((e) => CommunityPostModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      if (refresh) {
        posts.assignAll(mapped);
      } else {
        posts.addAll(mapped);
      }

      final cur = (data['currentPage'] as num?)?.toInt() ?? pageToFetch;
      final total = (data['totalPages'] as num?)?.toInt() ?? 1;
      currentPostsPage.value = cur;
      hasMorePosts.value = cur < total;
    } catch (e) {
      Get.snackbar('Error', _cleanError(e), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isPostsLoading.value = false;
    }
  }

  Future<void> createPost(String communityId) async {
    final raw = postContentController.text.trim();
    if (raw.isEmpty) {
      Get.snackbar('Error', 'Write something first', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    try {
      final res = await _repository.createPost(communityId, content: raw);
      final post = CommunityPostModel.fromJson(res);
      posts.insert(0, post);
      postContentController.clear();

      final sel = selectedCommunity.value;
      if (sel?.id == communityId) {
        selectedCommunity.value = sel!.copyWith(
          totalPosts: (sel.totalPosts ?? 0) + 1,
        );
      }
      _patchCommunityInLists(communityId, (c) {
        return c.copyWith(totalPosts: (c.totalPosts ?? 0) + 1);
      });
    } catch (e) {
      Get.snackbar('Error', _cleanError(e), snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> toggleLikePost(String postId) async {
    final i = posts.indexWhere((p) => p.id == postId);
    if (i < 0) return;
    final old = posts[i];
    final nextLiked = !old.isLiked;
    final nextCount = (old.likesCount ?? 0) + (nextLiked ? 1 : -1);
    final safeCount = nextCount < 0 ? 0 : nextCount;
    posts[i] = old.copyWith(
      isLiked: nextLiked,
      likesCount: safeCount,
    );
    posts.refresh();

    try {
      final res = await _repository.toggleLikePost(postId);
      posts[i] = old.copyWith(
        isLiked: res['isLiked'] as bool? ?? nextLiked,
        likesCount: (res['likesCount'] as num?)?.toInt() ?? safeCount,
      );
      posts.refresh();
    } catch (e) {
      posts[i] = old;
      posts.refresh();
      Get.snackbar('Error', _cleanError(e), snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> deletePost(String postId) async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete post?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Get.back(result: true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _repository.deletePost(postId);
      final had = posts.any((p) => p.id == postId);
      posts.removeWhere((p) => p.id == postId);

      final cid = selectedCommunity.value?.id;
      if (cid != null) {
        _patchCommunityInLists(cid, (c) {
          final next = (c.totalPosts ?? 1) - 1;
          return c.copyWith(totalPosts: next < 0 ? 0 : next);
        });
        final sel = selectedCommunity.value;
        if (sel != null) {
          final next = (sel.totalPosts ?? 1) - 1;
          selectedCommunity.value = sel.copyWith(totalPosts: next < 0 ? 0 : next);
        }
      }
      if (had) {
        Get.snackbar('Success', 'Post removed', snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar('Error', _cleanError(e), snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  void onClose() {
    searchController.dispose();
    postContentController.dispose();
    super.onClose();
  }
}
