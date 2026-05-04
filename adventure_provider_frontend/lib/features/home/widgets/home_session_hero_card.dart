import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../models/active_session_data.dart';

/// Hero card: active session (gradient) or empty “start adventure” state.
class HomeSessionHeroCard extends StatelessWidget {
  const HomeSessionHeroCard({
    super.key,
    this.activeSession,
    this.onViewMap,
    this.onEndSession,
    this.onStartAdventure,
  });

  final ActiveSessionData? activeSession;
  final VoidCallback? onViewMap;
  final VoidCallback? onEndSession;
  final VoidCallback? onStartAdventure;

  @override
  Widget build(BuildContext context) {
    if (activeSession != null) {
      return _ActiveSessionHeroCard(
        data: activeSession!,
        onViewMap: onViewMap,
        onEndSession: onEndSession,
      );
    }
    return _EmptySessionHeroCard(onStartAdventure: onStartAdventure);
  }
}

// ─── Active session ─────────────────────────────────────────────────────────

class _ActiveSessionHeroCard extends StatelessWidget {
  const _ActiveSessionHeroCard({
    required this.data,
    this.onViewMap,
    this.onEndSession,
  });

  final ActiveSessionData data;
  final VoidCallback? onViewMap;
  final VoidCallback? onEndSession;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B4332).withValues(alpha: 0.28),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primaryDark, AppColors.primaryLight],
                ),
              ),
            ),
            Positioned.fill(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  height: 96,
                  width: double.infinity,
                  child: CustomPaint(painter: _TopoWatermarkPainter()),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _ActiveSessionPill(),
                  const SizedBox(height: 14),
                  Text(
                    data.trailName,
                    style: GoogleFonts.bebasNeue(
                      fontSize: 28,
                      fontWeight: FontWeight.w400,
                      color: AppColors.surface,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${data.activityLabel} · Started ${data.startedAgoLabel}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.surface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _MetricsPanel(data: data),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 42,
                          child: FilledButton(
                            onPressed: onViewMap,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.surface,
                              foregroundColor: AppColors.primaryDark,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              textStyle: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            child: const Text('View on Map'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 42,
                          child: OutlinedButton(
                            onPressed: onEndSession,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.surface,
                              side: const BorderSide(
                                color: AppColors.surface,
                                width: 1,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              textStyle: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            child: const Text('End Session'),
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
      ),
    );
  }
}

class _ActiveSessionPill extends StatelessWidget {
  const _ActiveSessionPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.surface.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _BlinkingGreenDot(),
          const SizedBox(width: 8),
          Text(
            'ACTIVE SESSION',
            style: GoogleFonts.spaceMono(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
              color: AppColors.surface,
            ),
          ),
        ],
      ),
    );
  }
}

class _BlinkingGreenDot extends StatefulWidget {
  const _BlinkingGreenDot();

  @override
  State<_BlinkingGreenDot> createState() => _BlinkingGreenDotState();
}

class _BlinkingGreenDotState extends State<_BlinkingGreenDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(
        begin: 0.35,
        end: 1,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
      child: Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          color: AppColors.primaryLight,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _MetricsPanel extends StatelessWidget {
  const _MetricsPanel({required this.data});

  final ActiveSessionData data;

  String get _kmStr => data.km.toStringAsFixed(1);

  String get _stepsStr {
    final s = data.steps.toString();
    final len = s.length;
    if (len <= 3) return s;
    final first = len % 3;
    final buf = StringBuffer();
    if (first != 0) {
      buf.write(s.substring(0, first));
    }
    for (var i = first; i < len; i += 3) {
      if (buf.isNotEmpty) buf.write(',');
      buf.write(s.substring(i, math.min(i + 3, len)));
    }
    return buf.toString();
  }

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
            child: _MetricCell(value: _kmStr, label: 'KM'),
          ),
          Expanded(
            child: _MetricCell(value: data.timeLabel, label: 'TIME'),
          ),
          Expanded(
            child: _MetricCell(value: _stepsStr, label: 'STEPS'),
          ),
          Expanded(
            child: _MetricCell(value: '${data.kcal}', label: 'KCAL'),
          ),
        ],
      ),
    );
  }
}

class _MetricCell extends StatelessWidget {
  const _MetricCell({required this.value, required this.label});

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

// ─── Topo watermark (curved contour lines, SVG-like) ─────────────────────────

class _TopoWatermarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = AppColors.surface.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    final baseY = h * 0.55;

    void drawContour(double y0, double amplitude, double waves) {
      final path = Path()..moveTo(-8, y0);
      for (var i = 0; i <= 40; i++) {
        final t = i / 40;
        final x = t * (w + 16) - 8;
        final phase = t * math.pi * 2 * waves;
        final y = y0 + amplitude * math.sin(phase);
        path.lineTo(x, y);
      }
      canvas.drawPath(path, linePaint);
    }

    drawContour(baseY - 4, 7, 2);
    drawContour(baseY + 10, 9, 2.5);
    drawContour(baseY + 26, 11, 2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Empty session ───────────────────────────────────────────────────────────

class _EmptySessionHeroCard extends StatelessWidget {
  const _EmptySessionHeroCard({this.onStartAdventure});

  final VoidCallback? onStartAdventure;

  @override
  Widget build(BuildContext context) {
    const textPrimary = Color(0xFF1A1A2E);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D6A4F).withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2D6A4F), Color(0xFF52B788)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.directions_run,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE07B39).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      child: Text(
                        'NEW SESSION',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                          color: const Color(0xFFE07B39),
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Start an Adventure',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Track route, steps & calories',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      height: 1.3,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: onStartAdventure,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2D6A4F), Color(0xFF52B788)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2D6A4F).withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
