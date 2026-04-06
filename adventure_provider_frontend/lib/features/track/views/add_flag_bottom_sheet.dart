import 'dart:io' show File;
import 'dart:typed_data' show Uint8List;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../../core/constants/api_config.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/track_controller.dart';
import '../data/models/add_flag_data.dart';
import '../data/models/track_model.dart' as tm;
import '../track_flag_type_style.dart';

/// Flag type values sent to the backend / Socket `add_flag`.
const List<String> kTrackFlagTypeValues = [
  'rest_area',
  'water_stream',
  'steep_incline',
  'viewpoint',
  'hazard',
  'other',
];

/// Add or edit a flag: live recording (Socket), or track detail (REST).
class AddFlagBottomSheet extends StatefulWidget {
  const AddFlagBottomSheet({
    super.key,
    this.existingFlag,
    this.trackIdForDetail,
  });

  /// When set, sheet opens in edit mode with fields pre-filled.
  final tm.TrackFlag? existingFlag;

  /// When set, saves via REST for this track (not live Socket). Ignored for live flow.
  final String? trackIdForDetail;

  static Future<void> show(
    BuildContext context, {
    tm.TrackFlag? existingFlag,
    String? trackId,
  }) async {
    final c = Get.find<TrackController>();
    final pauseForLive = c.liveTrackId.value.isNotEmpty && trackId == null;
    if (pauseForLive) {
      await c.pauseGps();
    }
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => AddFlagBottomSheet(
        existingFlag: existingFlag,
        trackIdForDetail: trackId,
      ),
    ).whenComplete(() {
      if (pauseForLive) {
        c.resumeGps();
      }
    });
  }

  @override
  State<AddFlagBottomSheet> createState() => _AddFlagBottomSheetState();
}

class _AddFlagBottomSheetState extends State<AddFlagBottomSheet> {
  final MapController _mapController = MapController();
  final TextEditingController _notes = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  late ll.LatLng _pinLatLng;
  String _flagType = kTrackFlagTypeValues.first;
  final List<XFile> _images = <XFile>[];
  final List<String> _existingImageUrls = <String>[];
  bool _saving = false;

  bool get _isEditMode => widget.existingFlag != null;

  int get _totalImageCount => _existingImageUrls.length + _images.length;

  String _normalizeFlagType(String? t) {
    final s = t?.trim() ?? '';
    if (s.isEmpty) return 'other';
    return kTrackFlagTypeValues.contains(s) ? s : 'other';
  }

