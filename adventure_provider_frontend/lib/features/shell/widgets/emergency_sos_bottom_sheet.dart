import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../profile/controllers/profile_controller.dart';

void showEmergencySosBottomSheet() {
  Get.bottomSheet<void>(
    const EmergencySosBottomSheet(),
    isDismissible: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    enableDrag: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
  );
}

class EmergencySosBottomSheet extends StatelessWidget {
  const EmergencySosBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final profileController = Get.find<ProfileController>();
    final bottomSafe = MediaQuery.of(context).padding.bottom;

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.darkBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
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
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.sos,
                          color: AppColors.danger,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Emergency SOS',
                              style: GoogleFonts.bebasNeue(
                                fontSize: 22,
                                color: Colors.white,
                              ),
                            ),
                            Obx(() {
                              final p = profileController.profile.value;
                              final name = p?.emergencyContact?.name?.trim();
                              final subtitle = (name != null && name.isNotEmpty)
                                  ? 'Calling: $name'
                                  : 'No emergency contact saved';
                              return Text(
                                subtitle,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(
                    color: Color(0xFF2A2A2A),
                    height: 1,
                    thickness: 1,
                  ),
                  const SizedBox(height: 16),
                  Obx(() {
                    final p = profileController.profile.value;
                    final ec = p?.emergencyContact;
                    if (ec == null) {
                      return const SizedBox.shrink();
                    }
                    final name = ec.name?.trim();
                    final phone = ec.phone?.trim();
                    final relation = ec.relation?.trim();
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.darkSurface,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Emergency Contact',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  (name != null && name.isNotEmpty)
                                      ? name
                                      : 'Not set',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  (phone != null && phone.isNotEmpty)
                                      ? phone
                                      : '--',
                                  style: GoogleFonts.spaceMono(
                                    fontSize: 13,
                                    color: AppColors.primaryLight,
                                  ),
                                ),
                                if (relation != null && relation.isNotEmpty)
                                  Text(
                                    relation,
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.contact_phone_outlined,
                            color: AppColors.primaryLight,
                            size: 28,
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () {
                      Get.back<void>();
                      Get.find<ProfileController>().launchEmergencyCall();
                    },
                    child: Container(
                      width: double.infinity,
                      height: 54,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.danger,
                            Color(0xFFFF4444),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.danger.withValues(alpha: 0.4),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.phone, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Call Emergency Contact',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => Get.back<void>(),
                    child: Container(
                      width: double.infinity,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: bottomSafe + 8),
          ],
        ),
      ),
    );
  }
}
