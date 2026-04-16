import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/constants/api_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/community_controller.dart';
import '../data/models/comment_model.dart';

class PostCommentsScreen extends StatefulWidget {
  const PostCommentsScreen({super.key});

  @override
  State<PostCommentsScreen> createState() => _PostCommentsScreenState();
}

class _PostCommentsScreenState extends State<PostCommentsScreen> {
  final CommunityController _c = Get.find<CommunityController>();
  final AuthController _auth = Get.find<AuthController>();

  final RxList<Map> _mentions = <Map>[].obs;
  final FocusNode _focusNode = FocusNode();

  String get _postId {
    final args = Get.arguments;
    return args is Map ? args['postId']?.toString() ?? '' : '';
  }

  String get _communityId {
    final args = Get.arguments;
    return args is Map ? args['communityId']?.toString() ?? '' : '';
  }

  @override
  void initState() {
    super.initState();
    final pid = _postId;
    if (pid.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _c.fetchComments(pid, refresh: true);
      });
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    final cursor = _c.commentController.selection.baseOffset;
    final text = _c.commentController.text;
    final pos = cursor < 0 ? text.length : cursor.clamp(0, text.length);
    final at = text.lastIndexOf('@', pos - 1);
    if (at < 0) {
      _c.clearMentions();
      return;
    }
    final after = text.substring(at + 1, pos);
    if (after.contains(' ') || after.contains('\n') || after.contains('\t')) {
      _c.clearMentions();
      return;
    }
    _c.searchMentions(_communityId, after);
  }

  void _insertMention(String username, String userId) {
    final text = _c.commentController.text;
    final sel = _c.commentController.selection;
    final cursor = sel.baseOffset < 0 ? text.length : sel.baseOffset;
    final at = text.lastIndexOf('@', cursor - 1);
    if (at < 0) return;
    final before = text.substring(0, at);
    final after = text.substring(cursor);
    final inserted = '@$username ';
    final nextText = '$before$inserted$after';
    _c.commentController.value = TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(offset: (before + inserted).length),
    );
    _mentions.add({'userId': userId, 'username': username});
    _c.clearMentions();
  }

  Future<void> _showCommentMenu(CommentModel cmt) async {
    Get.bottomSheet<void>(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.danger),
                title: Text(
                  'Delete',
                  style: GoogleFonts.poppins(color: AppColors.danger),
                ),
                onTap: () {
                  Get.back<void>();
                  _c.deleteComment(cmt.id, _postId);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextSpan _spanContentWithMentions(String text) {
    final reg = RegExp(r'@([A-Za-z0-9_]+)');
    final spans = <TextSpan>[];
    var last = 0;
    for (final m in reg.allMatches(text)) {
      if (m.start > last) {
        spans.add(TextSpan(text: text.substring(last, m.start)));
      }
      spans.add(
        TextSpan(
          text: text.substring(m.start, m.end),
          style: GoogleFonts.poppins(
            fontSize: 13,
            height: 1.4,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryLight,
          ),
        ),
      );
      last = m.end;
    }
    if (last < text.length) {
      spans.add(TextSpan(text: text.substring(last)));
    }
    return TextSpan(
      style: GoogleFonts.poppins(
        fontSize: 13,
        height: 1.4,
        color: AppColors.textPrimary,
      ),
      children: spans,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pid = _postId;
    final me = _auth.user.value?.id;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F0),
      appBar: AppBar(
        title: Text(
          'Comments',
          style: GoogleFonts.bebasNeue(fontSize: 22, color: Colors.white),
        ),
        backgroundColor: AppColors.darkBackground,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (_c.isCommentsLoading.value && _c.comments.isEmpty) {
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                  itemCount: 3,
                  itemBuilder: (_, __) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Shimmer.fromColors(
                      baseColor: const Color(0xFFE2EDE8),
                      highlightColor: Colors.white,
                      child: Container(
                        height: 90,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                );
              }

              if (_c.comments.isEmpty) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 60),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline,
                          size: 48,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No comments yet',
                          style: GoogleFonts.bebasNeue(
                            fontSize: 22,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Be the first to comment!',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final isAdmin = _c.selectedCommunity.value?.userRole == 'admin';
              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 8),
                itemCount: _c.comments.length,
                itemBuilder: (context, i) {
                  final cmt = _c.comments[i];
                  final mine = me != null && cmt.author.id == me;
                  final canDelete = mine || isAdmin;
                  final av = ApiConfig.resolveMediaUrl(cmt.author.profileImage);
                  final hasMention = cmt.content.contains('@');
                  return Container(
                    margin: const EdgeInsets.only(bottom: 1),
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    color: Colors.white,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
                          backgroundImage: av != null && av.isNotEmpty
                              ? CachedNetworkImageProvider(av)
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    cmt.author.name,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    cmt.timeAgo,
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  if (canDelete)
                                    IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                      icon: const Icon(
                                        Icons.more_vert,
                                        size: 16,
                                        color: AppColors.textSecondary,
                                      ),
                                      onPressed: () => _showCommentMenu(cmt),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              if (hasMention)
                                RichText(text: _spanContentWithMentions(cmt.content))
                              else
                                Text(
                                  cmt.content,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    height: 1.4,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => _c.toggleCommentLike(cmt.id),
                                    child: Row(
                                      children: [
                                        Icon(
                                          cmt.isLiked ? Icons.favorite : Icons.favorite_border,
                                          color: AppColors.danger,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${cmt.likesCount}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  GestureDetector(
                                    onTap: () => _focusNode.requestFocus(),
                                    child: Text(
                                      'Reply',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
          ),
          Obx(() {
            if (!_c.showMentionDropdown.value || _c.mentionSuggestions.isEmpty) {
              return const SizedBox.shrink();
            }
            return Container(
              margin: const EdgeInsets.all(8),
              constraints: const BoxConstraints(maxHeight: 160),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2EDE8)),
              ),
              child: ListView.builder(
                itemCount: _c.mentionSuggestions.length,
                itemBuilder: (context, i) {
                  final m = _c.mentionSuggestions[i];
                  final name = (m['name'] ?? '').toString();
                  final userId = (m['userId'] ?? '').toString();
                  final profile = ApiConfig.resolveMediaUrl(m['profileImage']?.toString());
                  return ListTile(
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundImage: profile != null && profile.isNotEmpty
                          ? CachedNetworkImageProvider(profile)
                          : null,
                    ),
                    title: Text(name, style: GoogleFonts.poppins(fontSize: 13)),
                    onTap: () => _insertMention(name, userId),
                  );
                },
              ),
            );
          }),
          Container(
            padding: EdgeInsets.fromLTRB(
              12,
              8,
              12,
              8 + MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: const Color(0xFFE2EDE8))),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
                  backgroundImage:
                      ApiConfig.resolveMediaUrl(_auth.user.value?.profileImage) != null
                          ? CachedNetworkImageProvider(
                              ApiConfig.resolveMediaUrl(_auth.user.value?.profileImage)!,
                            )
                          : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0EDE8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: _c.commentController,
                      focusNode: _focusNode,
                      style: GoogleFonts.poppins(fontSize: 13),
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: 'Write a comment...',
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      onChanged: _onChanged,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Obx(() {
                  if (_c.isSubmittingComment.value) {
                    return const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    );
                  }
                  return GestureDetector(
                    onTap: () => _c.submitComment(pid, _mentions.toList()),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                      ),
                      child: const Icon(Icons.send, color: Colors.white, size: 18),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

