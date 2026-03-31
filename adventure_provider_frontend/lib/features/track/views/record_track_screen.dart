import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../controllers/track_controller.dart';

/// GPS recording screen: mock map, live stats, start/stop, save bottom sheet.
class RecordTrackScreen extends StatefulWidget {
  const RecordTrackScreen({super.key});

  @override
  State<RecordTrackScreen> createState() => _RecordTrackScreenState();
}

class _RecordTrackScreenState extends State<RecordTrackScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  static String _formatDurationSeconds(int seconds) {
    final safe = seconds < 0 ? 0 : seconds;
    final h = safe ~/ 3600;
    final m = (safe % 3600) ~/ 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  static String _formatSteps(int steps) {
    final s = steps.toString();
    final len = s.length;
    if (len <= 3) return s;
    final first = len % 3;
    final buf = StringBuffer();
    if (first != 0) buf.write(s.substring(0, first));
    for (var i = first; i < len; i += 3) {
      if (buf.isNotEmpty) buf.write(',');
      buf.write(s.substring(i, math.min(i + 3, len)));
    }
    return buf.toString();
  }

  Future<void> _onStopTap(TrackController c) async {
    await c.stopRecording();
    if (!mounted) return;
    if (c.recordingPath.isEmpty) return;
    await _showSaveTrackSheet(context, c);
  }

  Future<void> _showSaveTrackSheet(BuildContext context, TrackController c) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SaveTrackSheet(
        trackController: c,
        onSaved: () {
          Navigator.of(ctx).pop();
          if (context.mounted) Get.back<void>();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<TrackController>();

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final h = constraints.maxHeight;
            final mapH = h * 0.55;
            final panelH = h * 0.45;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: mapH,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        color: AppColors.darkSurface,
                        alignment: Alignment.center,
                        child: Text(
                          'Map View — Coming Soon',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primaryLight,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        left: 4,
                        right: 4,
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () => Get.back<void>(),
                              icon: const Icon(Icons.arrow_back_ios_new_rounded),
                              color: Colors.white,
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.black38,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'RECORD TRACK',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.bebasNeue(
                                  fontSize: 22,
                                  color: Colors.white,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 48),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: panelH,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.darkSurface,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                      child: Column(
                        children: [
                          Obx(() {
                            final km = (c.recordingDistance.value / 1000)
                                .toStringAsFixed(1);
                            final time = _formatDurationSeconds(
                              c.recordingDuration.value,
                            );
                            final stepsStr =
                                _formatSteps(c.recordingSteps.value);
                            final kcal = c.recordingCalories.value;
                            return _RecordingMetricsPanel(
                              kmStr: km,
                              timeLabel: time,
                              stepsStr: stepsStr,
                              kcalStr: '$kcal',
                            );
                          }),
                          const SizedBox(height: 28),
                          Obx(() {
                            final rec = c.isRecording.value;
                            return Column(
                              children: [
                                if (rec) ...[
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      FadeTransition(
                                        opacity:
                                            Tween<double>(begin: 0.35, end: 1)
                                                .animate(
                                          CurvedAnimation(
                                            parent: _pulseController,
                                            curve: Curves.easeInOut,
                                          ),
                                        ),
                                        child: Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: AppColors.danger,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'RECORDING',
                                        style: GoogleFonts.spaceMono(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.8,
                                          color: AppColors.danger,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                ] else
                                  const SizedBox(height: 39),
                                Material(
                                  color: AppColors.primary,
                                  shape: const CircleBorder(),
                                  child: InkWell(
                                    customBorder: const CircleBorder(),
                                    onTap: () {
                                      if (rec) {
                                        _onStopTap(c);
                                      } else {
                                        c.startRecording();
                                      }
                                    },
                                    child: SizedBox(
                                      width: 72,
                                      height: 72,
                                      child: Icon(
                                        rec ? Icons.stop : Icons.play_arrow,
                                        color: Colors.white,
                                        size: 40,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RecordingMetricsPanel extends StatelessWidget {
  const _RecordingMetricsPanel({
    required this.kmStr,
    required this.timeLabel,
    required this.stepsStr,
    required this.kcalStr,
  });

  final String kmStr;
  final String timeLabel;
  final String stepsStr;
  final String kcalStr;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF000000).withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _RecordingMetricCell(value: kmStr, label: 'KM'),
          ),
          Expanded(
            child: _RecordingMetricCell(value: timeLabel, label: 'TIME'),
          ),
          Expanded(
            child: _RecordingMetricCell(value: stepsStr, label: 'STEPS'),
          ),
          Expanded(
            child: _RecordingMetricCell(value: kcalStr, label: 'KCAL'),
          ),
        ],
      ),
    );
  }
}

class _RecordingMetricCell extends StatelessWidget {
  const _RecordingMetricCell({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          style: GoogleFonts.bebasNeue(
            fontSize: 20,
            fontWeight: FontWeight.w400,
            color: AppColors.surface,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.spaceMono(
            fontSize: 9,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
            color: AppColors.surface.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }
}

class _SaveTrackSheet extends StatefulWidget {
  const _SaveTrackSheet({
    required this.trackController,
    required this.onSaved,
  });

  final TrackController trackController;
  final VoidCallback onSaved;

  @override
  State<_SaveTrackSheet> createState() => _SaveTrackSheetState();
}

class _SaveTrackSheetState extends State<_SaveTrackSheet> {
  final _titleCtrl = TextEditingController();
  String _type = 'hiking';
  String _difficulty = 'easy';

  static const _types = [
    ('hiking', 'Hiking'),
    ('offroad', 'Offroad'),
    ('cycling', 'Cycling'),
    ('running', 'Running'),
  ];

  static const _difficulties = [
    ('easy', 'Easy'),
    ('moderate', 'Moderate'),
    ('hard', 'Hard'),
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      Get.snackbar(
        'Title required',
        'Enter a track title.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    await widget.trackController.saveRecordedTrack(
      title,
      '',
      _type,
      _difficulty,
    );
    if (!mounted) return;
    if (widget.trackController.recordingPath.isEmpty) {
      widget.onSaved();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottom),
      decoration: const BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Save track',
            style: GoogleFonts.bebasNeue(
              fontSize: 22,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleCtrl,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              labelText: 'Track title',
              labelStyle: GoogleFonts.poppins(color: Colors.white54),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white24),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primaryLight),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Type',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _types.map((e) {
              final sel = _type == e.$1;
              return ChoiceChip(
                label: Text(e.$2),
                selected: sel,
                onSelected: (_) => setState(() => _type = e.$1),
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.darkBackground,
                labelStyle: GoogleFonts.poppins(
                  fontSize: 12,
                  color: sel ? Colors.white : Colors.white70,
                ),
                showCheckmark: false,
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text(
            'Difficulty',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _difficulties.map((e) {
              final sel = _difficulty == e.$1;
              return ChoiceChip(
                label: Text(e.$2),
                selected: sel,
                onSelected: (_) => setState(() => _difficulty = e.$1),
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.darkBackground,
                labelStyle: GoogleFonts.poppins(
                  fontSize: 12,
                  color: sel ? Colors.white : Colors.white70,
                ),
                showCheckmark: false,
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Obx(() {
            final loading = widget.trackController.isLoading.value;
            return FilledButton(
              onPressed: loading ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Save Track',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            );
          }),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.white54),
            ),
          ),
        ],
      ),
    );
  }
}
