import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../controllers/track_controller.dart';

/// Track metadata form before live recording; [TrackController.startTrack] is wired later.
class RecordTrackScreen extends StatefulWidget {
  const RecordTrackScreen({super.key});

  @override
  State<RecordTrackScreen> createState() => _RecordTrackScreenState();
}

class _RecordTrackScreenState extends State<RecordTrackScreen> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String? _trackType;
  String _difficulty = 'easy';
  bool _isPublic = true;
  bool _isTestingMode = false;

  static const _typeEntries = <({String? value, String label})>[
    (value: null, label: 'Select track type'),
    (value: 'hiking', label: 'Hiking'),
    (value: 'offroad', label: 'Offroading'),
    (value: 'cycling', label: 'Cycling'),
    (value: 'running', label: 'Running'),
  ];

  static const _difficultyEntries = <({String value, String label})>[
    (value: 'easy', label: 'Easy'),
    (value: 'moderate', label: 'Moderate'),
    (value: 'hard', label: 'Hard'),
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration(String label, {String? hint}) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.homeHeaderBorder),
    );
    return InputDecoration(
      filled: true,
      fillColor: AppColors.darkSurface,
      labelText: label,
      hintText: hint,
      labelStyle: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 14),
      hintStyle: GoogleFonts.poppins(color: AppColors.textSecondary.withValues(alpha: 0.7)),
      floatingLabelStyle: GoogleFonts.poppins(color: AppColors.primaryLight),
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: AppColors.primaryLight, width: 1.5),
      ),
    );
  }

  InputDecoration _dropdownShellDecoration() {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.homeHeaderBorder),
    );
    return InputDecoration(
      filled: true,
      fillColor: AppColors.darkSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: AppColors.primaryLight, width: 1.5),
      ),
    );
  }

  Widget _dropdown<T>({
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    Widget? hint,
  }) {
    return InputDecorator(
      decoration: _dropdownShellDecoration(),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor: AppColors.darkSurface,
          iconEnabledColor: AppColors.surface,
          hint: hint,
          style: GoogleFonts.poppins(color: AppColors.surface, fontSize: 15),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Future<void> _onStartTrack() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      Get.snackbar(
        'Track name required',
        'Enter a name for your track.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.darkSurface,
        colorText: AppColors.surface,
      );
      return;
    }
    if (_trackType == null) {
      Get.snackbar(
        'Track type required',
        'Choose a track type.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.darkSurface,
        colorText: AppColors.surface,
      );
      return;
    }

    final c = Get.find<TrackController>();
    await c.startTrack(
      trackName: name,
      description: _descCtrl.text.trim(),
      trackType: _trackType!,
      difficulty: _difficulty,
      isPublic: _isPublic,
      isTestingMode: _isTestingMode,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.surface),
          onPressed: () => Get.back<void>(),
        ),
        title: Text(
          'Track Info',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.surface,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'NEW TRACK',
                style: GoogleFonts.bebasNeue(
                  fontSize: 28,
                  color: AppColors.surface,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Set up your adventure before you start recording.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _nameCtrl,
                style: GoogleFonts.poppins(color: AppColors.surface, fontSize: 15),
                decoration: _fieldDecoration('Track name', hint: 'e.g. Forest loop'),
              ),
              const SizedBox(height: 16),
              Text(
                'Track type',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              _dropdown<String?>(
                value: _trackType,
                hint: Text(
                  'Select track type',
                  style: GoogleFonts.poppins(color: AppColors.textSecondary),
                ),
                items: _typeEntries
                    .where((e) => e.value != null)
                    .map(
                      (e) => DropdownMenuItem<String?>(
                        value: e.value,
                        child: Text(e.label),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _trackType = v),
              ),
              const SizedBox(height: 16),
              Text(
                'Difficulty',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              _dropdown<String>(
                value: _difficulty,
                hint: null,
                items: _difficultyEntries
                    .map(
                      (e) => DropdownMenuItem<String>(
                        value: e.value,
                        child: Text(e.label),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _difficulty = v);
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descCtrl,
                minLines: 3,
                maxLines: 5,
                style: GoogleFonts.poppins(color: AppColors.surface, fontSize: 15),
                decoration: _fieldDecoration('Description', hint: 'Optional notes'),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Is Public',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: AppColors.surface,
                      ),
                    ),
                  ),
                  Switch(
                    value: _isPublic,
                    onChanged: (v) => setState(() => _isPublic = v),
                    activeThumbColor: AppColors.primaryLight,
                    activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
                    inactiveThumbColor: AppColors.textSecondary,
                    inactiveTrackColor: AppColors.darkSurface,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _isTestingMode,
                      onChanged: (v) => setState(() => _isTestingMode = v ?? false),
                      activeColor: AppColors.primaryLight,
                      checkColor: AppColors.surface,
                      side: const BorderSide(color: AppColors.homeHeaderBorder),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isTestingMode = !_isTestingMode),
                      child: Text(
                        'Testing mode: tap map to simulate location',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => _onStartTrack(),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.surface,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Start Track',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
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
