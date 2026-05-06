import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/widgets/auth_button.dart';
import '../../auth/widgets/auth_text_field.dart';
import '../controllers/community_controller.dart';

/// Dark theme create-community form.
class CreateCommunityScreen extends StatefulWidget {
  const CreateCommunityScreen({super.key});

  @override
  State<CreateCommunityScreen> createState() => _CreateCommunityScreenState();
}

class _CreateCommunityScreenState extends State<CreateCommunityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _picker = ImagePicker();

  CommunityController get _controller => Get.find<CommunityController>();

  File? _imageFile;
  File? _coverImageFile;
  String? _visibility;
  String? _category;

  static const _tips = <String>[
    'Use a clear name that describes your adventure focus',
    'Add a good photo — communities with images get 3x more joins',
    'Write a description that tells people what to expect',
    'Start with Public visibility — you can change it later',
    'Post regularly to keep your community active',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade700,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final x = await _picker.pickImage(source: source, imageQuality: 85);
    if (x != null && mounted) {
      setState(() => _imageFile = File(x.path));
    }
  }

  Future<void> _pickCoverImage(ImageSource source) async {
    final x = await _picker.pickImage(source: source, imageQuality: 85);
    if (x != null && mounted) {
      setState(() => _coverImageFile = File(x.path));
    }
  }

  void _openImagePickerSheet() {
    Get.bottomSheet<void>(
      Container(
        decoration: const BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.white70),
                title: Text(
                  'Choose from gallery',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
                onTap: () async {
                  Get.back<void>();
                  await _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.white70),
                title: Text(
                  'Take a photo',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
                onTap: () async {
                  Get.back<void>();
                  await _pickImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _openCoverImagePickerSheet() {
    Get.bottomSheet<void>(
      Container(
        decoration: const BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.white70),
                title: Text(
                  'Choose cover from gallery',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
                onTap: () async {
                  Get.back<void>();
                  await _pickCoverImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.white70),
                title: Text(
                  'Take a cover photo',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
                onTap: () async {
                  Get.back<void>();
                  await _pickCoverImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onCreate() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_visibility == null) {
      _showError('Please select visibility (Public or Private).');
      return;
    }
    if (_category == null) {
      _showError('Please select a category.');
      return;
    }

    await _controller.createCommunity(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      visibility: _visibility!,
      category: _category!,
      imageFile: _imageFile,
      coverImageFile: _coverImageFile,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: Get.back,
        ),
        title: Text(
          'New Community',
          style: GoogleFonts.bebasNeue(
            fontSize: 22,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: _openCoverImagePickerSheet,
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: AppColors.darkSurface,
                    border: Border.all(
                      color: const Color(0xFF2A2A2A),
                    ),
                    image: _coverImageFile != null
                        ? DecorationImage(
                            image: FileImage(_coverImageFile!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _coverImageFile == null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.image_outlined,
                                color: Colors.white70,
                                size: 28,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Add Cover Image',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Align(
                          alignment: Alignment.topRight,
                          child: Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Cover',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: SizedBox(
                  width: 104,
                  height: 104,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 52,
                        backgroundColor: AppColors.darkSurface,
                        child: _imageFile != null
                            ? ClipOval(
                                child: Image.file(
                                  _imageFile!,
                                  width: 104,
                                  height: 104,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Container(
                                width: 104,
                                height: 104,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppColors.darkSurface,
                                      AppColors.darkSurface.withValues(alpha: 0.6),
                                    ],
                                  ),
                                ),
                                child: const Icon(
                                  Icons.terrain,
                                  color: Colors.white,
                                  size: 36,
                                ),
                              ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: GestureDetector(
                          onTap: _openImagePickerSheet,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Community Profile Photo',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 28),
              AuthTextField(
                controller: _nameController,
                label: 'Community Name',
                hint: 'e.g. Lahore Hikers Club',
                prefixIcon: Icons.group,
                fillColor: AppColors.darkSurface,
                validator: (v) {
                  final t = v?.trim() ?? '';
                  if (t.isEmpty) return 'Name is required';
                  if (t.length < 3) return 'At least 3 characters';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AuthTextField(
                controller: _descriptionController,
                label: 'Description',
                hint: 'What is this community about?',
                prefixIcon: Icons.description_outlined,
                fillColor: AppColors.darkSurface,
                keyboardType: TextInputType.multiline,
                maxLines: 4,
                minLines: 3,
                validator: (v) {
                  final t = v?.trim() ?? '';
                  if (t.isEmpty) return 'Description is required';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Text(
                'Visibility',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _VisibilityOptionCard(
                      selected: _visibility == 'public',
                      icon: Icons.public,
                      title: 'Public',
                      subtitle: 'Anyone can join',
                      onTap: () => setState(() => _visibility = 'public'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _VisibilityOptionCard(
                      selected: _visibility == 'private',
                      icon: Icons.lock_outline,
                      title: 'Private',
                      subtitle: 'Invite only',
                      onTap: () => setState(() => _visibility = 'private'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Category',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _CategoryOptionCard(
                      selected: _category == 'hiking',
                      icon: Icons.hiking,
                      label: 'Hiking',
                      onTap: () => setState(() => _category = 'hiking'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _CategoryOptionCard(
                      selected: _category == 'offroading',
                      icon: Icons.directions_car_outlined,
                      label: 'Off-Road',
                      onTap: () => setState(() => _category = 'offroading'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _CategoryOptionCard(
                      selected: _category == 'both',
                      icon: Icons.terrain,
                      label: 'Both',
                      onTap: () => setState(() => _category = 'both'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.darkSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF2D6A4F).withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.lightbulb_outline,
                          size: 18,
                          color: AppColors.accentLight,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Tips for a great community',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: AppColors.accentLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._tips.map(
                      (tip) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              size: 14,
                              color: AppColors.primaryLight,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                tip,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Obx(
                () => AuthButton(
                  label: 'Create Community',
                  isLoading: _controller.isCreating.value,
                  onPressed: _onCreate,
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _VisibilityOptionCard extends StatelessWidget {
  const _VisibilityOptionCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.darkSurface
              : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AppColors.primaryLight
                : const Color(0xFF2A2A2A),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 28,
              color: selected ? AppColors.primaryLight : AppColors.textSecondary,
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryOptionCard extends StatelessWidget {
  const _CategoryOptionCard({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.darkSurface
              : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AppColors.primaryLight
                : const Color(0xFF2A2A2A),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22,
              color: selected ? AppColors.primaryLight : AppColors.textSecondary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
