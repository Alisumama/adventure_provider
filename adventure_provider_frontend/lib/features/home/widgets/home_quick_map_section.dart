import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';

/// Quick map preview block: header row + faux map with roads and GPS marker.
class HomeQuickMapSection extends StatelessWidget {
  const HomeQuickMapSection({super.key, this.onOpenFullMap, this.onOpenMapPreview});

  final VoidCallback? onOpenFullMap;
  final VoidCallback? onOpenMapPreview;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '📍 Quick Map',
              style: GoogleFonts.bebasNeue(
                fontSize: 17,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.5,
                color: AppColors.textPrimary,
              ),
            ),
            GestureDetector(
              onTap: onOpenFullMap,
              child: Text(
                'Open Full Map →',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 140,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: AppColors.mapPreviewBackground),
                const CustomPaint(
                  painter: _DiagonalStripesPainter(),
                ),
                const CustomPaint(
                  painter: _MapRoadsPainter(),
                ),
                const Center(
                  child: _PulsingLocationMarker(),
                ),
                Positioned(
                  left: 10,
                  top: 10,
                  child: _GpsActiveBadge(),
                ),
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: Material(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(999),
                    child: InkWell(
                      onTap: onOpenMapPreview ?? onOpenFullMap,
                      borderRadius: BorderRadius.circular(999),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        child: Text(
                          '🗺 Open Map',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.surface,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
                      color: AppColors.primaryLight.withValues(alpha: ringOpacity),
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
  @override
  State<_GpsActiveBadge> createState() => _GpsActiveBadgeState();
}

class _GpsActiveBadgeState extends State<_GpsActiveBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _dot;

  @override
  void initState() {
    super.initState();
    _dot = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _dot.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: Tween<double>(begin: 0.35, end: 1).animate(
              CurvedAnimation(parent: _dot, curve: Curves.easeInOut),
            ),
            child: Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'GPS Active',
            style: GoogleFonts.spaceMono(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
