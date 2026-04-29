import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/api_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../track/controllers/track_controller.dart';
import '../../track/data/models/track_model.dart';
import '../controllers/community_controller.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key, required this.communityId});

  final String communityId;

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final CommunityController _c = Get.find<CommunityController>();
  final AuthController _auth = Get.find<AuthController>();

  final TextEditingController _contentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  final RxList<File> _selectedImages = <File>[].obs;
  final Rxn<TrackModel> _selectedTrack = Rxn<TrackModel>();
  final RxList<Map> _mentions = <Map>[].obs;
  final RxString _content = ''.obs;

  String get _communityName =>
      _c.selectedCommunity.value?.name ?? 'Community';

  @override
  void dispose() {
    _contentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onContentChanged(String v) {
    _content.value = v;

    final cursor = _contentController.selection.baseOffset;
    final text = _contentController.text;
    final pos = cursor < 0 ? text.length : cursor.clamp(0, text.length);

    final at = text.lastIndexOf('@', pos - 1);
    if (at < 0) {
      _c.clearMentions();
      return;
    }
    final after = text.substring(at + 1, pos);
    if (after.contains(' ') ||
        after.contains('\n') ||
        after.contains('\t')) {
      _c.clearMentions();
      return;
    }
    _c.searchMentions(widget.communityId, after);
  }

  void _insertMention(String username, String userId) {
    final text = _contentController.text;
    final sel = _contentController.selection;
    final cursor = sel.baseOffset < 0 ? text.length : sel.baseOffset;

    final at = text.lastIndexOf('@', cursor - 1);
    if (at < 0) return;

    final before = text.substring(0, at);
    final after = text.substring(cursor);
    final inserted = '@$username ';
    final nextText = '$before$inserted$after';

    _contentController.value = TextEditingValue(
      text: nextText,
      selection:
          TextSelection.collapsed(offset: (before + inserted).length),
    );

    _mentions.add({'userId': userId, 'username': username});
    _c.clearMentions();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picks = await picker.pickMultiImage(imageQuality: 85);
    if (picks.isEmpty) return;

    final remaining = 4 - _selectedImages.length;
    final toAdd =
        picks.take(remaining).map((x) => File(x.path)).toList();
    _selectedImages.addAll(toAdd);
  }

  void _showTrackPicker() {
    final trackController = Get.find<TrackController>();

    Get.bottomSheet<void>(
      Material(
        color: Colors.transparent,
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.darkBackground,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: const Color(0xFF444444),
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 12),
                Text('Attach a route',
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: Colors.white)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 320,
                  child: Obx(() {
                    final tracks = trackController.myTracks;
                    if (tracks.isEmpty) {
                      return Center(
                        child: Text('No tracks found',
                            style: GoogleFonts.poppins(
                                color: Colors.white70)),
                      );
                    }
                    return ListView.builder(
                      padding:
                          const EdgeInsets.fromLTRB(12, 8, 12, 12),
                      itemCount: tracks.length,
                      itemBuilder: (context, i) {
                        final t = tracks[i];
                        final cover =
                            ApiConfig.resolveMediaUrl(t.coverImage);
                        return ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              width: 44,
                              height: 44,
                              child: cover != null && cover.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: cover,
                                      fit: BoxFit.cover)
                                  : Container(
                                      color: AppColors.darkSurface,
                                      alignment: Alignment.center,
                                      child: const Icon(Icons.terrain,
                                          color: Colors.white),
                                    ),
                            ),
                          ),
                          title: Text(
                            t.title,
                            style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13),
                          ),
                          subtitle: Text(
                              '${t.type} · ${(t.distance / 1000).toStringAsFixed(1)} km',
                              style: GoogleFonts.poppins(
                                  color: AppColors.textSecondary,
                                  fontSize: 11)),
                          onTap: () {
                            _selectedTrack.value = t;
                            Get.back<void>();
                          },
                        );
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Future<void> _submit() async {
    final content = _contentController.text.trim();
    if (content.isEmpty && _selectedImages.isEmpty) return;

    final trackId = _selectedTrack.value?.id;
    await _c.createPostAdvanced(widget.communityId,
        content: content, trackId: trackId);
    Get.back<void>();
  }

  @override
  Widget build(BuildContext context) {
    final u = _auth.user.value;
    final avatar = ApiConfig.resolveMediaUrl(u?.profileImage);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Get.back<void>(),
        ),
        centerTitle: true,
        title: Text('New Post',
            style: GoogleFonts.bebasNeue(
                fontSize: 20, color: Colors.white)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: _submit,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 6),
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8)),
                child: Obx(() {
                  final submitting = _c.isCreating.value;
                  if (submitting) {
                    return const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white));
                  }
                  return Text(
                    'Post',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Colors.white),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor:
                              AppColors.primaryLight.withValues(alpha: 0.15),
                          backgroundImage:
                              avatar != null && avatar.isNotEmpty
                                  ? CachedNetworkImageProvider(avatar)
                                  : null,
                          child: (avatar == null || avatar.isEmpty)
                              ? Text(
                                  (u?.name?.isNotEmpty ?? false)
                                      ? u!.name![0].toUpperCase()
                                      : '?',
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primaryLight),
                                )
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              u?.name ?? 'You',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Colors.white),
                            ),
                            Text(_communityName,
                                style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: AppColors.primaryLight)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: _contentController,
                              focusNode: _focusNode,
                              minLines: 4,
                              maxLines: null,
                              style: GoogleFonts.poppins(
                                  fontSize: 14, color: Colors.black),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: 'What do you want to share?',
                                hintStyle: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: AppColors.textSecondary),
                              ),
                              onChanged: _onContentChanged,
                            ),
                            Obx(() {
                              if (!_c.showMentionDropdown.value ||
                                  _c.mentionSuggestions.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              return Container(
                                margin: const EdgeInsets.only(top: 4),
                                constraints:
                                    const BoxConstraints(maxHeight: 200),
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius:
                                        BorderRadius.circular(12)),
                                child: ListView.builder(
                                  itemCount:
                                      _c.mentionSuggestions.length,
                                  itemBuilder: (context, i) {
                                    final m = _c.mentionSuggestions[i];
                                    final name =
                                        (m['name'] ?? '').toString();
                                    final userId =
                                        (m['userId'] ?? '').toString();
                                    final profile =
                                        ApiConfig.resolveMediaUrl(
                                            m['profileImage']
                                                ?.toString());
                                    return ListTile(
                                      leading: CircleAvatar(
                                          radius: 16,
                                          backgroundImage: profile !=
                                                      null &&
                                                  profile.isNotEmpty
                                              ? CachedNetworkImageProvider(
                                                  profile)
                                              : null),
                                      title: Text(name,
                                          style: GoogleFonts.poppins(
                                              fontSize: 13)),
                                      onTap: () => _insertMention(
                                          name, userId),
                                    );
                                  },
                                ),
                              );
                            }),
                            const SizedBox(height: 16),
                            Obx(() {
                              final t = _selectedTrack.value;
                              if (t == null) {
                                return const SizedBox.shrink();
                              }
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                    color: const Color(0xFF1E2A1E),
                                    borderRadius:
                                        BorderRadius.circular(12)),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '📍 ${t.title}',
                                        style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                            color:
                                                AppColors.primaryLight),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close,
                                          color:
                                              AppColors.textSecondary),
                                      onPressed: () =>
                                          _selectedTrack.value = null,
                                    ),
                                  ],
                                ),
                              );
                            }),
                            Obx(() {
                              if (_selectedImages.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: SizedBox(
                                  height: 90,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _selectedImages.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(width: 10),
                                    itemBuilder: (context, i) {
                                      final f = _selectedImages[i];
                                      return Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(
                                                    10),
                                            child: Image.file(f,
                                                width: 80,
                                                height: 80,
                                                fit: BoxFit.cover),
                                          ),
                                          Positioned(
                                            right: 4,
                                            top: 4,
                                            child: GestureDetector(
                                              onTap: () =>
                                                  _selectedImages
                                                      .removeAt(i),
                                              child: Container(
                                                width: 18,
                                                height: 18,
                                                decoration: BoxDecoration(
                                                    color: Colors.black
                                                        .withValues(
                                                            alpha: 0.6),
                                                    shape: BoxShape
                                                        .circle),
                                                child: const Icon(
                                                    Icons.close,
                                                    size: 12,
                                                    color:
                                                        Colors.white),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Bottom toolbar
            Container(
              decoration: const BoxDecoration(
                border: Border(
                    top: BorderSide(color: Color(0xFF2A2A2A))),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _contentController,
                builder: (_, value, __) {
                  final len = value.text.length;
                  return Row(
                    children: [
                      GestureDetector(
                        onTap: _pickImages,
                        child: const Icon(Icons.image_outlined,
                            color: AppColors.primaryLight, size: 26),
                      ),
                      const SizedBox(width: 20),
                      GestureDetector(
                        onTap: _showTrackPicker,
                        child: const Icon(Icons.route,
                            color: AppColors.primaryLight, size: 26),
                      ),
                      const SizedBox(width: 20),
                      GestureDetector(
                        onTap: () {
                          _focusNode.requestFocus();
                          _contentController.text =
                              '${_contentController.text}@';
                          _contentController.selection =
                              TextSelection.collapsed(
                                  offset:
                                      _contentController.text.length);
                          _onContentChanged(_contentController.text);
                        },
                        child: Text(
                          '@',
                          style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryLight),
                        ),
                      ),
                      const Spacer(),
                      Text('$len/500',
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppColors.textSecondary)),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
