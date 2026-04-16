import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';

class ImageGalleryScreen extends StatefulWidget {
  const ImageGalleryScreen({super.key});

  @override
  State<ImageGalleryScreen> createState() => _ImageGalleryScreenState();
}

class _ImageGalleryScreenState extends State<ImageGalleryScreen> {
  late final List<String> _images;
  late final int _initial;
  late final PageController _pageController;

  final RxInt _currentPage = 0.obs;
  final RxBool _chromeVisible = true.obs;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    final raw = args is Map ? args['images'] : null;
    _images = raw is List ? raw.map((e) => e.toString()).toList() : <String>[];
    _initial = (args is Map ? args['initialIndex'] : null) is int
        ? args['initialIndex'] as int
        : int.tryParse((args is Map ? args['initialIndex'] : null)?.toString() ?? '') ?? 0;
    final safeInitial =
        _initial.clamp(0, _images.isEmpty ? 0 : _images.length - 1);
    _currentPage.value = safeInitial;
    _pageController = PageController(initialPage: safeInitial);
    _scheduleAutoHide();
  }

  void _scheduleAutoHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      _chromeVisible.value = false;
    });
  }

  void _onTap() {
    final next = !_chromeVisible.value;
    _chromeVisible.value = next;
    if (next) _scheduleAutoHide();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _onTap,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            if (_images.isEmpty)
              const Center(
                child: Text(
                  'No images',
                  style: TextStyle(color: Colors.white70),
                ),
              )
            else
              PageView.builder(
                controller: _pageController,
                itemCount: _images.length,
                onPageChanged: (i) {
                  _currentPage.value = i;
                  _chromeVisible.value = true;
                  _scheduleAutoHide();
                },
                itemBuilder: (_, i) {
                  final url = _images[i];
                  return InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 4.0,
                    child: Center(
                      child: CachedNetworkImage(
                        imageUrl: url,
                        fit: BoxFit.contain,
                        placeholder: (_, __) => const CircularProgressIndicator(
                          color: AppColors.primaryLight,
                        ),
                      ),
                    ),
                  );
                },
              ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Obx(() {
                return AnimatedOpacity(
                  opacity: _chromeVisible.value ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: AppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Get.back<void>(),
                    ),
                  ),
                );
              }),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 16,
              child: Obx(() {
                return AnimatedOpacity(
                  opacity: _chromeVisible.value ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Center(
                    child: Text(
                      '${_currentPage.value + 1} / ${_images.length}',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