  InputDecoration _dropdownShellDecoration() {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.homeHeaderBorder),
    );
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: AppColors.primaryLight, width: 1.5),
      ),
    );
  }

  InputDecoration _notesDecoration(String label) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.homeHeaderBorder),
    );
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 14),
      floatingLabelStyle: GoogleFonts.poppins(color: AppColors.primaryLight),
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: AppColors.primaryLight, width: 1.5),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    final c = Get.find<TrackController>();
    final ef = widget.existingFlag;
    final detailId = widget.trackIdForDetail;

    if (ef != null) {
      _flagType = _normalizeFlagType(ef.type);
      _notes.text = ef.description ?? '';
      _pinLatLng = ll.LatLng(ef.lat, ef.lng);
      if (ef.images.isNotEmpty) {
        _existingImageUrls.addAll(ef.images);
      } else if (ef.photo != null && ef.photo!.trim().isNotEmpty) {
        _existingImageUrls.add(ef.photo!.trim());
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        try {
          _mapController.move(_pinLatLng, 16);
        } catch (_) {}
      });
    } else if (detailId != null && detailId.isNotEmpty) {
      final st = c.selectedTrack.value;
      if (st != null && st.geoPath.isNotEmpty) {
        final p = st.geoPath.first;
        _pinLatLng = ll.LatLng(p.latitude, p.longitude);
      } else {
        final cl = c.currentLocation.value;
        if (cl != null) {
          _pinLatLng = ll.LatLng(cl.latitude, cl.longitude);
        } else {
          _pinLatLng = const ll.LatLng(20, 0);
        }
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _maybeRefinePinFromGps();
      });
    } else {
      final cl = c.currentLocation.value;
      if (cl != null) {
        _pinLatLng = ll.LatLng(cl.latitude, cl.longitude);
      } else if (c.pathPoints.isNotEmpty) {
        final p = c.pathPoints.last;
        _pinLatLng = ll.LatLng(p.latitude, p.longitude);
      } else {
        _pinLatLng = const ll.LatLng(20, 0);
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _maybeRefinePinFromGps();
      });
    }
  }

  Future<void> _maybeRefinePinFromGps() async {
    final c = Get.find<TrackController>();
    if (c.currentLocation.value != null || c.pathPoints.isNotEmpty) {
      return;
    }
    try {
      final pos = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _pinLatLng = ll.LatLng(pos.latitude, pos.longitude);
      });
      _mapController.move(_pinLatLng, 16);
    } catch (_) {
      // Keep default center; user can pan/zoom and tap to place the pin.
    }
  }

  Future<ImageSource?> _askImageSource(BuildContext context) {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                  child: Text(
                    'Add photo',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.photo_camera_outlined, color: AppColors.primary),
                  title: Text(
                    'Camera',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  onTap: () => Navigator.pop(ctx, ImageSource.camera),
                ),
                ListTile(
                  leading: Icon(Icons.photo_library_outlined, color: AppColors.primary),
                  title: Text(
                    'Gallery',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage(BuildContext context) async {
    if (_totalImageCount >= 3) return;
    if (!mounted) return;
    final source = await _askImageSource(context);
    if (source == null || !mounted) return;
    final x = await _picker.pickImage(
      source: source,
      imageQuality: 85,
    );
    if (x == null || !mounted) return;
    setState(() => _images.add(x));
  }

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
  }

  void _removeExistingUrl(int index) {
    setState(() => _existingImageUrls.removeAt(index));
  }

  Future<void> _onSave() async {
    if (_saving) return;
    final track = Get.find<TrackController>();
    final detailId = widget.trackIdForDetail;

    final data = AddFlagData(
      type: _flagType,
      description: _notes.text.trim(),
      images: List<XFile>.from(_images),
      coordinate: tm.LatLng(_pinLatLng.latitude, _pinLatLng.longitude),
      existingImageUrls: List<String>.from(_existingImageUrls),
    );

    if (detailId != null && detailId.isNotEmpty) {
      setState(() => _saving = true);
      try {
        if (_isEditMode) {
          final fid = widget.existingFlag!.id;
          if (fid == null || fid.isEmpty) {
            Get.snackbar(
              'Flag',
              'This flag cannot be updated.',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: AppColors.darkSurface,
              colorText: AppColors.surface,
            );
          } else {
            await track.editFlag(fid, data);
            if (mounted) {
              Navigator.of(context).pop();
            }
          }
        } else {
          await track.addFlagToTrack(data);
          if (mounted) {
            Navigator.of(context).pop();
          }
        }
      } finally {
        if (mounted) {
          setState(() => _saving = false);
        }
      }
      return;
    }

    final tid = track.liveTrackId.value;
    if (tid.isEmpty) {
      Get.snackbar(
        'Track',
        'No active track session.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.darkSurface,
        colorText: AppColors.surface,
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final ok = await track.addFlag(
        AddFlagData(
          type: _flagType,
          description: _notes.text.trim(),
          images: List<XFile>.from(_images),
          coordinate: tm.LatLng(_pinLatLng.latitude, _pinLatLng.longitude),
        ),
      );
      if (ok && mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Widget _thumb(XFile x) {
    if (kIsWeb) {
      return FutureBuilder<Uint8List>(
        future: x.readAsBytes(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }
          return Image.memory(
            snap.data!,
            fit: BoxFit.cover,
            width: 72,
            height: 72,
          );
        },
      );
    }
    return Image.file(
      File(x.path),
      fit: BoxFit.cover,
      width: 72,
      height: 72,
    );
  }

  Widget _thumbUrl(String stored) {
    final url = ApiConfig.resolveMediaUrl(stored) ?? stored;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: CachedNetworkImage(
        imageUrl: url,
        width: 72,
        height: 72,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          width: 72,
          height: 72,
          color: AppColors.background,
          alignment: Alignment.center,
          child: const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (_, __, ___) => const Icon(
          Icons.broken_image_outlined,
          color: AppColors.homeGreetingGrey,
          size: 32,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _notes.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _isEditMode ? 'Edit Flag' : 'Add Flag',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Flag type',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              InputDecorator(
                decoration: _dropdownShellDecoration(),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _flagType,
                    isExpanded: true,
                    dropdownColor: AppColors.surface,
                    iconEnabledColor: AppColors.primary,
                    style: GoogleFonts.poppins(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                    ),
                    items: kTrackFlagTypeValues
                        .map(
                          (v) => DropdownMenuItem<String>(
                            value: v,
                            child: Row(
                              children: [
                                TrackFlagTypeCircleIcon(
                                  type: v,
                                  size: 28,
                                  iconSize: 15,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    trackFlagLabel(v),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _flagType = v);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _notes,
                maxLines: 3,
                style: GoogleFonts.poppins(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                ),
                decoration: _notesDecoration('Notes or description'),
              ),
              const SizedBox(height: 16),
              Text(
                'Photos (up to 3)',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 80,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (var i = 0; i < _existingImageUrls.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            _thumbUrl(_existingImageUrls[i]),
                            Positioned(
                              top: -6,
                              right: -6,
                              child: Material(
                                color: AppColors.darkSurface,
                                shape: const CircleBorder(),
                                child: InkWell(
                                  customBorder: const CircleBorder(),
                                  onTap: () => _removeExistingUrl(i),
                                  child: const Padding(
                                    padding: EdgeInsets.all(4),
                                    child: Icon(
                                      Icons.close,
                                      size: 16,
                                      color: AppColors.surface,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    for (var i = 0; i < _images.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: _thumb(_images[i]),
                            ),
                            Positioned(
                              top: -6,
                              right: -6,
                              child: Material(
                                color: AppColors.darkSurface,
                                shape: const CircleBorder(),
                                child: InkWell(
                                  customBorder: const CircleBorder(),
                                  onTap: () => _removeImage(i),
                                  child: const Padding(
                                    padding: EdgeInsets.all(4),
                                    child: Icon(
                                      Icons.close,
                                      size: 16,
                                      color: AppColors.surface,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_totalImageCount < 3)
                      Material(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          onTap: () => _pickImage(context),
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            width: 72,
                            height: 72,
                            child: Icon(
                              Icons.add_photo_alternate_outlined,
                              color: AppColors.primary,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Pin location',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Pan and pinch to move the map. Tap to place the pin, or drag the pin for fine adjustment.',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 176,
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _pinLatLng,
                      initialZoom: 16,
                      backgroundColor: AppColors.mapPreviewBackground,
                      onMapReady: () {
                        _mapController.move(_pinLatLng, 16);
                      },
                      onTap: (tapPosition, latLng) {
                        setState(() => _pinLatLng = latLng);
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'adventure_provider_frontend',
                      ),
                      Obx(() {
                        final c = Get.find<TrackController>();
                        final tid = widget.trackIdForDetail;
                        final List<ll.LatLng> pts;
                        if (tid != null && tid.isNotEmpty) {
                          final st = c.selectedTrack.value;
                          if (st != null && st.id == tid && st.geoPath.isNotEmpty) {
                            pts = st.geoPath
                                .map(
                                  (p) => ll.LatLng(p.latitude, p.longitude),
                                )
                                .toList(growable: false);
                          } else {
                            pts = const <ll.LatLng>[];
                          }
                        } else {
                          pts = c.pathPoints
                              .map(
                                (p) => ll.LatLng(p.latitude, p.longitude),
                              )
                              .toList(growable: false);
                        }
                        if (pts.length < 2) {
                          return const SizedBox.shrink();
                        }
                        return PolylineLayer(
                          polylines: [
                            Polyline(
                              points: pts,
                              color: AppColors.primary,
                              strokeWidth: 4,
                            ),
                          ],
                        );
                      }),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _pinLatLng,
                            width: 48,
                            height: 48,
                            alignment: Alignment.bottomCenter,
                            child: GestureDetector(
                              onPanUpdate: (details) {
                                final cam = _mapController.camera;
                                final next =
                                    cam.latLngToScreenOffset(_pinLatLng) +
                                        details.delta;
                                setState(() {
                                  _pinLatLng = cam.screenOffsetToLatLng(next);
                                });
                              },
                              child: TrackFlagTypeCircleIcon(
                                type: _flagType,
                                size: 40,
                                iconSize: 22,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _saving ? null : _onSave,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.surface,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _saving
                    ? SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.surface,
                        ),
                      )
                    : Text(
                        _isEditMode ? 'Update Flag' : 'Save Flag',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
