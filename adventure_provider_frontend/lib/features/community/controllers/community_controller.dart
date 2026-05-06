import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/controllers/auth_controller.dart';
import '../data/models/announcement_model.dart';
import '../data/models/comment_model.dart';
import '../data/models/community_member_model.dart';
import '../data/models/community_model.dart';
import '../data/models/community_event_model.dart';
import '../data/models/community_post_model.dart';
import '../data/models/community_rule_model.dart';
import '../data/models/reaction_summary_model.dart';
import '../data/repositories/community_repository.dart';

class CommunityController extends GetxController {
  CommunityController(this._repository);

  final CommunityRepository _repository;

  final RxList<CommunityModel> communities = <CommunityModel>[].obs;
  final RxList<CommunityModel> filteredCommunities = <CommunityModel>[].obs;
  final Rxn<CommunityModel> selectedCommunity = Rxn<CommunityModel>();

  final RxList<CommunityPostModel> posts = <CommunityPostModel>[].obs;

  final RxList<CommentModel> comments = <CommentModel>[].obs;
  final RxList<CommunityEventModel> events = <CommunityEventModel>[].obs;
  final RxList<AnnouncementModel> announcements = <AnnouncementModel>[].obs;
  final RxList<CommunityRuleModel> rules = <CommunityRuleModel>[].obs;
  final RxList<Map> mentionSuggestions = <Map>[].obs;

  final RxBool isLoading = false.obs;
  final RxBool isPostsLoading = false.obs;
  final RxBool isCreating = false.obs;
  final RxBool isCommentsLoading = false.obs;
  final RxBool isEventsLoading = false.obs;
  final RxBool isAnnouncementsLoading = false.obs;
  final RxBool isMentionLoading = false.obs;
  final RxBool isSubmittingComment = false.obs;

  final RxString searchQuery = ''.obs;
  final RxString selectedCategory = ''.obs;
  final RxString activePostId = ''.obs;
  final RxBool showMentionDropdown = false.obs;
  final RxInt selectedTab = 0.obs; // 0=Posts, 1=Announcements, 2=Events, 3=Rules

  final RxInt currentPostsPage = 1.obs;
  final RxBool hasMorePosts = true.obs;

  final RxList<CommunityMemberModel> members = <CommunityMemberModel>[].obs;
  final RxBool isMembersLoading = false.obs;
  final RxBool isSettingsLoading = false.obs;

  late final TextEditingController searchController;
  late final TextEditingController postContentController;
  late final TextEditingController editNameController;
  late final TextEditingController editDescriptionController;
  late final TextEditingController commentController;
  late final TextEditingController announcementTitleController;
  late final TextEditingController announcementContentController;

  Timer? _searchDebounce;

  /// Ignores stale [getCommunityPosts] responses after switching communities.
  String? _postsFetchCommunityId;
  int _postsFetchGeneration = 0;

  String _cleanError(Object e) =>
      e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');

