import 'dart:math' as math;
import 'package:avara_astrology_trial/services/age_profile_service.dart';
import 'package:avara_astrology_trial/theme/app_colors.dart';
import 'package:flutter/material.dart';

// =============================================================================
// 1. Age-Adaptive Creative Header Graphic (Point 11 & Point 9)
// =============================================================================

/// Dynamic canvas graphic that adapts its artistic theme based on the user's age group:
/// - Youth: Futuristic constellation orbital nodes & vibrant energy lines.
/// - Adult: Sleek minimalist geometric harmony & circadian flow.
/// - Senior: Sacred golden lotus & radiant aura petals.
class AgeAdaptiveHeaderGraphic extends StatelessWidget {
  const AgeAdaptiveHeaderGraphic({
    super.key,
    required this.ageGroup,
    this.height = 140,
  });

  final AgeGroup ageGroup;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: CustomPaint(
          painter: _AgeGraphicPainter(ageGroup: ageGroup),
        ),
      ),
    );
  }
}

class _AgeGraphicPainter extends CustomPainter {
  _AgeGraphicPainter({required this.ageGroup});

  final AgeGroup ageGroup;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    switch (ageGroup) {
      case AgeGroup.youth:
        _paintYouthConstellation(canvas, size, rect);
        break;
      case AgeGroup.adult:
        _paintAdultHarmonicMandala(canvas, size, rect);
        break;
      case AgeGroup.senior:
        _paintSeniorSacredLotus(canvas, size, rect);
        break;
    }
  }

  void _paintYouthConstellation(Canvas canvas, Size size, Rect rect) {
    // Dynamic deep indigo to electric purple gradient
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF2E0854), Color(0xFF4834D4), Color(0xFF686DE0)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    final linePaint = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.35)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    final starPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final glowPaint = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    // Orbital node points
    final points = [
      Offset(size.width * 0.15, size.height * 0.3),
      Offset(size.width * 0.35, size.height * 0.7),
      Offset(size.width * 0.55, size.height * 0.25),
      Offset(size.width * 0.75, size.height * 0.65),
      Offset(size.width * 0.9, size.height * 0.35),
    ];

    // Connect nodes
    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, linePaint);

    // Draw glowing stars and orbital circles
    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      canvas.drawCircle(p, 10, glowPaint);
      canvas.drawCircle(p, 4.5, starPaint);
      // Secondary concentric ring
      canvas.drawCircle(p, 12, linePaint);
    }
  }

  void _paintAdultHarmonicMandala(Canvas canvas, Size size, Rect rect) {
    // Executive mindful navy to ocean teal gradient
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF0F766E)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    final arcPaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.25)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width * 0.82, size.height * 0.5);

    // Concentric harmonic arcs
    for (double r = 20; r <= 120; r += 24) {
      canvas.drawCircle(center, r, arcPaint);
    }

    // Circadian flow sine curve
    final wavePath = Path();
    wavePath.moveTo(0, size.height * 0.6);
    for (double x = 0; x <= size.width; x += 10) {
      final y = size.height * 0.55 + math.sin(x * 0.02) * 18;
      wavePath.lineTo(x, y);
    }
    final wavePaint = Paint()
      ..color = Colors.tealAccent.withValues(alpha: 0.45)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(wavePath, wavePaint);
  }

  void _paintSeniorSacredLotus(Canvas canvas, Size size, Rect rect) {
    // Sacred golden saffron to warm sandalwood
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF78350F), Color(0xFFB45309), Color(0xFFD97706)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    final lotusCenter = Offset(size.width * 0.85, size.height * 0.5);
    final petalPaint = Paint()
      ..color = const Color(0xFFFEF3C7).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    // Radiant aura rays
    for (int i = 0; i < 12; i++) {
      final angle = (i * 30) * math.pi / 180;
      final p1 = Offset(lotusCenter.dx + math.cos(angle) * 16, lotusCenter.dy + math.sin(angle) * 16);
      final p2 = Offset(lotusCenter.dx + math.cos(angle) * 65, lotusCenter.dy + math.sin(angle) * 65);
      canvas.drawLine(p1, p2, petalPaint);
    }

    // Lotus petal curves
    for (int i = 0; i < 8; i++) {
      final angle = (i * 45) * math.pi / 180;
      canvas.save();
      canvas.translate(lotusCenter.dx, lotusCenter.dy);
      canvas.rotate(angle);
      final ovalRect = Rect.fromCenter(center: const Offset(26, 0), width: 34, height: 16);
      canvas.drawOval(ovalRect, petalPaint);
      canvas.restore();
    }

    canvas.drawCircle(
      lotusCenter,
      10,
      Paint()..color = const Color(0xFFFFFBEB),
    );
  }

  @override
  bool shouldRepaint(covariant _AgeGraphicPainter oldDelegate) =>
      oldDelegate.ageGroup != ageGroup;
}

