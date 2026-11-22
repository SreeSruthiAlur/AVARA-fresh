import 'dart:math' as math;
import 'package:avara_astrology_trial/screens/astrology_hub_screen.dart';
import 'package:avara_astrology_trial/screens/finance_screen.dart';
import 'package:avara_astrology_trial/screens/habits_screen.dart';
import 'package:avara_astrology_trial/screens/health_screen.dart';
import 'package:avara_astrology_trial/screens/insights_screen.dart';
import 'package:avara_astrology_trial/services/age_profile_service.dart';
import 'package:avara_astrology_trial/services/app_language_service.dart';
import 'package:avara_astrology_trial/services/tts_service.dart';
import 'package:avara_astrology_trial/services/voice_service.dart';
import 'package:avara_astrology_trial/theme/app_colors.dart';
import 'package:flutter/material.dart';

// =============================================================================
// 1. Age-Adaptive Creative Header Graphic (Point 11 & Point 9)
// =============================================================================

/// Dynamic canvas graphic that adapts its artistic theme based on the user's age group:
/// - Youth: Futuristic constellation orbital nodes & vibrant energy lines.
/// - Adult: Sleek minimalist geometric harmony & circadian flow.
/// - Senior: Sacred golden lotus & radiant aura petals.
class AgeAdaptiveHeaderGraphic extends StatefulWidget {
  const AgeAdaptiveHeaderGraphic({
    super.key,
    required this.ageGroup,
    this.height = 140,
  });

  final AgeGroup ageGroup;
  final double height;

  @override
  State<AgeAdaptiveHeaderGraphic> createState() =>
      _AgeAdaptiveHeaderGraphicState();
}

class _AgeAdaptiveHeaderGraphicState extends State<AgeAdaptiveHeaderGraphic>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: AnimatedBuilder(
          animation: _animController,
          builder: (context, _) {
            return CustomPaint(
              painter: _AgeGraphicPainter(
                ageGroup: widget.ageGroup,
                animValue: _animController.value,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AgeGraphicPainter extends CustomPainter {
  _AgeGraphicPainter({
    required this.ageGroup,
    required this.animValue,
  });

  final AgeGroup ageGroup;
  final double animValue;

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
    // Dynamic deep indigo to electric purple cyberpunk gradient
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF1F073D), Color(0xFF4834D4), Color(0xFF00CEC9)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    final linePaint = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.4)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    final starPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Drifting background cyber particles
    for (int i = 0; i < 9; i++) {
      final px = (size.width * ((i * 0.12 + animValue * 0.15) % 1.0));
      final py = (size.height * ((i * 0.23 + (1.0 - animValue) * 0.1) % 1.0));
      final pRadius = 1.2 + (i % 3) * 0.8;
      canvas.drawCircle(
        Offset(px, py),
        pRadius,
        Paint()..color = Colors.cyanAccent.withValues(alpha: 0.35 + 0.25 * math.sin(animValue * math.pi * 2 + i)),
      );
    }

    // Orbital node points with gentle undulating motion
    final points = [
      Offset(size.width * 0.12, size.height * (0.32 + 0.04 * math.sin(animValue * math.pi * 2))),
      Offset(size.width * 0.32, size.height * (0.68 + 0.03 * math.cos(animValue * math.pi * 2))),
      Offset(size.width * 0.52, size.height * (0.24 + 0.04 * math.sin(animValue * math.pi * 2 + 1.2))),
      Offset(size.width * 0.74, size.height * (0.64 + 0.03 * math.cos(animValue * math.pi * 2 + 2.1))),
      Offset(size.width * 0.92, size.height * (0.36 + 0.04 * math.sin(animValue * math.pi * 2 + 3.0))),
    ];

    // Connect nodes with laser lines
    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, linePaint);

    // Animated travelling photon packet along the constellation path
    final totalSegs = points.length - 1;
    final progressSeg = (animValue * totalSegs);
    final curIdx = progressSeg.floor().clamp(0, totalSegs - 1);
    final segFraction = progressSeg - curIdx;
    final photonX = points[curIdx].dx + (points[curIdx + 1].dx - points[curIdx].dx) * segFraction;
    final photonY = points[curIdx].dy + (points[curIdx + 1].dy - points[curIdx].dy) * segFraction;

    canvas.drawCircle(
      Offset(photonX, photonY),
      8,
      Paint()
        ..color = Colors.cyanAccent
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawCircle(
      Offset(photonX, photonY),
      3.5,
      Paint()..color = Colors.white,
    );

    // Draw glowing stars and orbital circles
    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      final pulse = 1.0 + 0.25 * math.sin(animValue * math.pi * 2 + i);
      canvas.drawCircle(
        p,
        10 * pulse,
        Paint()
          ..color = Colors.cyanAccent.withValues(alpha: 0.22)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawCircle(p, 4.5, starPaint);
      canvas.drawCircle(p, 12 * pulse, linePaint);
    }
  }

  void _paintAdultHarmonicMandala(Canvas canvas, Size size, Rect rect) {
    // Executive mindful navy to ocean teal gradient
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF0A1128), Color(0xFF1E3A8A), Color(0xFF0F766E)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    final center = Offset(size.width * 0.82, size.height * 0.5);

    // Concentric harmonic arcs with breathing pulsation
    for (double r = 20; r <= 120; r += 24) {
      final breathingR = r + 3.0 * math.sin(animValue * math.pi * 2 + r * 0.05);
      final arcPaint = Paint()
        ..color = const Color(0xFF38BDF8).withValues(alpha: 0.18 + 0.12 * math.cos(animValue * math.pi * 2))
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(center, breathingR, arcPaint);
    }

    // Dynamic living Circadian flow sine curve
    final wavePath = Path();
    wavePath.moveTo(0, size.height * 0.6);
    for (double x = 0; x <= size.width; x += 8) {
      final y = size.height * 0.55 +
          math.sin((x * 0.02) - (animValue * math.pi * 2)) * 18;
      wavePath.lineTo(x, y);
    }
    final wavePaint = Paint()
      ..color = Colors.tealAccent.withValues(alpha: 0.55)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;
    canvas.drawPath(wavePath, wavePaint);

    // Harmonic pulse dot traveling on the wave
    final beaconX = (size.width * 0.45);
    final beaconY = size.height * 0.55 +
        math.sin((beaconX * 0.02) - (animValue * math.pi * 2)) * 18;
    canvas.drawCircle(
      Offset(beaconX, beaconY),
      8,
      Paint()
        ..color = Colors.tealAccent
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawCircle(
      Offset(beaconX, beaconY),
      3.5,
      Paint()..color = Colors.white,
    );
  }

  void _paintSeniorSacredLotus(Canvas canvas, Size size, Rect rect) {
    // Sacred golden saffron to warm sandalwood
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF6B21A8), Color(0xFF92400E), Color(0xFFB45309), Color(0xFFD97706)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    final lotusCenter = Offset(size.width * 0.85, size.height * 0.5);
    final breathing = 1.0 + 0.08 * math.sin(animValue * math.pi * 2);

    // Radiant animated aura rays rotating softly
    final rotOffset = animValue * math.pi * 0.25;
    final petalPaint = Paint()
      ..color = const Color(0xFFFEF3C7).withValues(alpha: 0.35 + 0.15 * math.sin(animValue * math.pi * 2))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    for (int i = 0; i < 12; i++) {
      final angle = (i * 30) * math.pi / 180 + rotOffset;
      final p1 = Offset(
        lotusCenter.dx + math.cos(angle) * (16 * breathing),
        lotusCenter.dy + math.sin(angle) * (16 * breathing),
      );
      final p2 = Offset(
        lotusCenter.dx + math.cos(angle) * (68 * breathing),
        lotusCenter.dy + math.sin(angle) * (68 * breathing),
      );
      canvas.drawLine(p1, p2, petalPaint);
    }

    // Sacred Lotus petal curves with breathing bloom
    for (int i = 0; i < 8; i++) {
      final angle = (i * 45) * math.pi / 180 + (rotOffset * 0.3);
      canvas.save();
      canvas.translate(lotusCenter.dx, lotusCenter.dy);
      canvas.rotate(angle);
      final ovalRect = Rect.fromCenter(
        center: Offset(26 * breathing, 0),
        width: 36 * breathing,
        height: 18 * breathing,
      );
      canvas.drawOval(ovalRect, petalPaint);
      canvas.restore();
    }

    // Glowing golden central sun core
    canvas.drawCircle(
      lotusCenter,
      16 * breathing,
      Paint()
        ..color = const Color(0xFFFDE68A).withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawCircle(
      lotusCenter,
      11 * breathing,
      Paint()..color = const Color(0xFFFFFBEB),
    );
  }

  @override
  bool shouldRepaint(covariant _AgeGraphicPainter oldDelegate) =>
      oldDelegate.ageGroup != ageGroup || oldDelegate.animValue != animValue;
}

// Reusable sacred temple Diya oil lamp with animated flickering flame
class _FlickeringDiyaWidget extends StatefulWidget {
  const _FlickeringDiyaWidget({this.size = 28});
  final double size;

  @override
  State<_FlickeringDiyaWidget> createState() => _FlickeringDiyaWidgetState();
}

class _FlickeringDiyaWidgetState extends State<_FlickeringDiyaWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..repeat(reverse: true);
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
      builder: (context, _) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _DiyaPainter(flicker: _controller.value),
        );
      },
    );
  }
}

class _DiyaPainter extends CustomPainter {
  _DiyaPainter({required this.flicker});
  final double flicker;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Brass Diya Lamp Bowl Base
    final bowlPath = Path()
      ..moveTo(w * 0.15, h * 0.65)
      ..quadraticBezierTo(w * 0.5, h * 0.98, w * 0.85, h * 0.65)
      ..quadraticBezierTo(w * 0.5, h * 0.75, w * 0.15, h * 0.65);

    final brassPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFEF08A), Color(0xFFD97706), Color(0xFF78350F)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, h * 0.5, w, h * 0.5));

    canvas.drawPath(bowlPath, brassPaint);

    // Diya Stand
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(w * 0.5, h * 0.94), width: w * 0.35, height: h * 0.1),
        const Radius.circular(2),
      ),
      brassPaint,
    );

    // Flame Flicker
    final flameHeight = h * (0.45 + 0.10 * flicker);
    final flameTilt = (flicker - 0.5) * (w * 0.08);

    // Outer Aura Glow
    canvas.drawCircle(
      Offset(w * 0.5 + flameTilt * 0.5, h * 0.42),
      w * (0.35 + 0.08 * flicker),
      Paint()
        ..color = const Color(0xFFF59E0B).withValues(alpha: 0.35 + 0.15 * flicker)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Outer Golden-Red Flame
    final flamePath = Path()
      ..moveTo(w * 0.35, h * 0.65)
      ..quadraticBezierTo(w * 0.25, h * 0.45, w * 0.5 + flameTilt, h * 0.65 - flameHeight)
      ..quadraticBezierTo(w * 0.75, h * 0.45, w * 0.65, h * 0.65)
      ..close();

    final flamePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFFBEB), Color(0xFFFBBF24), Color(0xFFEA580C)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(flamePath, flamePaint);

    // Bright White Hot Inner Core
    final corePath = Path()
      ..moveTo(w * 0.42, h * 0.63)
      ..quadraticBezierTo(w * 0.38, h * 0.50, w * 0.5 + flameTilt * 0.6, h * 0.63 - flameHeight * 0.65)
      ..quadraticBezierTo(w * 0.62, h * 0.50, w * 0.58, h * 0.63)
      ..close();

    canvas.drawPath(corePath, Paint()..color = Colors.white.withValues(alpha: 0.9));
  }

  @override
  bool shouldRepaint(covariant _DiyaPainter oldDelegate) =>
      oldDelegate.flicker != flicker;
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
          const _CircadianWaveGraphWidget(),
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

// =============================================================================
// 3. Interactive Mindful Pranayama Breathing Aura Visualizer
// =============================================================================

/// Animated Pranayama / Mindful Breathing Aura Sphere.
/// Provides real-time expanding and contracting glowing auric rings
/// with custom sacred geometry and age-tailored color harmonies.
class MindfulBreathingAuraWidget extends StatefulWidget {
  const MindfulBreathingAuraWidget({super.key});

  @override
  State<MindfulBreathingAuraWidget> createState() =>
      _MindfulBreathingAuraWidgetState();
}

class _MindfulBreathingAuraWidgetState extends State<MindfulBreathingAuraWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isPlaying = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    setState(() {
      if (_isPlaying) {
        _controller.stop();
        _isPlaying = false;
      } else {
        _controller.repeat(reverse: true);
        _isPlaying = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ageGroup = AgeProfileService.instance.ageGroup;
    final theme = AgeProfileService.instance.activeTheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: theme.primaryAccent.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: theme.primaryAccent.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.air_rounded, color: theme.primaryAccent, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mindful Aura & Breath Harmony',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                          color: AppColors.deepNavy,
                        ),
                      ),
                      Text(
                        '4-second rhythmic vagal reset',
                        style: TextStyle(fontSize: 11, color: AppColors.secondaryText),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                onPressed: _togglePlay,
                icon: Icon(
                  _isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                  color: theme.primaryAccent,
                  size: 26,
                ),
                tooltip: _isPlaying ? 'Pause Breathing' : 'Resume Breathing',
              ),
            ],
          ),
          const SizedBox(height: 18),
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final progress = _controller.value;
                final isInhaling = _controller.status == AnimationStatus.forward;
                final instruction = isInhaling ? 'Inhale Peace...' : 'Release Tension...';

                return Column(
                  children: [
                    SizedBox(
                      width: 180,
                      height: 180,
                      child: CustomPaint(
                        painter: _AuraBreathPainter(
                          progress: progress,
                          ageGroup: ageGroup,
                          primaryColor: theme.primaryAccent,
                          secondaryColor: theme.secondaryAccent,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.self_improvement_rounded,
                                size: 28,
                                color: theme.primaryAccent,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                instruction,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: theme.primaryAccent,
                                ),
                              ),
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
          const SizedBox(height: 10),
          Center(
            child: Text(
              'Aligns heart-rate variability (HRV) and calms prefrontal cortex activity.',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.secondaryText.withValues(alpha: 0.9),
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _AuraBreathPainter extends CustomPainter {
  _AuraBreathPainter({
    required this.progress,
    required this.ageGroup,
    required this.primaryColor,
    required this.secondaryColor,
  });

  final double progress;
  final AgeGroup ageGroup;
  final Color primaryColor;
  final Color secondaryColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width * 0.46;

    // Concentric expanding aura waves
    for (int i = 3; i >= 1; i--) {
      final ringScale = 0.4 + (progress * 0.45 * (i / 3.0));
      final ringRadius = maxRadius * ringScale;
      final opacity = ((1.0 - (ringScale * 0.7)) * 0.28).clamp(0.04, 0.4);

      final auraPaint = Paint()
        ..color = primaryColor.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, ringRadius, auraPaint);

      final rimPaint = Paint()
        ..color = secondaryColor.withValues(alpha: opacity * 1.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawCircle(center, ringRadius, rimPaint);
    }

    // Sacred petal geometry or orbital rays based on age
    if (ageGroup == AgeGroup.senior) {
      // Golden lotus petals expanding
      final petalPaint = Paint()
        ..color = const Color(0xFFD97706).withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4;

      const petalCount = 8;
      final petalDist = 36.0 + (progress * 14.0);
      for (int k = 0; k < petalCount; k++) {
        final angle = (k * 360 / petalCount) * math.pi / 180;
        final px = center.dx + math.cos(angle) * petalDist;
        final py = center.dy + math.sin(angle) * petalDist;
        canvas.drawCircle(Offset(px, py), 12 + (progress * 4), petalPaint);
      }
    } else if (ageGroup == AgeGroup.youth) {
      // Constellation stardust nodes
      final starPaint = Paint()
        ..color = const Color(0xFF00CEC9).withValues(alpha: 0.6)
        ..style = PaintingStyle.fill;

      const nodeCount = 6;
      final nodeDist = 42.0 + (progress * 16.0);
      for (int k = 0; k < nodeCount; k++) {
        final angle = (k * 360 / nodeCount + (progress * 30)) * math.pi / 180;
        final px = center.dx + math.cos(angle) * nodeDist;
        final py = center.dy + math.sin(angle) * nodeDist;
        canvas.drawCircle(Offset(px, py), 3.5, starPaint);
      }
    }

    // Core central sanctuary sphere
    final coreRadius = 38.0 + (progress * 6.0);
    final coreGradient = RadialGradient(
      colors: [
        Colors.white,
        primaryColor.withValues(alpha: 0.15),
      ],
    ).createShader(Rect.fromCircle(center: center, radius: coreRadius));

    final corePaint = Paint()..shader = coreGradient;
    canvas.drawCircle(center, coreRadius, corePaint);

    final coreBorder = Paint()
      ..color = primaryColor.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, coreRadius, coreBorder);
  }

  @override
  bool shouldRepaint(covariant _AuraBreathPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.ageGroup != ageGroup ||
      oldDelegate.primaryColor != primaryColor;
}

// =============================================================================
// 4. Rotating Celestial Orbit & Navagraha Constellation Map
// =============================================================================

/// Rotating Celestial Orbit & Navagraha Constellation Map.
/// Draws glowing elliptical planetary orbits, revolving planet nodes with trails,
/// and golden stardust particles.
class ZodiacCelestialOrbitWidget extends StatefulWidget {
  const ZodiacCelestialOrbitWidget({super.key});

  @override
  State<ZodiacCelestialOrbitWidget> createState() =>
      _ZodiacCelestialOrbitWidgetState();
}

class _ZodiacCelestialOrbitWidgetState extends State<ZodiacCelestialOrbitWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  String _selectedPlanet = 'Jupiter (Guru) - Wisdom & Growth';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E1B4B), Color(0xFF172554)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E1B4B).withValues(alpha: 0.4),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.stars_rounded, color: Color(0xFFFFD700), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Celestial Navagraha Orbit Matrix',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Text(
                  'Live Celestial Flow',
                  style: TextStyle(fontSize: 10, color: Color(0xFFFFD700), fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 190,
            width: double.infinity,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return CustomPaint(
                  painter: _CelestialOrbitPainter(rotation: _controller.value),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Text(
                'Active Alignment: $_selectedPlanet',
                style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CelestialOrbitPainter extends CustomPainter {
  _CelestialOrbitPainter({required this.rotation});

  final double rotation;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Background stardust twinkling
    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.4);
    final random = math.Random(42);
    for (int s = 0; s < 45; s++) {
      final sx = random.nextDouble() * size.width;
      final sy = random.nextDouble() * size.height;
      final sr = random.nextDouble() * 1.5 + 0.4;
      canvas.drawCircle(Offset(sx, sy), sr, starPaint);
    }

    // Central Radiant Sun
    final sunGradient = const RadialGradient(
      colors: [Color(0xFFFFF7ED), Color(0xFFF59E0B), Color(0xFFD97706)],
    ).createShader(Rect.fromCircle(center: center, radius: 18));
    final sunGlow = Paint()
      ..color = const Color(0xFFF59E0B).withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(center, 22, sunGlow);
    canvas.drawCircle(center, 14, Paint()..shader = sunGradient);

    // Planetary Orbits
    final orbitSpeeds = [1.0, 0.7, 0.45, 0.3, 0.2];
    final orbitRadii = [34.0, 52.0, 70.0, 86.0, 102.0];
    final planetColors = [
      const Color(0xFF38BDF8), // Mercury
      const Color(0xFFF472B6), // Venus
      const Color(0xFF34D399), // Earth / Chandra
      const Color(0xFFFB923C), // Mars
      const Color(0xFFFBBF24), // Jupiter
    ];
    final planetSizes = [4.0, 5.0, 5.5, 4.5, 7.0];

    final orbitLinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 0; i < orbitRadii.length; i++) {
      final r = orbitRadii[i];
      canvas.drawCircle(center, r, orbitLinePaint);

      // Planet position based on orbital speed
      final angle = (rotation * 2 * math.pi * orbitSpeeds[i]) + (i * 1.3);
      final px = center.dx + math.cos(angle) * r;
      final py = center.dy + math.sin(angle) * r;

      // Glow behind planet
      final pGlow = Paint()
        ..color = planetColors[i].withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(Offset(px, py), planetSizes[i] + 3, pGlow);

      // Planet body
      final pBody = Paint()..color = planetColors[i];
      canvas.drawCircle(Offset(px, py), planetSizes[i], pBody);

      // Connect subtle harmonic chord line to center
      if (i == 4) {
        final chordPaint = Paint()
          ..color = const Color(0xFFFFD700).withValues(alpha: 0.25)
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke;
        canvas.drawLine(center, Offset(px, py), chordPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CelestialOrbitPainter oldDelegate) =>
      oldDelegate.rotation != rotation;
}

// =============================================================================
// 5. Visual Neuroplasticity Synapse Map for Habit Formation
// =============================================================================

/// Visual Neuroplasticity Synapse Map for Habit Formation.
/// Renders an organic neural network with pulsating synaptic action potentials
/// illustrating how repeated habits myelinate into automatic pathways.
class NeuralSynapseGrowthMap extends StatefulWidget {
  const NeuralSynapseGrowthMap({
    super.key,
    required this.neuralScore,
    required this.habitCount,
    required this.activeStreak,
  });

  final int neuralScore;
  final int habitCount;
  final int activeStreak;

  @override
  State<NeuralSynapseGrowthMap> createState() => _NeuralSynapseGrowthMapState();
}

class _NeuralSynapseGrowthMapState extends State<NeuralSynapseGrowthMap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C5CE7).withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.psychology_rounded, color: Color(0xFF6C5CE7), size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Neural Pathway Synapse Network',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.deepNavy,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE9FE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${widget.neuralScore}% Myelinated',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6C5CE7),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 140,
            width: double.infinity,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _SynapsePainter(
                    pulse: _pulseController.value,
                    neuralScore: widget.neuralScore,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _metricPill(label: 'Tracked Habits', value: '${widget.habitCount} active'),
              _metricPill(label: 'Current Streak', value: '🔥 ${widget.activeStreak} days'),
              _metricPill(label: 'Automaticity', value: widget.neuralScore > 70 ? 'High' : 'Building'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricPill({required String label, required String value}) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.deepNavy)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.secondaryText)),
      ],
    );
  }
}

class _SynapsePainter extends CustomPainter {
  _SynapsePainter({required this.pulse, required this.neuralScore});

  final double pulse;
  final int neuralScore;

  @override
  void paint(Canvas canvas, Size size) {
    // 6 Synaptic node points forming a neural tree
    final nodes = [
      Offset(size.width * 0.12, size.height * 0.5),  // Input Root
      Offset(size.width * 0.35, size.height * 0.25), // Association Branch 1
      Offset(size.width * 0.35, size.height * 0.75), // Association Branch 2
      Offset(size.width * 0.65, size.height * 0.3),  // Reinforcement Node 1
      Offset(size.width * 0.65, size.height * 0.7),  // Reinforcement Node 2
      Offset(size.width * 0.88, size.height * 0.5),  // Automatic Habit Core
    ];

    final edges = [
      [0, 1],
      [0, 2],
      [1, 3],
      [2, 4],
      [3, 5],
      [4, 5],
      [1, 4], // Cross-hemispheric bridge
    ];

    // Draw synaptic axon lines
    final axonPaint = Paint()
      ..color = const Color(0xFF6C5CE7).withValues(alpha: 0.2)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final myelinatedPaint = Paint()
      ..color = const Color(0xFF00B894)
      ..strokeWidth = 3.2
      ..style = PaintingStyle.stroke;

    final isHighMyelination = neuralScore >= 60;

    for (final edge in edges) {
      final p1 = nodes[edge[0]];
      final p2 = nodes[edge[1]];
      canvas.drawLine(p1, p2, isHighMyelination ? myelinatedPaint : axonPaint);

      // Draw firing action potential particle moving along axon
      final signalT = (pulse + (edge[0] * 0.15)) % 1.0;
      final sx = p1.dx + (p2.dx - p1.dx) * signalT;
      final sy = p1.dy + (p2.dy - p1.dy) * signalT;

      final sparkGlow = Paint()
        ..color = const Color(0xFF00CEC9).withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(Offset(sx, sy), 5, sparkGlow);
      canvas.drawCircle(Offset(sx, sy), 2.5, Paint()..color = const Color(0xFF00CEC9));
    }

    // Draw synaptic nodes
    for (int i = 0; i < nodes.length; i++) {
      final p = nodes[i];
      final isCore = i == 0 || i == 5;

      final nodeGlow = Paint()
        ..color = (isCore ? const Color(0xFF6C5CE7) : const Color(0xFF00B894)).withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(p, isCore ? 14 : 10, nodeGlow);

      final nodeFill = Paint()
        ..color = isCore ? const Color(0xFF6C5CE7) : const Color(0xFF00B894);
      canvas.drawCircle(p, isCore ? 8 : 6, nodeFill);

      canvas.drawCircle(
        p,
        isCore ? 8 : 6,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SynapsePainter oldDelegate) =>
      oldDelegate.pulse != pulse || oldDelegate.neuralScore != neuralScore;
}

// =============================================================================
// 6. 3D Glowing Glass Spherical Energy Bubble Painter
// =============================================================================

/// Draws a luminous 3D glass/energy sphere with glowing aura,
/// specular highlights, and internal energy swirl for Explore Topics.
class Spherical3DBubblePainter extends CustomPainter {
  Spherical3DBubblePainter({
    required this.accentColor,
    required this.bgGradient,
    this.floatOffset = 0.0,
  });

  final Color accentColor;
  final List<Color> bgGradient;
  final double floatOffset;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + floatOffset);
    final radius = size.width * 0.46;

    // Outer luminous aura ring
    final auraPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawCircle(center, radius + 8, auraPaint);

    // 3D Spherical Radial Gradient
    final sphereGradient = RadialGradient(
      center: const Alignment(-0.35, -0.4),
      radius: 0.95,
      colors: [
        Colors.white.withValues(alpha: 0.9),
        bgGradient[0],
        bgGradient.length > 1 ? bgGradient[1] : bgGradient[0],
        accentColor.withValues(alpha: 0.95),
      ],
      stops: const [0.0, 0.35, 0.7, 1.0],
    ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, Paint()..shader = sphereGradient);

    // Subtle internal energy rings
    final ringPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, radius * 0.75, ringPaint);

    // Top-left curved specular light reflection
    final highlightPath = Path()
      ..addArc(
        Rect.fromCircle(center: Offset(center.dx - radius * 0.2, center.dy - radius * 0.25), radius: radius * 0.45),
        -math.pi * 0.8,
        math.pi * 0.6,
      );
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;
    canvas.drawPath(highlightPath, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant Spherical3DBubblePainter oldDelegate) =>
      oldDelegate.accentColor != accentColor ||
      oldDelegate.floatOffset != floatOffset;
}

// =============================================================================
// 6B. Living Visual Energy Conduit Connector (Eliminating Disjointed Blocks)
// =============================================================================

/// An animated glowing energy conduit that runs vertically between dashboard
/// sections, visually connecting them so they do not feel like separate blocks,
/// but rather a unified, continuous living life-flow pipeline.
class FlowConduitConnector extends StatefulWidget {
  const FlowConduitConnector({
    super.key,
    required this.title,
    this.subtitle,
    this.accentColor,
    this.height = 44,
  });

  final String title;
  final String? subtitle;
  final Color? accentColor;
  final double height;

  @override
  State<FlowConduitConnector> createState() => _FlowConduitConnectorState();
}

