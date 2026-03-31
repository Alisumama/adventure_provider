import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../models/active_session_data.dart';

/// Hero card: active session (gradient) or empty dashed “start adventure” state.
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
    return ClipRRect(
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
                colors: [
                  AppColors.primaryDark,
                  AppColors.primaryLight,
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                height: 96,
                width: double.infinity,
                child: CustomPaint(
                  painter: _TopoWatermarkPainter(),
                ),
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
        border: Border.all(
          color: AppColors.surface.withValues(alpha: 0.25),
        ),
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
      opacity: Tween<double>(begin: 0.35, end: 1).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        color: AppColors.surface,
        child: CustomPaint(
          foregroundPainter: _DashedRRectPainter(
            borderRadius: 20,
            color: AppColors.primary.withValues(alpha: 0.45),
            strokeWidth: 1.5,
            dashLength: 7,
            gapLength: 5,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.homeHeaderIconFill,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.play_arrow_rounded,
                    size: 20,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Start an Adventure',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Begin a live session to track your route, steps, and calories.',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          height: 1.35,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onStartAdventure,
                    customBorder: const CircleBorder(),
                    child: Ink(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primaryLight,
                            AppColors.primary,
                          ],
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: AppColors.surface,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  _DashedRRectPainter({
    required this.borderRadius,
    required this.color,
    required this.strokeWidth,
    required this.dashLength,
    required this.gapLength,
  });

  final double borderRadius;
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      Radius.circular(borderRadius),
    );
    final path = Path()..addRRect(rrect);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final len = dashLength.clamp(0.0, metric.length - distance);
        final extract = metric.extractPath(distance, distance + len);
        canvas.drawPath(extract, paint);
        distance += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
