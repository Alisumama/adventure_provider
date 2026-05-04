import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';

/// Quick map preview block: header row + faux map with roads and GPS marker.
class HomeQuickMapSection extends StatelessWidget {
  const HomeQuickMapSection({
    super.key,
    this.onOpenFullMap,
    this.onOpenMapPreview,
  });

  final VoidCallback? onOpenFullMap;
  final VoidCallback? onOpenMapPreview;

  static const _textPrimary = Color(0xFF1A1A2E);
  static const _primary = Color(0xFF2D6A4F);
  static const _primaryLight = Color(0xFF52B788);
  static const _primaryDark = Color(0xFF1B4332);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'QUICK MAP',
                    style: GoogleFonts.bebasNeue(
                      fontSize: 22,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 1.5,
                      color: _textPrimary,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    width: 40,
                    height: 3,
                    decoration: BoxDecoration(
                      color: _primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              GestureDetector(
                onTap: onOpenFullMap,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Full Map',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 11,
                      color: _primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 170,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const ColoredBox(color: AppColors.mapPreviewBackground),
                  const CustomPaint(painter: _DiagonalStripesPainter()),
                  const CustomPaint(painter: _MapRoadsPainter()),
                  const Center(child: _PulsingLocationMarker()),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.25),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Positioned(top: 12, left: 12, child: _GpsActiveBadge()),
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: onOpenMapPreview ?? onOpenFullMap,
                      child: Container(
                        decoration: BoxDecoration(
                          color: _primaryDark,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: _primaryDark.withValues(alpha: 0.5),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.map_outlined,
                              color: Colors.white,
                              size: 15,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Open Map',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Diagonal hatch (subtle topo feel) ─────────────────────────────────────────

class _DiagonalStripesPainter extends CustomPainter {
  const _DiagonalStripesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.surface.withValues(alpha: 0.07)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const spacing = 10.0;
    final double d = size.width + size.height;

    for (double i = -d; i < d; i += spacing) {
      final path = Path()
        ..moveTo(i, 0)
        ..lineTo(i + size.height, size.height);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── White “roads” ───────────────────────────────────────────────────────────

class _MapRoadsPainter extends CustomPainter {
  const _MapRoadsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final roadWide = Paint()
      ..color = AppColors.surface
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4;

    final roadNarrow = Paint()
      ..color = AppColors.surface
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.2;

    final path1 = Path()
      ..moveTo(-4, h * 0.38)
      ..quadraticBezierTo(w * 0.35, h * 0.32, w * 0.72, h * 0.48)
      ..quadraticBezierTo(w * 0.88, h * 0.56, w + 4, h * 0.52);
    canvas.drawPath(path1, roadWide);

    final path2 = Path()
      ..moveTo(w * 0.08, h + 2)
      ..quadraticBezierTo(w * 0.22, h * 0.62, w * 0.48, h * 0.44)
      ..quadraticBezierTo(w * 0.7, h * 0.28, w + 2, h * 0.12);
    canvas.drawPath(path2, roadNarrow);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Pulsing center pin ──────────────────────────────────────────────────────

class _PulsingLocationMarker extends StatefulWidget {
  const _PulsingLocationMarker();

  @override
  State<_PulsingLocationMarker> createState() => _PulsingLocationMarkerState();
}

class _PulsingLocationMarkerState extends State<_PulsingLocationMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final ringScale = 0.85 + t * 0.9;
        final ringOpacity = (1 - t) * 0.55;
        return SizedBox(
          width: 52,
          height: 52,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: ringScale,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primaryLight.withValues(
                        alpha: ringOpacity,
                      ),
                      width: 2,
                    ),
                  ),
                ),
              ),
              Transform.scale(
                scale: 0.92 + math.sin(t * math.pi) * 0.08,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryDark.withValues(alpha: 0.35),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── GPS badge ────────────────────────────────────────────────────────────────

class _GpsActiveBadge extends StatefulWidget {
  const _GpsActiveBadge();

  @override
  State<_GpsActiveBadge> createState() => _GpsActiveBadgeState();
}

class _GpsActiveBadgeState extends State<_GpsActiveBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryLight = Color(0xFF52B788);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E).withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primaryLight.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: Tween<double>(
              begin: 0.85,
              end: 1.12,
            ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut)),
            child: Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: primaryLight,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'GPS Active',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