class _FlowConduitConnectorState extends State<FlowConduitConnector>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ageGroup = AgeProfileService.instance.ageGroup;
    final color = widget.accentColor ??
        switch (ageGroup) {
          AgeGroup.youth => const Color(0xFF00CEC9),
          AgeGroup.adult => const Color(0xFF2563EB),
          AgeGroup.senior => const Color(0xFFD97706),
        };

    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, _) {
          return CustomPaint(
            painter: _ConduitLinePainter(
              color: color,
              animValue: _animController.value,
            ),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4.5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.45), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.16),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.keyboard_double_arrow_down_rounded, size: 13, color: color),
                    const SizedBox(width: 5),
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: color,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Icon(Icons.keyboard_double_arrow_down_rounded, size: 13, color: color),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ConduitLinePainter extends CustomPainter {
  _ConduitLinePainter({
    required this.color,
    required this.animValue,
  });

  final Color color;
  final double animValue;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final h = size.height;

    // Glowing background line
    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.22)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(cx, 0), Offset(cx, h), linePaint);

    // Glowing travelling energy pulse particles
    final particlePaint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 3; i++) {
      final t = (animValue + (i * 0.33)) % 1.0;
      final y = t * h;
      final alpha = (math.sin(t * math.pi) * 0.9).clamp(0.2, 0.95);
      particlePaint.color = color.withValues(alpha: alpha);
      canvas.drawCircle(Offset(cx, y), 3.0, particlePaint);

      // Soft halo glow
      canvas.drawCircle(
        Offset(cx, y),
        6.0,
        Paint()
          ..color = color.withValues(alpha: alpha * 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ConduitLinePainter oldDelegate) =>
      oldDelegate.animValue != animValue || oldDelegate.color != color;
}

// =============================================================================
// 7. Connected Pillars Nexus Widget (Interconnected Holistic Ecosystem)
// =============================================================================

/// Interactive interconnected pentagonal nexus showing how Astrology, Health,
/// Habits, Finance, and Insights are interconnected in daily life as a continuous
/// life flow, eliminating isolated blocks and making the holistic cycle clear.
class ConnectedPillarsNexusWidget extends StatefulWidget {
  const ConnectedPillarsNexusWidget({
    super.key,
    required this.onOpenPillar,
  });

  final void Function(int pillarIndex) onOpenPillar;

  @override
  State<ConnectedPillarsNexusWidget> createState() =>
      _ConnectedPillarsNexusWidgetState();
}

class _ConnectedPillarsNexusWidgetState
    extends State<ConnectedPillarsNexusWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  int _selectedPillar = 0; // 0: Astrology, 1: Health, 2: Habits, 3: Finance, 4: Insights

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getPillars(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.telugu:
        return [
          {
            'name': 'జ్యోతిషం',
            'role': 'కాస్మిక్ & సర్కాడియన్ క్లాక్',
            'color': const Color(0xFF6C5CE7),
            'icon': Icons.nightlight_round,
            'fedFrom': 'విశ్లేషణలు (ఆత్మ సంకల్పం & కర్మ సమతుల్యత)',
            'feedsInto': 'ఆరోగ్యం (నిద్ర & జీవన లయ సమయాలు)',
            'synergy': 'సూర్య, చంద్ర గ్రహ స్థానాల ఆధారంగా ఉదయపు ఏకాగ్రతా వేళలను (10:00 AM - 1:30 PM) నిర్దేశిస్తుంది.',
            'connectsTo': 'ఆరోగ్యానికి సరైన నిద్ర వేళలు, జీర్ణక్రియ సమయాలను అందిస్తుంది.',
            'practicalImpact': 'కాస్మిక్ వేళల్లో జీవించడం వల్ల మెదడు అలసట 35% తగ్గి సహజ శక్తి పెరుగుతుంది.',
            'nextName': 'ఆరోగ్యం',
          },
          {
            'name': 'ఆరోగ్యం',
            'role': 'శరీర శక్తి & ఆయుర్వేదం',
            'color': const Color(0xFF00CEC9),
            'icon': Icons.favorite_rounded,
            'fedFrom': 'జ్యోతిషం (సర్కాడియన్ నిద్ర వేళలు)',
            'feedsInto': 'అలవాట్లు (సాధన & ఏకాగ్రత సంకల్పం)',
            'synergy': 'పిత్త-కఫ సమతుల్యత, గాఢ నిద్ర మరియు సమతుల్య పోషణ ద్వారా శరీర రోగనిరోధక శక్తిని ఇస్తుంది.',
            'connectsTo': 'రోజువారీ అలవాట్లను క్రమశిక్షణతో ఆచరించడానికి అవసరమైన దృఢ సంకల్ప శక్తిని ఇస్తుంది.',
            'practicalImpact': 'గాఢ నిద్ర మరియు హైడ్రేషన్ ఉదయం 25 నిమిషాల డీప్ వర్క్ స్ప్రింట్‌లకు అపార శక్తినిస్తాయి.',
            'nextName': 'అలవాట్లు',
          },
          {
            'name': 'అలవాట్లు',
            'role': 'రోజువారీ సాధన & లక్ష్యాలు',
            'color': const Color(0xFFE17055),
            'icon': Icons.track_changes_rounded,
            'fedFrom': 'ఆరోగ్యం (శారీరక శక్తి & నిశ్చల మనస్సు)',
            'feedsInto': 'ఆర్థికం (క్రమశిక్షణ & స్పృహతో కూడిన వ్యయం)',
            'synergy': '25 నిమిషాల ఏకాగ్రత మరియు రోజూ స్థిరమైన దినచర్యల ద్వారా న్యూరల్ మార్గాలను బలపరుస్తుంది.',
            'connectsTo': 'ఒత్తిడితో కూడిన అనవసర ఖర్చులను నియంత్రించి ఆర్థిక ప్రశాంతతను కాపాడుతుంది.',
            'practicalImpact': 'స్థిరమైన అలవాట్లు డోపమైన్ కోసం చేసే అనవసర కొనుగోళ్లను అరికట్టి ₹12,000+ ఆదా చేస్తాయి.',
            'nextName': 'ఆర్థికం',
          },
          {
            'name': 'ఆర్థికం',
            'role': 'స్పృహతో కూడిన సంపద & బడ్జెట్',
            'color': const Color(0xFF00B894),
            'icon': Icons.account_balance_wallet_rounded,
            'fedFrom': 'అలవాట్లు (క్రమశిక్షణ & సంతృప్తి భావన)',
            'feedsInto': 'విశ్లేషణలు (మానసిక ప్రశాంతత & సమగ్ర జీవన సూచిక)',
            'synergy': 'క్రమశిక్షణతో కూడిన బడ్జెట్ మరియు 24-గంటల ఆలోచనా వ్యవధి ఆర్థిక స్వేచ్ఛను ఇస్తాయి.',
            'connectsTo': 'డబ్బు ఆందోళనలను తొలగించి, ప్రశాంత ధ్యానం మరియు విశ్లేషణలకు మనస్సును స్వేచ్ఛ చేస్తుంది.',
            'practicalImpact': 'అప్పులు, అనవసర ఖర్చులు లేకపోవడం వల్ల నిద్ర నాణ్యత మరియు మానసిక ప్రశాంతత పెరుగుతాయి.',
            'nextName': 'విశ్లేషణలు',
          },
          {
            'name': 'విశ్లేషణలు',
            'role': 'జీవిత సమగ్ర సమతుల్యత',
            'color': const Color(0xFFE84393),
            'icon': Icons.auto_graph_rounded,
            'fedFrom': 'ఆర్థికం (ఆర్థిక భద్రత & మనశ్శాంతి)',
            'feedsInto': 'జ్యోతిషం (ఆత్మ కర్మ చక్ర సమలేఖనం)',
            'synergy': 'అన్ని 4 విభాగాలను సంశ్లేషణ చేసి 88% సంపూర్ణ జీవన సూచికను లెక్కిస్తుంది.',
            'connectsTo': 'జీవిత సమగ్ర వృద్ధిని మీ ఆత్మ కర్మ వికాసంతో తిరిగి జోడించి చక్రం పూర్తి చేస్తుంది.',
            'practicalImpact': 'వారం వారం మీ సమగ్ర సమతుల్యత పెరిగేకొద్దీ జీవితంలో స్థిరత్వం, ఆనందం సాధ్యమవుతాయి.',
            'nextName': 'జ్యోతిషం',
          },
        ];
      case AppLanguage.tanglish:
        return [
          {
            'name': 'Astrology',
            'role': 'Cosmic & Circadian Clock',
            'color': const Color(0xFF6C5CE7),
            'icon': Icons.nightlight_round,
            'fedFrom': 'Insights (Soul Alignment & Balance)',
            'feedsInto': 'Health (Sleep & Nutrition Hours)',
            'synergy': 'Sun & Moon positions base chesukuni peak focus time (10 AM - 1:30 PM) ni guide chestundi.',
            'connectsTo': 'Health ki correct sleep timings and nutrition rhythm istundi.',
            'practicalImpact': 'Cosmic hours lo unte mental fatigue taggi naturally active ga untaru.',
            'nextName': 'Health',
          },
          {
            'name': 'Health',
            'role': 'Body Energy & Ayurveda',
            'color': const Color(0xFF00CEC9),
            'icon': Icons.favorite_rounded,
            'fedFrom': 'Astrology (Circadian Sleep Cycles)',
            'feedsInto': 'Habits (Willpower & Routine Energy)',
            'synergy': 'Pitta-Kapha balance, deep rest and hydration tho body vitality ni boost chestundi.',
            'connectsTo': 'Daily habits consistent ga cheyadaniki solid physical willpower istundi.',
            'practicalImpact': 'Good sleep valla morning study and work blocks lo 100% focus untundi.',
            'nextName': 'Habits',
          },
          {
            'name': 'Habits',
            'role': 'Daily Sadhana & Focus',
            'color': const Color(0xFFE17055),
            'icon': Icons.track_changes_rounded,
            'fedFrom': 'Health (High Energy & Mental Rest)',
            'feedsInto': 'Finance (Self-Control & Mindful Spending)',
            'synergy': '25-minute Pomodoro focus sprints and evening routines tho mind ni train chestundi.',
            'connectsTo': 'Stress-spending ni stop chesi financial peace ni protect chestundi.',
            'practicalImpact': 'Mindful routines valla impulsive online shopping aagi money save avtundi.',
            'nextName': 'Finance',
          },
          {
            'name': 'Finance',
            'role': 'Mindful Wealth & Budget',
            'color': const Color(0xFF00B894),
            'icon': Icons.account_balance_wallet_rounded,
            'fedFrom': 'Habits (Discipline & Contentment)',
            'feedsInto': 'Insights (Peace of Mind & Life Score)',
            'synergy': 'Disciplined monthly budgeting and 24-hr cooling pause financial freedom istundi.',
            'connectsTo': 'Money tension teesesi peaceful meditation and self-insights ki scope istundi.',
            'practicalImpact': 'No financial worry leads to deeper restful sleep and anxiety-free life.',
            'nextName': 'Insights',
          },
          {
            'name': 'Insights',
            'role': 'Holistic Life Synthesis',
            'color': const Color(0xFFE84393),
            'icon': Icons.auto_graph_rounded,
            'fedFrom': 'Finance (Financial Stability & Peace)',
            'feedsInto': 'Astrology (Full Karmic Alignment)',
            'synergy': 'Anni 4 pillars data ni analyze chesi 88% Life Harmony Index generate chestundi.',
            'connectsTo': 'Life growth ni karmic evolution tho re-align chesi circle complete chestundi.',
            'practicalImpact': 'Tracking your overall harmony keeps you peaceful and balanced every single day.',
            'nextName': 'Astrology',
          },
        ];
      case AppLanguage.malayalam:
        return [
          {
            'name': 'ജ്യോതിഷം',
            'role': 'കോസ്മിക് & സർക്കാഡിയൻ ക്ലോക്ക്',
            'color': const Color(0xFF6C5CE7),
            'icon': Icons.nightlight_round,
            'fedFrom': 'സ്ഥിതിവിവരക്കണക്കുകൾ (ആത്മീയ സമനില)',
            'feedsInto': 'ആരോഗ്യം (ഉറക്കവും ജീവനരീതിയും)',
            'synergy': 'സൂര്യ-ചന്ദ്ര സ്ഥാനങ്ങളെ അടിസ്ഥാനമാക്കി ഏകാഗ്രതയുള്ള സമയം (10 AM - 1:30 PM) നിർണ്ണയിക്കുന്നു.',
            'connectsTo': 'ആരോഗ്യത്തിന് അനുയോജ്യമായ ഉറക്ക സമയവും ഭക്ഷണ സമയവും നൽകുന്നു.',
            'practicalImpact': 'പ്രകൃതി നിയമങ്ങളോടൊപ്പം ജീവിക്കുമ്പോൾ മാനസിക ഉന്മേഷം 35% വർദ്ധിക്കുന്നു.',
            'nextName': 'ആരോഗ്യം',
          },
          {
            'name': 'ആരോഗ്യം',
            'role': 'ശരീര ഊർജ്ജവും ആയുർവേദവും',
            'color': const Color(0xFF00CEC9),
            'icon': Icons.favorite_rounded,
            'fedFrom': 'ജ്യോതിഷം (സർക്കാഡിയൻ ഉറക്ക സമയം)',
            'feedsInto': 'ശീലങ്ങൾ (ദൈനംദിന ഇച്ഛാശക്തി)',
            'synergy': 'പിത്ത-കഫ സന്തുലിതാവസ്ഥയും ഗാഢനിദ്രയും നൽകി ശരീരത്തിന് പ്രതിരോധശേഷി നൽകുന്നു.',
            'connectsTo': 'ദൈനംദിന ശീലങ്ങൾ കൃത്യമായി പാലിക്കാൻ ആവശ്യമായ മനക്കരുത്ത് നൽകുന്നു.',
            'practicalImpact': 'നല്ല ഉറക്കവും ശുദ്ധജലവും രാവിലെ പഠനത്തിനും ജോലിക്കും അപാര ഊർജ്ജം നൽകുന്നു.',
            'nextName': 'ശീലങ്ങൾ',
          },
          {
            'name': 'ശീലങ്ങൾ',
            'role': 'ദൈനംദിന സാധനയും ലക്ഷ്യങ്ങളും',
            'color': const Color(0xFFE17055),
            'icon': Icons.track_changes_rounded,
            'fedFrom': 'ആരോഗ്യം (ശാരീരിക കരുത്തും പ്രശാന്തതയും)',
            'feedsInto': 'ധനകാര്യം (സാമ്പത്തിക നിയന്ത്രണം)',
            'synergy': '25 മിനിറ്റ് ഏകാഗ്രതയും സ്ഥിരമായ ദിനചര്യകളും തലച്ചോറിനെ ശക്തിപ്പെടുത്തുന്നു.',
            'connectsTo': 'അനാവശ്യ ചെലവുകൾ ഒഴിവാക്കി സാമ്പത്തിക ഭദ്രത സംരക്ഷിക്കുന്നു.',
            'practicalImpact': 'അനാവശ്യ ഓൺലൈൻ പർച്ചേസുകൾ ഒഴിവാക്കി സാമ്പത്തിക സ്വാതന്ത്ര്യം നൽകുന്നു.',
            'nextName': 'ധനകാര്യം',
          },
          {
            'name': 'ധനകാര്യം',
            'role': 'ബജറ്റും സമ്പത്തും',
            'color': const Color(0xFF00B894),
            'icon': Icons.account_balance_wallet_rounded,
            'fedFrom': 'ശീലങ്ങൾ (ആത്മനിയന്ത്രണവും സംതൃപ്തിയും)',
            'feedsInto': 'സ്ഥിതിവിവരക്കണക്കുകൾ (മനസ്സമാധാനം)',
            'synergy': 'കൃത്യമായ ബജറ്റും ചെലവ് നിയന്ത്രണവും സാമ്പത്തിക സുരക്ഷിതത്വം ഉറപ്പാക്കുന്നു.',
            'connectsTo': 'സാമ്പത്തിക ഉത്കണ്ഠകൾ ഒഴിവാക്കി പ്രശാന്തമായ ധ്യാനത്തിന് വഴി നൽകുന്നു.',
            'practicalImpact': 'സാമ്പത്തിക സമാധാനം ഉറക്കത്തിന്റെ ഗുണനിലവാരവും സന്തോഷവും വർദ്ധിപ്പിക്കുന്നു.',
            'nextName': 'സ്ഥിതിവിവരക്കണക്കുകൾ',
          },
          {
            'name': 'സ്ഥിതിവിവരക്കണക്കുകൾ',
            'role': 'ജീവിത സന്തുലിതാവസ്ഥ',
            'color': const Color(0xFFE84393),
            'icon': Icons.auto_graph_rounded,
            'fedFrom': 'ധനകാര്യം (സാമ്പത്തിക സമാധാനം)',
            'feedsInto': 'ജ്യോതിഷം (ആത്മീയ കർമ്മ ചക്രം)',
            'synergy': 'നാല് ഘടകങ്ങളെയും സംയോജിപ്പിച്ച് 88% സമഗ്ര ജീവിത സൂചിക കണക്കാക്കുന്നു.',
            'connectsTo': 'ജീവിത വിജയത്തെ ആത്മീയ വളർച്ചയുമായി വീണ്ടും ബന്ധിപ്പിച്ച് ചക്രം പൂർത്തിയാക്കുന്നു.',
            'practicalImpact': 'ദിവസേന നിങ്ങളുടെ ജീവിത സന്തുലിതാവസ്ഥ വിലയിരുത്തി സമാധാനത്തോടെ മുന്നേറുക.',
            'nextName': 'ജ്യോതിഷം',
          },
        ];
      case AppLanguage.manglish:
      case AppLanguage.english:
        return [
          {
            'name': 'Astrology',
            'role': 'Cosmic & Circadian Clock',
            'color': const Color(0xFF6C5CE7),
            'icon': Icons.nightlight_round,
            'fedFrom': 'Insights (Soul Alignment & Balance)',
            'feedsInto': 'Health (Circadian Wake & Sleep Hours)',
            'synergy': 'Aligns daily mental focus windows (10:00 AM - 1:30 PM) using planetary hora and lunar cycles.',
            'connectsTo': 'Feeds biological wake times, Agni digestive cycles, and melatonin rhythm into Health.',
            'practicalImpact': 'Living in circadian sync drops brain fog by 35% and boosts natural morning vitality.',
            'nextName': 'Health',
          },
          {
            'name': 'Health',
            'role': 'Vital Body, Rest & Ayurveda',
            'color': const Color(0xFF00CEC9),
            'icon': Icons.favorite_rounded,
            'fedFrom': 'Astrology (Circadian Rhythm)',
            'feedsInto': 'Habits (Willpower & Routine Energy)',
            'synergy': 'Maintains Pitta-Kapha balance, deep restorative sleep, and low stress cortisol levels.',
            'connectsTo': 'Supplies the physiological willpower needed to maintain disciplined daily Habits.',
            'practicalImpact': 'Deep restorative sleep directly powers your 25m deep-focus study blocks without burnout.',
            'nextName': 'Habits',
          },
          {
            'name': 'Habits',
            'role': 'Daily Sadhana & Execution',
            'color': const Color(0xFFE17055),
            'icon': Icons.track_changes_rounded,
            'fedFrom': 'Health (Physical Energy & Rested Mind)',
            'feedsInto': 'Finance (Conscious Spending Discipline)',
            'synergy': 'Builds strong neural pathways through 25m Pomodoro sprints and mindful evening wind-downs.',
            'connectsTo': 'Prevents dopamine-seeking impulse spending, guarding Mindful Finance.',
            'practicalImpact': 'Consistent daily routines stop impulsive online shopping, saving ₹12,000+ monthly.',
            'nextName': 'Finance',
          },
          {
            'name': 'Finance',
            'role': 'Mindful Wealth & Artha Harmony',
            'color': const Color(0xFF00B894),
            'icon': Icons.account_balance_wallet_rounded,
            'fedFrom': 'Habits (Self-Control & Contentment)',
            'feedsInto': 'Insights (Mental Peace & Harmony Score)',
            'synergy': 'Disciplined budgeting and 24-hr cooling pauses remove financial insecurity.',
            'connectsTo': 'Removes financial anxiety, creating mental stillness for Insights and meditation.',
            'practicalImpact': 'Zero money stress leads directly to restful sleep and anxiety-free self-reflection.',
            'nextName': 'Insights',
          },
          {
            'name': 'Insights',
            'role': 'Holistic Life Synthesis',
            'color': const Color(0xFFE84393),
            'icon': Icons.auto_graph_rounded,
            'fedFrom': 'Finance (Financial Freedom & Peace)',
            'feedsInto': 'Astrology (Completing the Karmic Loop)',
            'synergy': 'Synthesizes all 4 components into a unified 88% Holistic Life Index.',
            'connectsTo': 'Closes the sacred loop by aligning ongoing life growth with your soul\'s karmic destiny.',
            'practicalImpact': 'Seeing your unified harmony score gives you crystal-clear clarity on where to grow.',
            'nextName': 'Astrology',
          },
        ];
    }
  }

  void _showFlowExplanationDialog(BuildContext context) {
    final lang = AppLanguageService.instance.currentLanguage;
    final pillars = _getPillars(lang);

    final title = switch (lang) {
      AppLanguage.telugu => '🔗 5 విభాగాల సంపూర్ణ అనుసంధానం',
      AppLanguage.tanglish => '🔗 5 Pillars Connected Life Flow',
      AppLanguage.malayalam => '🔗 5 ഘടകങ്ങളുടെ പരസ്പര ബന്ധം',
      AppLanguage.manglish => '🔗 5 Pillars Connected Life Flow',
      AppLanguage.english => '🔗 How All 5 Life Pillars Connect as One Flow',
    };

    final subtitle = switch (lang) {
      AppLanguage.telugu => 'AVARA ప్రత్యేకత: ఇవి వేర్వేరు భాగాలు కావు — ఒకదానితో ఒకటి అనుసంధానమైన ఏకైక జీవన ప్రవాహం.',
      AppLanguage.tanglish => 'AVARA uniqueness: These are not separate blocks — they form one continuous connected life loop.',
      AppLanguage.malayalam => 'ഇവ വെവ്വേറെ ബ്ലോക്കുകളല്ല — പരസ്പരം ബന്ധിതമായ ഒരു സമ്പൂർണ്ണ ജീവിത പ്രവാഹമാണ്.',
      AppLanguage.manglish => 'These are not separate blocks — they form one continuous connected life loop.',
      AppLanguage.english => 'AVARA philosophy: These are not separate apps — they form one unbreakable cause-and-effect life loop.',
    };

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.blue.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.all_inclusive_rounded, color: AppColors.blue, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.deepNavy),
                        ),
                        Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.secondaryText, height: 1.3)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Divider(),
              const SizedBox(height: 12),
              for (int i = 0; i < 5; i++) ...[
                _buildFlowLoopStepCard(
                  stepNum: i + 1,
                  current: pillars[i],
                  next: pillars[(i + 1) % 5],
                  isLast: i == 4,
                ),
                if (i < 4) ...[
                  Center(
                    child: Container(
                      height: 22,
                      width: 2,
                      color: (pillars[i]['color'] as Color).withValues(alpha: 0.35),
                      margin: const EdgeInsets.symmetric(vertical: 2),
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 18),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(ctx).pop(),
                  icon: const Icon(Icons.check_circle_rounded, size: 18),
                  label: const Text('Got It! I Understand the Flow', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFlowLoopStepCard({
    required int stepNum,
    required Map<String, dynamic> current,
    required Map<String, dynamic> next,
    required bool isLast,
  }) {
    final color = current['color'] as Color;
    final nextColor = next['color'] as Color;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    child: Center(
                      child: Text(
                        '$stepNum',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(current['icon'] as IconData, size: 18, color: color),
                  const SizedBox(width: 6),
                  Text(
                    '${current['name']} (${current['role']})',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Feeds ➔',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: nextColor),
                  ),
                  const SizedBox(width: 4),
                  Icon(next['icon'] as IconData, size: 14, color: nextColor),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '⚡ How it functions: ${current['synergy']}',
            style: const TextStyle(fontSize: 11, color: AppColors.deepNavy, height: 1.35),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.link_rounded, size: 15, color: nextColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${current['name']} ──► ${next['name']}: ${current['connectsTo']}',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: nextColor, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLanguageService.instance.currentLanguage;
    final pillars = _getPillars(lang);
    final activePillar = pillars[_selectedPillar];
    final activeColor = activePillar['color'] as Color;
    final nextIdx = (_selectedPillar + 1) % 5;
    final nextPillar = pillars[nextIdx];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: activeColor.withValues(alpha: 0.35), width: 1.8),
        boxShadow: [
          BoxShadow(
            color: activeColor.withValues(alpha: 0.12),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Ecosystem title + 88% In Sync badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: activeColor.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.all_inclusive_rounded, color: activeColor, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        switch (lang) {
                          AppLanguage.telugu => 'జీవన సమగ్ర ప్రవాహం',
                          AppLanguage.tanglish => 'Unified Life Ecosystem',
                          AppLanguage.malayalam => 'സമഗ്ര ജീവിത പ്രവാഹം',
                          AppLanguage.manglish => 'Unified Life Ecosystem',
                          AppLanguage.english => 'Unified Life Ecosystem',
                        },
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15.5,
                          color: AppColors.deepNavy,
                        ),
                      ),
                      Text(
                        switch (lang) {
                          AppLanguage.telugu => '5 విభాగాలు అనుసంధానమై నిరంతరం ప్రవహిస్తాయి',
                          AppLanguage.tanglish => '5 pillars connected as one seamless life flow',
                          AppLanguage.malayalam => '5 ഘടകങ്ങളും പരസ്പരം ബന്ധിതമായ ഒരു പ്രവാഹം',
                          AppLanguage.manglish => '5 pillars connected as one seamless life flow',
                          AppLanguage.english => 'All 5 pillars connected as one continuous life flow',
                        },
                        style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF00B894).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF00B894).withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.link_rounded, size: 14, color: Color(0xFF00B894)),
                    SizedBox(width: 4),
                    Text(
                      '88% In Sync',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00B894),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 1. Horizontal Connected Flow Ribbon (Shows sequential 1 -> 2 -> 3 -> 4 -> 5 -> 1)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (int i = 0; i < 5; i++) ...[
                    GestureDetector(
                      onTap: () => setState(() => _selectedPillar = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _selectedPillar == i ? (pillars[i]['color'] as Color) : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: pillars[i]['color'] as Color,
                            width: _selectedPillar == i ? 1.8 : 1.0,
                          ),
                          boxShadow: _selectedPillar == i
                              ? [
                                  BoxShadow(
                                    color: (pillars[i]['color'] as Color).withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              pillars[i]['icon'] as IconData,
                              size: 14,
                              color: _selectedPillar == i ? Colors.white : (pillars[i]['color'] as Color),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${i + 1}. ${pillars[i]['name']}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _selectedPillar == i ? Colors.white : AppColors.deepNavy,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (i < 4) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: _selectedPillar == i
                              ? (pillars[i]['color'] as Color)
                              : Colors.grey.shade400,
                        ),
                      ),
                    ] else ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          Icons.replay_rounded,
                          size: 14,
                          color: _selectedPillar == 4
                              ? (pillars[4]['color'] as Color)
                              : Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 2. Nexus Interactive Canvas Graph (Central pulsing hub with directed closed energy loop)
          SizedBox(
            height: 230,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _NexusPainter(
                    pulse: _pulseController.value,
                    selectedPillar: _selectedPillar,
                  ),
                  child: Stack(
                    children: [
                      // Center AVARA Core Hub
                      Center(
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [activeColor, activeColor.withValues(alpha: 0.75)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: activeColor.withValues(alpha: 0.35),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('AVARA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10.5, letterSpacing: 0.8)),
                                Text('Life Nexus', style: TextStyle(color: Colors.white70, fontSize: 8.5)),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Surrounding 5 Interactive Pillar Nodes
                      ...List.generate(5, (index) {
                        final p = pillars[index];
                        final pColor = p['color'] as Color;
                        final angle = (index * 72 - 90) * math.pi / 180;

                        return Align(
                          alignment: Alignment(
                            math.cos(angle) * 0.88,
                            math.sin(angle) * 0.88,
                          ),
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedPillar = index),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: _selectedPillar == index ? pColor : Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: pColor,
                                  width: _selectedPillar == index ? 2.8 : 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: pColor.withValues(alpha: _selectedPillar == index ? 0.4 : 0.15),
                                    blurRadius: _selectedPillar == index ? 12 : 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  p['icon'] as IconData,
                                  color: _selectedPillar == index ? Colors.white : pColor,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),

          // 3. Interconnection Detail Card (Explains Incoming & Outgoing Life Flow)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: activeColor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: activeColor.withValues(alpha: 0.25), width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top: Step indicator & Open Pillar link
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: activeColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Step ${_selectedPillar + 1} of 5',
                            style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${activePillar['name']} • ${activePillar['role']}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                            color: activeColor,
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () => widget.onOpenPillar(_selectedPillar),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        child: Row(
                          children: [
                            Text('Open ${activePillar['name']}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: activeColor)),
                            const SizedBox(width: 3),
                            Icon(Icons.arrow_forward_rounded, size: 13, color: activeColor),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Connected Inflow & Outflow Badges
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: activeColor.withValues(alpha: 0.18)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.arrow_downward_rounded, size: 14, color: Color(0xFF64748B)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(fontSize: 11, color: AppColors.deepNavy, height: 1.3),
                                children: [
                                  const TextSpan(text: 'Incoming Energy: ', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                                  TextSpan(text: activePillar['fedFrom'] as String),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.arrow_forward_rounded, size: 14, color: activeColor),
                          const SizedBox(width: 6),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(fontSize: 11, color: AppColors.deepNavy, height: 1.3),
                                children: [
                                  TextSpan(text: 'Direct Outflow: ', style: TextStyle(fontWeight: FontWeight.bold, color: activeColor)),
                                  TextSpan(text: activePillar['feedsInto'] as String),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Daily Impact
                Text(
                  '⚡ Daily Life Impact: ${activePillar['practicalImpact']}',
                  style: TextStyle(fontSize: 11, color: activeColor.withValues(alpha: 0.95), fontWeight: FontWeight.w600, height: 1.35),
                ),
                const SizedBox(height: 12),

                // Actions: Advance to Next Step + Understand Complete Loop
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showFlowExplanationDialog(context),
                        icon: const Icon(Icons.lightbulb_rounded, size: 15),
                        label: const Text(
                          '💡 How It Connects',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: activeColor,
                          side: BorderSide(color: activeColor.withValues(alpha: 0.5)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _selectedPillar = nextIdx;
                          });
                        },
                        icon: const Icon(Icons.arrow_forward_rounded, size: 15),
                        label: Text(
                          'Next Flow: ${nextPillar['name']} ➔',
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: activeColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
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

class _NexusPainter extends CustomPainter {
  _NexusPainter({
    required this.pulse,
    required this.selectedPillar,
  });

  final double pulse;
  final int selectedPillar;

  static const List<Color> pillarColors = [
    Color(0xFF6C5CE7), // Astrology
    Color(0xFF00CEC9), // Health
    Color(0xFFE17055), // Habits
    Color(0xFF00B894), // Finance
    Color(0xFFE84393), // Insights
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.height * 0.39;

    // Calculate the 5 pillar node positions
    final nodePoints = List.generate(5, (i) {
      final angle = (i * 72 - 90) * math.pi / 180;
      return Offset(center.dx + math.cos(angle) * radius, center.dy + math.sin(angle) * radius);
    });

    // Draw connecting closed pentagonal loop (Astrology -> Health -> Habits -> Finance -> Insights -> Astrology)
    final loopPaint = Paint()
      ..color = const Color(0xFF6C5CE7).withValues(alpha: 0.18)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;

    final loopPath = Path()..moveTo(nodePoints[0].dx, nodePoints[0].dy);
    for (int i = 1; i < 5; i++) {
      loopPath.lineTo(nodePoints[i].dx, nodePoints[i].dy);
    }
    loopPath.close();
    canvas.drawPath(loopPath, loopPaint);

    // Draw active flow glow between selected pillar and the next pillar
    final nextIdx = (selectedPillar + 1) % 5;
    final activeEdgePaint = Paint()
      ..color = pillarColors[selectedPillar].withValues(alpha: 0.75)
      ..strokeWidth = 3.6
      ..style = PaintingStyle.stroke;
    canvas.drawLine(nodePoints[selectedPillar], nodePoints[nextIdx], activeEdgePaint);

    // Draw lines connecting each pillar to the central AVARA hub
    for (int i = 0; i < 5; i++) {
      final isSel = selectedPillar == i;
      final spokePaint = Paint()
        ..color = isSel
            ? pillarColors[i].withValues(alpha: 0.55)
            : Colors.grey.withValues(alpha: 0.18)
        ..strokeWidth = isSel ? 2.5 : 1.2
        ..style = PaintingStyle.stroke;
      canvas.drawLine(center, nodePoints[i], spokePaint);

      // Draw flowing energy sparks moving between nodes
      final p1 = nodePoints[i];
      final p2 = nodePoints[(i + 1) % 5];
      final t = (pulse + (i * 0.2)) % 1.0;
      final sparkPos = Offset(p1.dx + (p2.dx - p1.dx) * t, p1.dy + (p2.dy - p1.dy) * t);

      final sparkPaint = Paint()..color = pillarColors[i].withValues(alpha: 0.7);
      canvas.drawCircle(sparkPos, 3.5, sparkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _NexusPainter oldDelegate) =>
      oldDelegate.pulse != pulse ||
      oldDelegate.selectedPillar != selectedPillar;
}

// =============================================================================
// 8. Unified Daily Holistic Synergy Stream (Chronological Connected Flow)
// =============================================================================

/// Chronological connected flow showing how today's Astrology, Health, Habits,
/// Finance, and Insights work together as one seamless progression.
class UnifiedHolisticSynergyStream extends StatelessWidget {
  const UnifiedHolisticSynergyStream({
    super.key,
    required this.onOpenPillar,
  });

  final void Function(int pillarIndex) onOpenPillar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
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
                  Icon(Icons.timeline_rounded, color: AppColors.blue, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Today’s Integrated Life Stream',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.5,
                      color: AppColors.deepNavy,
                    ),
                  ),
                ],
              ),
              Text(
                '5 Pillars Aligned',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          _buildStreamStep(
            index: 0,
            icon: Icons.nightlight_round,
            color: const Color(0xFF6C5CE7),
            pillarName: 'Astrology',
            timing: 'Dawn (06:00 AM)',
            action: 'Mercury in 10th house favors strategic decision making & study.',
            isLast: false,
          ),
          _buildStreamStep(
            index: 1,
            icon: Icons.favorite_rounded,
            color: const Color(0xFF00CEC9),
            pillarName: 'Health',
            timing: 'Morning (07:30 AM)',
            action: 'Hydrate with warm water & 15m sunlight walk to prime dopamine.',
            isLast: false,
          ),
          _buildStreamStep(
            index: 2,
            icon: Icons.track_changes_rounded,
            color: const Color(0xFFE17055),
            pillarName: 'Habits',
            timing: 'Midday Focus (10:00 AM)',
            action: 'Execute your 25-minute Pomodoro deep work sprint without phone.',
            isLast: false,
          ),
          _buildStreamStep(
            index: 3,
            icon: Icons.account_balance_wallet_rounded,
            color: const Color(0xFF00B894),
            pillarName: 'Finance',
            timing: 'Afternoon (03:00 PM)',
            action: 'Apply the 24-hr cooling pause on non-essential online retail.',
            isLast: false,
          ),
          _buildStreamStep(
            index: 4,
            icon: Icons.auto_graph_rounded,
            color: const Color(0xFFE84393),
            pillarName: 'Insights',
            timing: 'Evening (08:30 PM)',
            action: 'Review your 88% holistic synergy score and reflect on growth.',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStreamStep({
    required int index,
    required IconData icon,
    required Color color,
    required String pillarName,
    required String timing,
    required String action,
    required bool isLast,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step timeline indicator
          Column(
            children: [
              GestureDetector(
                onTap: () => onOpenPillar(index),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 1.5),
                  ),
                  child: Icon(icon, size: 16, color: color),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: color.withValues(alpha: 0.3),
                    margin: const EdgeInsets.symmetric(vertical: 2),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          // Step content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
              child: GestureDetector(
                onTap: () => onOpenPillar(index),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$pillarName • $timing',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        Icon(Icons.chevron_right, size: 16, color: color.withValues(alpha: 0.7)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      action,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.deepNavy,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 8. Interactive Age Cohort Mode Switcher (Point 11 & Point 2)
// =============================================================================

class AgeCohortSelectorBar extends StatelessWidget {
  const AgeCohortSelectorBar({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        AgeProfileService.instance,
        AppLanguageService.instance,
      ]),
      builder: (context, _) {
        final currentGroup = AgeProfileService.instance.ageGroup;
        final activeTheme = AgeProfileService.instance.activeTheme;
        final currentLang = AppLanguageService.instance.currentLanguage;

        final youthTitle = switch (currentLang) {
          AppLanguage.telugu => '⚡ యువత (<22)',
          AppLanguage.tanglish => '⚡ Youth (<22)',
          AppLanguage.malayalam => '⚡ യുവാക്കൾ (<22)',
          AppLanguage.manglish => '⚡ Youth (<22)',
          AppLanguage.english => '⚡ Youth (<22)',
        };

        final adultTitle = switch (currentLang) {
          AppLanguage.telugu => '💼 పెద్దలు (22-45)',
          AppLanguage.tanglish => '💼 Adult (22-45)',
          AppLanguage.malayalam => '💼 മുതിർന്നവർ (22-45)',
          AppLanguage.manglish => '💼 Adult (22-45)',
          AppLanguage.english => '💼 Adult (22-45)',
        };

        final seniorTitle = switch (currentLang) {
          AppLanguage.telugu => '🌸 సీనియర్లు (45+)',
          AppLanguage.tanglish => '🌸 Senior (45+)',
          AppLanguage.malayalam => '🌸 വയോധികർ (45+)',
          AppLanguage.manglish => '🌸 Senior (45+)',
          AppLanguage.english => '🌸 Senior (45+)',
        };

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: activeTheme.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: activeTheme.primaryAccent.withValues(alpha: 0.25),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: activeTheme.primaryAccent.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              _buildSegment(
                context,
                title: youthTitle,
                group: AgeGroup.youth,
                isActive: currentGroup == AgeGroup.youth,
                activeColor: const Color(0xFF6C5CE7),
              ),
              _buildSegment(
                context,
                title: adultTitle,
                group: AgeGroup.adult,
                isActive: currentGroup == AgeGroup.adult,
                activeColor: const Color(0xFF1E3A8A),
              ),
              _buildSegment(
                context,
                title: seniorTitle,
                group: AgeGroup.senior,
                isActive: currentGroup == AgeGroup.senior,
                activeColor: const Color(0xFFB45309),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSegment(
    BuildContext context, {
    required String title,
    required AgeGroup group,
    required bool isActive,
    required Color activeColor,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          AgeProfileService.instance.setAgeGroup(group);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive ? Colors.white : AppColors.secondaryText,
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// 9. Holistic Radar Synergy Chart (5-Pillar Spider Chart)
// =============================================================================

class HolisticRadarSynergyChart extends StatefulWidget {
  const HolisticRadarSynergyChart({
    super.key,
    this.astrologyScore = 0.92,
    this.healthScore = 0.85,
    this.habitsScore = 0.88,
    this.financeScore = 0.80,
    this.insightsScore = 0.90,
  });

  final double astrologyScore;
  final double healthScore;
  final double habitsScore;
  final double financeScore;
  final double insightsScore;

  @override
  State<HolisticRadarSynergyChart> createState() =>
      _HolisticRadarSynergyChartState();
}

class _HolisticRadarSynergyChartState extends State<HolisticRadarSynergyChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compositeScore = ((widget.astrologyScore +
                widget.healthScore +
                widget.habitsScore +
                widget.financeScore +
                widget.insightsScore) /
            5 *
            100)
        .round();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.radar_rounded, color: Color(0xFF6C5CE7), size: 20),
                  SizedBox(width: 8),
                  Text(
                    '5-Pillar Synergy Radar',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.deepNavy,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C5CE7).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$compositeScore% Life Harmony',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6C5CE7),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _RadarPainter(
                    progress: _animController.value,
                    scores: [
                      widget.astrologyScore,
                      widget.healthScore,
                      widget.habitsScore,
                      widget.financeScore,
                      widget.insightsScore,
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter({required this.progress, required this.scores});

  final double progress;
  final List<double> scores; // 0: Astrology, 1: Health, 2: Habits, 3: Finance, 4: Insights

  static const List<String> labels = ['Astrology', 'Health', 'Habits', 'Finance', 'Insights'];
  static const List<Color> colors = [
    Color(0xFF6C5CE7),
    Color(0xFF00CEC9),
    Color(0xFFE17055),
    Color(0xFF00B894),
    Color(0xFFE84393),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.36;

    final gridPaint = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw concentric pentagons (20%, 40%, 60%, 80%, 100%)
    for (int step = 1; step <= 5; step++) {
      final r = radius * (step / 5);
      final path = Path();
      for (int i = 0; i < 5; i++) {
        final angle = (i * 2 * math.pi / 5) - (math.pi / 2);
        final x = center.dx + r * math.cos(angle);
        final y = center.dy + r * math.sin(angle);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    // Draw radial axis spokes
    for (int i = 0; i < 5; i++) {
      final angle = (i * 2 * math.pi / 5) - (math.pi / 2);
      final end = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.drawLine(center, end, gridPaint);
    }

    // Draw animated filled synergy polygon
    final polyPath = Path();
    final polyPoints = <Offset>[];
    for (int i = 0; i < 5; i++) {
      final angle = (i * 2 * math.pi / 5) - (math.pi / 2);
      final val = scores[i] * progress;
      final pt = Offset(
        center.dx + radius * val * math.cos(angle),
        center.dy + radius * val * math.sin(angle),
      );
      polyPoints.add(pt);
      if (i == 0) {
        polyPath.moveTo(pt.dx, pt.dy);
      } else {
        polyPath.lineTo(pt.dx, pt.dy);
      }
    }
    polyPath.close();

    final fillPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF6C5CE7).withValues(alpha: 0.38),
          const Color(0xFF00CEC9).withValues(alpha: 0.18),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;
    canvas.drawPath(polyPath, fillPaint);

    final borderPaint = Paint()
      ..color = const Color(0xFF6C5CE7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    canvas.drawPath(polyPath, borderPaint);

    // Draw vertex dots and labels
    for (int i = 0; i < 5; i++) {
      final pt = polyPoints[i];
      final nodePaint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pt, 5, nodePaint);
      canvas.drawCircle(pt, 5, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.5);

      // Label
      final angle = (i * 2 * math.pi / 5) - (math.pi / 2);
      final labelDist = radius + 22;
      final lx = center.dx + labelDist * math.cos(angle);
      final ly = center.dy + labelDist * math.sin(angle);

      final textSpan = TextSpan(
        text: '${labels[i]}\n${(scores[i] * 100).toInt()}%',
        style: TextStyle(
          color: colors[i],
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
          height: 1.1,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(lx - textPainter.width / 2, ly - textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// =============================================================================
// 10. Cross-Pillar Synergy Bridge (Embedded on Individual Screens)
// =============================================================================

/// Dynamic 4-way cross-link card placed on any pillar screen showing how that
/// component directly powers the other 4 components in daily self-help life.
class HolisticCrossPillarBridge extends StatelessWidget {
  const HolisticCrossPillarBridge({
    super.key,
    required this.currentPillarIndex, // 0: Astrology, 1: Health, 2: Habits, 3: Finance, 4: Insights
    this.onNavigateToPillar,
  });

  final int currentPillarIndex;
  final void Function(int targetIndex)? onNavigateToPillar;

  void _navigateToPillar(BuildContext context, int targetIndex) {
    if (onNavigateToPillar != null) {
      onNavigateToPillar!(targetIndex);
      return;
    }
    switch (targetIndex) {
      case 0:
        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AstrologyHubScreen()));
        break;
      case 1:
        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const HealthScreen()));
        break;
      case 2:
        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const HabitsScreen()));
        break;
      case 3:
        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const FinanceScreen()));
        break;
      case 4:
        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const InsightsScreen()));
        break;
    }
  }

  static List<Map<String, dynamic>> _getPillarMeta(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.telugu:
        return const [
          {'name': 'జ్యోతిషం', 'icon': Icons.nightlight_round, 'color': Color(0xFF6C5CE7)},
          {'name': 'ఆరోగ్యం', 'icon': Icons.favorite_rounded, 'color': Color(0xFF00CEC9)},
          {'name': 'అలవాట్లు', 'icon': Icons.track_changes_rounded, 'color': Color(0xFFE17055)},
          {'name': 'ఆర్థికం', 'icon': Icons.account_balance_wallet_rounded, 'color': Color(0xFF00B894)},
          {'name': 'విశ్లేషణలు', 'icon': Icons.auto_graph_rounded, 'color': Color(0xFFE84393)},
        ];
      case AppLanguage.malayalam:
        return const [
          {'name': 'ജ്യോതിഷം', 'icon': Icons.nightlight_round, 'color': Color(0xFF6C5CE7)},
          {'name': 'ആരോഗ്യം', 'icon': Icons.favorite_rounded, 'color': Color(0xFF00CEC9)},
          {'name': 'ശീലങ്ങൾ', 'icon': Icons.track_changes_rounded, 'color': Color(0xFFE17055)},
          {'name': 'ധനകാര്യം', 'icon': Icons.account_balance_wallet_rounded, 'color': Color(0xFF00B894)},
          {'name': 'ഉൾക്കാഴ്ചകൾ', 'icon': Icons.auto_graph_rounded, 'color': Color(0xFFE84393)},
        ];
      case AppLanguage.tanglish:
        return const [
          {'name': 'Astrology', 'icon': Icons.nightlight_round, 'color': Color(0xFF6C5CE7)},
          {'name': 'Health', 'icon': Icons.favorite_rounded, 'color': Color(0xFF00CEC9)},
          {'name': 'Habits', 'icon': Icons.track_changes_rounded, 'color': Color(0xFFE17055)},
          {'name': 'Finance', 'icon': Icons.account_balance_wallet_rounded, 'color': Color(0xFF00B894)},
          {'name': 'Insights', 'icon': Icons.auto_graph_rounded, 'color': Color(0xFFE84393)},
        ];
      case AppLanguage.manglish:
        return const [
          {'name': 'Astrology', 'icon': Icons.nightlight_round, 'color': Color(0xFF6C5CE7)},
          {'name': 'Health', 'icon': Icons.favorite_rounded, 'color': Color(0xFF00CEC9)},
          {'name': 'Habits', 'icon': Icons.track_changes_rounded, 'color': Color(0xFFE17055)},
          {'name': 'Finance', 'icon': Icons.account_balance_wallet_rounded, 'color': Color(0xFF00B894)},
          {'name': 'Insights', 'icon': Icons.auto_graph_rounded, 'color': Color(0xFFE84393)},
        ];
      case AppLanguage.english:
        return const [
          {'name': 'Astrology', 'icon': Icons.nightlight_round, 'color': Color(0xFF6C5CE7)},
          {'name': 'Health', 'icon': Icons.favorite_rounded, 'color': Color(0xFF00CEC9)},
          {'name': 'Habits', 'icon': Icons.track_changes_rounded, 'color': Color(0xFFE17055)},
          {'name': 'Finance', 'icon': Icons.account_balance_wallet_rounded, 'color': Color(0xFF00B894)},
          {'name': 'Insights', 'icon': Icons.auto_graph_rounded, 'color': Color(0xFFE84393)},
        ];
    }
  }

  List<Map<String, dynamic>> _getCrossConnections(AppLanguage lang) {
    switch (currentPillarIndex) {
      case 0: // From Astrology
        switch (lang) {
          case AppLanguage.telugu:
            return [
              {'targetIndex': 1, 'title': 'శరీర ఆరోగ్యం & జీవశక్తి', 'desc': 'పిత్త-శాంత్ పోషణ & రాత్రి 10 గంటల నిద్ర ప్రస్తుత చంద్ర లయతో సరిపోలుతాయి.'},
              {'targetIndex': 2, 'title': 'దైనందిన సాధన & అలవాట్లు', 'desc': 'సూర్య హోరా వేళల్లో మీ కఠినమైన 25 నిమిషాల ఏకాగ్రతా సాధన అత్యుత్తమ ఫలితాన్నిస్తుంది.'},
              {'targetIndex': 3, 'title': 'స్పృహతో కూడిన సంపద & ఆర్థికం', 'desc': 'బుధ గ్రహ స్థితి తొందరపాటు ఖర్చుల కంటే వ్యూహాత్మక పొదుపును సూచిస్తుంది.'},
              {'targetIndex': 4, 'title': 'సమగ్ర జీవన విశ్లేషణలు', 'desc': 'వేద గ్రహ లయలు మీ భావోద్వేగ స్థితికి లోతైన ఆధ్యాత్మిక కారణాలను వివరిస్తాయి.'},
            ];
          case AppLanguage.malayalam:
            return [
              {'targetIndex': 1, 'title': 'ശരീര ആരോഗ്യവും ഊർജ്ജവും', 'desc': 'പിത്ത ശാന്തി ഭക്ഷണവും രാത്രി 10 മണി ഉറക്കവും ചന്ദ്ര താളവുമായി യോജിക്കുന്നു.'},
              {'targetIndex': 2, 'title': 'ദൈനംദിന ശീലങ്ങളുടെ അച്ചടക്കം', 'desc': 'സൂര്യ ഹോര നിങ്ങളുടെ 25 മിനിറ്റ് ഏകാഗ്രത പഠനത്തിന് ഏറ്റവും അനുകൂലമാണ്.'},
              {'targetIndex': 3, 'title': 'വിവേകപൂർണ്ണമായ ധനകാര്യം', 'desc': 'ബുധന്റെ സ്വാധീനം അനാവശ്യ ചിലവുകൾ ഒഴിവാക്കി ബുദ്ധിപരമായ ബജറ്റിംഗ് നിർദ്ദേശിക്കുന്നു.'},
              {'targetIndex': 4, 'title': 'സമഗ്ര ഉൾക്കാഴ്ചകൾ', 'desc': 'ഗ്രഹ സ്വാധീനങ്ങൾ നിങ്ങളുടെ മാനസികാവസ്ഥകൾക്ക് ആത്മീയ ഉൾക്കാഴ്ച നൽകുന്നു.'},
            ];
          default:
            return [
              {'targetIndex': 1, 'title': 'Health & Body Vitals', 'desc': 'Pitta-pacifying cooling nutrition & 10 PM sleep align with current lunar cycle.'},
              {'targetIndex': 2, 'title': 'Daily Habits Execution', 'desc': 'Surya Hora (Solar hour) favors your hardest 25m cognitive focus sprint.'},
              {'targetIndex': 3, 'title': 'Mindful Wealth & Finance', 'desc': 'Mercury aspect advises strategic budgeting over impulsive speculative investments.'},
              {'targetIndex': 4, 'title': 'Holistic Insights', 'desc': 'Vedic planetary archetypes provide compassionate context to your emotional patterns.'},
            ];
        }

      case 1: // From Health
        switch (lang) {
          case AppLanguage.telugu:
            return [
              {'targetIndex': 0, 'title': 'ఖగోళ & సర్కాడియన్ క్లాక్', 'desc': 'చంద్ర లయలతో నిద్రను అనుసంధానించడం వల్ల గాఢ నిద్ర నాణ్యత 34% పెరుగుతుంది.'},
              {'targetIndex': 2, 'title': 'అలవాట్ల సంకల్ప బలం', 'desc': 'శారీరక శక్తి పుష్కలంగా ఉన్నప్పుడు కఠినమైన అలవాట్లను కొనసాగించే మనోబలం లభిస్తుంది.'},
              {'targetIndex': 3, 'title': 'అనవసర ఖర్చుల నియంత్రణ', 'desc': 'తక్కువ కార్టిసాల్ ఒత్తిడి డోపమైన్ కోసం చేసే భావోద్వేగ కొనుగోళ్లను 42% తగ్గిస్తుంది.'},
              {'targetIndex': 4, 'title': 'సమగ్ర జీవన సూచిక', 'desc': '7+ గంటల నాణ్యమైన నిద్ర ప్రశాంతమైన, అత్యున్నత ఉత్పాదక దినాన్ని నిర్దేశిస్తుంది.'},
            ];
          case AppLanguage.malayalam:
            return [
              {'targetIndex': 0, 'title': 'സർക്കാഡിയൻ ജൈവ താളം', 'desc': 'ചന്ദ്ര ചക്രവുമായി ഉറക്കം യോജിപ്പിക്കുന്നത് ശാന്തമായ ഉറക്കം 34% വർദ്ധിപ്പിക്കുന്നു.'},
              {'targetIndex': 2, 'title': 'ശീലങ്ങളുടെ മനോധൈര്യം', 'desc': 'ശാരീരിക ഊർജ്ജം മികച്ച ശീലങ്ങൾ മുടങ്ങാതെ പാലിക്കാൻ മനോധൈര്യം നൽകുന്നു.'},
              {'targetIndex': 3, 'title': 'അനാവശ്യ ചിലവ് നിയന്ത്രണം', 'desc': 'കുറഞ്ഞ മാനസിക സമ്മർദ്ദം അനാവശ്യ ഷോപ്പിംഗ് 42% കുറയ്ക്കുന്നു.'},
              {'targetIndex': 4, 'title': 'സമഗ്ര ഉൾക്കാഴ്ചകൾ', 'desc': '7+ മണിക്കൂർ ഗാഢനിദ്ര ശാന്തവും വ്യക്തവുമായ ദിവസങ്ങൾ ഉറപ്പാക്കുന്നു.'},
            ];
          default:
            return [
              {'targetIndex': 0, 'title': 'Cosmic & Circadian Clock', 'desc': 'Syncing sleep with lunar circadian rhythms deepens restorative REM by 34%.'},
              {'targetIndex': 2, 'title': 'Neural Habit Streaks', 'desc': 'High physiological energy gives the prefrontal willpower to sustain hard habit streaks.'},
              {'targetIndex': 3, 'title': 'Impulse Spend Protection', 'desc': 'Low cortisol stress levels reduce emotional retail and comfort spending by 42%.'},
              {'targetIndex': 4, 'title': 'Holistic Insights', 'desc': '7+ hours of quality sleep directly predicts your calmest, high-clarity days.'},
            ];
        }

      case 2: // From Habits
        switch (lang) {
          case AppLanguage.telugu:
            return [
              {'targetIndex': 0, 'title': 'ఖగోళ శక్తి సమన్వయం', 'desc': 'ఉదయం 7:30 గంటల అలవాట్లు సూర్య ప్రాణశక్తిని సంపూర్ణంగా ఒడిసిపడతాయి.'},
              {'targetIndex': 1, 'title': 'శారీరక ఆరోగ్య పుష్టి', 'desc': 'ఉదయపు సూర్యరశ్మి మరియు నీరు త్రాగే అలవాటు రాత్రి మెలటోనిన్ ఉత్పత్తిని పునరుద్ధరిస్తాయి.'},
              {'targetIndex': 3, 'title': 'ఆర్థిక స్వాతంత్ర్యం', 'desc': '24 గంటల ఆలోచనా విరామ అలవాటు అనవసర ఖర్చుల నుండి ₹1,850+ ఆదా చేసింది.'},
              {'targetIndex': 4, 'title': 'సంపూర్ణ జీవన సూచిక', 'desc': 'స్థిరమైన 6 రోజుల అలవాట్ల రికార్డు 91% జీవిత సామరస్య రేటింగ్‌ను అందిస్తుంది.'},
            ];
          case AppLanguage.malayalam:
            return [
              {'targetIndex': 0, 'title': 'ജ്യോതിഷ ഊർജ്ജ കൊടുമുടി', 'desc': 'രാവിലെ 7:30 നുള്ള ശീലങ്ങൾ സൗരോർജ്ജ പ്രാണൻ പൂർണ്ണമായി സ്വീകരിക്കുന്നു.'},
              {'targetIndex': 1, 'title': 'ശാരീരിക ആരോഗ്യ ചൈതന്യം', 'desc': 'പ്രഭാത വെയിലും ജലപാന ശീലവും ഉന്മേഷവും രാത്രിക്കാല ഉറക്കവും നൽകുന്നു.'},
              {'targetIndex': 3, 'title': 'സാമ്പത്തിക സ്വാതന്ത്ര്യം', 'desc': '24 മണിക്കൂർ ഷോപ്പിംഗ് ചിന്താ ശീലം ₹1,850 ലാഭിക്കാൻ സഹായിച്ചു.'},
              {'targetIndex': 4, 'title': 'സമഗ്ര ജീവിത സ്കോർ', 'desc': 'സ്ഥിരമായ 6 ദിവസത്തെ ശീലങ്ങൾ 91% ജീവിത സന്തുലിതാവസ്ഥ നൽകുന്നു.'},
            ];
          default:
            return [
              {'targetIndex': 0, 'title': 'Astrological Energy Peak', 'desc': 'Completing morning habits at 7:30 AM catches the peak solar prana window.'},
              {'targetIndex': 1, 'title': 'Physical Health Vitality', 'desc': 'Morning sunlight & hydration habit boosts dopamine and resets nighttime melatonin.'},
              {'targetIndex': 3, 'title': 'Financial Freedom', 'desc': 'The 24-hr shopping cooling pause habit has prevented ₹1,850 in impulse buys.'},
              {'targetIndex': 4, 'title': 'Holistic Life Score', 'desc': 'Active 6-day habit streaks correlate with a 91% life harmony rating.'},
            ];
        }

      case 3: // From Finance
        switch (lang) {
          case AppLanguage.telugu:
            return [
              {'targetIndex': 0, 'title': 'ఖగోళ విజ్ఞానం & కాలజ్ఞానం', 'desc': 'దీర్ఘకాలిక పెట్టుబడులను శుభ గురు సంచార దశలతో సమలేఖనం చేసుకోండి.'},
              {'targetIndex': 1, 'title': 'నివారణాత్మక ఆరోగ్యం', 'desc': 'ఆర్థిక అనిశ్చితి తొలగడం గుండెపై ఒత్తిడిని మరియు ఆందోళనను తగ్గిస్తుంది.'},
              {'targetIndex': 2, 'title': 'రోజువారీ అలవాట్ల క్రమశిక్షణ', 'desc': 'రోజూ 2 నిమిషాల ఖర్చుల నమోదు అలవాటు జీవితాంతం నిలిచే సంపద క్రమశిక్షణను ఇస్తుంది.'},
              {'targetIndex': 4, 'title': 'సమగ్ర జీవన తృప్తి', 'desc': 'ఆర్థిక ప్రశాంతత మీ వారపు సమగ్ర జీవిత సంతృప్తికి 30% దోహదం చేస్తుంది.'},
            ];
          case AppLanguage.malayalam:
            return [
              {'targetIndex': 0, 'title': 'ജ്യോതിഷ ജ്ഞാനം', 'desc': 'ദീർഘകാല നിക്ഷേപങ്ങൾ വ്യാഴ ഗ്രഹ മാറ്റങ്ങളുമായി യോജിപ്പിക്കുക.'},
              {'targetIndex': 1, 'title': 'ആരോഗ്യ സുരക്ഷ', 'desc': 'സാമ്പത്തിക സുരക്ഷിതത്വം മാനസിക സമ്മർദ്ദവും ഹൃദയാഘാത സാധ്യതയും കുറയ്ക്കുന്നു.'},
              {'targetIndex': 2, 'title': 'ദൈനംദിന ശീലങ്ങൾ', 'desc': 'ദിവസേന 2 മിനിറ്റ് ചിലവുകൾ കുറിക്കുന്ന ശീലം ദീർഘകാല സമ്പത്ത് വളർത്തുന്നു.'},
              {'targetIndex': 4, 'title': 'സമഗ്ര സന്തോഷം', 'desc': 'സാമ്പത്തിക സമാധാനം നിങ്ങളുടെ ആഴ്ചയിലെ 30% സന്തോഷം നൽകുന്നു.'},
            ];
          default:
            return [
              {'targetIndex': 0, 'title': 'Astrological Wisdom', 'desc': 'Align long-term asset allocation with auspicious Jupiter transit phases.'},
              {'targetIndex': 1, 'title': 'Preventative Health', 'desc': 'Removing financial uncertainty lowers chronic cardiovascular stress and anxiety.'},
              {'targetIndex': 2, 'title': 'Daily Habit Streaks', 'desc': 'Daily 2-minute expense logging habit builds lifelong wealth discipline.'},
              {'targetIndex': 4, 'title': 'Holistic Reflections', 'desc': 'Financial peace of mind contributes 30% to your overall weekly life satisfaction.'},
            ];
        }

      case 4: // From Insights
      default:
        switch (lang) {
          case AppLanguage.telugu:
            return [
              {'targetIndex': 0, 'title': 'ఖగోళ పునాది', 'desc': 'గ్రహ సంచారాలను మీ వ్యక్తిగత భావోద్వేగ మార్పులతో మేళవిస్తుంది.'},
              {'targetIndex': 1, 'title': 'ఆరోగ్య పునరుద్ధరణ పోకడలు', 'desc': 'నిద్ర రికవరీ మరియు వారపు సృజనాత్మక ఉత్పాదకత మధ్య సంబంధాన్ని దృశ్యమానం చేస్తుంది.'},
              {'targetIndex': 2, 'title': 'అలవాట్ల న్యూరల్ వృద్ధి', 'desc': 'చిన్నపాటి ఘర్షణలను గుర్తించి మీ 1% అలవాటు మెరుగుదలలు సులభంగా స్థిరపడేలా చేస్తుంది.'},
              {'targetIndex': 3, 'title': 'బడ్జెట్ సమతుల్యత', 'desc': 'స్పృహతో కూడిన అలవాట్ల ద్వారా ఆదా అయిన డబ్బును మరియు మానసిక సంతృప్తిని ట్రాక్ చేస్తుంది.'},
            ];
          case AppLanguage.malayalam:
            return [
              {'targetIndex': 0, 'title': 'ജ്യോതിഷ അടിത്തറ', 'desc': 'ഗ്രഹ മാറ്റങ്ങളെ നിങ്ങളുടെ യഥാർത്ഥ മാനസിക മാറ്റങ്ങളുമായി ബന്ധിപ്പിക്കുന്നു.'},
              {'targetIndex': 1, 'title': 'ആരോഗ്യ പുരോഗതി', 'desc': 'ഉറക്കവും ആഴ്ചയിലെ സർഗ്ഗാത്മക ഉൽപാദനക്ഷമതയും തമ്മിലുള്ള ബന്ധം കാണിക്കുന്നു.'},
              {'targetIndex': 2, 'title': 'ശീലങ്ങളുടെ വളർച്ച', 'desc': 'സൂക്ഷ്മ ഘർഷണങ്ങൾ കണ്ടെത്തി 1% ശീല പുരോഗതി എളുപ്പമാക്കുന്നു.'},
              {'targetIndex': 3, 'title': 'ബജറ്റ് സന്തുലനം', 'desc': 'ശരിയായ ശീലങ്ങളിലൂടെ ലഭിച്ച സാമ്പത്തിക നേട്ടം ട്രാക്ക് ചെയ്യുന്നു.'},
            ];
          default:
            return [
              {'targetIndex': 0, 'title': 'Astrology Grounding', 'desc': 'Combines planetary transits with your actual journaled mood shifts.'},
              {'targetIndex': 1, 'title': 'Health Recovery Trends', 'desc': 'Visualizes the link between sleep recovery and weekly creative productivity.'},
              {'targetIndex': 2, 'title': 'Habit Neural Growth', 'desc': 'Identifies micro-friction points so your 1% habit improvements stick easily.'},
              {'targetIndex': 3, 'title': 'Budgeting Balance', 'desc': 'Tracks your emotional ROI and money saved from mindful habit choices.'},
            ];
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLanguageService.instance.currentLanguage;
    final pillarMetas = _getPillarMeta(lang);
    final activePillar = pillarMetas[currentPillarIndex];
    final activeColor = activePillar['color'] as Color;
    final connections = _getCrossConnections(lang);

    final headerTitle = switch (lang) {
      AppLanguage.telugu => '🔗 ${activePillar['name']} ఎలా అనుసంధానమైంది',
      AppLanguage.malayalam => '🔗 ${activePillar['name']} എങ്ങനെ ബന്ധപ്പെട്ടിരിക്കുന്നു',
      AppLanguage.tanglish => '🔗 How ${activePillar['name']} Connects',
      AppLanguage.manglish => '🔗 How ${activePillar['name']} Connects',
      AppLanguage.english => '🔗 How ${activePillar['name']} Connects',
    };

    final subtitleText = switch (lang) {
      AppLanguage.telugu => 'మీ 5 స్తంభాల అఖండ జీవన చక్రంలో భాగం',
      AppLanguage.malayalam => 'നിങ്ങളുടെ 5 സ്തംഭ സമഗ്ര ജീവിത വ്യവസ്ഥയുടെ ഭാഗം',
      AppLanguage.tanglish => 'Mee 5-pillar holistic ecosystem lo oka bhaagam',
      AppLanguage.manglish => 'Njangalude 5-pillar holistic ecosystem-inte bhaagam',
      AppLanguage.english => 'Part of your 5-pillar holistic ecosystem',
    };

    final connectedBadge = switch (lang) {
      AppLanguage.telugu => 'అనుసంధానం ⚡',
      AppLanguage.malayalam => 'ബന്ധിപ്പിച്ചു ⚡',
      _ => 'Connected ⚡',
    };

    final openText = switch (lang) {
      AppLanguage.telugu => 'తెరువు',
      AppLanguage.malayalam => 'തുറക്കുക',
      _ => 'Open',
    };

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: activeColor.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: activeColor.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: activeColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.hub_rounded, color: activeColor, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            headerTitle,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.deepNavy,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            subtitleText,
                            style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF00B894).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  connectedBadge,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00B894),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 4 Cross-Connections
          ...connections.map((c) {
            final targetIdx = c['targetIndex'] as int;
            final targetMeta = pillarMetas[targetIdx];
            final targetColor = targetMeta['color'] as Color;

            return InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _navigateToPillar(context, targetIdx),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: targetColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: targetColor.withValues(alpha: 0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: targetColor.withValues(alpha: 0.15),
                      child: Icon(targetMeta['icon'] as IconData, size: 14, color: targetColor),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                targetMeta['name'] as String,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: targetColor,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    openText,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      color: targetColor,
                                    ),
                                  ),
                                  Icon(Icons.chevron_right, size: 13, color: targetColor),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            c['desc'] as String,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.deepNavy,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// =============================================================================
// 11. Youth Bespoke Cyber-Glow Hero & Focus Pods (<22)
// =============================================================================

class CyberGlowHeroWidget extends StatefulWidget {
  const CyberGlowHeroWidget({
    super.key,
    required this.userName,
    required this.onOpenFocus,
    required this.onOpenBreathing,
    required this.onOpenCareer,
    required this.onOpenDetox,
  });

  final String userName;
  final VoidCallback onOpenFocus;
  final VoidCallback onOpenBreathing;
  final VoidCallback onOpenCareer;
  final VoidCallback onOpenDetox;

  @override
  State<CyberGlowHeroWidget> createState() => _CyberGlowHeroWidgetState();
}

class _CyberGlowHeroWidgetState extends State<CyberGlowHeroWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2A0845), Color(0xFF6441A5), Color(0xFF00CEC9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C5CE7).withValues(alpha: 0.4),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Animated Cyber Particle Backdrop
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, _) => CustomPaint(
                  painter: _CyberParticleBackdropPainter(animValue: _animController.value),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Row: Level & Fire Streak
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bolt_rounded, color: Color(0xFFFFEAA7), size: 18),
                            SizedBox(width: 4),
                            Text(
                              '⚡ Level 4 Cosmic Explorer',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF7675).withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFFF7675)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('🔥 7 Days Hot!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Greeting
                  Text(
                    'Ready to Level Up, ${widget.userName}? 🚀',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Mercury is firing up your prefrontal cortex today. Channel sharp focus into your highest-priority study block!',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Gamified XP Bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('MIND XP TO LEVEL 5', style: TextStyle(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                          Text('420 / 500 XP (84%)', style: TextStyle(color: const Color(0xFF55EFC4), fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: 0.84,
                          minHeight: 10,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          valueColor: const AlwaysStoppedAnimation(Color(0xFF00CEC9)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 4 Quick Action Pods
                  Row(
                    children: [
                      _buildPod(
                        title: '25m Focus',
                        sub: 'Pomodoro',
                        icon: Icons.timer_rounded,
                        color: const Color(0xFFFF7675),
                        onTap: widget.onOpenFocus,
                      ),
                      const SizedBox(width: 8),
                      _buildPod(
                        title: 'Exam Calm',
                        sub: 'Breathe',
                        icon: Icons.air_rounded,
                        color: const Color(0xFF74B9FF),
                        onTap: widget.onOpenBreathing,
                      ),
                      const SizedBox(width: 8),
                      _buildPod(
                        title: 'Talents',
                        sub: 'Careers',
                        icon: Icons.rocket_launch_rounded,
                        color: const Color(0xFFA29BFE),
                        onTap: widget.onOpenCareer,
                      ),
                      const SizedBox(width: 8),
                      _buildPod(
                        title: 'Dopamine',
                        sub: 'Detox',
                        icon: Icons.phonelink_erase_rounded,
                        color: const Color(0xFF55EFC4),
                        onTap: widget.onOpenDetox,
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

  Widget _buildPod({
    required String title,
    required String sub,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
              Text(
                sub,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 9.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CyberParticleBackdropPainter extends CustomPainter {
  _CyberParticleBackdropPainter({required this.animValue});
  final double animValue;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Glowing drifting digital particles
    final particlePaint = Paint()..style = PaintingStyle.fill;
    const particleDefs = [
      Offset(0.12, 0.25),
      Offset(0.35, 0.15),
      Offset(0.78, 0.20),
      Offset(0.90, 0.45),
      Offset(0.20, 0.70),
      Offset(0.65, 0.80),
      Offset(0.85, 0.85),
      Offset(0.48, 0.40),
    ];

    for (int i = 0; i < particleDefs.length; i++) {
      final base = particleDefs[i];
      final phase = (animValue + (i * 0.125)) % 1.0;
      final dy = math.sin(phase * math.pi * 2) * 8.0;
      final dx = math.cos(phase * math.pi * 2) * 5.0;
      final pos = Offset((base.dx * w) + dx, (base.dy * h) + dy);

      final alpha = (0.2 + 0.3 * math.sin(phase * math.pi)).clamp(0.1, 0.5);
      final color = (i % 2 == 0)
          ? const Color(0xFF00CEC9).withValues(alpha: alpha)
          : const Color(0xFFFF7675).withValues(alpha: alpha);

      particlePaint.color = color;
      canvas.drawCircle(pos, 2.5 + (i % 3), particlePaint);
    }

    // High tech angled grid lines
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1.0;

    for (double x = -h; x < w + h; x += 40) {
      canvas.drawLine(
        Offset(x + (animValue * 40), 0),
        Offset(x + (animValue * 40) + h, h),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CyberParticleBackdropPainter oldDelegate) =>
      oldDelegate.animValue != animValue;
}

// =============================================================================
// 12. Adult Executive Flow & KPI Equilibrium Widget (22-45)
// =============================================================================

class ExecutiveKpiEquilibriumWidget extends StatefulWidget {
  const ExecutiveKpiEquilibriumWidget({
    super.key,
    required this.userName,
    required this.onOpenPillar,
  });

  final String userName;
  final void Function(int index) onOpenPillar;

  @override
  State<ExecutiveKpiEquilibriumWidget> createState() =>
      _ExecutiveKpiEquilibriumWidgetState();
}

class _ExecutiveKpiEquilibriumWidgetState
    extends State<ExecutiveKpiEquilibriumWidget> {
  int _modeIndex = 1; // 0: Sprint, 1: Equilibrium, 2: Restoration

  static const List<Map<String, dynamic>> _modes = [
    {
      'label': '⚡ Sprint',
      'flowPct': '94% HIGH SPRINT',
      'focus': '96%',
      'focusSub': 'Mercury 10H Peak',
      'burnout': '74%',
      'burnoutSub': 'High Output Window',
      'wealth': '91%',
      'wealthSub': 'Strategic ROI Active',
      'headline': 'High-Stakes Decision & Career Acceleration',
      'strategy': 'Sun & Mercury align in your 10th house. Push top negotiations, sprint milestones, and complex architecture reviews before 2:30 PM.',
    },
    {
      'label': '⚖️ Equilibrium',
      'flowPct': '88% IN FLOW',
      'focus': '92%',
      'focusSub': 'Surya Hora Peak',
      'burnout': '86%',
      'burnoutSub': '7.4h Sleep REM',
      'wealth': '89%',
      'wealthSub': '24h Pause Active',
      'headline': 'Sustainable Executive Flow & Life Boundaries',
      'strategy': 'Jupiter aspects your 2nd and 6th houses. Keep deliberate boundaries between high-focus work and family restoration tonight.',
    },
    {
      'label': '🌿 Restoration',
      'flowPct': '92% RECHARGING',
      'focus': '75%',
      'focusSub': 'Low Stress Band',
      'burnout': '96%',
      'burnoutSub': 'Zero Fatigue Risk',
      'wealth': '94%',
      'wealthSub': 'Compounding Safe',
      'headline': 'Cognitive Bandwidth & Adrenal Recovery',
      'strategy': 'Moon transits Chandra-lagna. Postpone non-urgent administrative friction. Take a 30m digital sunset and replenish deep cognitive reserves.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final mode = _modes[_modeIndex];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF1E3A8A), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.show_chart_rounded, color: Color(0xFF60A5FA), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'EXECUTIVE EQUILIBRIUM',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        'Hello, ${widget.userName} • 22-45 Adult',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF10B981)),
                ),
                child: Text(
                  mode['flowPct'] as String,
                  style: const TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 3 Mode Interactive Segmented Selector
          Row(
            children: List.generate(_modes.length, (idx) {
              final isSel = idx == _modeIndex;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: idx < 2 ? 8 : 0),
                  child: GestureDetector(
                    onTap: () => setState(() => _modeIndex = idx),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSel ? const Color(0xFF2563EB) : const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSel ? const Color(0xFF60A5FA) : const Color(0xFF334155),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _modes[idx]['label'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                            color: isSel ? Colors.white : const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 18),

          // 3 Metric KPI Rings
          Row(
            children: [
              _buildKpiCard(
                title: 'Strategic Focus',
                pct: mode['focus'] as String,
                sub: mode['focusSub'] as String,
                color: const Color(0xFF60A5FA),
                icon: Icons.track_changes_rounded,
                onTap: () => widget.onOpenPillar(2), // Habits
              ),
              const SizedBox(width: 10),
              _buildKpiCard(
                title: 'Burnout Defense',
                pct: mode['burnout'] as String,
                sub: mode['burnoutSub'] as String,
                color: const Color(0xFF34D399),
                icon: Icons.favorite_rounded,
                onTap: () => widget.onOpenPillar(1), // Health
              ),
              const SizedBox(width: 10),
              _buildKpiCard(
                title: 'Mindful Wealth',
                pct: mode['wealth'] as String,
                sub: mode['wealthSub'] as String,
                color: const Color(0xFFF59E0B),
                icon: Icons.account_balance_wallet_rounded,
                onTap: () => widget.onOpenPillar(3), // Finance
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Executive Strategy Tip
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.tips_and_updates_rounded, color: Color(0xFFFBBF24), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mode['headline'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        mode['strategy'] as String,
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 11.5,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String pct,
    required String sub,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 6),
              Text(
                pct,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10.5,
                ),
              ),
              Text(
                sub,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 9.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// 13. Senior Sacred Vedic Sanctuary & Daily Sloka Card (45+)
// =============================================================================

class SacredVedicSanctuaryCard extends StatefulWidget {
  const SacredVedicSanctuaryCard({
    super.key,
    required this.userName,
    this.onOpenAudioSloka,
    required this.onOpenAyurveda,
    required this.onOpenWalk,
    required this.onOpenBlessings,
  });

  final String userName;
  final VoidCallback? onOpenAudioSloka;
  final VoidCallback onOpenAyurveda;
  final VoidCallback onOpenWalk;
  final VoidCallback onOpenBlessings;

  @override
  State<SacredVedicSanctuaryCard> createState() => _SacredVedicSanctuaryCardState();
}

class _SacredVedicSanctuaryCardState extends State<SacredVedicSanctuaryCard>
    with SingleTickerProviderStateMixin {
  int _selectedMantraIndex = 0;
  bool _isPlaying = false;
  bool _isPlayingTranslation = false;
  late final AnimationController _rippleController;
  String _translationChoice = 'auto'; // 'auto', 'en', 'te', 'none'

  static const List<Map<String, String>> _mantras = [
    {
      'id': 'asato_ma',
      'nameEn': 'Pavamana Shanti',
      'nameTe': 'పవమాన శాంతి',
      'nameTanglish': 'Pavamana Shanti',
      'nameMl': 'പവമാന ശാന്തി',
      'nameManglish': 'Pavamana Shanthi',
      'titleEn': 'Pavamana Shanti Mantra (Asato Ma Sadgamaya)',
      'titleTe': 'పవమాన శాంతి మంత్రం (Asato Ma Sadgamaya)',
      'titleTanglish': 'Pavamana Shanti Mantram (Asato Ma Sadgamaya)',
      'titleMl': 'പവമാന ശാന്തി മന്ത്രം (അസതോ മാ സദ്ഗമയ)',
      'titleManglish': 'Pavamana Shanthi Mantram (Asato Ma Sadgamaya)',
      'sourceEn': 'Brihadaranyaka Upanishad 1.3.28',
      'sourceTe': 'బృహదారణ్యకోపనిషత్ 1.3.28',
      'sourceTanglish': 'Brihadaranyaka Upanishad 1.3.28',
      'sourceMl': 'ബൃഹദാരണ്യകോപനിഷത്ത് 1.3.28',
      'sourceManglish': 'Brihadaranyakopanishad 1.3.28',
      'devanagari': 'ॐ असतो मा सद्गमय ।\nतमसो मा ज्योतिर्गमय ।\nमृत्योर्मा अमृतं गमय ॥\nॐ शान्तिः शान्तिः शान्तिः ॥',
      'transliteration': 'Om Asato Maa Sadgamaya |\nTamaso Maa Jyotirgamaya |\nMrityor Maa Amritam Gamaya ||\nOm Shantih Shantih Shantih ||',
      'teluguScript': 'ఓం అసతో మా సద్గమయ ।\nతమసో మా జ్యోతిర్గమయ ।\nమృత్యోర్మా అమృతం గమయ ॥\nఓం శాంతిః శాంతిః శాంతిః ॥',
      'malayalamScript': 'ഓം അസതോ മാ സദ്ഗമയ ।\nതമസോ മാ ജ്യോതിർഗമയ ।\nമൃത്യോർമാ അമൃതം ഗമയ ॥\nഓം ശാന്തിഃ ശാന്തിഃ ശാന്തിഃ ॥',
      'meaningEn': 'Lead me from falsehood to eternal truth, from spiritual darkness to the supreme light of wisdom, and from mortality into immortality. Om peace, peace, peace.',
      'meaningTe': 'నన్ను అసత్యము నుండి సత్యము వైపుకు, అజ్ఞానపు చీకటి నుండి దివ్యమైన జ్ఞానపు వెలుగు వైపుకు, మృత్యు భయం నుండి మోక్షము వైపుకు నడిపించు పరమాత్మా.',
      'meaningTanglish': 'Nannu asathyam nundi sathyam vaipuku, cheekati nundi divyamaina velugu vaipuku, mrityu bhayam nundi moksham vaipuku nadipinchu Paramatma.',
      'meaningMl': 'എന്നെ അസത്യത്തിൽ നിന്ന് സത്യത്തിലേക്കും, അജ്ഞാനത്തിന്റെ ഇരുട്ടിൽ നിന്ന് ദിവ്യ ജ്ഞാനത്തിന്റെ പ്രകാശത്തിലേക്കും, മൃത്യുവിൽ നിന്ന് അമൃതത്വത്തിലേക്കും നയിച്ചാലും.',
      'meaningManglish': 'Enne asathyathil ninnu sathyathilekkum, iruttil ninnu velichathilekkum, mrithyuvil ninnu amrithathvathilekkum nayichaalum.',
      'benefitEn': 'Dispels anxiety and fear, installs deep meditative composure, and bestows divine protective aura.',
      'benefitTe': 'భయ నివారణ, మానసిక ప్రశాంతత మరియు దివ్య రక్షణ చేకూరుతాయి.',
      'benefitTanglish': 'Bhaya nivarana, manasika prasanthata mariyu divya rakshana labhisthundi.',
      'benefitMl': 'ഭയ നിവാരണം, അഗാധമായ മനഃശാന്തി, ദിവ്യമായ സംരക്ഷണം ലഭിക്കുന്നു.',
      'benefitManglish': 'Bhaya nivaranam, mana shanthi, divya samrakshanam labhikkunnu.',
      'sanskritSpeech': 'Om Asato maa sad gamaya, Tamaso maa jyotir gamaya, Mrityor maa amritam gamaya, Om Shantih Shantih Shantih.',
    },
    {
      'id': 'gayatri',
      'nameEn': 'Gayatri Mantra',
      'nameTe': 'గాయత్రీ మంత్రం',
      'nameTanglish': 'Gayatri Mantram',
      'nameMl': 'ഗായത്രീ മന്ത്രം',
      'nameManglish': 'Gayatri Mantram',
      'titleEn': 'Gayatri Maha Mantra (Rigveda 3.62.10)',
      'titleTe': 'గాయత్రీ మహా మంత్రం (ఋగ్వేదం 3.62.10)',
      'titleTanglish': 'Gayatri Maha Mantram (Rigveda 3.62.10)',
      'titleMl': 'ഗായത്രീ മഹാ മന്ത്രം (ഋഗ്വേദം 3.62.10)',
      'titleManglish': 'Gayatri Maha Mantram (Rigveda 3.62.10)',
      'sourceEn': 'Rigveda 3.62.10 • Meditative Chanting',
      'sourceTe': 'ఋగ్వేదం 3.62.10 • ధ్యాన పఠనం (Meditative India)',
      'sourceTanglish': 'Rigveda 3.62.10 • Dhyana Pathanam',
      'sourceMl': 'ഋഗ്വേദം 3.62.10 • ധ്യാന ജപം',
      'sourceManglish': 'Rigvedam 3.62.10 • Dhyana Japam',
      'devanagari': 'ॐ भूर्भुवः स्वः ।\nतत्सवितुर्वरेण्यं भर्गो देवस्य धीमहि ।\nधियो यो नः प्रचोदयात् ॥',
      'transliteration': 'Om Bhur Bhuvah Svah |\nTat Savitur Varenyam Bhargo Devasya Dhimahi |\nDhiyo Yo Nah Prachodayat ||',
      'teluguScript': 'ఓం భూర్భువః స్వః ।\nతత్సవితుర్వరేణ్యం భర్గో దేవస్య ధీమహి ।\nధియో యో నః ప్రచోదయాత్ ॥',
      'malayalamScript': 'ഓം ഭൂർഭുവഃ സ്വഃ ।\nതത്സവിതുർവരേണ്യം ഭർഗോ ദേവസ്യ ധീമഹി ।\nധിയോ യോ നഃ പ്രചോദയാത് ॥',
      'meaningEn': 'We meditate upon the transcendental radiance of the divine Sun (Savitr). May that sacred celestial light stimulate and guide our intellect onto the righteous path of truth.',
      'meaningTe': 'ముల్లోకాలను ప్రకాశింపజేసే సవితృ సూర్య భగవానుని పరమ దివ్య తేజాన్ని మేము ధ్యానిస్తున్నాము. ఆయన మా బుద్ధిని సత్య జ్ఞాన మార్గంలో నడిపించుగాక.',
      'meaningTanglish': 'Mullokalani prakashimpajese Savitru Surya Bhagavanuni divya tejaanni dhyanisthunnamu. Ayana maa buddhini sanmargamlo nadipinchugaaka.',
      'meaningMl': 'മുപ്പുലോകങ്ങളെയും പ്രകാശിപ്പിക്കുന്ന സവിതൃ സൂര്യ ഭഗവാന്റെ പരമ ദിവ്യ തേജസ്സിനെ ഞങ്ങൾ ധ്യാനിക്കുന്നു. അവിടുന്ന് ഞങ്ങളുടെ ബുദ്ധിയെ സത്യമാർഗ്ഗത്തിലേക്ക് നയിക്കട്ടെ.',
      'meaningManglish': 'Muppulokangaleyum prakashippikkunna soorya bhagavante thejassine dhyanikkunnu. Nammude buddhiye sanmaargathilekku nayikkatte.',
      'benefitEn': 'Purifies consciousness, sharpens intellect, dissolves negative mental impressions, and fosters longevity.',
      'benefitTe': 'సకల పాప వినాశనం, బుద్ధి వికాసం, ఆయురారోగ్యాలు మరియు ప్రాణ శక్తి వృద్ధి.',
      'benefitTanglish': 'Sakala papa nashanam, buddhi vikasam mariyu ayur-arogyalu labhisthayi.',
      'benefitMl': 'സകല പാപ നാശനം, ബുദ്ധി വികാസം, ആയുരാരോഗ്യ വർദ്ധനവ്.',
      'benefitManglish': 'Sakala paapa nashanam, buddhi vikaasam, aayurarogya vardhanavu.',
      'sanskritSpeech': 'Om Bhur Bhuvah Svah, Tat Savitur Varenyam, Bhargo Devasya Dhimahi, Dhiyo Yo Nah Prachodayat.',
    },
    {
      'id': 'mrityunjaya',
      'nameEn': 'Maha Mrityunjaya',
      'nameTe': 'మహా మృత్యుంజయ',
      'nameTanglish': 'Maha Mrityunjaya',
      'nameMl': 'മഹാ മൃത്യുഞ്ജയ',
      'nameManglish': 'Maha Mrityunjaya',
      'titleEn': 'Maha Mrityunjaya Mantra (Rigveda 7.59.12)',
      'titleTe': 'మహా మృత్యుంజయ మంత్రం (ఋగ్వేదం 7.59.12)',
      'titleTanglish': 'Maha Mrityunjaya Mantram (Rigveda 7.59.12)',
      'titleMl': 'മഹാ മൃത്യുഞ്ജയ മന്ത്രം (ഋഗ്വേദം 7.59.12)',
      'titleManglish': 'Maha Mrityunjaya Mantram (Rigveda 7.59.12)',
      'sourceEn': 'Rigveda 7.59.12 • Sage Markandeya',
      'sourceTe': 'ఋగ్వేదం 7.59.12 • మార్కండేయ మహర్షి',
      'sourceTanglish': 'Rigveda 7.59.12 • Markandeya Maharshi',
      'sourceMl': 'ഋഗ്വേദം 7.59.12 • മാർക്കണ്ഡേയ മഹർഷി',
      'sourceManglish': 'Rigvedam 7.59.12 • Markandeya Maharshi',
      'devanagari': 'ॐ त्र्यम्बकं यजामहे सुगन्धिं पुष्टिवर्धनम् ।\nउर्वारुकमिव बन्धनान् मृत्योर्मुक्षीय माऽमृतात् ॥',
      'transliteration': 'Om Tryambakam Yajaamahe Sugandhim Pushtivardhanam |\nUrvaarukamiva Bandhanaan Mrityor Muksheeya Maamritaat ||',
      'teluguScript': 'ఓం త్ర్యంబకం యజామహే సుగంధిం పుష్టివర్ధనమ్ ।\nఉర్వారుకమివ బంధనాన్ మృత్యోర్ముక్షీయ మామృతాత్ ॥',
      'malayalamScript': 'ഓം ത്ര്യംബകം യജാമഹേ സുഗന്ധിം പുഷ്ടിവർദ്ധനം ।\nഉർവ്വാരുകമിവ ബന്ധനാന്മൃത്യോർമുക്ഷീയ മാമൃതാത് ॥',
      'meaningEn': 'We worship the fragrant, three-eyed Lord Shiva who nourishes and sustains all beings. As a ripe fruit naturally frees itself from the vine, liberate us from mortal fears and spiritual bondages into immortality.',
      'meaningTe': 'సుగంధభరితుడై, సకల ప్రాణులను పోషించే ముక్కంటి పరమేశ్వరుని మేము పూజిస్తున్నాము. పండిన దోసపండు తొడిమ నుండి సునాయాసంగా రాలినట్లు, మమ్ములను మృత్యు భయాల నుండి విముక్తులను చేయుము.',
      'meaningTanglish': 'Sugandha bharitudai, sakala pranulanu poshinchu Mukkanti Parameshwaruni poojisthunnamu. Mrityu bhayam nundi vimukthulanu cheyumu.',
      'meaningMl': 'സുഗന്ധഭരിതനും സകല ജീവജാലങ്ങളെയും പരിപാലിക്കുന്നവനുമായ ത്രിലോചനനായ പരമശിവനെ ഞങ്ങൾ ആരാധിക്കുന്നു. പഴുത്ത വെള്ളരിക്ക വള്ളിയിൽ നിന്ന് അടരുന്നതുപോലെ, മൃത്യു ഭയത്തിൽ നിന്നും ഞങ്ങളെ മുക്തരാക്കി അമൃതത്വം നൽകിയാലും.',
      'meaningManglish': 'Sugandhabharithanum sakala jeevaneyum paripalikkunnavanumaaya Paramashivane namaskarikkunnu. Mrithyu bhayathil ninnu mukthi nalkiyaalum.',
      'benefitEn': 'Grants longevity, relief from ailments, liberation from mortal fears, vitality, and spiritual healing.',
      'benefitTe': 'దీర్ఘాయుష్షు, రోగ నివారణ, అకాల మృత్యు భయ నాశనం మరియు సంపూర్ణ స్వస్థత.',
      'benefitTanglish': 'Deerghayushshu, roga nivarana mariyu arogya siddhi labhisthayi.',
      'benefitMl': 'ദീർഘായുസ്സ്, രോഗശാന്തി, അപമൃത്യു ഭയമില്ലായ്മ, പൂർണ്ണ സ്വസ്ഥത.',
      'benefitManglish': 'Deerghaayussu, roga shaanthi, mrithyu bhayamillayma, poorna swasthatha.',
      'sanskritSpeech': 'Om Tryambakam Yajaamahe Sugandhim Pushtivardhanam, Urvaarukamiva Bandhanaan Mrityor Muksheeya Maamritaat.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    AppLanguageService.instance.addListener(_handleLangChange);
    TtsService.instance.addListener(_handleTtsChange);
  }

  void _handleLangChange() {
    if (mounted) setState(() {});
  }

  void _handleTtsChange() {
    if (mounted) {
      final isSpeaking = TtsService.instance.isSpeaking;
      final isSpeakingTr = TtsService.instance.isSpeakingTranslation;
      if (isSpeaking != _isPlaying || isSpeakingTr != _isPlayingTranslation) {
        setState(() {
          _isPlaying = isSpeaking;
          _isPlayingTranslation = isSpeakingTr;
          if (_isPlaying) {
            _rippleController.repeat();
          } else {
            _rippleController.stop();
            _rippleController.reset();
          }
        });
      }
    }
  }

  @override
  void dispose() {
    AppLanguageService.instance.removeListener(_handleLangChange);
    TtsService.instance.removeListener(_handleTtsChange);
    _rippleController.dispose();
    super.dispose();
  }

  void _toggleChant() {
    if (_isPlaying) {
      TtsService.instance.stop();
      setState(() {
        _isPlaying = false;
        _isPlayingTranslation = false;
      });
      _rippleController.stop();
      _rippleController.reset();
    } else {
      final m = _mantras[_selectedMantraIndex];
      TtsService.instance.playSacredChant(m['sanskritSpeech']!);
      setState(() {
        _isPlaying = true;
        _isPlayingTranslation = false;
      });
      _rippleController.repeat();

      final currentLang = AppLanguageService.instance.currentLanguage;
      final isTe = currentLang == AppLanguage.telugu;
      final title = isTe ? m['titleTe']! : m['titleEn']!;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.temple_hindu_rounded, color: Color(0xFFFDE68A), size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isTe
                      ? '🔔 పవిత్ర సంస్కృత వేద పఠనం: $title (Pure Indian Sanskrit Tone)'
                      : '🔔 Sacred Sanskrit Recitation: $title (Pure Indian Sanskrit Tone)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF78350F),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _toggleTranslationAudio(String effectiveLang) {
    if (_isPlayingTranslation) {
      TtsService.instance.stop();
      setState(() {
        _isPlayingTranslation = false;
        _isPlaying = false;
      });
      _rippleController.stop();
      _rippleController.reset();
    } else {
      final m = _mantras[_selectedMantraIndex];
      final mantraKey = m['id']!;
      final fallback = switch (effectiveLang) {
        'te' => '${m['meaningTe']!} ${m['benefitTe']!}',
        'tanglish' => '${m['meaningTanglish']!} ${m['benefitTanglish']!}',
        'ml' => '${m['meaningMl']!} ${m['benefitMl']!}',
        'manglish' => '${m['meaningManglish']!} ${m['benefitManglish']!}',
        _ => '${m['meaningEn']!} ${m['benefitEn']!}',
      };

      TtsService.instance.playTranslationVoice(
        mantraKey: mantraKey,
        langCode: effectiveLang,
        fallbackText: fallback,
      );
      setState(() {
        _isPlayingTranslation = true;
        _isPlaying = true;
      });
      _rippleController.repeat();

      final snackMsg = switch (effectiveLang) {
        'te' => '🔊 పవిత్ర తెలుగు అర్థ వివరణ వింటున్నారు (Authentic Telugu Voice)...',
        'tanglish' => '🔊 Reading Tanglish meaning aloud...',
        'ml' => '🔊 പവിത്ര മലയാള അർത്ഥ വിവരണം കേൾക്കുന്നു (Authentic Malayalam Voice)...',
        'manglish' => '🔊 Reading Manglish meaning aloud...',
        _ => '🔊 Reading English Translation Aloud (Clear Meditative Voice)...',
      };

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                effectiveLang == 'te' || effectiveLang == 'ml' ? Icons.translate_rounded : Icons.record_voice_over_rounded,
                color: const Color(0xFFFDE68A),
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  snackMsg,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF78350F),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Widget _buildTranslationChoiceChip(String label, String value, String activeValue) {
    final isSelected = activeValue == value;
    return GestureDetector(
      onTap: () {
        if (_isPlayingTranslation) {
          TtsService.instance.stop();
        }
        setState(() => _translationChoice = value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFB45309) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF92400E) : const Color(0xFFFCD34D),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : const Color(0xFF78350F),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentLang = AppLanguageService.instance.currentLanguage;

    final m = _mantras[_selectedMantraIndex];

    final effectiveTranslation = _translationChoice == 'auto'
        ? currentLang.code
        : _translationChoice;

    final headerSubtitle = switch (currentLang) {
      AppLanguage.telugu => 'వేద శాంతి & జీవన సౌభాగ్యం',
      AppLanguage.tanglish => 'Vedic Shanti & Jeevana Soubhagyam',
      AppLanguage.malayalam => 'വേദ ശാന്തിയും ജീവിത സൗഭാഗ്യവും',
      AppLanguage.manglish => 'Veda Shanthiyum Jeevitha Soubhagyavum',
      AppLanguage.english => 'Vedic Peace & Vitality',
    };

    final greeting = switch (currentLang) {
      AppLanguage.telugu => 'నమస్తే, ${widget.userName} గారు 🙏',
      AppLanguage.tanglish => 'Namaste, ${widget.userName} garu 🙏',
      AppLanguage.malayalam => 'നമസ്തേ, ${widget.userName} 🙏',
      AppLanguage.manglish => 'Namaste, ${widget.userName} 🙏',
      AppLanguage.english => 'Namaste, ${widget.userName} 🙏',
    };

    final badgeText = switch (currentLang) {
      AppLanguage.telugu => '🌸 45+ సౌభాగ్యం',
      AppLanguage.tanglish => '🌸 45+ Serenity',
      AppLanguage.malayalam => '🌸 45+ സൗഭാഗ്യം',
      AppLanguage.manglish => '🌸 45+ Soubhagyam',
      AppLanguage.english => '🌸 45+ Grace & Serenity',
    };

    final mantraTitle = switch (currentLang) {
      AppLanguage.telugu => m['titleTe']!,
      AppLanguage.tanglish => m['titleTanglish']!,
      AppLanguage.malayalam => m['titleMl']!,
      AppLanguage.manglish => m['titleManglish']!,
      AppLanguage.english => m['titleEn']!,
    };

    final mantraSource = switch (currentLang) {
      AppLanguage.telugu => m['sourceTe']!,
      AppLanguage.tanglish => m['sourceTanglish']!,
      AppLanguage.malayalam => m['sourceMl']!,
      AppLanguage.manglish => m['sourceManglish']!,
      AppLanguage.english => m['sourceEn']!,
    };

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF5),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFB45309), width: 2.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB45309).withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Arched Sacred Header with quick language switcher
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const _FlickeringDiyaWidget(size: 30),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            headerSubtitle,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF92400E),
                            ),
                          ),
                          Text(
                            greeting,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF78350F),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  // Quick Language Toggle for all 5 languages
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFD97706), width: 1.2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final lang in AppLanguage.values)
                          InkWell(
                            onTap: () => AppLanguageService.instance.setLanguage(lang),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: currentLang == lang ? const Color(0xFFB45309) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                lang.shortLabel,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: currentLang == lang ? Colors.white : const Color(0xFF78350F),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFD97706)),
                    ),
                    child: Text(
                      badgeText,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFB45309),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 3 Sacred Mantra Tab Selector Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_mantras.length, (idx) {
                final isSel = idx == _selectedMantraIndex;
                final mantraLabel = switch (currentLang) {
                  AppLanguage.telugu => _mantras[idx]['nameTe']!,
                  AppLanguage.tanglish => _mantras[idx]['nameTanglish']!,
                  AppLanguage.malayalam => _mantras[idx]['nameMl']!,
                  AppLanguage.manglish => _mantras[idx]['nameManglish']!,
                  AppLanguage.english => _mantras[idx]['nameEn']!,
                };

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      mantraLabel,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: isSel ? Colors.white : const Color(0xFF78350F),
                      ),
                    ),
                    selected: isSel,
                    selectedColor: const Color(0xFFB45309),
                    backgroundColor: const Color(0xFFFEF3C7),
                    side: BorderSide(
                      color: isSel ? const Color(0xFF92400E) : const Color(0xFFFCD34D),
                    ),
                    onSelected: (val) {
                      if (val) {
                        setState(() {
                          _selectedMantraIndex = idx;
                          if (_isPlaying) {
                            TtsService.instance.stop();
                            _isPlaying = false;
                            _isPlayingTranslation = false;
                          }
                        });
                      }
                    },
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 14),

          // Daily Sacred Sloka Card (High-Contrast Large Typography)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFCD34D), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.auto_awesome, color: Color(0xFFD97706), size: 18),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              mantraTitle,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF92400E),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      mantraSource,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFFB45309),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Sanskrit Devanagari Script (Pure Scripture)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Text(
                    m['devanagari']!,
                    style: const TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF78350F),
                      height: 1.5,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Translation Preference Bar (Asks the user directly!)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFDF5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFCD34D)),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        const Icon(Icons.translate_rounded, size: 15, color: Color(0xFF92400E)),
                        const SizedBox(width: 6),
                        Text(
                          switch (currentLang) {
                            AppLanguage.telugu => 'అనువాదం:',
                            AppLanguage.malayalam => 'വിവർത്തനം:',
                            _ => 'Translation:',
                          },
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF92400E),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _buildTranslationChoiceChip('English', 'en', effectiveTranslation),
                        const SizedBox(width: 4),
                        _buildTranslationChoiceChip('తెలుగు', 'te', effectiveTranslation),
                        const SizedBox(width: 4),
                        _buildTranslationChoiceChip('Tanglish', 'tanglish', effectiveTranslation),
                        const SizedBox(width: 4),
                        _buildTranslationChoiceChip('മലയാളം', 'ml', effectiveTranslation),
                        const SizedBox(width: 4),
                        _buildTranslationChoiceChip('Manglish', 'manglish', effectiveTranslation),
                        const SizedBox(width: 4),
                        _buildTranslationChoiceChip(
                          switch (currentLang) {
                            AppLanguage.telugu => 'కేవలం సంస్కృతం',
                            AppLanguage.malayalam => 'സംസ്കൃതം മാത്രം',
                            _ => 'None',
                          },
                          'none',
                          effectiveTranslation,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Display Based on Chosen Translation Preference
                if (effectiveTranslation == 'en') ...[
                  // English Transliteration
                  Text(
                    m['transliteration']!,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF78350F),
                      height: 1.4,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Meaning: ${m['meaningEn']}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF451A03),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.shield_outlined, color: Color(0xFFB45309), size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Spiritual Benefit: ${m['benefitEn']}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF92400E),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (effectiveTranslation == 'te') ...[
                  // Telugu Script
                  Text(
                    m['teluguScript']!,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF92400E),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'భావం: ${m['meaningTe']}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF451A03),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.shield_outlined, color: Color(0xFFB45309), size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'ఫలం: ${m['benefitTe']}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF92400E),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (effectiveTranslation == 'tanglish') ...[
                  Text(
                    m['transliteration']!,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF78350F),
                      height: 1.4,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Bhaavam: ${m['meaningTanglish']}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF451A03),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.shield_outlined, color: Color(0xFFB45309), size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Phalam: ${m['benefitTanglish']}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF92400E),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (effectiveTranslation == 'ml') ...[
                  Text(
                    m['malayalamScript'] ?? m['devanagari']!,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF92400E),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'അർത്ഥം: ${m['meaningMl']}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF451A03),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.shield_outlined, color: Color(0xFFB45309), size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'ഫലം: ${m['benefitMl']}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF92400E),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (effectiveTranslation == 'manglish') ...[
                  Text(
                    m['transliteration']!,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF78350F),
                      height: 1.4,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Artham: ${m['meaningManglish']}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF451A03),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.shield_outlined, color: Color(0xFFB45309), size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Phalam: ${m['benefitManglish']}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF92400E),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Pure Sanskrit Selected
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7).withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      switch (currentLang) {
                        AppLanguage.telugu => 'సంస్కృత మూల శ్లోకం మాత్రమే ప్రదర్శించబడుతోంది.',
                        AppLanguage.malayalam => 'സംസ്കൃത മൂല ശ്ലോകം മാത്രമാണ് കാണിക്കുന്നത്.',
                        _ => 'Pure Vedic chanting mode active. Select a language above to view translations.',
                      },
                      style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFF78350F)),
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // Animated Soundwave Visualizer (Pulsing when chanting or reading translation)
                if (_isPlaying) ...[
                  AnimatedBuilder(
                    animation: _rippleController,
                    builder: (context, _) {
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('🕉️', style: TextStyle(fontSize: 20)),
                            const SizedBox(width: 10),
                            ...List.generate(7, (i) {
                              final wave = math.sin((_rippleController.value * 2 * math.pi) + (i * 0.8));
                              final barHeight = 8.0 + (wave.abs() * 22.0);
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                width: 5,
                                height: barHeight,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD97706),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              );
                            }),
                            const SizedBox(width: 10),
                            Text(
                              _isPlayingTranslation
                                  ? switch (effectiveTranslation) {
                                      'te' => 'తెలుగు అర్థ వివరణ పఠనం సాగుతోంది (Pure Telugu Voice)...',
                                      'ml' => 'മലയാള അർത്ഥ വിവരണം കേൾക്കുന്നു (Pure Malayalam Voice)...',
                                      'tanglish' => 'Reading Tanglish meaning aloud...',
                                      'manglish' => 'Reading Manglish meaning aloud...',
                                      _ => 'Reading English translation aloud (Clear Voice)...',
                                    }
                                  : switch (currentLang) {
                                      AppLanguage.telugu => '432Hz వేద నాదం మారుమ్రోగుతోంది...',
                                      AppLanguage.malayalam => '432Hz വേദ നാദം മുഴങ്ങുന്നു...',
                                      _ => 'Resonating with authentic 432Hz Vedic resonance...',
                                    },
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFB45309),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                ],

                // 1. Audio Chanting Button (Pure Indian Sanskrit Tone)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _toggleChant,
                    icon: Icon(
                      (_isPlaying && !_isPlayingTranslation)
                          ? Icons.stop_circle_rounded
                          : Icons.volume_up_rounded,
                      size: 24,
                      color: Colors.white,
                    ),
                    label: Text(
                      (_isPlaying && !_isPlayingTranslation)
                          ? switch (currentLang) {
                              AppLanguage.telugu => 'పఠనం ఆపండి (Stop Chanting)',
                              AppLanguage.malayalam => 'ജപം നിർത്തൂ (Stop Chanting)',
                              _ => 'Stop Chanting',
                            }
                          : switch (currentLang) {
                              AppLanguage.telugu => 'పవిత్ర సంస్కృత పఠనం వినండి (Pure Sanskrit Tone)',
                              AppLanguage.malayalam => 'പവിത്ര സംസ്കൃത ജപം കേൾക്കൂ (Pure Sanskrit Tone)',
                              _ => 'Listen to Sacred Sanskrit Chanting (Pure Tone)',
                            },
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (_isPlaying && !_isPlayingTranslation)
                          ? const Color(0xFFDC2626)
                          : const Color(0xFFB45309),
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 3,
                    ),
                  ),
                ),

                // 2. Translation Voice Button
                if (effectiveTranslation != 'none') ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _toggleTranslationAudio(effectiveTranslation),
                      icon: Icon(
                        _isPlayingTranslation
                            ? Icons.stop_circle_rounded
                            : Icons.record_voice_over_rounded,
                        size: 20,
                        color: const Color(0xFF78350F),
                      ),
                      label: Text(
                        _isPlayingTranslation
                            ? switch (effectiveTranslation) {
                                'te' => 'వివరణ ఆపండి (Stop Voice)',
                                'ml' => 'വിവരണം നിർത്തൂ (Stop Voice)',
                                _ => 'Stop Voice Reading',
                              }
                            : switch (effectiveTranslation) {
                                'te' => '🔊 తెలుగు భావాన్ని స్పష్టమైన గొంతుతో వినండి (Play Telugu Voice)',
                                'tanglish' => '🔊 Play Tanglish Voice',
                                'ml' => '🔊 മലയാള അർത്ഥം വ്യക്തമായ ശബ്ദത്തിൽ കേൾക്കൂ (Play Malayalam Voice)',
                                'manglish' => '🔊 Play Manglish Voice',
                                _ => '🔊 Listen to English Translation Aloud (Play English Voice)',
                              },
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF78350F),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFFFEF3C7).withValues(alpha: 0.65),
                        side: const BorderSide(color: Color(0xFFD97706), width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 4 Senior Health & Peace Actions (Large touch targets: minimum 60px)
          Text(
            switch (currentLang) {
              AppLanguage.telugu => 'దినచర్య & ఆయుర్వేద ఆరోగ్య రక్షణ (Daily Senior Care):',
              AppLanguage.tanglish => 'Dinacharya & Ayurvedic Arogya Rakshana:',
              AppLanguage.malayalam => 'ദിനചര്യയും ആയുർവേദ ആരോഗ്യ സംരക്ഷണവും:',
              AppLanguage.manglish => 'Dinacharyayum Ayurveda Aarogya Samrakshanavum:',
              AppLanguage.english => 'Daily Dinacharya & Ayurvedic Wellness Care:',
            },
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF78350F),
            ),
          ),
          const SizedBox(height: 10),

          _buildSeniorActionTile(
            title: switch (currentLang) {
              AppLanguage.telugu => 'గోరువెచ్చని నీరు & కీళ్ల ఆరోగ్యం (Joint & Gut Care)',
              AppLanguage.tanglish => 'Goruvetchani Neeru & Keella Aarogyam',
              AppLanguage.malayalam => 'ചെറുചൂടുവെള്ളവും സന്ധി സംരക്ഷണവും (Joint & Gut Care)',
              AppLanguage.manglish => 'Cheruchoodu Vellavum Sandhi Samrakshanavum',
              AppLanguage.english => 'Warm Water & Joint Care (Vata Balance)',
            },
            desc: switch (currentLang) {
              AppLanguage.telugu => 'వాత దోషాన్ని శాంతింపజేయడానికి ఉదయం శొంఠి మరియు గోరువెచ్చని నీరు తీసుకోండి.',
              AppLanguage.tanglish => 'Vata doshanni santhimpajeyadaniki udayam shonti mariyu goruvetchani neeru theesukondi.',
              AppLanguage.malayalam => 'വാതദോഷം ശമിപ്പിക്കാൻ രാവിലെ ചുക്കും ചെറുചൂടുവെള്ളവും കുടിക്കുക.',
              AppLanguage.manglish => 'Vatha dosham shamikkan ravile chukkum cheruchooduvellavum kudikkuka.',
              AppLanguage.english => 'Drink warm water with dry ginger in the morning to pacify Vata and nourish joint vitality.',
            },
            icon: Icons.health_and_safety_rounded,
            color: const Color(0xFF047857),
            onTap: widget.onOpenAyurveda,
          ),
          const SizedBox(height: 10),
          _buildSeniorActionTile(
            title: switch (currentLang) {
              AppLanguage.telugu => 'ప్రశాంత ఉదయపు నడక & ప్రాణాయామం (Morning Walk)',
              AppLanguage.tanglish => 'Prasantha Udayapu Nadaka & Pranayamam',
              AppLanguage.malayalam => 'പ്രഭാത നടത്തവും പ്രാണായാമവും (Morning Walk)',
              AppLanguage.manglish => 'Prabhatha Nadathavum Pranayamavum',
              AppLanguage.english => 'Peaceful Morning Walk & Pranayama (Sunrise Vitality)',
            },
            desc: switch (currentLang) {
              AppLanguage.telugu => 'బ్రాహ్మీ ముహూర్తంలో 15 నిమిషాల సున్నితమైన నడక మీ గుండెకు, ఊపిరితిత్తులకు అమృతం.',
              AppLanguage.tanglish => 'Brahma muhurthamlo 15 nimishala sunnithamaina nadaka gundeku, oopirithitthulaku amrutham.',
              AppLanguage.malayalam => 'ബ്രാഹ്മമുഹൂർത്തത്തിലെ 15 മിനിറ്റ് നടത്തം ഹൃദയത്തിനും ശ്വാസകോശത്തിനും ഉത്തമം.',
              AppLanguage.manglish => 'Brahma muhurthathile 15 minute nadatham hrudayathinnu aarogyam.',
              AppLanguage.english => 'A gentle 15-minute walk during Brahma Muhurtha revitalizes circulation, lungs, and joints.',
            },
            icon: Icons.directions_walk_rounded,
            color: const Color(0xFFB45309),
            onTap: widget.onOpenWalk,
          ),
          const SizedBox(height: 10),
          _buildSeniorActionTile(
            title: switch (currentLang) {
              AppLanguage.telugu => 'పిల్లల క్షేమం & వేద పరిహారాలు (Family Blessings)',
              AppLanguage.tanglish => 'Pillala Kshemam & Veda Pariharalu',
              AppLanguage.malayalam => 'കുടുംബ സൗഖ്യവും വേദ പരിഹാരങ്ങളും (Family Blessings)',
              AppLanguage.manglish => 'Kudumba Soukhyavum Veda Pariharangalum',
              AppLanguage.english => 'Family Blessings & Vedic Remedies',
            },
            desc: switch (currentLang) {
              AppLanguage.telugu => 'పిల్లల, మనవళ్ల భవిష్యత్తు కోసం శాంతి మంత్రాలు మరియు గురు గ్రహ పరిహారాలు చూడండి.',
              AppLanguage.tanglish => 'Pillala, manavalla bhavishyatthu kosam shanti mantralu mariyu Guru graha pariharalu choodandi.',
              AppLanguage.malayalam => 'മക്കൾക്കും പേരക്കുട്ടികൾക്കുമായി ശാന്തി മന്ത്രങ്ങളും വ്യാഴ പരിഹാരങ്ങളും കാണുക.',
              AppLanguage.manglish => 'Makkalkkum perakkuttikalkkum aayi shanthi manthrangal kaanuka.',
              AppLanguage.english => 'Peace mantras and Jupiter remedies dedicated to the long-term flourishing of children & grandchildren.',
            },
            icon: Icons.diversity_1_rounded,
            color: const Color(0xFF6C5CE7),
            onTap: widget.onOpenBlessings,
          ),
        ],
      ),
    );
  }

    Widget _buildSeniorActionTile({
    required String title,
    required String desc,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    desc,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF451A03),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color, size: 22),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// 14. Senior 108-Bead Sacred Japa Mala Counter (Interactive Chanting Widget)
// =============================================================================

class SacredJapaMalaCounterWidget extends StatefulWidget {
  const SacredJapaMalaCounterWidget({super.key});

  @override
  State<SacredJapaMalaCounterWidget> createState() =>
      _SacredJapaMalaCounterWidgetState();
}

class _SacredJapaMalaCounterWidgetState
    extends State<SacredJapaMalaCounterWidget>
    with TickerProviderStateMixin {
  int _count = 0;
  int _completedMalas = 0;
  static const int _target = 108;
  int _selectedMantraIdx = 0;
  bool _isPlayingVoice = false;
  String _malaTranslationChoice = 'auto'; // 'auto', 'en', 'te', 'tanglish', 'ml', 'manglish'

  late final AnimationController _auraController;
  late final AnimationController _rotationController;
  late final AnimationController _rippleController;
  late final AnimationController _bellController;
  double _currentRotation = 0.0;
  double _targetRotation = 0.0;

  static const List<Map<String, String>> _mantras = [
    {
      'id': 'gayatri',
      'nameEn': 'Gayatri Maha Mantra',
      'nameTe': 'గాయత్రీ మహా మంత్రం',
      'nameTanglish': 'Gayatri Maha Mantram',
      'nameMl': 'ഗായത്രീ മഹാ മന്ത്രം',
      'nameManglish': 'Gayatri Maha Mantram',
      'sanskrit': 'Om Bhur Bhuvah Svah, Tat Savitur Varenyam, Bhargo Devasya Dhimahi, Dhiyo Yo Nah Prachodayat.',
      'sanskritTe': 'ఓం భూర్భువస్స్వః తత్సవితుర్వరేణ్యం భర్గో దేవస్య ధీమహి ధియో యో నః ప్రచోదయాత్।',
      'sanskritMl': 'ഓം ഭൂർഭുവസ്സ്വഃ തത്സവിതുർവരേണ്യം ഭർഗോ ദേവസ്യ ധീമഹി ധിയോ യോ നഃ പ്രചോദയാത്।',
      'meaningEn': 'May the divine light of Savitr illuminate our intellect onto the righteous path.',
      'meaningTe': 'సవితృ సూర్య భగవానుని తేజస్సు మా బుద్ధిని సన్మార్గంలో నడిపించుగాక.',
      'meaningTanglish': 'Savitru soorya bhagavanuni thejassu maa buddhini sanmaargamlo nadipinchugaaka.',
      'meaningMl': 'സവിതൃ സൂര്യ ഭഗവാന്റെ ദിവ്യ തേജസ്സ് നമ്മുടെ ബുദ്ധിയെ സന്മാർഗ്ഗത്തിലേക്ക് നയിക്കട്ടെ.',
      'meaningManglish': 'Savithru soorya bhagavante divya thejassu nammude buddhiye sanmaargathilekku nayikkatte.',
    },
    {
      'id': 'om_namah_shivaya',
      'nameEn': 'Om Namah Shivaya (Panchakshari)',
      'nameTe': 'ఓం నమః శివాయ (పంచాక్షరీ)',
      'nameTanglish': 'Om Namah Shivaya (Panchakshari)',
      'nameMl': 'ഓം നമഃ ശിവായ (പഞ്ചാക്ഷരി)',
      'nameManglish': 'Om Namah Shivaya (Panchakshari)',
      'sanskrit': 'Om Namah Shivaaya, Om Namah Shivaaya, Om Namah Shivaaya.',
      'sanskritTe': 'ఓం నమః శివాయ, ఓం నమః శివాయ, ఓం నమః శివాయ।',
      'sanskritMl': 'ഓം നമഃ ശിവായ, ഓം നമഃ ശിവായ, ഓം നമഃ ശിവായ।',
      'meaningEn': 'Salutations to the auspicious Lord Shiva.',
      'meaningTe': 'మంగళకరుడైన పరమశివునికి ప్రణామాలు.',
      'meaningTanglish': 'Mangalakarudaina Paramashivuniki pranamaalu.',
      'meaningMl': 'മംഗളസ്വരൂപനായ പരമശിവന് പ്രണാമങ്ങൾ.',
      'meaningManglish': 'Mangalaswaroopanaaya Paramashivannu pranavam.',
    },
    {
      'id': 'mrityunjaya',
      'nameEn': 'Maha Mrityunjaya Mantra',
      'nameTe': 'మహా మృత్యుంజయ మంత్రం',
      'nameTanglish': 'Maha Mrityunjaya Mantram',
      'nameMl': 'മഹാ മൃത്യുഞ്ജയ മന്ത്രം',
      'nameManglish': 'Maha Mrityunjaya Mantram',
      'sanskrit': 'Om Tryambakam Yajaamahe Sugandhim Pushtivardhanam, Urvaarukamiva Bandhanaan Mrityor Muksheeya Maamritaat.',
      'sanskritTe': 'ఓం త్ర్యంబకం యజామహే సుగంధిం పుష్టివర్ధనం ఉర్వారుకమివ బంధనాన్ మృత్యోర్ముక్షీయ మామృతాత్।',
      'sanskritMl': 'ഓം ത്ര്യംബകം യജാമഹേ സുഗന്ധിം പുഷ്ടിവർദ്ധനം ഉർവ്വാരുകമിവ ബന്ധനാൻ മൃത്യോർമുക്ഷീയ മാമൃതാത്।',
      'meaningEn': 'May Lord Shiva grant longevity, healing and complete health.',
      'meaningTe': 'పరమశివుని కటాక్షంతో దీర్ఘాయుష్షు మరియు సంపూర్ణ ఆరోగ్యం కలుగుగాక.',
      'meaningTanglish': 'Paramashivuni kataakshamtho deerghaayushshu mariyu sampoorna aarogyam kalugugaaka.',
      'meaningMl': 'പരമശിവന്റെ കൃപയാൽ ദീർഘాయുസ്സും പൂർണ്ണ ആരോഗ്യവും ലഭിക്കട്ടെ.',
      'meaningManglish': 'Paramashivante krupayal deerghaayussum poorna aarogyavum labhikkatte.',
    },
    {
      'id': 'om_namo_narayanaya',
      'nameEn': 'Om Namo Narayanaya (Ashtakshari)',
      'nameTe': 'ఓం నమో నారాయణాయ (అష్టాక్షరీ)',
      'nameTanglish': 'Om Namo Narayanaya (Ashtakshari)',
      'nameMl': 'ഓം നമോ നാരായണായ (അഷ്ടാക്ഷരി)',
      'nameManglish': 'Om Namo Narayanaya (Ashtakshari)',
      'sanskrit': 'Om Namo Naaraayanaaya, Om Namo Naaraayanaaya.',
      'sanskritTe': 'ఓం నమో నారాయణాయ, ఓం నమో నారాయణాయ।',
      'sanskritMl': 'ഓം നമോ നാരായണായ, ഓം നമോ നാരായണായ।',
      'meaningEn': 'Salutations to Lord Vishnu, the protector and preserver of all realms.',
      'meaningTe': 'జగద్రక్షకుడైన శ్రీమహావిష్ణువునకు ప్రణామాలు.',
      'meaningTanglish': 'Jagadrakshakudaina Srimahaavishnuvunaku pranamaalu.',
      'meaningMl': 'ജഗദ്രക്ഷകനായ ശ്രീമഹാവിഷ്ണുവിന് പ്രണാമങ്ങൾ.',
      'meaningManglish': 'Jagadrakshakanaaya Sreemahavishnuvinnu pranavam.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _auraController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _bellController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    AppLanguageService.instance.addListener(_handleLangChange);
    TtsService.instance.addListener(_handleTtsChange);
    VoiceService.instance.onJapaMalaTapRequest = _increment;
    VoiceService.instance.onJapaMalaResetRequest = _reset;
  }

  void _handleLangChange() {
    if (mounted) {
      setState(() {});
    }
  }

  void _handleTtsChange() {
    if (mounted) {
      final isSpeaking = TtsService.instance.isSpeaking;
      if (isSpeaking != _isPlayingVoice) {
        setState(() => _isPlayingVoice = isSpeaking);
      }
    }
  }

  @override
  void dispose() {
    VoiceService.instance.onJapaMalaTapRequest = null;
    VoiceService.instance.onJapaMalaResetRequest = null;
    AppLanguageService.instance.removeListener(_handleLangChange);
    TtsService.instance.removeListener(_handleTtsChange);
    _auraController.dispose();
    _rotationController.dispose();
    _rippleController.dispose();
    _bellController.dispose();
    super.dispose();
  }

  void _increment() {
    TtsService.instance.playTempleBell();
    _bellController.forward(from: 0.0);
    _rippleController.forward(from: 0.0);
    _currentRotation = _targetRotation;
    _targetRotation += (2 * math.pi) / 27; // Rotate 1 prayer bead step
    _rotationController.forward(from: 0.0);

    setState(() {
      if (_count < _target) {
        _count++;
        if (_count == _target) {
          _completedMalas++;
          final currentLang = AppLanguageService.instance.currentLanguage;

          final celebration = switch (currentLang) {
            AppLanguage.telugu => '🎉 108 మణుల జపం పూర్తయింది! (${_completedMalas}వ మాల సంపూర్ణం) శాంతి శాంతి శాంతిః 🙏',
            AppLanguage.tanglish => '🎉 108 Manula Japam Poorthi ayindi! (${_completedMalas}va maala sampoornam) Shanti Shanti Shanti 🙏',
            AppLanguage.malayalam => '🎉 108 മണികളുടെ ജപം പൂർത്തിയായി! (${_completedMalas}-ാം മാല സമ്പൂർണ്ണം) ശാന്തി ശാന്തി ശാന്തി 🙏',
            AppLanguage.manglish => '🎉 108 Manikalude Japam Poorthiyaayi! (${_completedMalas}-am mala sampoornam) Shanthi Shanthi Shanthi 🙏',
            AppLanguage.english => '🎉 108 Sacred Beads Japa Completed! (${_completedMalas} malas complete) Om Shanti Shanti Shanti 🙏',
          };

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.stars_rounded, color: Colors.amberAccent, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      celebration,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF78350F),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else {
        _count = 1;
      }
    });
  }

  void _reset() {
    setState(() {
      _count = 0;
      _currentRotation = 0.0;
      _targetRotation = 0.0;
    });
  }

  void _toggleMalaVoice(String effectiveLang) {
    if (_isPlayingVoice) {
      TtsService.instance.stop();
      setState(() => _isPlayingVoice = false);
    } else {
      final m = _mantras[_selectedMantraIdx];
      final mantraKey = m['id']!;
      final textToSpeak = switch (effectiveLang) {
        'te' => m['meaningTe']!,
        'tanglish' => m['meaningTanglish']!,
        'ml' => m['meaningMl']!,
        'manglish' => m['meaningManglish']!,
        _ => m['meaningEn']!,
      };

      TtsService.instance.playTranslationVoice(
        mantraKey: mantraKey,
        langCode: effectiveLang,
        fallbackText: textToSpeak,
      );
      setState(() => _isPlayingVoice = true);

      final snackMsg = switch (effectiveLang) {
        'te' => '🔊 జప మంత్ర భావాన్ని తెలుగు గొంతుతో వింటున్నారు (Telugu Voice)...',
        'tanglish' => '🔊 Reading Japa mantra meaning in Tanglish voice...',
        'ml' => '🔊 ജപ മന്ത്ര അർത്ഥം മലയാളത്തിൽ കേൾക്കുന്നു (Malayalam Voice)...',
        'manglish' => '🔊 Reading Japa mantra meaning in Manglish voice...',
        _ => '🔊 Reading Japa mantra meaning in English voice...',
      };

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                effectiveLang == 'te' || effectiveLang == 'ml' ? Icons.translate_rounded : Icons.record_voice_over_rounded,
                color: const Color(0xFFFDE68A),
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  snackMsg,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF78350F),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Widget _buildChoiceChip(String label, String value, String activeValue) {
    final isSelected = activeValue == value;
    return GestureDetector(
      onTap: () {
        if (_isPlayingVoice) {
          TtsService.instance.stop();
        }
        setState(() => _malaTranslationChoice = value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFB45309) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF92400E) : const Color(0xFFFCD34D),
            width: isSelected ? 1.4 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : const Color(0xFF78350F),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentLang = AppLanguageService.instance.currentLanguage;

    final effectiveMalaTranslation = _malaTranslationChoice == 'auto'
        ? currentLang.code
        : _malaTranslationChoice;

    final double progress = _count / _target;
    final m = _mantras[_selectedMantraIdx];

    final mantraName = switch (currentLang) {
      AppLanguage.telugu => m['nameTe']!,
      AppLanguage.tanglish => m['nameTanglish']!,
      AppLanguage.malayalam => m['nameMl']!,
      AppLanguage.manglish => m['nameManglish']!,
      AppLanguage.english => m['nameEn']!,
    };

    final mantraMeaning = switch (effectiveMalaTranslation) {
      'te' => m['meaningTe']!,
      'tanglish' => m['meaningTanglish']!,
      'ml' => m['meaningMl']!,
      'manglish' => m['meaningManglish']!,
      _ => m['meaningEn']!,
    };

    final headerTitle = switch (currentLang) {
      AppLanguage.telugu => '108 మణుల వేద జపమాల',
      AppLanguage.tanglish => '108 Manula Veda Japamala',
      AppLanguage.malayalam => '108 മണികളുടെ വേദ ജപമാല',
      AppLanguage.manglish => '108 Manikalude Veda Japamala',
      AppLanguage.english => '108 Sacred Beads Japa Mala',
    };

    final completedMalasLabel = switch (currentLang) {
      AppLanguage.telugu => 'పూర్తయిన మాలలు: $_completedMalas',
      AppLanguage.tanglish => 'Poorthi ayina maalalu: $_completedMalas',
      AppLanguage.malayalam => 'പൂർത്തിയായ മാലകൾ: $_completedMalas',
      AppLanguage.manglish => 'Poorthiyaya malakal: $_completedMalas',
      AppLanguage.english => 'Completed Malas: $_completedMalas',
    };

    final resetLabel = switch (currentLang) {
      AppLanguage.telugu => 'రీసెట్',
      AppLanguage.tanglish => 'Reset',
      AppLanguage.malayalam => 'റീസെറ്റ്',
      AppLanguage.manglish => 'Reset',
      AppLanguage.english => 'Reset',
    };

    final beadsCountLabel = switch (currentLang) {
      AppLanguage.telugu => '/ 108 మణులు',
      AppLanguage.tanglish => '/ 108 Manulu',
      AppLanguage.malayalam => '/ 108 മണികൾ',
      AppLanguage.manglish => '/ 108 Manikal',
      AppLanguage.english => '/ 108 Beads',
    };

    final bellTapLabel = switch (currentLang) {
      AppLanguage.telugu => 'గంట మ్రోగింపు',
      AppLanguage.tanglish => 'Ganta Tap',
      AppLanguage.malayalam => 'മണി മുഴക്കുക',
      AppLanguage.manglish => 'Mani Tap',
      AppLanguage.english => 'BELL TAP',
    };

    final bottomInstruction = _count == _target
        ? switch (currentLang) {
            AppLanguage.telugu => '🎉 108 మణుల జపం పూర్తయింది! శాంతి శాంతి శాంతిః 🙏',
            AppLanguage.tanglish => '🎉 108 Manula Japam Poorthi ayindi! Shanti Shanti Shanti 🙏',
            AppLanguage.malayalam => '🎉 108 മണികളുടെ ജപം പൂർത്തിയായി! ശാന്തി ശാന്തി ശാന്തി 🙏',
            AppLanguage.manglish => '🎉 108 Manikalude Japam Poorthiyaayi! Shanthi Shanthi Shanthi 🙏',
            AppLanguage.english => '🎉 108 Beads Japa Completed! Om Shanti Shanti Shanti 🙏',
          }
        : switch (currentLang) {
            AppLanguage.telugu => 'ఒక్కొక్క మణిని జపిస్తూ స్క్రీన్‌పై తాకండి (తాకినప్పుడు వేద గంట మ్రోగుతుంది 🔔)',
            AppLanguage.tanglish => 'Okkokka manini japistoo screen pai thaakandi (thaakinappudu veda ganta mroguthundi 🔔)',
            AppLanguage.malayalam => 'ഓരോ മണിയും ജപിക്കുമ്പോൾ സ്ക്രീനിൽ തൊടുക (തൊടുമ്പോൾ വേദ മണി മുഴങ്ങും 🔔)',
            AppLanguage.manglish => 'Oro maniyum japikkumbol screenil thoduka (thodumbol veda mani muzhangum 🔔)',
            AppLanguage.english => 'Tap the screen as you chant each bead (a sacred bell rings on each tap 🔔)',
          };

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFB45309), width: 1.8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB45309).withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with Mala Count & Quick Language Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const _FlickeringDiyaWidget(size: 28),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            headerTitle,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF78350F),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            completedMalasLabel,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF92400E),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  // Language Switcher for all 5 languages directly on the Japa Mala card!
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFD97706), width: 1.2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final lang in AppLanguage.values)
                          InkWell(
                            onTap: () => AppLanguageService.instance.setLanguage(lang),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: currentLang == lang ? const Color(0xFFB45309) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                lang.shortLabel,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: currentLang == lang ? Colors.white : const Color(0xFF78350F),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_count > 0) ...[
                    const SizedBox(width: 6),
                    TextButton.icon(
                      onPressed: _reset,
                      icon: const Icon(Icons.refresh_rounded, size: 15, color: Color(0xFFB45309)),
                      label: Text(
                        resetLabel,
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFFB45309)),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Mantra Selector Chips (Adapts across all 5 languages)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_mantras.length, (i) {
                final isSel = i == _selectedMantraIdx;
                final item = _mantras[i];
                final label = switch (currentLang) {
                  AppLanguage.telugu => item['nameTe']!,
                  AppLanguage.tanglish => item['nameTanglish']!,
                  AppLanguage.malayalam => item['nameMl']!,
                  AppLanguage.manglish => item['nameManglish']!,
                  AppLanguage.english => item['nameEn']!,
                };

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSel ? Colors.white : const Color(0xFF78350F),
                      ),
                    ),
                    selected: isSel,
                    selectedColor: const Color(0xFFB45309),
                    backgroundColor: const Color(0xFFFEF3C7),
                    onSelected: (val) {
                      if (val) {
                        setState(() {
                          _selectedMantraIdx = i;
                          if (_isPlayingVoice) {
                            TtsService.instance.stop();
                            _isPlayingVoice = false;
                          }
                        });
                      }
                    },
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),

          // Active Chanting Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFCD34D)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        mantraName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF92400E),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildChoiceChip('Auto', 'auto', _malaTranslationChoice),
                          const SizedBox(width: 3),
                          _buildChoiceChip('EN', 'en', effectiveMalaTranslation),
                          const SizedBox(width: 3),
                          _buildChoiceChip('తెలుగు', 'te', effectiveMalaTranslation),
                          const SizedBox(width: 3),
                          _buildChoiceChip('Tanglish', 'tanglish', effectiveMalaTranslation),
                          const SizedBox(width: 3),
                          _buildChoiceChip('മലയാളം', 'ml', effectiveMalaTranslation),
                          const SizedBox(width: 3),
                          _buildChoiceChip('Manglish', 'manglish', effectiveMalaTranslation),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  switch (effectiveMalaTranslation) {
                    'te' => m['sanskritTe'] ?? m['sanskrit']!,
                    'ml' => m['sanskritMl'] ?? m['sanskrit']!,
                    _ => m['sanskrit']!,
                  },
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF78350F),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  mantraMeaning,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF92400E),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                // Dedicated Voice Reading Button for Mala Mantra
                InkWell(
                  onTap: () => _toggleMalaVoice(effectiveMalaTranslation),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFCD34D)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isPlayingVoice ? Icons.stop_circle_rounded : Icons.record_voice_over_rounded,
                          size: 15,
                          color: const Color(0xFFB45309),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isPlayingVoice
                              ? switch (effectiveMalaTranslation) {
                                  'te' => 'ఆపండి (Stop Voice)',
                                  'ml' => 'നിർത്തൂ (Stop Voice)',
                                  _ => 'Stop Voice',
                                }
                              : switch (effectiveMalaTranslation) {
                                  'te' => '🔊 తెలుగు భావాన్ని వినండి (Telugu Voice)',
                                  'tanglish' => '🔊 Tanglish Meaning Voice',
                                  'ml' => '🔊 മലയാള അർത്ഥം കേൾക്കൂ (Malayalam Voice)',
                                  'manglish' => '🔊 Manglish Meaning Voice',
                                  _ => '🔊 Listen to Meaning (English Voice)',
                                },
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF78350F),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Central Interactive 3D Rudraksha Bead Ring with Tactile Tap Rotation & Soundwave Aura
          Center(
            child: GestureDetector(
              onTap: _increment,
              child: SizedBox(
                width: 250,
                height: 250,
                child: AnimatedBuilder(
                  animation: Listenable.merge([
                    _auraController,
                    _rotationController,
                    _rippleController,
                    _bellController,
                  ]),
                  builder: (context, _) {
                    final animatedAngle = _currentRotation +
                        (_targetRotation - _currentRotation) *
                            Curves.easeOutBack.transform(_rotationController.value);

                    return CustomPaint(
                      painter: _SacredMalaBeadsPainter(
                        progress: progress,
                        count: _count,
                        rotationAngle: animatedAngle,
                        auraValue: _auraController.value,
                        rippleValue: _rippleController.value,
                      ),
                      child: Center(
                        child: Container(
                          width: 136,
                          height: 136,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const RadialGradient(
                              colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
                            ),
                            border: Border.all(color: const Color(0xFFD97706), width: 2.2),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFB45309).withValues(alpha: 0.28),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Faint sacred Om watermark
                              Opacity(
                                opacity: 0.12,
                                child: const Text(
                                  'ॐ',
                                  style: TextStyle(
                                    fontSize: 84,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFB45309),
                                  ),
                                ),
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Animated swinging bell icon
                                  Transform.rotate(
                                    angle: math.sin(_bellController.value * math.pi * 3) * 0.25,
                                    child: const Text('🔔', style: TextStyle(fontSize: 22)),
                                  ),
                                  const SizedBox(height: 2),
                                  AnimatedScale(
                                    duration: const Duration(milliseconds: 140),
                                    scale: _rippleController.isAnimating ? 1.15 : 1.0,
                                    curve: Curves.easeOutBack,
                                    child: Text(
                                      '$_count',
                                      style: const TextStyle(
                                        fontSize: 34,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF78350F),
                                        height: 1.1,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    beadsCountLabel,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF92400E),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFFCD34D)),
                                    ),
                                    child: Text(
                                      bellTapLabel,
                                      style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFFB45309),
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          Center(
            child: Text(
              bottomInstruction,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF78350F),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SacredMalaBeadsPainter extends CustomPainter {
  _SacredMalaBeadsPainter({
    required this.progress,
    required this.count,
    required this.rotationAngle,
    required this.auraValue,
    required this.rippleValue,
  });

  final double progress;
  final int count;
  final double rotationAngle;
  final double auraValue;
  final double rippleValue;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final R = size.width * 0.38; // Radius of beads loop (~95px)
    const rBead = 8.5; // Radius of each bead

    // 1. Divine Sacred Golden Aura Rays behind the Rosary
    _paintSacredAura(canvas, center, size.width * 0.48);

    // 2. Tap Ripple Shockwave (Expands outward when tapped)
    if (rippleValue > 0.0 && rippleValue < 1.0) {
      final rippleRadius = 68.0 + (55.0 * rippleValue);
      final rippleAlpha = ((1.0 - rippleValue) * 0.55).clamp(0.0, 1.0);
      final ripplePaint = Paint()
        ..color = const Color(0xFFF59E0B).withValues(alpha: rippleAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0 - (1.5 * rippleValue);
      canvas.drawCircle(center, rippleRadius, ripplePaint);
    }

    // 3. Braided Golden Silk Mala Thread Circle
    final threadPaint = Paint()
      ..color = const Color(0xFFD97706).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    canvas.drawCircle(center, R, threadPaint);

    // 4. Paint 27 Realistic 3D Rudraksha Prayer Beads
    final completedBeadsInCycle = count % 27;
    final isFullCycleCompleted = count > 0 && completedBeadsInCycle == 0;

    for (int i = 0; i < 27; i++) {
      final theta = (i * 2 * math.pi / 27) - (math.pi / 2) + rotationAngle;
      final bx = center.dx + R * math.cos(theta);
      final by = center.dy + R * math.sin(theta);
      final beadCenter = Offset(bx, by);

      final isCompleted = isFullCycleCompleted || i < completedBeadsInCycle;
      final isActive = i == completedBeadsInCycle && !isFullCycleCompleted;

      // Drop shadow for spherical depth
      canvas.drawCircle(
        Offset(bx, by + 1.8),
        rBead,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.22)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
      );

      // Spherical 3D gradient for Rudraksha texture
      final beadShader = RadialGradient(
        center: const Alignment(-0.35, -0.35),
        radius: 0.9,
        colors: isCompleted
            ? [
                const Color(0xFFFFFBEB),
                const Color(0xFFFDE68A),
                const Color(0xFFF59E0B),
                const Color(0xFFB45309),
              ]
            : [
                const Color(0xFFE08B3E),
                const Color(0xFF9A3412),
                const Color(0xFF7C2D12),
                const Color(0xFF451A03),
              ],
        stops: const [0.0, 0.35, 0.75, 1.0],
      ).createShader(Rect.fromCircle(center: beadCenter, radius: rBead));

      canvas.drawCircle(beadCenter, rBead, Paint()..shader = beadShader);

      // Gold Filigree Bead Caps at both poles
      final capPaint = Paint()
        ..color = const Color(0xFFFEF08A)
        ..style = PaintingStyle.fill;
      final capDist = rBead * 0.92;
      canvas.drawCircle(
        Offset(bx + capDist * math.cos(theta + math.pi / 2), by + capDist * math.sin(theta + math.pi / 2)),
        1.8,
        capPaint,
      );
      canvas.drawCircle(
        Offset(bx - capDist * math.cos(theta + math.pi / 2), by - capDist * math.sin(theta + math.pi / 2)),
        1.8,
        capPaint,
      );

      // Specular highlight dot for shiny natural wood sheen
      canvas.drawCircle(
        Offset(bx - rBead * 0.32, by - rBead * 0.32),
        1.8,
        Paint()..color = Colors.white.withValues(alpha: 0.75),
      );

      // Active bead halo beacon ring
      if (isActive) {
        final beaconPulse = 1.0 + 0.3 * auraValue;
        canvas.drawCircle(
          beadCenter,
          (rBead + 3.0) * beaconPulse,
          Paint()
            ..color = const Color(0xFFF59E0B).withValues(alpha: 0.45)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
      }
    }

    // 5. Meru / Guru Bead (కల్పవృక్ష గురు మణి) at Apex
    _paintGuruBeadAndTassel(canvas, center, R, rotationAngle);
  }

  void _paintSacredAura(Canvas canvas, Offset center, double maxRadius) {
    const auraRays = 16;
    final rayPaint = Paint()
      ..color = const Color(0xFFFDE68A).withValues(alpha: 0.20 + 0.15 * auraValue)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    final rayRot = auraValue * math.pi * 0.12;

    for (int i = 0; i < auraRays; i++) {
      final angle = (i * 2 * math.pi / auraRays) + rayRot;
      final innerP = Offset(center.dx + 70 * math.cos(angle), center.dy + 70 * math.sin(angle));
      final outerP = Offset(center.dx + (maxRadius + 6 * auraValue) * math.cos(angle), center.dy + (maxRadius + 6 * auraValue) * math.sin(angle));
      canvas.drawLine(innerP, outerP, rayPaint);
    }

    // Outer golden petal tips
    final petalPaint = Paint()
      ..color = const Color(0xFFFEF3C7).withValues(alpha: 0.35 + 0.15 * auraValue)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    for (int i = 0; i < auraRays; i++) {
      final angle = (i * 2 * math.pi / auraRays) + rayRot;
      final midR = maxRadius - 4;
      final pt = Offset(center.dx + midR * math.cos(angle), center.dy + midR * math.sin(angle));
      canvas.drawCircle(pt, 3.5, petalPaint);
    }
  }

  void _paintGuruBeadAndTassel(Canvas canvas, Offset center, double R, double rot) {
    // Meru bead is at top angle (-pi/2)
    final guruTheta = -math.pi / 2 + rot;
    final gx = center.dx + R * math.cos(guruTheta);
    final gy = center.dy + R * math.sin(guruTheta);
    final guruCenter = Offset(gx, gy);
    const rGuru = 12.0;

    // Shadow
    canvas.drawCircle(
      Offset(gx, gy + 2.5),
      rGuru,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5),
    );

    // Guru Bead 3D Amber Sphere
    final guruShader = RadialGradient(
      center: const Alignment(-0.35, -0.35),
      radius: 0.85,
      colors: const [
        Color(0xFFFFFBEB),
        Color(0xFFFDE68A),
        Color(0xFFD97706),
        Color(0xFF78350F),
      ],
      stops: const [0.0, 0.35, 0.75, 1.0],
    ).createShader(Rect.fromCircle(center: guruCenter, radius: rGuru));

    canvas.drawCircle(guruCenter, rGuru, Paint()..shader = guruShader);

    // Specular dot
    canvas.drawCircle(
      Offset(gx - 4, gy - 4),
      2.5,
      Paint()..color = Colors.white.withValues(alpha: 0.85),
    );

    // Golden Stupa / Crown on top of Guru Bead
    final crownPath = Path()
      ..moveTo(gx - 7, gy - rGuru)
      ..lineTo(gx, gy - rGuru - 8)
      ..lineTo(gx + 7, gy - rGuru)
      ..close();
    canvas.drawPath(
      crownPath,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFEF08A), Color(0xFFD97706), Color(0xFFB45309)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(gx - 7, gy - rGuru - 8, 14, 8)),
    );

    // Hanging Sacred Silk Saffron Tassel
    final tasselSway = math.sin(auraValue * math.pi * 2) * 2.5;
    final tasselStartY = gy + rGuru;
    final tasselEndY = tasselStartY + 16;

    // Gold collar binding
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(gx, tasselStartY + 2), width: 8, height: 4),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFFF59E0B),
    );

    // Flowing silk fringe
    final tasselPaint = Paint()
      ..color = const Color(0xFFEA580C)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    for (int t = -4; t <= 4; t += 2) {
      final p1 = Offset(gx + t * 0.6, tasselStartY + 4);
      final p2 = Offset(gx + t * 1.8 + tasselSway, tasselEndY);
      canvas.drawLine(p1, p2, tasselPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SacredMalaBeadsPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.count != count ||
      oldDelegate.rotationAngle != rotationAngle ||
      oldDelegate.auraValue != auraValue ||
      oldDelegate.rippleValue != rippleValue;
}

class AyurvedicTridoshaWheel extends StatelessWidget {
  const AyurvedicTridoshaWheel({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppLanguageService.instance,
      builder: (context, _) {
        final currentLang = AppLanguageService.instance.currentLanguage;

        final title = switch (currentLang) {
          AppLanguage.telugu => 'ఆయుర్వేద త్రిదోష సమతుల్యత (Tridosha Balance)',
          AppLanguage.tanglish => 'Ayurvedic Tridosha Samathulyatha (Balance)',
          AppLanguage.malayalam => 'ആയുർവേദ ത്രിദോഷ സന്തുലിതാവസ്ഥ (Tridosha Balance)',
          AppLanguage.manglish => 'Ayurveda Tridosha Santhulithavastha (Balance)',
          AppLanguage.english => 'Ayurvedic Tridosha Vitality Balance',
        };

        final vataDosha = switch (currentLang) {
          AppLanguage.telugu => 'వాతం (Vata - Air & Space)',
          AppLanguage.tanglish => 'Vatam (Vata - Air & Space)',
          AppLanguage.malayalam => 'വാതം (Vata - Air & Space)',
          AppLanguage.manglish => 'Vatham (Vata - Air & Space)',
          AppLanguage.english => 'Vata (Air & Space - Nervous System)',
        };
        final vataBalance = switch (currentLang) {
          AppLanguage.telugu => 'శాంతంగా ఉంది (Balanced)',
          AppLanguage.tanglish => 'Shanthamga undi (Balanced)',
          AppLanguage.malayalam => 'സന്തുലിതമാണ് (Balanced)',
          AppLanguage.manglish => 'Santhulithamanu (Balanced)',
          AppLanguage.english => 'Balanced & Calm',
        };
        final vataTip = switch (currentLang) {
          AppLanguage.telugu => 'కీళ్లకు నువ్వుల నూనె మర్దన & గోరువెచ్చని ఆహారం మేలు చేస్తుంది.',
          AppLanguage.tanglish => 'Keellaku nuvvula noone mardana & goruvetchani aahaaram melu chesthundi.',
          AppLanguage.malayalam => 'സന്ധികളിൽ നല്ലെണ്ണ മസാജും ചൂടുള്ള ഭക്ഷണവും വാതശമനത്തിന് ഉത്തമമാണ്.',
          AppLanguage.manglish => 'Sandhikalil nallenna massageum choodulla bhakshanavum vatha shamananathinnu nallathaanu.',
          AppLanguage.english => 'Warm sesame oil joint massage & warm nourishing meals pacify Vata.',
        };

        final pittaDosha = switch (currentLang) {
          AppLanguage.telugu => 'పిత్తం (Pitta - Fire & Energy)',
          AppLanguage.tanglish => 'Pittam (Pitta - Fire & Energy)',
          AppLanguage.malayalam => 'പിത്തം (Pitta - Fire & Energy)',
          AppLanguage.manglish => 'Pitham (Pitta - Fire & Energy)',
          AppLanguage.english => 'Pitta (Fire & Energy - Metabolism)',
        };
        final pittaBalance = switch (currentLang) {
          AppLanguage.telugu => 'మధ్యస్థం (Optimal)',
          AppLanguage.tanglish => 'Madhyastham (Optimal)',
          AppLanguage.malayalam => 'ഉത്തമ നിലയിൽ (Optimal)',
          AppLanguage.manglish => 'Uthama nilayil (Optimal)',
          AppLanguage.english => 'Optimal & Vibrant',
        };
        final pittaTip = switch (currentLang) {
          AppLanguage.telugu => 'మధ్యాహ్నం నెయ్యి మరియు దానిమ్మ రసంతో అగ్నిని చల్లబరచండి.',
          AppLanguage.tanglish => 'Madhyaahnam neyyi mariyu daanimma rasamtho agnini challabarachandi.',
          AppLanguage.malayalam => 'പശുവിൻ നെയ്യും മാതളനാരങ്ങാനീരും കഴിച്ച് ഉദരാഗ്നി ശാന്തമാക്കൂ.',
          AppLanguage.manglish => 'Pashuvin neyyum maathalanaranga juiceum kazhichu pitha shanthi varuthoo.',
          AppLanguage.english => 'Nourish digestive fire with cow ghee, sweet fruits, and pomegranate juice.',
        };

        final kaphaDosha = switch (currentLang) {
          AppLanguage.telugu => 'కఫం (Kapha - Earth & Water)',
          AppLanguage.tanglish => 'Kapham (Kapha - Earth & Water)',
          AppLanguage.malayalam => 'കഫം (Kapha - Earth & Water)',
          AppLanguage.manglish => 'Kapham (Kapha - Earth & Water)',
          AppLanguage.english => 'Kapha (Earth & Water - Immunity)',
        };
        final kaphaBalance = switch (currentLang) {
          AppLanguage.telugu => 'స్థిరంగా ఉంది (Steady)',
          AppLanguage.tanglish => 'Sthiramga undi (Steady)',
          AppLanguage.malayalam => 'സ്ഥിരതയുള്ളത് (Steady)',
          AppLanguage.manglish => 'Sthirathayullathu (Steady)',
          AppLanguage.english => 'Steady & Grounded',
        };
        final kaphaTip = switch (currentLang) {
          AppLanguage.telugu => 'ఉదయం నడకతో శ్వాసకోశాలను ఉత్తేజపరచండి.',
          AppLanguage.tanglish => 'Udayam nadakatho swasakoshalanu utthejaparachandi.',
          AppLanguage.malayalam => 'പ്രഭാത നടത്തത്തിലൂടെ ശ്വാസകോശങ്ങൾക്ക് ഉന്മേഷം പകരൂ.',
          AppLanguage.manglish => 'Prabhatha nadathathilude shwaasakosham unmeshamaakkoo.',
          AppLanguage.english => 'Energize respiratory vitality with an active sunrise morning walk.',
        };

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.eco_rounded, color: Color(0xFF047857), size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.deepNavy,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Quick Language Toggle for all 5 languages
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0).withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final lang in AppLanguage.values)
                          InkWell(
                            onTap: () => AppLanguageService.instance.setLanguage(lang),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: currentLang == lang ? const Color(0xFF047857) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                lang.shortLabel,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: currentLang == lang ? Colors.white : AppColors.deepNavy,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Interactive Animated Tridosha Harmony Mandala Wheel
              const _TridoshaHarmonyMandalaWidget(),
              const SizedBox(height: 14),

              // 3 Dosha Bars
              _buildDoshaRow(
                dosha: vataDosha,
                pct: 0.35,
                color: const Color(0xFF3B82F6),
                balance: vataBalance,
                tip: vataTip,
              ),
              const SizedBox(height: 10),
              _buildDoshaRow(
                dosha: pittaDosha,
                pct: 0.45,
                color: const Color(0xFFF59E0B),
                balance: pittaBalance,
                tip: pittaTip,
              ),
              const SizedBox(height: 10),
              _buildDoshaRow(
                dosha: kaphaDosha,
                pct: 0.20,
                color: const Color(0xFF10B981),
                balance: kaphaBalance,
                tip: kaphaTip,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDoshaRow({
    required String dosha,
    required double pct,
    required Color color,
    required String balance,
    required String tip,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dosha,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  balance,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  tip,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.secondaryText,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TridoshaHarmonyMandalaWidget extends StatefulWidget {
  const _TridoshaHarmonyMandalaWidget();

  @override
  State<_TridoshaHarmonyMandalaWidget> createState() =>
      _TridoshaHarmonyMandalaWidgetState();
}

class _TridoshaHarmonyMandalaWidgetState
    extends State<_TridoshaHarmonyMandalaWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
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
      builder: (context, _) {
        return CustomPaint(
          size: const Size(double.infinity, 124),
          painter: _TridoshaMandalaPainter(animValue: _controller.value),
        );
      },
    );
  }
}

class _TridoshaMandalaPainter extends CustomPainter {
  _TridoshaMandalaPainter({required this.animValue});
  final double animValue;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.height * 0.42;

    // 3 Tri-Dosha Lobes at 120 deg apart
    final angles = [
      -math.pi / 2, // Vata (Top)
      -math.pi / 2 + 2 * math.pi / 3, // Pitta (Bottom Right)
      -math.pi / 2 + 4 * math.pi / 3, // Kapha (Bottom Left)
    ];

    final colors = [
      const Color(0xFF3B82F6), // Vata blue
      const Color(0xFFF59E0B), // Pitta amber
      const Color(0xFF10B981), // Kapha emerald
    ];

    final labels = ['VATA 💨', 'PITTA 🔥', 'KAPHA 🌱'];

    // Outer connecting harmony ring
    final ringPaint = Paint()
      ..color = const Color(0xFFD97706).withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, radius, ringPaint);

    // Dynamic rotation flow
    final rot = animValue * math.pi * 2;

    // Draw 3 flowing energy petals
    for (int i = 0; i < 3; i++) {
      final a = angles[i] + (rot * 0.08);
      final px = center.dx + radius * 0.75 * math.cos(a);
      final py = center.dy + radius * 0.75 * math.sin(a);
      final lobeCenter = Offset(px, py);

      // Energy lobe glow
      canvas.drawCircle(
        lobeCenter,
        22 + 3 * math.sin(animValue * math.pi * 2 + i * 2),
        Paint()
          ..color = colors[i].withValues(alpha: 0.20)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );

      // Inner lobe circle
      canvas.drawCircle(
        lobeCenter,
        18,
        Paint()
          ..shader = RadialGradient(
            colors: [colors[i].withValues(alpha: 0.5), colors[i]],
          ).createShader(Rect.fromCircle(center: lobeCenter, radius: 18)),
      );

      // Text label
      final textPainter = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: const TextStyle(
            fontSize: 8.5,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(lobeCenter.dx - textPainter.width / 2, lobeCenter.dy - textPainter.height / 2),
      );
    }

    // Center Golden Equilibrium Jewel
    final centerPulse = 1.0 + 0.15 * math.sin(animValue * math.pi * 2);
    canvas.drawCircle(
      center,
      12 * centerPulse,
      Paint()
        ..color = const Color(0xFFFDE68A).withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawCircle(
      center,
      7,
      Paint()..color = const Color(0xFFD97706),
    );
    canvas.drawCircle(
      center,
      3,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _TridoshaMandalaPainter oldDelegate) =>
      oldDelegate.animValue != animValue;
}

// =============================================================================
// 16. Youth Interactive Quest & Pomodoro Engine (<22)
// =============================================================================

class YouthCyberQuestEngine extends StatefulWidget {
  const YouthCyberQuestEngine({super.key});

  @override
  State<YouthCyberQuestEngine> createState() => _YouthCyberQuestEngineState();
}

class _YouthCyberQuestEngineState extends State<YouthCyberQuestEngine> {
  final Set<int> _completedQuests = {0};

  void _toggleQuest(int index) {
    setState(() {
      if (_completedQuests.contains(index)) {
        _completedQuests.remove(index);
      } else {
        _completedQuests.add(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final quests = [
      {
        'title': '25m Deep Focus Study Sprint',
        'sub': 'Phone on silent • Complete 1 textbook concept',
        'xp': '+50 XP',
        'icon': Icons.timer_rounded,
        'color': const Color(0xFF6C5CE7),
      },
      {
        'title': '3m Exam Calm Breathing Reset',
        'sub': 'Inhale 4s, Hold 4s, Exhale 6s to lower test anxiety',
        'xp': '+30 XP',
        'icon': Icons.air_rounded,
        'color': const Color(0xFF00CEC9),
      },
      {
        'title': '24-Hour Social Media Dopamine Pause',
        'sub': 'Replace night phone scrolling with 5 pages reading',
        'xp': '+40 XP',
        'icon': Icons.phonelink_erase_rounded,
        'color': const Color(0xFFFF7675),
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF6C5CE7).withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C5CE7).withValues(alpha: 0.1),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.sports_esports_rounded, color: Color(0xFF6C5CE7), size: 22),
                  SizedBox(width: 8),
                  Text(
                    '⚡ Daily Mind Quests',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.deepNavy,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C5CE7).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_completedQuests.length} of 3 Done',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6C5CE7),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          ...quests.asMap().entries.map((entry) {
            final idx = entry.key;
            final q = entry.value;
            final isDone = _completedQuests.contains(idx);
            final color = q['color'] as Color;

            return GestureDetector(
              onTap: () => _toggleQuest(idx),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDone ? color.withValues(alpha: 0.08) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDone ? color : AppColors.border,
                    width: isDone ? 1.6 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isDone ? color : color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isDone ? Icons.check_rounded : (q['icon'] as IconData),
                        size: 18,
                        color: isDone ? Colors.white : color,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            q['title'] as String,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: isDone ? color : AppColors.deepNavy,
                              decoration: isDone ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            q['sub'] as String,
                            style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        q['xp'] as String,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// =============================================================================
// 17. Adult Executive Circadian Energy Flow Waveform (22-45)
// =============================================================================

class ExecutiveCircadianFlowCard extends StatelessWidget {
  const ExecutiveCircadianFlowCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.timeline_rounded, color: Color(0xFF1E3A8A), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Circadian Focus & Peak Hours',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.deepNavy,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Peak: 10 AM - 1 PM',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Live Animated Circadian Energy Wave Canvas
          const _CircadianWaveGraphWidget(),
          const SizedBox(height: 16),

          // 4 Workday Segments
          _buildSegmentTile(
            time: '06:00 AM – 09:00 AM',
            label: 'Metabolic Priming',
            desc: 'Hydration & sunlight reset dopamine • Light planning',
            level: '85% Energy',
            color: const Color(0xFF0D9488),
          ),
          const SizedBox(height: 8),
          _buildSegmentTile(
            time: '10:00 AM – 01:30 PM',
            label: '⚡ Executive Deep Work Peak',
            desc: 'High cognitive bandwidth • Protect from low-priority meetings',
            level: '96% Energy',
            color: const Color(0xFF2563EB),
          ),
          const SizedBox(height: 8),
          _buildSegmentTile(
            time: '02:00 PM – 03:30 PM',
            label: 'Post-Prandial Creative Flow',
            desc: 'Strategic brainstorming, design thinking & informal 1-on-1s',
            level: '74% Energy',
            color: const Color(0xFFF59E0B),
          ),
          const SizedBox(height: 8),
          _buildSegmentTile(
            time: '08:30 PM – 10:30 PM',
            label: 'Cortisol Decompression',
            desc: 'Digital sunset • Prepares melatonin for restorative REM sleep',
            level: '55% Energy',
            color: const Color(0xFF8B5CF6),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentTile({
    required String time,
    required String label,
    required String desc,
    required String level,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 38,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
                    ),
                    Text(
                      level,
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: color),
                    ),
                  ],
                ),
                Text(
                  time,
                  style: const TextStyle(fontSize: 10, color: AppColors.secondaryText),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(fontSize: 11, color: AppColors.deepNavy),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CircadianWaveGraphWidget extends StatefulWidget {
  const _CircadianWaveGraphWidget();

  @override
  State<_CircadianWaveGraphWidget> createState() =>
      _CircadianWaveGraphWidgetState();
}

class _CircadianWaveGraphWidgetState extends State<_CircadianWaveGraphWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
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
      builder: (context, _) {
        return CustomPaint(
          size: const Size(double.infinity, 90),
          painter: _CircadianWavePainter(animValue: _controller.value),
        );
      },
    );
  }
}

class _CircadianWavePainter extends CustomPainter {
  _CircadianWavePainter({required this.animValue});
  final double animValue;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Timeline base grid line
    final baseLinePaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, h * 0.78), Offset(w, h * 0.78), baseLinePaint);

    // Shaded Peak Window (from x = w * 0.25 to x = w * 0.55)
    final peakRect = Rect.fromLTRB(w * 0.25, 0, w * 0.55, h * 0.78);
    final peakPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF2563EB).withValues(alpha: 0.16),
          const Color(0xFF2563EB).withValues(alpha: 0.02),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(peakRect);
    canvas.drawRRect(RRect.fromRectAndRadius(peakRect, const Radius.circular(8)), peakPaint);

    // Continuous Circadian Energy Sine Wave
    final wavePath = Path();
    final fillPath = Path();
    fillPath.moveTo(0, h * 0.78);

    for (double x = 0; x <= w; x += 6) {
      final normX = x / w;
      // Multi-frequency curve representing 24h biological alertness
      final biologicalBase = math.sin(normX * math.pi) * 30.0;
      final waveDrift = math.sin((normX * math.pi * 4) - (animValue * math.pi * 2)) * 4.0;
      final y = (h * 0.70) - biologicalBase - waveDrift;

      if (x == 0) {
        wavePath.moveTo(x, y);
      } else {
        wavePath.lineTo(x, y);
      }
      fillPath.lineTo(x, y);
    }
    fillPath.lineTo(w, h * 0.78);
    fillPath.close();

    // Wave Fill
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          colors: [
            const Color(0xFF38BDF8).withValues(alpha: 0.18),
            const Color(0xFF1E3A8A).withValues(alpha: 0.02),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // Wave Stroke
    canvas.drawPath(
      wavePath,
      Paint()
        ..color = const Color(0xFF2563EB)
        ..strokeWidth = 2.4
        ..style = PaintingStyle.stroke,
    );

    // Animated Pulsing Beacon on Current Hour (Peak Zone)
    final beaconX = w * 0.38;
    final beaconNormX = beaconX / w;
    final beaconY = (h * 0.70) -
        (math.sin(beaconNormX * math.pi) * 30.0) -
        math.sin((beaconNormX * math.pi * 4) - (animValue * math.pi * 2)) * 4.0;

    canvas.drawCircle(
      Offset(beaconX, beaconY),
      8 + 4 * math.sin(animValue * math.pi * 2),
      Paint()
        ..color = const Color(0xFF2563EB).withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawCircle(
      Offset(beaconX, beaconY),
      4.5,
      Paint()..color = const Color(0xFF2563EB),
    );
    canvas.drawCircle(
      Offset(beaconX, beaconY),
      2.0,
      Paint()..color = Colors.white,
    );

    // Timeline Labels
    const labels = ['06:00', '12:00', '18:00', '24:00'];
    for (int i = 0; i < 4; i++) {
      final lx = (w * 0.05) + (i * (w * 0.28));
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(lx, h * 0.81));
    }
  }

  @override
  bool shouldRepaint(covariant _CircadianWavePainter oldDelegate) =>
      oldDelegate.animValue != animValue;
}

// =============================================================================
// 18. AgeCohortAmbientBackground (Transforms entire screen UI/UX dynamically)
// =============================================================================

/// Dynamic animated living background canvas that transforms the entire screen's
/// visual ambiance based on the active [AgeGroup]:
/// - Youth: Animated cyberpunk constellation with drifting stardust particles and neon corner auras.
/// - Adult: Animated circadian bio-rhythm sine wave undulations and sapphire/cobalt executive quartz glow.
/// - Senior: Auspicious temple parchment tone with floating sacred diya light embers and a slow-rotating golden lotus mandala watermark.
class AgeCohortAmbientBackground extends StatefulWidget {
  const AgeCohortAmbientBackground({
    super.key,
    required this.child,
    this.ageGroup,
  });

  final Widget child;
  final AgeGroup? ageGroup;

  @override
  State<AgeCohortAmbientBackground> createState() => _AgeCohortAmbientBackgroundState();
}

class _AgeCohortAmbientBackgroundState extends State<AgeCohortAmbientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ambientController;

  @override
  void initState() {
    super.initState();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    )..repeat();
  }

  @override
  void dispose() {
    _ambientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeGroup = widget.ageGroup ?? AgeProfileService.instance.ageGroup;

    return AnimatedBuilder(
      animation: _ambientController,
      builder: (context, _) {
        return CustomPaint(
          painter: _CohortAmbientPainter(
            group: activeGroup,
            animValue: _ambientController.value,
          ),
          child: widget.child,
        );
      },
    );
  }
}

class _CohortAmbientPainter extends CustomPainter {
  _CohortAmbientPainter({required this.group, required this.animValue});

  final AgeGroup group;
  final double animValue;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    switch (group) {
      case AgeGroup.youth:
        _paintYouthCyberAmbience(canvas, size, w, h);
        break;
      case AgeGroup.adult:
        _paintAdultCircadianAmbience(canvas, size, w, h);
        break;
      case AgeGroup.senior:
        _paintSeniorSanctuaryAmbience(canvas, size, w, h);
        break;
    }
  }

  void _paintYouthCyberAmbience(Canvas canvas, Size size, double w, double h) {
    // Top-right and bottom-left neon energy orbs
    final orb1Center = Offset(w * 0.85, 120 + 20 * math.sin(animValue * math.pi * 2));
    final orb1Paint = Paint()
      ..color = const Color(0xFF6C5CE7).withValues(alpha: 0.08 + 0.04 * math.sin(animValue * math.pi * 2))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 55);
    canvas.drawCircle(orb1Center, 90, orb1Paint);

    final orb2Center = Offset(w * 0.15, 450 + 25 * math.cos(animValue * math.pi * 2));
    final orb2Paint = Paint()
      ..color = const Color(0xFF00CEC9).withValues(alpha: 0.07 + 0.03 * math.cos(animValue * math.pi * 2))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 65);
    canvas.drawCircle(orb2Center, 110, orb2Paint);

    // Drifting subtle neon stardust particles
    for (int i = 0; i < 12; i++) {
      final px = (w * ((i * 0.19 + animValue * 0.08) % 1.0));
      final py = (h * ((i * 0.27 + (1.0 - animValue) * 0.06) % 1.0));
      final pRadius = 1.2 + (i % 3) * 0.9;
      final pPaint = Paint()
        ..color = (i % 2 == 0 ? const Color(0xFF6C5CE7) : const Color(0xFF00CEC9))
            .withValues(alpha: 0.25 + 0.20 * math.sin(animValue * math.pi * 2 + i));
      canvas.drawCircle(Offset(px, py), pRadius, pPaint);
    }
  }

  void _paintAdultCircadianAmbience(Canvas canvas, Size size, double w, double h) {
    // Subtle circadian sapphire energy glow
    final orbCenter = Offset(w * 0.5, 200 + 15 * math.sin(animValue * math.pi * 2));
    final orbPaint = Paint()
      ..color = const Color(0xFF2563EB).withValues(alpha: 0.05 + 0.02 * math.sin(animValue * math.pi * 2))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);
    canvas.drawCircle(orbCenter, 140, orbPaint);

    // Dynamic circadian flowing wave in background
    final wavePath = Path();
    wavePath.moveTo(0, 320);
    for (double x = 0; x <= w; x += 10) {
      final normX = x / w;
      final y = 320 + math.sin(normX * math.pi * 3 + animValue * math.pi * 2) * 18;
      wavePath.lineTo(x, y);
    }
    final wavePaint = Paint()
      ..color = const Color(0xFF0D9488).withValues(alpha: 0.06)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(wavePath, wavePaint);
  }

  void _paintSeniorSanctuaryAmbience(Canvas canvas, Size size, double w, double h) {
    // Auspicious warm golden diya glow
    final diyaCenter = Offset(w * 0.82, 160);
    final diyaPaint = Paint()
      ..color = const Color(0xFFD97706).withValues(alpha: 0.08 + 0.03 * math.sin(animValue * math.pi * 2))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 70);
    canvas.drawCircle(diyaCenter, 120, diyaPaint);

    // Floating sacred golden embers drifting upward
    for (int i = 0; i < 10; i++) {
      final px = (w * ((i * 0.17 + 0.05) % 0.9));
      final rawY = (h * ((i * 0.31 - animValue * 0.12) % 1.0));
      final py = rawY < 0 ? rawY + h : rawY;
      final emberPaint = Paint()
        ..color = const Color(0xFFB45309).withValues(alpha: 0.22 + 0.18 * math.sin(animValue * math.pi * 2 + i));
      canvas.drawCircle(Offset(px, py), 1.6 + (i % 2) * 0.8, emberPaint);
    }

    // Sacred rotating lotus mandala watermark in upper corner
    final mandalaCenter = Offset(w * 0.92, 100);
    const mandalaRadius = 65.0;
    final mandalaPaint = Paint()
      ..color = const Color(0xFFB45309).withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.save();
    canvas.translate(mandalaCenter.dx, mandalaCenter.dy);
    canvas.rotate(animValue * math.pi * 0.15);
    for (int p = 0; p < 8; p++) {
      final angle = (p * math.pi / 4);
      final px = math.cos(angle) * (mandalaRadius * 0.5);
      final py = math.sin(angle) * (mandalaRadius * 0.5);
      canvas.drawCircle(Offset(px, py), mandalaRadius * 0.45, mandalaPaint);
    }
    canvas.drawCircle(Offset.zero, mandalaRadius * 0.75, mandalaPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CohortAmbientPainter oldDelegate) =>
      oldDelegate.animValue != animValue || oldDelegate.group != group;
}

// =============================================================================
// 19. UnifiedFivePillarsLifeRiver (Connected 5-Pillar Seamless Ecosystem)
// =============================================================================

/// Centerpiece widget providing a fully unified, interconnected, continuous life flow
/// for all 5 AVARA components:
/// Astrology ➔ Health ➔ Habits ➔ Finance ➔ Insights ↺ (Continuous Loop)
///
/// Features:
/// 1. An unbroken continuous flowing river / circuit connecting all 5 pillars.
/// 2. Active animated traveling energy packets showing how energy flows continuously from one pillar to the next.
/// 3. Clear cause-and-effect explanations so the user understands why and how all 5 things are connected.
/// 4. Interactive "Follow the Life Flow ➔" step-through button.
/// 5. 100% localized in Telugu, Malayalam, Tanglish, Manglish, and English.
/// 6. Audio listening button (TTS) with native neural voice explaining the connected life flow.
class UnifiedFivePillarsLifeRiver extends StatefulWidget {
  const UnifiedFivePillarsLifeRiver({
    super.key,
    required this.onOpenPillar,
  });

  final void Function(int pillarIndex) onOpenPillar;

  @override
  State<UnifiedFivePillarsLifeRiver> createState() => _UnifiedFivePillarsLifeRiverState();
}

class _UnifiedFivePillarsLifeRiverState extends State<UnifiedFivePillarsLifeRiver>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flowController;
  int _activeNode = 0;

  @override
  void initState() {
    super.initState();
    _flowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
  }

  @override
  void dispose() {
    _flowController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getPillars(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.telugu:
        return [
          {
            'name': 'జ్యోతిషం',
            'role': 'కాస్మిక్ & సర్కాడియన్ క్లాక్',
            'color': const Color(0xFF6C5CE7),
            'icon': Icons.nightlight_round,
            'fedFrom': 'విశ్లేషణలు (ఆత్మ సంకల్పం & కర్మ సమతుల్యత)',
            'feedsInto': 'ఆరోగ్యం (నిద్ర & జీవన లయ సమయాలు)',
            'flowBridge': 'సర్కాడియన్ శక్తి & సరైన సమయం ➔ ఆరోగ్యానికి ఇస్తుంది',
            'synergy': 'సూర్య, చంద్ర గ్రహ స్థానాల ఆధారంగా ఉదయపు ఏకాగ్రతా వేళలను (10:00 AM - 1:30 PM) నిర్దేశిస్తుంది.',
            'connectsTo': 'ఆరోగ్యానికి సరైన నిద్ర వేళలు, జీర్ణక్రియ సమయాలను అందిస్తుంది.',
            'practicalImpact': 'కాస్మిక్ వేళల్లో జీవించడం వల్ల మెదడు అలసట 35% తగ్గి సహజ శక్తి పెరుగుతుంది.',
            'nextName': 'ఆరోగ్యం',
          },
          {
            'name': 'ఆరోగ్యం',
            'role': 'శరీర శక్తి & ఆయుర్వేదం',
            'color': const Color(0xFF00CEC9),
            'icon': Icons.favorite_rounded,
            'fedFrom': 'జ్యోతిషం (సర్కాడియన్ నిద్ర వేళలు)',
            'feedsInto': 'అలవాట్లు (సాధన & ఏకాగ్రత సంకల్పం)',
            'flowBridge': 'శారీరక శక్తి & దృఢ సంకల్పం ➔ అలవాట్లకు ఇస్తుంది',
            'synergy': 'పిత్త-కఫ సమతుల్యత, గాఢ నిద్ర మరియు సమతుల్య పోషణ ద్వారా శరీర రోగనిరోధక శక్తిని ఇస్తుంది.',
            'connectsTo': 'రోజువారీ అలవాట్లను క్రమశిక్షణతో ఆచరించడానికి అవసరమైన దృఢ సంకల్ప శక్తిని ఇస్తుంది.',
            'practicalImpact': 'గాఢ నిద్ర మరియు హైడ్రేషన్ ఉదయం 25 నిమిషాల డీప్ వర్క్ స్ప్రింట్‌లకు అపార శక్తినిస్తాయి.',
            'nextName': 'అలవాట్లు',
          },
          {
            'name': 'అలవాట్లు',
            'role': 'రోజువారీ సాధన & లక్ష్యాలు',
            'color': const Color(0xFFE17055),
            'icon': Icons.track_changes_rounded,
            'fedFrom': 'ఆరోగ్యం (శారీరక శక్తి & నిశ్చల మనస్సు)',
            'feedsInto': 'ఆర్థికం (క్రమశిక్షణ & స్పృహతో కూడిన వ్యయం)',
            'flowBridge': 'క్రమశిక్షణ & ఆత్మనిగ్రహం ➔ అనవసర ఖర్చులను అరికడుతుంది',
            'synergy': '25 నిమిషాల ఏకాగ్రత మరియు రోజూ స్థిరమైన దినచర్యల ద్వారా న్యూరల్ మార్గాలను బలపరుస్తుంది.',
            'connectsTo': 'ఒత్తిడితో కూడిన అనవసర ఖర్చులను నియంత్రించి ఆర్థిక ప్రశాంతతను కాపాడుతుంది.',
            'practicalImpact': 'స్థిరమైన అలవాట్లు డోపమైన్ కోసం చేసే అనవసర కొనుగోళ్లను అరికట్టి ₹12,000+ ఆదా చేస్తాయి.',
            'nextName': 'ఆర్థికం',
          },
          {
            'name': 'ఆర్థికం',
            'role': 'స్పృహతో కూడిన సంపద & బడ్జెట్',
            'color': const Color(0xFF00B894),
            'icon': Icons.account_balance_wallet_rounded,
            'fedFrom': 'అలవాట్లు (క్రమశిక్షణ & సంతృప్తి భావన)',
            'feedsInto': 'విశ్లేషణలు (మానసిక ప్రశాంతత & సమగ్ర జీవన సూచిక)',
            'flowBridge': 'ఆర్థిక భద్రత & ప్రశాంతత ➔ విశ్లేషణలకు మనస్సును స్వేచ్ఛ చేస్తుంది',
            'synergy': 'క్రమశిక్షణతో కూడిన బడ్జెట్ మరియు 24-గంటల ఆలోచనా వ్యవధి ఆర్థిక స్వేచ్ఛను ఇస్తాయి.',
            'connectsTo': 'డబ్బు ఆందోళనలను తొలగించి, ప్రశాంత ధ్యానం మరియు విశ్లేషణలకు మనస్సును స్వేచ్ఛ చేస్తుంది.',
            'practicalImpact': 'అప్పులు, అనవసర ఖర్చులు లేకపోవడం వల్ల నిద్ర నాణ్యత మరియు మానసిక ప్రశాంతత పెరుగుతాయి.',
            'nextName': 'విశ్లేషణలు',
          },
          {
            'name': 'విశ్లేషణలు',
            'role': 'జీవిత సమగ్ర సమతుల్యత',
            'color': const Color(0xFFE84393),
            'icon': Icons.auto_graph_rounded,
            'fedFrom': 'ఆర్థికం (ఆర్థిక భద్రత & మనశ్శాంతి)',
            'feedsInto': 'జ్యోతిషం (ఆత్మ కర్మ చక్ర సమలేఖనం)',
            'flowBridge': 'సమగ్ర జీవన సామరస్యం ➔ ఆత్మ కర్మ చక్రాన్ని పూర్తి చేస్తుంది',
            'synergy': 'అన్ని 4 విభాగాలను సంశ్లేషణ చేసి 88% సంపూర్ణ జీవన సూచికను లెక్కిస్తుంది.',
            'connectsTo': 'జీవిత సమగ్ర వృద్ధిని మీ ఆత్మ కర్మ వికాసంతో తిరిగి జోడించి చక్రం పూర్తి చేస్తుంది.',
            'practicalImpact': 'వారం వారం మీ సమగ్ర సమతుల్యత పెరిగేకొద్దీ జీవితంలో స్థిరత్వం, ఆనందం సాధ్యమవుతాయి.',
            'nextName': 'జ్యోతిషం',
          },
        ];

      case AppLanguage.malayalam:
        return [
          {
            'name': 'ജ്യോതിഷം',
            'role': 'കോസ്മിക് & സർക്കാഡിയൻ ക്ലോക്ക്',
            'color': const Color(0xFF6C5CE7),
            'icon': Icons.nightlight_round,
            'fedFrom': 'ഉൾക്കാഴ്ചകൾ (ആത്മീയ സമനില & കർമ്മം)',
            'feedsInto': 'ആരോഗ്യം (ഉറക്കവും ജീവനരീതിയും)',
            'flowBridge': 'സർക്കാഡിയൻ ഊർജ്ജവും സമയവും ➔ ആരോഗ്യത്തിന് നൽകുന്നു',
            'synergy': 'സൂര്യ-ചന്ദ്ര സ്ഥാനങ്ങളെ അടിസ്ഥാനമാക്കി ഏകാഗ്രതയുള്ള സമയം (10 AM - 1:30 PM) നിർണ്ണയിക്കുന്നു.',
            'connectsTo': 'ആരോഗ്യത്തിന് അനുയോജ്യമായ ഉറക്ക സമയവും ഭക്ഷണ സമയവും നൽകുന്നു.',
            'practicalImpact': 'പ്രകൃതി നിയമങ്ങളോടൊപ്പം ജീവിക്കുമ്പോൾ മാനസിക ഉന്മേഷം 35% വർദ്ധിക്കുന്നു.',
            'nextName': 'ആരോഗ്യം',
          },
          {
            'name': 'ആരോഗ്യം',
            'role': 'ശരീര ഊർജ്ജവും ആയുർവേദവും',
            'color': const Color(0xFF00CEC9),
            'icon': Icons.favorite_rounded,
            'fedFrom': 'ജ്യോതിഷം (സർക്കാഡിയൻ ഉറക്ക സമയം)',
            'feedsInto': 'ശീലങ്ങൾ (ദൈനംദിന ഇച്ഛാശക്തി)',
            'flowBridge': 'ശാരീരിക കരുത്തും ഉന്മേഷവും ➔ ശീലങ്ങൾക്ക് ഇച്ഛാശക്തി നൽകുന്നു',
            'synergy': 'പിത്ത-കഫ സന്തുലിതാവസ്ഥയും ഗാഢനിദ്രയും നൽകി ശരീരത്തിന് പ്രതിരോധശേഷി നൽകുന്നു.',
            'connectsTo': 'ദൈനംദിന ശീലങ്ങൾ കൃത്യമായി പാലിക്കാൻ ആവശ്യമായ മനക്കരുത്ത് നൽകുന്നു.',
            'practicalImpact': 'നല്ല ഉറക്കവും ശുദ്ധജലവും രാവിലെ പഠനത്തിനും ജോലിക്കും അപാര ഊർജ്ജം നൽകുന്നു.',
            'nextName': 'ശീലങ്ങൾ',
          },
          {
            'name': 'ശീലങ്ങൾ',
            'role': 'ദൈനംദിന സാധനയും ലക്ഷ്യങ്ങളും',
            'color': const Color(0xFFE17055),
            'icon': Icons.track_changes_rounded,
            'fedFrom': 'ആരോഗ്യം (ശാരീരിക കരുത്തും പ്രശാന്തതയും)',
            'feedsInto': 'ധനകാര്യം (സാമ്പത്തിക നിയന്ത്രണം)',
            'flowBridge': 'അച്ചടക്കവും ആത്മനിയന്ത്രണവും ➔ അനാവശ്യ ചിലവുകൾ തടയുന്നു',
            'synergy': '25 മിനിറ്റ് ഏകാഗ്രതയും സ്ഥിരമായ ദിനചര്യകളും തലച്ചോറിനെ ശക്തിപ്പെടുത്തുന്നു.',
            'connectsTo': 'അനാവശ്യ ചെലവുകൾ ഒഴിവാക്കി സാമ്പത്തിക ഭദ്രത സംരക്ഷിക്കുന്നു.',
            'practicalImpact': 'അനാവശ്യ ഓൺലൈൻ പർച്ചേസുകൾ ഒഴിവാക്കി സാമ്പത്തിക സ്വാതന്ത്ര്യം നൽകുന്നു.',
            'nextName': 'ധനകാര്യം',
          },
          {
            'name': 'ധനകാര്യം',
            'role': 'ബജറ്റും സമ്പത്തും',
            'color': const Color(0xFF00B894),
            'icon': Icons.account_balance_wallet_rounded,
            'fedFrom': 'ശീലങ്ങൾ (ആത്മനിയന്ത്രണവും സംതൃപ്തിയും)',
            'feedsInto': 'ഉൾക്കാഴ്ചകൾ (മനസ്സമാധാനം & ലൈഫ് സ്കോർ)',
            'flowBridge': 'സാമ്പത്തിക ഭദ്രത ➔ മനസ്സിന് ധ്യാനത്തിനും വിശകലനത്തിനും സ്വാതന്ത്ര്യം നൽകുന്നു',
            'synergy': 'കൃത്യമായ ബജറ്റും ചെലവ് നിയന്ത്രണവും സാമ്പത്തിക സുരക്ഷിതത്വം ഉറപ്പാക്കുന്നു.',
            'connectsTo': 'സാമ്പത്തിക ഉത്കണ്ഠകൾ ഒഴിവാക്കി പ്രശാന്തമായ ധ്യാനത്തിന് വഴി നൽകുന്നു.',
            'practicalImpact': 'സാമ്പത്തിക സമാധാനം ഉറക്കത്തിന്റെ ഗുണനിലവാരവും സന്തോഷവും വർദ്ധിപ്പിക്കുന്നു.',
            'nextName': 'ഉൾക്കാഴ്ചകൾ',
          },
          {
            'name': 'ഉൾക്കാഴ്ചകൾ',
            'role': 'ജീവിത സന്തുലിതാവസ്ഥ',
            'color': const Color(0xFFE84393),
            'icon': Icons.auto_graph_rounded,
            'fedFrom': 'ധനകാര്യം (സാമ്പത്തിക സമാധാനം)',
            'feedsInto': 'ജ്യോതിഷം (ആത്മീയ കർമ്മ ചക്രം)',
            'flowBridge': 'സമഗ്ര ജീവിത ഐക്യം ➔ കർമ്മ ചക്രത്തെ പൂർത്തിയാക്കുന്നു',
            'synergy': 'നാല് ഘടകങ്ങളെയും സംയോജിപ്പിച്ച് 88% സമഗ്ര ജീവിത സൂചിക കണക്കാക്കുന്നു.',
            'connectsTo': 'ജീവിത വിജയത്തെ ആത്മീയ വളർച്ചയുമായി വീണ്ടും ബന്ധിപ്പിച്ച് ചക്രം പൂർത്തിയാക്കുന്നു.',
            'practicalImpact': 'ദിവസേന നിങ്ങളുടെ ജീവിത സന്തുലിതാവസ്ഥ വിലയിരുത്തി സമാധാനത്തോടെ മുന്നേറുക.',
            'nextName': 'ജ്യോതിഷം',
          },
        ];

      default:
        return [
          {
            'name': 'Astrology',
            'role': 'Cosmic & Circadian Clock',
            'color': const Color(0xFF6C5CE7),
            'icon': Icons.nightlight_round,
            'fedFrom': 'Insights (Soul Alignment & Balance)',
            'feedsInto': 'Health (Circadian Wake & Sleep Hours)',
            'flowBridge': 'Circadian Timing & Energy Windows ➔ Powers Biological Health',
            'synergy': 'Aligns daily mental focus windows (10:00 AM - 1:30 PM) using planetary hora and lunar cycles.',
            'connectsTo': 'Feeds biological wake times, Agni digestive cycles, and melatonin rhythm into Health.',
            'practicalImpact': 'Living in circadian sync drops brain fog by 35% and boosts natural morning vitality.',
            'nextName': 'Health',
          },
          {
            'name': 'Health',
            'role': 'Vital Body, Rest & Ayurveda',
            'color': const Color(0xFF00CEC9),
            'icon': Icons.favorite_rounded,
            'fedFrom': 'Astrology (Circadian Biological Rhythm)',
            'feedsInto': 'Habits (Physical Stamina & Willpower)',
            'flowBridge': 'High Physical Energy & Rested Mind ➔ Fuels Unbreakable Habit Streaks',
            'synergy': 'Cultivates biological stamina, Pitta-Kapha equilibrium, deep restorative REM, and cellular vitality.',
            'connectsTo': 'Provides the physical willpower necessary to execute daily habit routines without burnout.',
            'practicalImpact': 'Restful sleep directly powers your daily 25-minute Pomodoro study & work sprints.',
            'nextName': 'Habits',
          },
          {
            'name': 'Habits',
            'role': 'Consistent Sadhana & Focus',
            'color': const Color(0xFFE17055),
            'icon': Icons.track_changes_rounded,
            'fedFrom': 'Health (Physical Energy & Clear Mind)',
            'feedsInto': 'Finance (Discipline Prevents Impulse Spends)',
            'flowBridge': 'Daily Focus & Emotional Self-Control ➔ Protects Wealth & Savings',
            'synergy': 'Strengthens neural willpower pathways through 25-minute focus sprints, hydration, and daily journaling.',
            'connectsTo': 'Prevents stress-driven retail therapy by replacing dopamine triggers with mindful progress.',
            'practicalImpact': 'Disciplined micro-habits eliminate impulsive buying and save ₹12,000+ every single month.',
            'nextName': 'Finance',
          },
          {
            'name': 'Finance',
            'role': 'Mindful Wealth & Budgeting',
            'color': const Color(0xFF00B894),
            'icon': Icons.account_balance_wallet_rounded,
            'fedFrom': 'Habits (Discipline & Contentment)',
            'feedsInto': 'Insights (Financial Peace Frees the Mind)',
            'flowBridge': 'Zero Money Anxiety ➔ Frees Mind for Deep Self-Reflection & Peace',
            'synergy': 'Ensures freedom through clear category tracking, mindful spending pauses, and budget peace.',
            'connectsTo': 'Eliminates chronic financial anxiety, creating mental spaciousness for deep inner reflection.',
            'practicalImpact': 'Zero money anxiety leads to measurably lower evening cortisol and peaceful sleep.',
            'nextName': 'Insights',
          },
          {
            'name': 'Insights',
            'role': 'Holistic Life Synthesis',
            'color': const Color(0xFFE84393),
            'icon': Icons.auto_graph_rounded,
            'fedFrom': 'Finance (Financial Stability & Peace)',
            'feedsInto': 'Astrology (Full Karmic Evolution Loop)',
            'flowBridge': 'Holistic Harmony Synthesis ➔ Completes the Karmic Evolutionary Cycle',
            'synergy': 'Synthesizes all 4 pillars into your 88% Holistic Life Harmony score, revealing cross-life patterns.',
            'connectsTo': 'Feeds your synthesized growth back into your birth chart, completing the unbreakable life loop.',
            'practicalImpact': 'Weekly harmony tracking ensures all five life dimensions grow synchronously as one.',
            'nextName': 'Astrology',
          },
        ];
    }
  }

  void _speakFlowExplanation(BuildContext context, Map<String, dynamic> pillar, AppLanguage lang) {
    final speechText = switch (lang) {
      AppLanguage.telugu =>
        '${pillar['name']}. ఇది ${pillar['role']}. ఇది ${pillar['fedFrom']} నుండి శక్తిని పొందుతుంది. మరియు ${pillar['feedsInto']} లోకి ప్రవహిస్తుంది. ${pillar['synergy']} ${pillar['practicalImpact']}',
      AppLanguage.malayalam =>
        '${pillar['name']}. ഇത് ${pillar['role']}. ഇത് ${pillar['fedFrom']} വഴി ശക്തി പ്രാപിക്കുന്നു, കൂടാതെ ${pillar['feedsInto']} ലേക്ക് ഒഴുകുന്നു. ${pillar['synergy']} ${pillar['practicalImpact']}',
      _ =>
        '${pillar['name']}. Role: ${pillar['role']}. Fed from: ${pillar['fedFrom']}. Feeds into: ${pillar['feedsInto']}. ${pillar['synergy']} Practical impact: ${pillar['practicalImpact']}',
    };
    TtsService.instance.speak(speechText, language: lang);
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLanguageService.instance.currentLanguage;
    final tr = AppLanguageService.instance.tr;
    final pillars = _getPillars(lang);
    final active = pillars[_activeNode];
    final activeColor = active['color'] as Color;

    final title = tr('five_pillars_title');
    final subtitle = tr('five_pillars_subtitle');
    final nextBtnText = tr('flow_next_btn');

    final fedFromLabel = switch (lang) {
      AppLanguage.telugu => '◀ ఇన్పుట్ (ఎక్కడి నుండి వచ్చింది):',
      AppLanguage.malayalam => '◀ ഇൻപുട്ട് (എവിടെ നിന്ന് ലഭിക്കുന്നു):',
      _ => '◀ Fed From (Incoming Power):',
    };

    final feedsIntoLabel = switch (lang) {
      AppLanguage.telugu => '▶ అవుట్‌పుట్ (ఎక్కడికి వెళుతుంది):',
      AppLanguage.malayalam => '▶ ഔട്ട്പുട്ട് (എങ്ങോട്ട് ഒഴുകുന്നു):',
      _ => '▶ Feeds Into (Outgoing Synergy):',
    };

    final whyConnectsLabel = switch (lang) {
      AppLanguage.telugu => '🔗 ఇవి ఎలా అనుసంధానమై ఉన్నాయి:',
      AppLanguage.malayalam => '🔗 ഇവ എങ്ങനെ പരസ്പരം ബന്ധപ്പെട്ടിരിക്കുന്നു:',
      _ => '🔗 How These Form One Connected Flow:',
    };

    final impactLabel = switch (lang) {
      AppLanguage.telugu => '⚡ ప్రత్యక్ష దైనందిన ప్రయోజనం:',
      AppLanguage.malayalam => '⚡ ദൈനംദിന ജീവിതത്തിലെ മാറ്റം:',
      _ => '⚡ Practical Real-World Impact:',
    };

    final listenBtnLabel = switch (lang) {
      AppLanguage.telugu => 'వినండి 🔊',
      AppLanguage.malayalam => 'കേൾക്കുക 🔊',
      _ => 'Listen 🔊',
    };

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: activeColor.withValues(alpha: 0.32), width: 1.8),
        boxShadow: [
          BoxShadow(
            color: activeColor.withValues(alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [activeColor, activeColor.withValues(alpha: 0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.all_inclusive_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.deepNavy,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: activeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Loop ↺',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: activeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Interconnected Horizontal River Nodes (Astrology ➔ Health ➔ Habits ➔ Finance ➔ Insights ↺)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                for (int i = 0; i < 5; i++) ...[
                  InkWell(
                    onTap: () => setState(() => _activeNode = i),
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _activeNode == i
                            ? (pillars[i]['color'] as Color).withValues(alpha: 0.14)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _activeNode == i
                              ? (pillars[i]['color'] as Color)
                              : AppColors.border,
                          width: _activeNode == i ? 2.0 : 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: pillars[i]['color'] as Color,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              pillars[i]['icon'] as IconData,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            pillars[i]['name'] as String,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: _activeNode == i
                                  ? (pillars[i]['color'] as Color)
                                  : AppColors.deepNavy,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Animated Pulsing Flow Arrow between nodes
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      i == 4 ? Icons.repeat_rounded : Icons.arrow_forward_rounded,
                      size: 16,
                      color: _activeNode == i
                          ? (pillars[i]['color'] as Color)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Active Pillar Detailed Synergy Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: activeColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: activeColor.withValues(alpha: 0.22), width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(active['icon'] as IconData, color: activeColor, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          '${active['name']} • ${active['role']}',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: activeColor,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _speakFlowExplanation(context, active, lang),
                      icon: const Icon(Icons.volume_up_rounded, size: 14),
                      label: Text(listenBtnLabel, style: const TextStyle(fontSize: 11)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: activeColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Connection Bridge Line
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: activeColor.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.sync_alt_rounded, size: 16, color: activeColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          active['flowBridge'] as String,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: activeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Fed From & Feeds Into
                Text(
                  fedFromLabel,
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.secondaryText),
                ),
                Text(
                  active['fedFrom'] as String,
                  style: const TextStyle(fontSize: 11.5, color: AppColors.deepNavy, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  feedsIntoLabel,
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.secondaryText),
                ),
                Text(
                  active['feedsInto'] as String,
                  style: const TextStyle(fontSize: 11.5, color: AppColors.deepNavy, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),

                // Why connects
                Text(
                  whyConnectsLabel,
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.secondaryText),
                ),
                Text(
                  active['synergy'] as String,
                  style: const TextStyle(fontSize: 12, color: AppColors.deepNavy, height: 1.3),
                ),
                const SizedBox(height: 8),

                // Practical impact
                Text(
                  impactLabel,
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.secondaryText),
                ),
                Text(
                  active['practicalImpact'] as String,
                  style: TextStyle(fontSize: 11.5, color: activeColor, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => widget.onOpenPillar(_activeNode),
                  icon: Icon(Icons.open_in_new_rounded, size: 16, color: activeColor),
                  label: Text(
                    '${active['name']} ➔',
                    style: TextStyle(fontWeight: FontWeight.bold, color: activeColor),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: activeColor, width: 1.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() => _activeNode = (_activeNode + 1) % 5);
                  },
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  label: Text(
                    nextBtnText,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: activeColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}