// =============================================================================
// 2. Daily Multi-Format Graphic Reports (Point 10)
// =============================================================================

/// Creative Graphic 1: Radial Multi-Ring Energy Gauge
class RadialEnergyGauge extends StatelessWidget {
  const RadialEnergyGauge({
    super.key,
    required this.mindScore,
    required this.vitalityScore,
    required this.habitScore,
    required this.wealthScore,
  });

  final double mindScore; // 0.0 - 1.0
  final double vitalityScore;
  final double habitScore;
  final double wealthScore;

  double get overallAverage =>
      ((mindScore + vitalityScore + habitScore + wealthScore) / 4 * 100);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.pie_chart_outline_rounded, color: AppColors.blue, size: 20),
              SizedBox(width: 8),
              Text(
                'Holistic Self-Help Vitality Ring',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.deepNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CustomPaint(
                  painter: _RadialRingsPainter(
                    mind: mindScore,
                    vitality: vitalityScore,
                    habit: habitScore,
                    wealth: wealthScore,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${overallAverage.toInt()}%',
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            color: AppColors.deepNavy,
                          ),
                        ),
                        const Text(
                          'Energy Index',
                          style: TextStyle(fontSize: 9, color: AppColors.secondaryText),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _legendItem(color: const Color(0xFF6C5CE7), label: 'Mind Calm', value: mindScore),
                    const SizedBox(height: 6),
                    _legendItem(color: const Color(0xFF00B894), label: 'Vitality', value: vitalityScore),
                    const SizedBox(height: 6),
                    _legendItem(color: const Color(0xFFE17055), label: 'Habit Mastery', value: habitScore),
                    const SizedBox(height: 6),
                    _legendItem(color: const Color(0xFF0984E3), label: 'Mindful Wealth', value: wealthScore),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem({required Color color, required String label, required double value}) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.deepNavy, fontWeight: FontWeight.w600)),
        ),
        Text('${(value * 100).toInt()}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

class _RadialRingsPainter extends CustomPainter {
  _RadialRingsPainter({
    required this.mind,
    required this.vitality,
    required this.habit,
    required this.wealth,
  });

  final double mind;
  final double vitality;
  final double habit;
  final double wealth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const strokeW = 6.0;

    _drawArc(canvas, center, radius: 52, progress: mind, color: const Color(0xFF6C5CE7), strokeW: strokeW);
    _drawArc(canvas, center, radius: 43, progress: vitality, color: const Color(0xFF00B894), strokeW: strokeW);
    _drawArc(canvas, center, radius: 34, progress: habit, color: const Color(0xFFE17055), strokeW: strokeW);
    _drawArc(canvas, center, radius: 25, progress: wealth, color: const Color(0xFF0984E3), strokeW: strokeW);
  }

  void _drawArc(
    Canvas canvas,
    Offset center, {
    required double radius,
    required double progress,
    required Color color,
    required double strokeW,
  }) {
    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..strokeWidth = strokeW
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, bgPaint);

    final activePaint = Paint()
      ..color = color
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final sweepAngle = 2 * math.pi * progress.clamp(0.05, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RadialRingsPainter oldDelegate) => true;
}