  Map<String, dynamic> _asJsonMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    throw Exception('Invalid response');
  }

  CommunityModel _communityFromResponseMap(Map<String, dynamic> json) {
    final raw = json['community'] ?? json['data'] ?? json;
    if (raw is Map) {
      final base = CommunityModel.fromJson(_asJsonMap(raw));
      // Backend often sends isMember / userRole on the root (not inside community).
      return base.copyWith(
        isMember: json['isMember'] is bool ? json['isMember'] as bool : base.isMember,
        userRole:
            json.containsKey('userRole') ? json['userRole'] as String? : base.userRole,
      );
    }
    throw Exception('Invalid community');
  }

  List<CommunityModel> _parseCommunityList(Map<String, dynamic> json) {
    final list = json['communities'] ?? json['data'] ?? json['results'];
    if (list is! List) return [];
    return list
        .map((e) =>
            CommunityModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  List<CommunityMemberModel> _parseMembersList(Map<String, dynamic> json) {
    final list = json['members'] ?? json['data'];
    if (list is! List) return [];
    return list
        .whereType<Map>()
        .map((e) => CommunityMemberModel.fromJson(_asJsonMap(e)))
        .toList();
  }

  List<CommunityPostModel> _parsePostList(Map<String, dynamic> json) {
    final list = json['posts'] ?? json['data'] ?? json['results'];
    if (list is! List) return [];
    return list.map((e) {
      if (e is! Map) {
        throw Exception('Invalid post in list');
      }
      return CommunityPostModel.fromJson(_asJsonMap(e));
    }).toList();
  }

  List<CommentModel> _parseCommentList(Map<String, dynamic> json) {
    final list = json['comments'] ?? json['data'] ?? json['results'];
    if (list is! List) return [];
    return list
        .whereType<Map>()
        .map((e) => CommentModel.fromJson(_asJsonMap(e)))
        .toList();
  }

  List<CommunityEventModel> _parseEventList(Map<String, dynamic> json) {
    final list = json['events'] ?? json['data'] ?? json['results'];
    if (list is! List) return [];
    return list
        .whereType<Map>()
        .map((e) => CommunityEventModel.fromJson(_asJsonMap(e)))
        .toList();
  }

  List<AnnouncementModel> _parseAnnouncementList(Map<String, dynamic> json) {
    final list = json['announcements'] ?? json['data'] ?? json['results'];
    if (list is! List) return [];
    return list
        .whereType<Map>()
        .map((e) => AnnouncementModel.fromJson(_asJsonMap(e)))
        .toList();
  }

  List<CommunityRuleModel> _parseRulesList(Map<String, dynamic> json) {
    final list = json['rules'] ?? json['data'] ?? json['results'];
    if (list is! List) return [];
    return list
        .whereType<Map>()
        .map((e) => CommunityRuleModel.fromJson(_asJsonMap(e)))
        .toList();
  }

  bool _parseHasMore(Map<String, dynamic> json, int fetchedCount) {
    final direct = json['hasMore'];
    if (direct is bool) return direct;
    final pagination = json['pagination'];
    if (pagination is Map) {
      final hm = pagination['hasMore'] ?? pagination['has_next'];
      if (hm is bool) return hm;
    }
    final meta = json['meta'];
    if (meta is Map) {
      final hm = meta['hasMore'];
      if (hm is bool) return hm;
    }
    return fetchedCount >= 10;
  }

  CommunityPostModel _postFromResponseMap(Map<String, dynamic> json) {
    final raw = json['post'] ?? json['data'] ?? json;
    if (raw is Map) {
      return CommunityPostModel.fromJson(_asJsonMap(raw));
    }
    throw Exception('Invalid post');
  }

  String? _extractCommunityId(Map<String, dynamic> json) {
    final c = json['community'];
    if (c is Map) {
      final m = _asJsonMap(c);
      return m['_id']?.toString() ?? m['id']?.toString();
    }
    return json['_id']?.toString() ?? json['id']?.toString();
  }

  void _patchCommunityById(
    String id,
    CommunityModel Function(CommunityModel c) update,
  ) {
    void patch(RxList<CommunityModel> list) {
      final i = list.indexWhere((c) => c.id == id);
      if (i >= 0) list[i] = update(list[i]);
    }

    patch(communities);
    patch(filteredCommunities);
    final sel = selectedCommunity.value;
    if (sel != null && sel.id == id) {
      selectedCommunity.value = update(sel);
    }
  }

  @override
  void onInit() {
    super.onInit();
    searchController = TextEditingController();
    postContentController = TextEditingController();
    editNameController = TextEditingController();
    editDescriptionController = TextEditingController();
    commentController = TextEditingController();
    announcementTitleController = TextEditingController();
    announcementContentController = TextEditingController();
    fetchCommunities();
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    searchController.dispose();
    postContentController.dispose();
    editNameController.dispose();
    editDescriptionController.dispose();
    commentController.dispose();
    announcementTitleController.dispose();
    announcementContentController.dispose();
    super.onClose();
  }

  Future<void> fetchCommunities({bool refresh = false}) async {
    isLoading.value = true;
    try {
      final map = await _repository.getAllCommunities(
        search: searchQuery.value.isEmpty ? null : searchQuery.value,
        category: selectedCategory.value.isEmpty ? null : selectedCategory.value,
      );
      final list = _parseCommunityList(map);
      communities.assignAll(list);
      filteredCommunities.assignAll(list);
    } catch (e) {
      Get.snackbar(
        'Error',
        _cleanError(e),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> searchCommunities(String query) async {
    _searchDebounce?.cancel();
    searchQuery.value = query;
    await fetchCommunities();
  }

  /// Updates [searchQuery] immediately; debounces the network fetch (400ms).
  void scheduleSearchCommunities(String query) {
    searchQuery.value = query;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      fetchCommunities();
    });
  }

  void clearSearch() {
    _searchDebounce?.cancel();
    searchController.clear();
    searchCommunities('');
  }

  Future<void> setCategory(String category) async {
    selectedCategory.value = category;
    await fetchCommunities(refresh: true);
  }

  Future<void> fetchCommunityDetail(String communityId) async {
    if (selectedCommunity.value?.id != communityId) {
      selectedCommunity.value = null;
    }
    try {
      final map = await _repository.getCommunityDetail(communityId);
      selectedCommunity.value = _communityFromResponseMap(map);
    } catch (e) {
      Get.snackbar(
        'Error',
        _cleanError(e),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> joinCommunity(
    String communityId, {
    bool navigateToDetail = true,
  }) async {
    try {
      await _repository.joinCommunity(communityId);
      _patchCommunityById(
        communityId,
        (c) => c.copyWith(
          isMember: true,
          membersCount: c.membersCount + 1,
        ),
      );
      Get.snackbar(
        'Success',
        'Joined successfully! 🎉',
        snackPosition: SnackPosition.BOTTOM,
      );
      await fetchCommunityDetail(communityId);
      if (navigateToDetail) {
        await Get.toNamed(AppRoutes.communityDetailNamed(communityId));
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        _cleanError(e),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> leaveCommunity(String communityId) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Leave community?'),
        content: const Text(
          'You will no longer see posts from this community in your feed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _repository.leaveCommunity(communityId);
      _patchCommunityById(
        communityId,
        (c) => c.copyWith(
          isMember: false,
          membersCount: c.membersCount > 0 ? c.membersCount - 1 : 0,
        ),
      );
      Get.snackbar(
        'Left community',
        'You have left this community.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        _cleanError(e),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> createCommunity({
    required String name,
    required String description,
    required String visibility,
    required String category,
    File? imageFile,
    File? coverImageFile,
  }) async {
    isCreating.value = true;
    try {
      final map = await _repository.createCommunity(
        name: name,
        description: description,
        visibility: visibility,
        category: category,
      );
      final id = _extractCommunityId(map);
      if (imageFile != null && id != null && id.isNotEmpty) {
        await _repository.updateCommunityImage(id, imageFile);
      }
      if (coverImageFile != null && id != null && id.isNotEmpty) {
        await _repository.updateCommunityCoverImage(id, coverImageFile);
      }
      Get.snackbar(
        'Success',
        'Community created! 🏔️',
        snackPosition: SnackPosition.BOTTOM,
      );
      Get.back();
      await fetchCommunities();
    } catch (e) {
      Get.snackbar(
        'Error',
        _cleanError(e),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isCreating.value = false;
    }
  }

  Future<void> fetchPosts(String communityId, {bool refresh = false}) async {
    final effectiveRefresh = refresh || posts.isEmpty;
    if (_postsFetchCommunityId != communityId) {
      _postsFetchCommunityId = communityId;
      _postsFetchGeneration++;
    }
    if (effectiveRefresh) {
      currentPostsPage.value = 1;
      posts.clear();
      hasMorePosts.value = true;
    }
    if (!hasMorePosts.value && !effectiveRefresh) return;

    final generation = _postsFetchGeneration;
    isPostsLoading.value = true;
    try {
      final page = effectiveRefresh ? 1 : currentPostsPage.value;
      final map = await _repository.getCommunityPosts(
        communityId,
        page: page,
      );
      if (generation != _postsFetchGeneration) return;

      final list = _parsePostList(map);
      final hasMore = _parseHasMore(map, list.length);

      if (effectiveRefresh) {
        posts.assignAll(list);
      } else {
        posts.addAll(list);
      }
      hasMorePosts.value = hasMore;
      if (hasMore && list.isNotEmpty) {
        currentPostsPage.value = page + 1;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        _cleanError(e),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isPostsLoading.value = false;
    }
  }

  Future<void> createPost(String communityId) async {
    final content = postContentController.text.trim();
    if (content.isEmpty) return;

    try {
      final map = await _repository.createPost(
        communityId,
        content: content,
      );
      final post = _postFromResponseMap(map);
      posts.insert(0, post);
      postContentController.clear();

      _patchCommunityById(
        communityId,
        (c) => c.copyWith(totalPosts: c.totalPosts + 1),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        _cleanError(e),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Used by the new create-post bottom sheet (supports optional trackId).
  Future<void> createPostAdvanced(
    String communityId, {
    required String content,
    String? trackId,
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return;
    try {
      final map = await _repository.createPost(
        communityId,
        content: trimmed,
        trackId: trackId,
      );
      final post = _postFromResponseMap(map);
      posts.insert(0, post);
      _patchCommunityById(
        communityId,
        (c) => c.copyWith(totalPosts: c.totalPosts + 1),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        _cleanError(e),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> toggleLikePost(String postId) async {
    final i = posts.indexWhere((p) => p.id == postId);
    if (i < 0) return;

    final prev = posts[i];
    final nextLiked = !prev.isLiked;
    final nextCount = nextLiked
        ? prev.likesCount + 1
        : (prev.likesCount > 0 ? prev.likesCount - 1 : 0);
    posts[i] = prev.copyWith(isLiked: nextLiked, likesCount: nextCount);

    try {
      final map = await _repository.toggleLikePost(postId);
      final idx = posts.indexWhere((p) => p.id == postId);
      if (idx < 0) return;
      final cur = posts[idx];
      posts[idx] = cur.copyWith(
        isLiked: map['isLiked'] as bool? ?? cur.isLiked,
        likesCount: (map['likesCount'] as num?)?.toInt() ?? cur.likesCount,
      );
    } catch (e) {
      posts[i] = prev;
      Get.snackbar(
        'Error',
        _cleanError(e),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> deletePost(
    String postId, {
    bool showConfirmDialog = true,
  }) async {
    if (showConfirmDialog) {
      final confirmed = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Delete post?'),
          content: const Text('This cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    try {
      await _repository.deletePost(postId);
      posts.removeWhere((p) => p.id == postId);

      final cid = selectedCommunity.value?.id;
      if (cid != null) {
        _patchCommunityById(
          cid,
          (c) => c.copyWith(
            totalPosts: c.totalPosts > 0 ? c.totalPosts - 1 : 0,
          ),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        _cleanError(e),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // ── COMMENT METHODS ───────────────────────────────────
  Future<void> fetchComments(String postId, {bool refresh = false}) async {
    activePostId.value = postId;
    isCommentsLoading.value = true;
    try {
      final map = await _repository.getComments(postId, page: 1);
      final list = _parseCommentList(map);
      if (refresh) {
        comments.assignAll(list);
      } else {
        if (comments.isEmpty || activePostId.value != postId) {
          comments.assignAll(list);
        } else {
          comments.addAll(list);
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        _cleanError(e),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isCommentsLoading.value = false;
    }
  }

  Future<void> submitComment(String postId, List<Map> mentions) async {
    final content = commentController.text.trim();
    if (content.isEmpty) return;

    isSubmittingComment.value = true;
    try {
      final map = await _repository.addComment(
        postId,
        content: content,
        mentions: mentions,
      );
      final raw = map['comment'] ?? map['data'] ?? map;
      final created = raw is Map ? CommentModel.fromJson(_asJsonMap(raw)) : null;
      if (created != null) {
        comments.insert(0, created);
      }
      commentController.clear();

      final i = posts.indexWhere((p) => p.id == postId);
      if (i >= 0) {
        final p = posts[i];
        posts[i] = p.copyWith(commentsCount: p.commentsCount + 1);
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        _cleanError(e),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSubmittingComment.value = false;
    }
  }

  Future<void> deleteComment(String commentId, String postId) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete comment?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _repository.deleteComment(commentId);
      comments.removeWhere((c) => c.id == commentId);

      final i = posts.indexWhere((p) => p.id == postId);
      if (i >= 0) {
        final p = posts[i];
        final next = p.commentsCount > 0 ? p.commentsCount - 1 : 0;
        posts[i] = p.copyWith(commentsCount: next);
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        _cleanError(e),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> toggleCommentLike(String commentId) async {
    final i = comments.indexWhere((c) => c.id == commentId);
    if (i < 0) return;

    final prev = comments[i];
    final nextLiked = !prev.isLiked;
    final nextCount =
        nextLiked ? prev.likesCount + 1 : (prev.likesCount > 0 ? prev.likesCount - 1 : 0);
    comments[i] = prev.copyWith(isLiked: nextLiked, likesCount: nextCount);

    try {
      final map = await _repository.toggleCommentLike(commentId);
      final idx = comments.indexWhere((c) => c.id == commentId);
      if (idx < 0) return;
      final cur = comments[idx];
      comments[idx] = cur.copyWith(
        isLiked: map['isLiked'] as bool? ?? cur.isLiked,
        likesCount: (map['likesCount'] as num?)?.toInt() ?? cur.likesCount,
      );
    } catch (e) {
      comments[i] = prev;
      Get.snackbar(
        'Error',
        _cleanError(e),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // ── REACTION METHODS ──────────────────────────────────
  Future<void> reactToPost(String postId, String emoji) async {
    try {
      final map = await _repository.reactToPost(postId, emoji);
      final i = posts.indexWhere((p) => p.id == postId);
      if (i < 0) return;
      final p = posts[i];

      final countsRaw = map['reactionCounts'];
      final countsMap = countsRaw is Map<String, dynamic>
          ? countsRaw
          : (countsRaw is Map ? Map<String, dynamic>.from(countsRaw) : const <String, dynamic>{});

      final summary = ReactionSummaryModel.fromJson({
        'fire': countsMap['fire'],
        'heart': countsMap['heart'],
        'clap': countsMap['clap'],
        'wow': countsMap['wow'],
        'haha': countsMap['haha'],
        'strong': countsMap['strong'],
        'userReaction': map['userReaction'],
        'totalReactions': map['totalReactions'],
      });

      posts[i] = p.copyWith(reactionSummary: summary);
    } catch (e) {
      Get.snackbar(
        'Error',
        _cleanError(e),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // ── EVENT METHODS ─────────────────────────────────────
  Future<void> fetchEvents(String communityId, {bool upcoming = true}) async {
    isEventsLoading.value = true;
    try {
      final map = await _repository.getCommunityEvents(
        communityId,
        upcoming: upcoming,
      );
      events.assignAll(_parseEventList(map));
    } catch (e) {
      Get.snackbar('Error', _cleanError(e), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isEventsLoading.value = false;
    }
  }

  Future<void> joinEvent(String communityId, String eventId) async {
    try {
      await _repository.joinCommunityEvent(communityId, eventId);
      final i = events.indexWhere((e) => e.id == eventId);
      if (i >= 0) {
        final ev = events[i];
        events[i] = ev.copyWith(
          isJoined: true,
          participantsCount: ev.participantsCount + 1,
        );
      }
      Get.snackbar(
        'Success',
        'You joined the event! 🎉',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar('Error', _cleanError(e), snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> leaveEvent(String communityId, String eventId) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Leave event?'),
        content: const Text('You will lose your spot in this event.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _repository.leaveCommunityEvent(communityId, eventId);
      final i = events.indexWhere((e) => e.id == eventId);
      if (i >= 0) {
        final ev = events[i];
        final next = ev.participantsCount > 0 ? ev.participantsCount - 1 : 0;
        events[i] = ev.copyWith(isJoined: false, participantsCount: next);
      }
    } catch (e) {
      Get.snackbar('Error', _cleanError(e), snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> createEvent(String communityId, Map eventData) async {
    try {
      final map = await _repository.createCommunityEvent(
        communityId,
        Map<String, dynamic>.from(eventData),
      );
      final raw = map['event'] ?? map['data'] ?? map;
      if (raw is Map) {
        events.insert(0, CommunityEventModel.fromJson(_asJsonMap(raw)));
      }
      Get.snackbar(
        'Success',
        'Event created! 🏔️',
        snackPosition: SnackPosition.BOTTOM,
      );
      Get.back();
    } catch (e) {
      Get.snackbar('Error', _cleanError(e), snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> deleteEvent(String communityId, String eventId) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete event?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _repository.deleteCommunityEvent(communityId, eventId);
      events.removeWhere((e) => e.id == eventId);
    } catch (e) {
      Get.snackbar('Error', _cleanError(e), snackPosition: SnackPosition.BOTTOM);
    }
  }

  // ── ANNOUNCEMENT METHODS ──────────────────────────────
  Future<void> fetchAnnouncements(String communityId) async {
    isAnnouncementsLoading.value = true;
    try {
      final map = await _repository.getAnnouncements(communityId);
      announcements.assignAll(_parseAnnouncementList(map));
    } catch (e) {
      Get.snackbar('Error', _cleanError(e), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isAnnouncementsLoading.value = false;
    }
  }

  Future<void> createAnnouncement(String communityId, bool isPinned) async {
    final title = announcementTitleController.text.trim();
    final content = announcementContentController.text.trim();
    if (title.isEmpty || content.isEmpty) return;

    try {
      final map = await _repository.createAnnouncement(
        communityId,
        title: title,
        content: content,
        isPinned: isPinned,
      );
      final raw = map['announcement'] ?? map['data'] ?? map;
      if (raw is Map) {
        announcements.insert(0, AnnouncementModel.fromJson(_asJsonMap(raw)));
      }
      announcementTitleController.clear();
      announcementContentController.clear();
      Get.back();
    } catch (e) {
      Get.snackbar('Error', _cleanError(e), snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> togglePin(String announcementId) async {
    try {
      final map = await _repository.togglePinAnnouncement(announcementId);
      final pinned = map['isPinned'] as bool?;
      final i = announcements.indexWhere((a) => a.id == announcementId);
      if (i >= 0 && pinned != null) {
        final a = announcements[i];
        announcements[i] = a.copyWith(isPinned: pinned);
      }
    } catch (e) {
      Get.snackbar('Error', _cleanError(e), snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> deleteAnnouncement(String announcementId) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete announcement?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _repository.deleteAnnouncement(announcementId);
      announcements.removeWhere((a) => a.id == announcementId);
    } catch (e) {
      Get.snackbar('Error', _cleanError(e), snackPosition: SnackPosition.BOTTOM);
    }
  }

  // ── RULES METHODS ─────────────────────────────────────
  Future<void> fetchRules(String communityId) async {
    try {
      final map = await _repository.getCommunityRules(communityId);
      rules.assignAll(_parseRulesList(map));
    } catch (e) {
      Get.snackbar('Error', _cleanError(e), snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> saveRules(String communityId, List<CommunityRuleModel> updatedRules) async {
    try {
      final payload = updatedRules.map((r) => r.toJson()).toList();
      final map = await _repository.updateCommunityRules(communityId, payload);
      rules.assignAll(_parseRulesList(map));
      Get.snackbar(
        'Success',
        'Rules saved ✅',
        snackPosition: SnackPosition.BOTTOM,
      );
      Get.back();
    } catch (e) {
      Get.snackbar('Error', _cleanError(e), snackPosition: SnackPosition.BOTTOM);
    }
  }

  // ── MENTION METHODS ───────────────────────────────────
  Future<void> searchMentions(String communityId, String query) async {
    final q = query.trim();
    if (q.length < 1) {
      mentionSuggestions.clear();
      return;
    }

    isMentionLoading.value = true;
    try {
      final map = await _repository.getMembersForMention(communityId, q);
      final list = map['members'];
      if (list is List) {
        mentionSuggestions.assignAll(list.whereType<Map>().toList());
      } else {
        mentionSuggestions.clear();
      }
      showMentionDropdown.value = true;
    } catch (e) {
      Get.snackbar('Error', _cleanError(e), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isMentionLoading.value = false;
    }
  }

  void clearMentions() {
    mentionSuggestions.clear();
    showMentionDropdown.value = false;
  }

  Future<void> fetchMembers(String communityId) async {
    isMembersLoading.value = true;
    try {
      final map = await _repository.getCommunityMembers(communityId);
      final list = _parseMembersList(map);
      members.assignAll(list);
    } catch (e) {
      Get.snackbar(
        'Error',
        _cleanError(e),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isMembersLoading.value = false;
    }
  }

  Future<void> removeMember(
    String communityId,
    String userId,
    String memberName,
  ) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Are you sure you want to remove $memberName?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _repository.removeMember(communityId, userId);
      members.removeWhere((m) => m.userId == userId);
      _patchCommunityById(
        communityId,
        (c) => c.copyWith(
          membersCount: c.membersCount > 0 ? c.membersCount - 1 : 0,
        ),
      );
      Get.snackbar(
        'Member removed',
        '$memberName has been removed',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        _cleanError(e),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> promoteMember(String communityId, String userId) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Promote to Moderator'),
        content: const Text(
          'This member will be able to manage posts and remove members.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Promote'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _repository.promoteMember(communityId, userId);
      final i = members.indexWhere((m) => m.userId == userId);
      if (i >= 0) {
        members[i] = members[i].copyWith(role: 'moderator');
      }
      Get.snackbar(
        'Success',
        'Promoted to moderator ✅',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        _cleanError(e),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> demoteModerator(String communityId, String userId) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Demote moderator?'),
        content: const Text(
          'This member will become a regular member and lose moderator tools.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Demote'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _repository.demoteModerator(communityId, userId);
      final i = members.indexWhere((m) => m.userId == userId);
      if (i >= 0) {
        members[i] = members[i].copyWith(role: 'member');
      }
      Get.snackbar(
        'Success',
        'Demoted to member',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        _cleanError(e),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> transferAdmin(
    String communityId,
    String userId,
    String memberName,
  ) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Transfer Admin Role'),
        content: Text(
          'You will lose your admin privileges. '
          '$memberName will become the new admin. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text(
              'Transfer',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _repository.transferAdmin(communityId, userId);
      final myId = Get.find<AuthController>().user.value?.id;
      for (var i = 0; i < members.length; i++) {
        final m = members[i];
        if (m.userId == userId) {
          members[i] = m.copyWith(role: 'admin');
        } else if (myId != null && m.userId == myId) {
          members[i] = m.copyWith(role: 'member');
        }
      }
      final sel = selectedCommunity.value;
      if (sel != null && sel.id == communityId) {
        selectedCommunity.value = sel.copyWith(userRole: 'member');
      }
      Get.snackbar(
        'Success',
        'Admin role transferred to $memberName',
        snackPosition: SnackPosition.BOTTOM,
      );
      Get.back();
    } catch (e) {
      Get.snackbar(
        'Error',
        _cleanError(e),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> deleteCommunity(String communityId) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete Community'),
        content: const Text(
          'This will permanently delete the community '
          'and all its posts. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    isSettingsLoading.value = true;
    try {
      await _repository.deleteCommunity(communityId);
      communities.removeWhere((c) => c.id == communityId);
      filteredCommunities.removeWhere((c) => c.id == communityId);
      if (selectedCommunity.value?.id == communityId) {
        selectedCommunity.value = null;
      }
      Get.snackbar(
        'Success',
        'Community deleted',
        snackPosition: SnackPosition.BOTTOM,
      );
      Get.offAllNamed(AppRoutes.community);
    } catch (e) {
      Get.snackbar(
        'Error',
        _cleanError(e),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSettingsLoading.value = false;
    }
  }

  Future<void> updateCommunitySettings(
    String communityId, {
    String? name,
    String? description,
    String? visibility,
    String? category,
  }) async {
    final data = <String, dynamic>{
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (visibility != null) 'visibility': visibility,
      if (category != null) 'category': category,
    };
    if (data.isEmpty) return;

    isSettingsLoading.value = true;
    try {
      final map = await _repository.updateCommunity(communityId, data);
      final updated = _communityFromResponseMap(map);
      selectedCommunity.value = updated;
      _patchCommunityById(communityId, (_) => updated);
      Get.snackbar(
        'Success',
        'Settings saved ✅',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        _cleanError(e),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSettingsLoading.value = false;
    }
  }

  Future<void> updateCommunityImageFromSettings(
    String communityId,
    File imageFile,
  ) async {
    try {
      await _repository.updateCommunityImage(communityId, imageFile);
      await fetchCommunityDetail(communityId);
      Get.snackbar(
        'Success',
        'Community photo updated',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        _cleanError(e),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