/// Creative Graphic 2: Circadian Daily Energy Wave Curve
class CircadianWaveformChart extends StatelessWidget {
  const CircadianWaveformChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.show_chart_rounded, color: Color(0xFF00B894), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Circadian Energy Waveform',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.deepNavy,
                    ),
                  ),
                ],
              ),
              Text(
                'Optimal Flow: Peak Focus at 10 AM',
                style: TextStyle(fontSize: 11, color: Color(0xFF00B894), fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 90,
            width: double.infinity,
            child: CustomPaint(
              painter: _CircadianWavePainter(),
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('6 AM (Dawn)', style: TextStyle(fontSize: 10, color: AppColors.secondaryText)),
              Text('10 AM (Peak Focus)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.deepNavy)),
              Text('2 PM (Calm)', style: TextStyle(fontSize: 10, color: AppColors.secondaryText)),
              Text('6 PM (Reflection)', style: TextStyle(fontSize: 10, color: AppColors.secondaryText)),
              Text('10 PM (Sleep)', style: TextStyle(fontSize: 10, color: AppColors.secondaryText)),
            ],
          ),
        ],
      ),
    );
  }
}

class _CircadianWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    path.moveTo(0, size.height * 0.7);

    // Morning awakening -> peak focus at 10 AM -> dip -> evening recovery
    path.cubicTo(
      size.width * 0.15, size.height * 0.6,
      size.width * 0.25, size.height * 0.15,
      size.width * 0.35, size.height * 0.2, // Peak 10 AM
    );
    path.cubicTo(
      size.width * 0.45, size.height * 0.25,
      size.width * 0.55, size.height * 0.7,
      size.width * 0.65, size.height * 0.65, // 2 PM lunch dip
    );
    path.cubicTo(
      size.width * 0.75, size.height * 0.6,
      size.width * 0.85, size.height * 0.45,
      size.width, size.height * 0.85, // Night wind down
    );

    // Fill under curve
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF00B894).withValues(alpha: 0.25),
          const Color(0xFF0984E3).withValues(alpha: 0.05),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Offset.zero & size);
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = const Color(0xFF00B894)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, linePaint);

    // Current hour marker (at roughly 35% of the chart)
    final markerX = size.width * 0.35;
    final markerY = size.height * 0.2;
    canvas.drawCircle(Offset(markerX, markerY), 5, Paint()..color = const Color(0xFF00B894));
    canvas.drawCircle(Offset(markerX, markerY), 9, Paint()..color = const Color(0xFF00B894).withValues(alpha: 0.3));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Creative Graphic 3: Planetary Harmony 5-Axis Radar Chart
class PlanetaryHarmonyRadar extends StatelessWidget {
  const PlanetaryHarmonyRadar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.hub_rounded, color: Color(0xFF6C5CE7), size: 20),
              SizedBox(width: 8),
              Text(
                'Planetary Harmony Matrix',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.deepNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 150,
            width: double.infinity,
            child: CustomPaint(
              painter: _PlanetaryRadarPainter(),
            ),
          ),
          const SizedBox(height: 6),
          const Center(
            child: Text(
              'High Mercury & Jupiter Alignment: Exceptional day for studies and decision making.',
              style: TextStyle(fontSize: 11, color: AppColors.secondaryText, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanetaryRadarPainter extends CustomPainter {
  final labels = ['Sun (Vitality)', 'Moon (Peace)', 'Mercury (Focus)', 'Jupiter (Wisdom)', 'Saturn (Grit)'];
  final values = [0.85, 0.70, 0.95, 0.88, 0.78];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.height * 0.42;

    final gridPaint = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw background concentric pentagons
    for (double f = 0.25; f <= 1.0; f += 0.25) {
      final pPath = Path();
      for (int i = 0; i < 5; i++) {
        final angle = (i * 72 - 90) * math.pi / 180;
        final x = center.dx + math.cos(angle) * (radius * f);
        final y = center.dy + math.sin(angle) * (radius * f);
        if (i == 0) pPath.moveTo(x, y); else pPath.lineTo(x, y);
      }
      pPath.close();
      canvas.drawPath(pPath, gridPaint);
    }

    // Draw data polygon
    final dataPath = Path();
    for (int i = 0; i < 5; i++) {
      final angle = (i * 72 - 90) * math.pi / 180;
      final val = values[i];
      final x = center.dx + math.cos(angle) * (radius * val);
      final y = center.dy + math.sin(angle) * (radius * val);
      if (i == 0) dataPath.moveTo(x, y); else dataPath.lineTo(x, y);
    }
    dataPath.close();

    final fillPaint = Paint()
      ..color = const Color(0xFF6C5CE7).withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawPath(dataPath, fillPaint);

    final strokePaint = Paint()
      ..color = const Color(0xFF6C5CE7)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(dataPath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
