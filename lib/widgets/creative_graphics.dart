import 'dart:math' as math;
import 'package:avara_astrology_trial/services/age_profile_service.dart';
import 'package:avara_astrology_trial/services/app_language_service.dart';
import 'package:avara_astrology_trial/services/tts_service.dart';
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
// 7. Connected Pillars Nexus Widget (Interconnected Holistic Ecosystem)
// =============================================================================

/// Interactive interconnected pentagonal nexus showing how Astrology, Health,
/// Habits, Finance, and Insights are interconnected in daily life.
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

  static const List<Map<String, dynamic>> _pillars = [
    {
      'name': 'Astrology',
      'role': 'Circadian & Cosmic Clock',
      'color': Color(0xFF6C5CE7),
      'icon': Icons.nightlight_round,
      'synergy': 'Guides peak mental energy windows (10 AM - 1 PM) and lunar emotional cycles.',
      'connectsTo': 'Feeds optimal waking and nutrition timing directly into Health & Habits.',
    },
    {
      'name': 'Health',
      'role': 'Vital Body & Rest',
      'color': Color(0xFF00CEC9),
      'icon': Icons.favorite_rounded,
      'synergy': 'Provides physiological energy, deep sleep, and low stress cortisol.',
      'connectsTo': 'Gives physical willpower needed to maintain consistent daily Habits.',
    },
    {
      'name': 'Habits',
      'role': 'Daily Execution',
      'color': Color(0xFFE17055),
      'icon': Icons.track_changes_rounded,
      'synergy': 'Builds myelinated neural pathways through 25m focus & evening wind-downs.',
      'connectsTo': 'Eliminates impulsive stress-spending and protects Mindful Finance.',
    },
    {
      'name': 'Finance',
      'role': 'Mindful Wealth',
      'color': Color(0xFF00B894),
      'icon': Icons.account_balance_wallet_rounded,
      'synergy': 'Disciplined budgeting and 24-hr cooling pauses preserve freedom.',
      'connectsTo': 'Removes financial anxiety, allowing deep peace for Insights & Meditation.',
    },
    {
      'name': 'Insights',
      'role': 'Holistic Synthesis',
      'color': Color(0xFFE84393),
      'icon': Icons.auto_graph_rounded,
      'synergy': 'Synthesizes all 4 components into a unified 88% Holistic Life Index.',
      'connectsTo': 'Reveals cross-pillar patterns so you continuously grow better.',
    },
  ];

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

  @override
  Widget build(BuildContext context) {
    final activePillar = _pillars[_selectedPillar];
    final activeColor = activePillar['color'] as Color;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: activeColor.withValues(alpha: 0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: activeColor.withValues(alpha: 0.1),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
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
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: activeColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.hub_rounded, color: activeColor, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Unified Life Ecosystem',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.deepNavy,
                        ),
                      ),
                      Text(
                        'All 5 pillars connected as one life flow',
                        style: TextStyle(fontSize: 11, color: AppColors.secondaryText),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00B894).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
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
          const SizedBox(height: 18),

          // Nexus Interactive Canvas Graph
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
                          width: 68,
                          height: 68,
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
                                Text('AVARA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.8)),
                                Text('Nexus', style: TextStyle(color: Colors.white70, fontSize: 8.5)),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Surrounding 5 Interactive Pillar Buttons
                      ...List.generate(5, (index) {
                        final p = _pillars[index];
                        final pColor = p['color'] as Color;
                        final angle = (index * 72 - 90) * math.pi / 180;
                        const radius = 86.0;

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
                                  width: _selectedPillar == index ? 2.5 : 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: pColor.withValues(alpha: _selectedPillar == index ? 0.35 : 0.15),
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

          // Interconnection Detail Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: activeColor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: activeColor.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(activePillar['icon'] as IconData, size: 16, color: activeColor),
                        const SizedBox(width: 6),
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
                const SizedBox(height: 8),
                Text(
                  '⚡ How it functions: ${activePillar['synergy']}',
                  style: const TextStyle(fontSize: 11, color: AppColors.deepNavy, height: 1.3),
                ),
                const SizedBox(height: 4),
                Text(
                  '🔗 Interconnection: ${activePillar['connectsTo']}',
                  style: TextStyle(fontSize: 11, color: activeColor, fontWeight: FontWeight.w600, height: 1.3),
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
      listenable: AgeProfileService.instance,
      builder: (context, _) {
        final currentGroup = AgeProfileService.instance.ageGroup;
        final activeTheme = AgeProfileService.instance.activeTheme;

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
                title: '⚡ Youth (<22)',
                group: AgeGroup.youth,
                isActive: currentGroup == AgeGroup.youth,
                activeColor: const Color(0xFF6C5CE7),
              ),
              _buildSegment(
                context,
                title: '💼 Adult (22-45)',
                group: AgeGroup.adult,
                isActive: currentGroup == AgeGroup.adult,
                activeColor: const Color(0xFF1E3A8A),
              ),
              _buildSegment(
                context,
                title: '🌸 Senior (45+)',
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

  static const List<Map<String, dynamic>> _pillarMeta = [
    {'name': 'Astrology', 'icon': Icons.nightlight_round, 'color': Color(0xFF6C5CE7)},
    {'name': 'Health', 'icon': Icons.favorite_rounded, 'color': Color(0xFF00CEC9)},
    {'name': 'Habits', 'icon': Icons.track_changes_rounded, 'color': Color(0xFFE17055)},
    {'name': 'Finance', 'icon': Icons.account_balance_wallet_rounded, 'color': Color(0xFF00B894)},
    {'name': 'Insights', 'icon': Icons.auto_graph_rounded, 'color': Color(0xFFE84393)},
  ];

  List<Map<String, dynamic>> _getCrossConnections() {
    switch (currentPillarIndex) {
      case 0: // From Astrology
        return [
          {
            'targetIndex': 1,
            'title': 'Health & Body Vitals',
            'desc': 'Pitta-pacifying cooling nutrition & 10 PM sleep align with current lunar cycle.',
          },
          {
            'targetIndex': 2,
            'title': 'Daily Habits Execution',
            'desc': 'Surya Hora (Solar hour) favors your hardest 25m cognitive focus sprint.',
          },
          {
            'targetIndex': 3,
            'title': 'Mindful Wealth & Finance',
            'desc': 'Mercury aspect advises strategic budgeting over impulsive speculative investments.',
          },
          {
            'targetIndex': 4,
            'title': 'Holistic Insights',
            'desc': 'Vedic planetary archetypes provide compassionate context to your emotional patterns.',
          },
        ];

      case 1: // From Health
        return [
          {
            'targetIndex': 0,
            'title': 'Cosmic & Circadian Clock',
            'desc': 'Syncing sleep with lunar circadian rhythms deepens restorative REM by 34%.',
          },
          {
            'targetIndex': 2,
            'title': 'Neural Habit Streaks',
            'desc': 'High physiological energy gives the prefrontal willpower to sustain hard habit streaks.',
          },
          {
            'targetIndex': 3,
            'title': 'Impulse Spend Protection',
            'desc': 'Low cortisol stress levels reduce emotional retail and comfort spending by 42%.',
          },
          {
            'targetIndex': 4,
            'title': 'Holistic Insights',
            'desc': '7+ hours of quality sleep directly predicts your calmest, high-clarity days.',
          },
        ];

      case 2: // From Habits
        return [
          {
            'targetIndex': 0,
            'title': 'Astrological Energy Peak',
            'desc': 'Completing morning habits at 7:30 AM catches the peak solar prana window.',
          },
          {
            'targetIndex': 1,
            'title': 'Physical Health Vitality',
            'desc': 'Morning sunlight & hydration habit boosts dopamine and resets nighttime melatonin.',
          },
          {
            'targetIndex': 3,
            'title': 'Financial Freedom',
            'desc': 'The 24-hr shopping cooling pause habit has prevented ₹1,850 in impulse buys.',
          },
          {
            'targetIndex': 4,
            'title': 'Holistic Life Score',
            'desc': 'Active 6-day habit streaks correlate with a 91% life harmony rating.',
          },
        ];

      case 3: // From Finance
        return [
          {
            'targetIndex': 0,
            'title': 'Astrological Wisdom',
            'desc': 'Align long-term asset allocation with auspicious Jupiter transit phases.',
          },
          {
            'targetIndex': 1,
            'title': 'Preventative Health',
            'desc': 'Removing financial uncertainty lowers chronic cardiovascular stress and anxiety.',
          },
          {
            'targetIndex': 2,
            'title': 'Daily Habit Streaks',
            'desc': 'Daily 2-minute expense logging habit builds lifelong wealth discipline.',
          },
          {
            'targetIndex': 4,
            'title': 'Holistic Reflections',
            'desc': 'Financial peace of mind contributes 30% to your overall weekly life satisfaction.',
          },
        ];

      case 4: // From Insights
      default:
        return [
          {
            'targetIndex': 0,
            'title': 'Astrology Grounding',
            'desc': 'Combines planetary transits with your actual journaled mood shifts.',
          },
          {
            'targetIndex': 1,
            'title': 'Health Recovery Trends',
            'desc': 'Visualizes the link between sleep recovery and weekly creative productivity.',
          },
          {
            'targetIndex': 2,
            'title': 'Habit Neural Growth',
            'desc': 'Identifies micro-friction points so your 1% habit improvements stick easily.',
          },
          {
            'targetIndex': 3,
            'title': 'Budgeting Balance',
            'desc': 'Tracks your emotional ROI and money saved from mindful habit choices.',
          },
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final activePillar = _pillarMeta[currentPillarIndex];
    final activeColor = activePillar['color'] as Color;
    final connections = _getCrossConnections();

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
              Row(
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🔗 How ${activePillar['name']} Connects',
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.deepNavy,
                        ),
                      ),
                      const Text(
                        'Part of your 5-pillar holistic ecosystem',
                        style: TextStyle(fontSize: 11, color: AppColors.secondaryText),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF00B894).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Connected',
                  style: TextStyle(
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
            final targetMeta = _pillarMeta[targetIdx];
            final targetColor = targetMeta['color'] as Color;

            return Container(
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
                            if (onNavigateToPillar != null)
                              GestureDetector(
                                onTap: () => onNavigateToPillar!(targetIdx),
                                child: Row(
                                  children: [
                                    Text(
                                      'Open',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        color: targetColor,
                                      ),
                                    ),
                                    Icon(Icons.chevron_right, size: 13, color: targetColor),
                                  ],
                                ),
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

class CyberGlowHeroWidget extends StatelessWidget {
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
            'Ready to Level Up, $userName? 🚀',
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
                onTap: onOpenFocus,
              ),
              const SizedBox(width: 8),
              _buildPod(
                title: 'Exam Calm',
                sub: 'Breathe',
                icon: Icons.air_rounded,
                color: const Color(0xFF74B9FF),
                onTap: onOpenBreathing,
              ),
              const SizedBox(width: 8),
              _buildPod(
                title: 'Talents',
                sub: 'Careers',
                icon: Icons.rocket_launch_rounded,
                color: const Color(0xFFA29BFE),
                onTap: onOpenCareer,
              ),
              const SizedBox(width: 8),
              _buildPod(
                title: 'Dopamine',
                sub: 'Detox',
                icon: Icons.phonelink_erase_rounded,
                color: const Color(0xFF55EFC4),
                onTap: onOpenDetox,
              ),
            ],
          ),
        ],
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
  late final AnimationController _rippleController;
  String _translationChoice = 'auto'; // 'auto', 'en', 'te', 'none'

  static const List<Map<String, String>> _mantras = [
    {
      'id': 'asato_ma',
      'nameEn': 'Pavamana Shanti',
      'nameTe': 'పవమాన శాంతి',
      'nameTanglish': 'Pavamana Shanti',
      'titleEn': 'Pavamana Shanti Mantra (Asato Ma Sadgamaya)',
      'titleTe': 'పవమాన శాంతి మంత్రం (Asato Ma Sadgamaya)',
      'titleTanglish': 'Pavamana Shanti Mantram (Asato Ma Sadgamaya)',
      'sourceEn': 'Brihadaranyaka Upanishad 1.3.28',
      'sourceTe': 'బృహదారణ్యకోపనిషత్ 1.3.28',
      'sourceTanglish': 'Brihadaranyaka Upanishad 1.3.28',
      'devanagari': 'ॐ असतो मा सद्गमय ।\nतमसो मा ज्योतिर्गमय ।\nमृत्योर्मा अमृतं गमय ॥\nॐ शान्तिः शान्तिः शान्तिः ॥',
      'transliteration': 'Om Asato Maa Sadgamaya |\nTamaso Maa Jyotirgamaya |\nMrityor Maa Amritam Gamaya ||\nOm Shantih Shantih Shantih ||',
      'teluguScript': 'ఓం అసతో మా సద్గమయ ।\nతమసో మా జ్యోతిర్గమయ ।\nమృత్యోర్మా అమృతం గమయ ॥\nఓం శాంతిః శాంతిః శాంతిః ॥',
      'meaningEn': 'Lead me from falsehood to eternal truth, from spiritual darkness to the supreme light of wisdom, and from mortality into immortality. Om peace, peace, peace.',
      'meaningTe': 'నన్ను అసత్యము నుండి సత్యము వైపుకు, అజ్ఞానపు చీకటి నుండి దివ్యమైన జ్ఞానపు వెలుగు వైపుకు, మృత్యు భయం నుండి మోక్షము వైపుకు నడిపించు పరమాత్మా.',
      'meaningTanglish': 'Nannu asathyam nundi sathyam vaipuku, cheekati nundi divyamaina velugu vaipuku, mrityu bhayam nundi moksham vaipuku nadipinchu Paramatma.',
      'benefitEn': 'Dispels anxiety and fear, installs deep meditative composure, and bestows divine protective aura.',
      'benefitTe': 'భయ నివారణ, మానసిక ప్రశాంతత మరియు దివ్య రక్షణ చేకూరుతాయి.',
      'benefitTanglish': 'Bhaya nivarana, manasika prasanthata mariyu divya rakshana labhisthundi.',
      'sanskritSpeech': 'Om Asato maa sad gamaya, Tamaso maa jyotir gamaya, Mrityor maa amritam gamaya, Om Shantih Shantih Shantih.',
    },
    {
      'id': 'gayatri',
      'nameEn': 'Gayatri Mantra',
      'nameTe': 'గాయత్రీ మంత్రం',
      'nameTanglish': 'Gayatri Mantram',
      'titleEn': 'Gayatri Maha Mantra (Rigveda 3.62.10)',
      'titleTe': 'గాయత్రీ మహా మంత్రం (ఋగ్వేదం 3.62.10)',
      'titleTanglish': 'Gayatri Maha Mantram (Rigveda 3.62.10)',
      'sourceEn': 'Rigveda 3.62.10 • Meditative Chanting',
      'sourceTe': 'ఋగ్వేదం 3.62.10 • ధ్యాన పఠనం (Meditative India)',
      'sourceTanglish': 'Rigveda 3.62.10 • Dhyana Pathanam',
      'devanagari': 'ॐ भूर्भुवः स्वः ।\nतत्सवितुर्वरेण्यं भर्गो देवस्य धीमहि ।\nधियो यो नः प्रचोदयात् ॥',
      'transliteration': 'Om Bhur Bhuvah Svah |\nTat Savitur Varenyam Bhargo Devasya Dhimahi |\nDhiyo Yo Nah Prachodayat ||',
      'teluguScript': 'ఓం భూర్భువః స్వః ।\nతత్సవితుర్వరేణ్యం భర్గో దేవస్య ధీమహి ।\nధియో యో నః ప్రచోదయాత్ ॥',
      'meaningEn': 'We meditate upon the transcendental radiance of the divine Sun (Savitr). May that sacred celestial light stimulate and guide our intellect onto the righteous path of truth.',
      'meaningTe': 'ముల్లోకాలను ప్రకాశింపజేసే సవితృ సూర్య భగవానుని పరమ దివ్య తేజాన్ని మేము ధ్యానిస్తున్నాము. ఆయన మా బుద్ధిని సత్య జ్ఞాన మార్గంలో నడిపించుగాక.',
      'meaningTanglish': 'Mullokalani prakashimpajese Savitru Surya Bhagavanuni divya tejaanni dhyanisthunnamu. Ayana maa buddhini sanmargamlo nadipinchugaaka.',
      'benefitEn': 'Purifies consciousness, sharpens intellect, dissolves negative mental impressions, and fosters longevity.',
      'benefitTe': 'సకల పాప వినాశనం, బుద్ధి వికాసం, ఆయురారోగ్యాలు మరియు ప్రాణ శక్తి వృద్ధి.',
      'benefitTanglish': 'Sakala papa nashanam, buddhi vikasam mariyu ayur-arogyalu labhisthayi.',
      'sanskritSpeech': 'Om Bhur Bhuvah Svah, Tat Savitur Varenyam, Bhargo Devasya Dhimahi, Dhiyo Yo Nah Prachodayat.',
    },
    {
      'id': 'mrityunjaya',
      'nameEn': 'Maha Mrityunjaya',
      'nameTe': 'మహా మృత్యుంజయ',
      'nameTanglish': 'Maha Mrityunjaya',
      'titleEn': 'Maha Mrityunjaya Mantra (Rigveda 7.59.12)',
      'titleTe': 'మహా మృత్యుంజయ మంత్రం (ఋగ్వేదం 7.59.12)',
      'titleTanglish': 'Maha Mrityunjaya Mantram (Rigveda 7.59.12)',
      'sourceEn': 'Rigveda 7.59.12 • Sage Markandeya',
      'sourceTe': 'ఋగ్వేదం 7.59.12 • మార్కండేయ మహర్షి',
      'sourceTanglish': 'Rigveda 7.59.12 • Markandeya Maharshi',
      'devanagari': 'ॐ त्र्यम्बकं यजामहे सुगन्धिं पुष्टिवर्धनम् ।\nउर्वारुकमिव बन्धनान् मृत्योर्मुक्षीय माऽमृतात् ॥',
      'transliteration': 'Om Tryambakam Yajaamahe Sugandhim Pushtivardhanam |\nUrvaarukamiva Bandhanaan Mrityor Muksheeya Maamritaat ||',
      'teluguScript': 'ఓం త్ర్యంబకం యజామహే సుగంధిం పుష్టివర్ధనమ్ ।\nఉర్వారుకమివ బంధనాన్ మృత్యోర్ముక్షీయ మామృతాత్ ॥',
      'meaningEn': 'We worship the fragrant, three-eyed Lord Shiva who nourishes and sustains all beings. As a ripe fruit naturally frees itself from the vine, liberate us from mortal fears and spiritual bondages into immortality.',
      'meaningTe': 'సుగంధభరితుడై, సకల ప్రాణులను పోషించే ముక్కంటి పరమేశ్వరుని మేము పూజిస్తున్నాము. పండిన దోసపండు తొడిమ నుండి సునాయాసంగా రాలినట్లు, మమ్ములను మృత్యు భయాల నుండి విముక్తులను చేయుము.',
      'meaningTanglish': 'Sugandha bharitudai, sakala pranulanu poshinchu Mukkanti Parameshwaruni poojisthunnamu. Mrityu bhayam nundi vimukthulanu cheyumu.',
      'benefitEn': 'Grants longevity, relief from ailments, liberation from mortal fears, vitality, and spiritual healing.',
      'benefitTe': 'దీర్ఘాయుష్షు, రోగ నివారణ, అకాల మృత్యు భయ నాశనం మరియు సంపూర్ణ స్వస్థత.',
      'benefitTanglish': 'Deerghayushshu, roga nivarana mariyu arogya siddhi labhisthayi.',
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
    TtsService.instance.addListener(_handleTtsChange);
  }

  void _handleTtsChange() {
    if (mounted) {
      final isSpeaking = TtsService.instance.isSpeaking;
      if (isSpeaking != _isPlaying) {
        setState(() {
          _isPlaying = isSpeaking;
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
    TtsService.instance.removeListener(_handleTtsChange);
    _rippleController.dispose();
    super.dispose();
  }

  void _toggleChant() {
    if (_isPlaying) {
      TtsService.instance.stop();
      setState(() => _isPlaying = false);
      _rippleController.stop();
      _rippleController.reset();
    } else {
      final m = _mantras[_selectedMantraIndex];
      TtsService.instance.playSacredChant(m['sanskritSpeech']!);
      setState(() => _isPlaying = true);
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

  Widget _buildTranslationChoiceChip(String label, String value, String activeValue) {
    final isSelected = activeValue == value;
    return GestureDetector(
      onTap: () => setState(() => _translationChoice = value),
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
    final isTe = currentLang == AppLanguage.telugu;
    final isTanglish = currentLang == AppLanguage.tanglish;

    final m = _mantras[_selectedMantraIndex];

    final effectiveTranslation = _translationChoice == 'auto'
        ? (isTe ? 'te' : 'en')
        : _translationChoice;

    final headerSubtitle = isTe
        ? 'వేద శాంతి & జీవన సౌభాగ్యం'
        : (isTanglish ? 'Vedic Shanti & Jeevana Soubhagyam' : 'Vedic Peace & Vitality');

    final greeting = isTe
        ? 'నమస్తే, ${widget.userName} గారు 🙏'
        : (isTanglish ? 'Namaste, ${widget.userName} garu 🙏' : 'Namaste, ${widget.userName} 🙏');

    final badgeText = isTe
        ? '🌸 45+ సౌభాగ్యం'
        : (isTanglish ? '🌸 45+ Serenity' : '🌸 45+ Grace & Serenity');

    final mantraTitle = isTe
        ? m['titleTe']!
        : (isTanglish ? m['titleTanglish']! : m['titleEn']!);

    final mantraSource = isTe
        ? m['sourceTe']!
        : (isTanglish ? m['sourceTanglish']! : m['sourceEn']!);

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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDE68A),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFD97706), width: 1.5),
                    ),
                    child: const Icon(Icons.spa_rounded, color: Color(0xFFB45309), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Column(
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
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF78350F),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  // Quick Language Toggle
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFD97706), width: 1.2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () => AppLanguageService.instance.setLanguage(AppLanguage.english),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: currentLang == AppLanguage.english ? const Color(0xFFB45309) : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'EN',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: currentLang == AppLanguage.english ? Colors.white : const Color(0xFF78350F),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 2),
                        InkWell(
                          onTap: () => AppLanguageService.instance.setLanguage(AppLanguage.telugu),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: currentLang == AppLanguage.telugu ? const Color(0xFFB45309) : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'తెలుగు',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: currentLang == AppLanguage.telugu ? Colors.white : const Color(0xFF78350F),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFD97706)),
                    ),
                    child: Text(
                      badgeText,
                      style: const TextStyle(
                        fontSize: 11,
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
                final mantraLabel = isTe
                    ? _mantras[idx]['nameTe']!
                    : (isTanglish ? _mantras[idx]['nameTanglish']! : _mantras[idx]['nameEn']!);

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
                  child: Row(
                    children: [
                      const Icon(Icons.translate_rounded, size: 15, color: Color(0xFF92400E)),
                      const SizedBox(width: 6),
                      Text(
                        isTe ? 'అనువాదం:' : 'Translation:',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF92400E),
                        ),
                      ),
                      const Spacer(),
                      _buildTranslationChoiceChip('English', 'en', effectiveTranslation),
                      const SizedBox(width: 4),
                      _buildTranslationChoiceChip('తెలుగు', 'te', effectiveTranslation),
                      const SizedBox(width: 4),
                      _buildTranslationChoiceChip(isTe ? 'కేవలం సంస్కృతం' : 'None', 'none', effectiveTranslation),
                    ],
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
                  // English Meaning
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
                  // Telugu Meaning
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
                ] else ...[
                  // Pure Sanskrit Selected
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7).withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isTe
                          ? 'సంస్కృత మూల శ్లోకం మాత్రమే ప్రదర్శించబడుతోంది. అనువాదం కోసం పైన "English" లేదా "తెలుగు" ఎంచుకోండి.'
                          : 'Pure Vedic chanting mode active. Select English or Telugu above to view translations.',
                      style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFF78350F)),
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // Animated Soundwave Visualizer (Pulsing when chanting)
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
                              isTe
                                  ? '432Hz వేద నాదం మారుమ్రోగుతోంది...'
                                  : 'Resonating with authentic 432Hz Vedic resonance...',
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

                // Audio Chanting Button (Pure Indian Sanskrit Tone)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _toggleChant,
                    icon: Icon(
                      _isPlaying ? Icons.stop_circle_rounded : Icons.volume_up_rounded,
                      size: 24,
                      color: Colors.white,
                    ),
                    label: Text(
                      _isPlaying
                          ? (isTe ? 'పఠనం ఆపండి (Stop Chanting)' : 'Stop Chanting')
                          : (isTe
                              ? 'పవిత్ర సంస్కృత పఠనం వినండి (Pure Sanskrit Tone)'
                              : 'Listen to Sacred Sanskrit Chanting (Pure Tone)'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isPlaying ? const Color(0xFFDC2626) : const Color(0xFFB45309),
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 4 Senior Health & Peace Actions (Large touch targets: minimum 60px)
          Text(
            isTe
                ? 'దినచర్య & ఆయుర్వేద ఆరోగ్య రక్షణ (Daily Senior Care):'
                : 'Daily Dinacharya & Ayurvedic Wellness Care:',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF78350F),
            ),
          ),
          const SizedBox(height: 10),

          _buildSeniorActionTile(
            title: isTe
                ? 'గోరువెచ్చని నీరు & కీళ్ల ఆరోగ్యం (Joint & Gut Care)'
                : 'Warm Water & Joint Care (Vata Balance)',
            desc: isTe
                ? 'వాత దోషాన్ని శాంతింపజేయడానికి ఉదయం శొంఠి మరియు గోరువెచ్చని నీరు తీసుకోండి.'
                : 'Drink warm water with dry ginger in the morning to pacify Vata and nourish joint vitality.',
            icon: Icons.health_and_safety_rounded,
            color: const Color(0xFF047857),
            onTap: widget.onOpenAyurveda,
          ),
          const SizedBox(height: 10),
          _buildSeniorActionTile(
            title: isTe
                ? 'ప్రశాంత ఉదయపు నడక & ప్రాణాయామం (Morning Walk)'
                : 'Peaceful Morning Walk & Pranayama (Sunrise Vitality)',
            desc: isTe
                ? 'బ్రాహ్మీ ముహూర్తంలో 15 నిమిషాల సున్నితమైన నడక మీ గుండెకు, ఊపిరితిత్తులకు అమృతం.'
                : 'A gentle 15-minute walk during Brahma Muhurtha revitalizes circulation, lungs, and joints.',
            icon: Icons.directions_walk_rounded,
            color: const Color(0xFFB45309),
            onTap: widget.onOpenWalk,
          ),
          const SizedBox(height: 10),
          _buildSeniorActionTile(
            title: isTe
                ? 'పిల్లల క్షేమం & వేద పరిహారాలు (Family Blessings)'
                : 'Family Blessings & Vedic Remedies',
            desc: isTe
                ? 'పిల్లల, మనవళ్ల భవిష్యత్తు కోసం శాంతి మంత్రాలు మరియు గురు గ్రహ పరిహారాలు చూడండి.'
                : 'Peace mantras and Jupiter remedies dedicated to the long-term flourishing of children & grandchildren.',
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
    extends State<SacredJapaMalaCounterWidget> {
  int _count = 0;
  int _completedMalas = 0;
  static const int _target = 108;
  int _selectedMantraIdx = 0;

  static const List<Map<String, String>> _mantras = [
    {
      'nameEn': 'Gayatri Maha Mantra',
      'nameTe': 'గాయత్రీ మహా మంత్రం',
      'sanskrit': 'Om Bhur Bhuvah Svah, Tat Savitur Varenyam, Bhargo Devasya Dhimahi, Dhiyo Yo Nah Prachodayat.',
      'meaningEn': 'May the divine light of Savitr illuminate our intellect onto the righteous path.',
      'meaningTe': 'సవితృ సూర్య భగవానుని తేజస్సు మా బుద్ధిని సన్మార్గంలో నడిపించుగాక.',
    },
    {
      'nameEn': 'Om Namah Shivaya (Panchakshari)',
      'nameTe': 'ఓం నమః శివాయ (పంచాక్షరీ)',
      'sanskrit': 'Om Namah Shivaaya, Om Namah Shivaaya, Om Namah Shivaaya.',
      'meaningEn': 'Salutations to the auspicious Lord Shiva.',
      'meaningTe': 'మంగళకరుడైన పరమశివునికి ప్రణామాలు.',
    },
    {
      'nameEn': 'Maha Mrityunjaya Mantra',
      'nameTe': 'మహా మృత్యుంజయ మంత్రం',
      'sanskrit': 'Om Tryambakam Yajaamahe Sugandhim Pushtivardhanam, Urvaarukamiva Bandhanaan Mrityor Muksheeya Maamritaat.',
      'meaningEn': 'May Lord Shiva grant longevity, healing and complete health.',
      'meaningTe': 'పరమశివుని కటాక్షంతో దీర్ఘాయుష్షు మరియు సంపూర్ణ ఆరోగ్యం కలుగుగాక.',
    },
    {
      'nameEn': 'Om Namo Narayanaya (Ashtakshari)',
      'nameTe': 'ఓం నమో నారాయణాయ (అష్టాక్షరీ)',
      'sanskrit': 'Om Namo Naaraayanaaya, Om Namo Naaraayanaaya.',
      'meaningEn': 'Salutations to Lord Vishnu, the protector and preserver of all realms.',
      'meaningTe': 'జగద్రక్షకుడైన శ్రీమహావిష్ణువునకు ప్రణామాలు.',
    },
  ];

  void _increment() {
    TtsService.instance.playTempleBell();
    setState(() {
      if (_count < _target) {
        _count++;
        if (_count == _target) {
          _completedMalas++;
          final currentLang = AppLanguageService.instance.currentLanguage;
          final isTe = currentLang == AppLanguage.telugu;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.stars_rounded, color: Colors.amberAccent, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isTe
                          ? '🎉 108 మణుల జపం పూర్తయింది! (${_completedMalas}వ మాల సంపూర్ణం) శాంతి శాంతి శాంతిః 🙏'
                          : '🎉 108 Sacred Beads Japa Completed! (${_completedMalas} malas complete) Om Shanti Shanti Shanti 🙏',
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
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentLang = AppLanguageService.instance.currentLanguage;
    final isTe = currentLang == AppLanguage.telugu;

    final double progress = _count / _target;
    final m = _mantras[_selectedMantraIdx];
    final mantraName = isTe ? m['nameTe']! : m['nameEn']!;
    final mantraMeaning = isTe ? m['meaningTe']! : m['meaningEn']!;

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
          // Header with Mala Count
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDE68A),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFD97706)),
                    ),
                    child: const Icon(Icons.circle_outlined, color: Color(0xFFB45309), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isTe ? '108 మణుల వేద జపమాల' : '108 Sacred Beads Japa Mala',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF78350F),
                        ),
                      ),
                      Text(
                        isTe
                            ? 'పూర్తయిన మాలలు: $_completedMalas'
                            : 'Completed Malas: $_completedMalas',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF92400E),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (_count > 0)
                TextButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.refresh_rounded, size: 16, color: Color(0xFFB45309)),
                  label: Text(
                    isTe ? 'రీసెట్' : 'Reset',
                    style: const TextStyle(fontSize: 12, color: Color(0xFFB45309)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Mantra Selector Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_mantras.length, (i) {
                final isSel = i == _selectedMantraIdx;
                final item = _mantras[i];
                final label = isTe ? item['nameTe']! : item['nameEn']!;

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
                      if (val) setState(() => _selectedMantraIdx = i);
                    },
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 14),

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
                Text(
                  mantraName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF92400E),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  m['sanskrit']!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF78350F),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  mantraMeaning,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF92400E),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Central Tap Rosary Bead Disc with Brass Bell Sound
          Center(
            child: GestureDetector(
              onTap: _increment,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 160,
                    height: 160,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 12,
                      backgroundColor: const Color(0xFFFDE68A),
                      valueColor: const AlwaysStoppedAnimation(Color(0xFFB45309)),
                    ),
                  ),
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      gradient: const RadialGradient(
                        colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFD97706), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFB45309).withValues(alpha: 0.25),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('📿', style: TextStyle(fontSize: 20)),
                        Text(
                          '$_count',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF78350F),
                            height: 1.1,
                          ),
                        ),
                        Text(
                          isTe ? '/ 108 మణులు' : '/ 108 Beads',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF92400E),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.touch_app_rounded, size: 12, color: Color(0xFFB45309)),
                            SizedBox(width: 2),
                            Text(
                              'BELL TAP',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFB45309),
                                letterSpacing: 0.8,
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
          ),
          const SizedBox(height: 14),

          Center(
            child: Text(
              _count == _target
                  ? (isTe
                      ? '🎉 108 మణుల జపం పూర్తయింది! శాంతి శాంతి శాంతిః 🙏'
                      : '🎉 108 Beads Japa Completed! Om Shanti Shanti Shanti 🙏')
                  : (isTe
                      ? 'ఒక్కొక్క మణిని జపిస్తూ స్క్రీన్‌పై తాకండి (తాకినప్పుడు వేద గంట మ్రోగుతుంది 🔔)'
                      : 'Tap the screen as you chant each bead (a sacred bell rings on each tap 🔔)'),
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

// =============================================================================
// 15. Senior Ayurvedic Tridosha Vitality Wheel
// =============================================================================

class AyurvedicTridoshaWheel extends StatelessWidget {
  const AyurvedicTridoshaWheel({super.key});

  @override
  Widget build(BuildContext context) {
    final currentLang = AppLanguageService.instance.currentLanguage;
    final isTe = currentLang == AppLanguage.telugu;

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
              Row(
                children: [
                  const Icon(Icons.eco_rounded, color: Color(0xFF047857), size: 22),
                  const SizedBox(width: 8),
                  Text(
                    isTe
                        ? 'ఆయుర్వేద త్రిదోష సమతుల్యత (Tridosha Balance)'
                        : 'Ayurvedic Tridosha Vitality Balance',
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.deepNavy,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 3 Dosha Bars
          _buildDoshaRow(
            dosha: isTe ? 'వాతం (Vata - Air & Space)' : 'Vata (Air & Space - Nervous System)',
            pct: 0.35,
            color: const Color(0xFF3B82F6),
            balance: isTe ? 'శాంతంగా ఉంది (Balanced)' : 'Balanced & Calm',
            tip: isTe
                ? 'కీళ్లకు నువ్వుల నూనె మర్దన & గోరువెచ్చని ఆహారం మేలు చేస్తుంది.'
                : 'Warm sesame oil joint massage & warm nourishing meals pacify Vata.',
          ),
          const SizedBox(height: 10),
          _buildDoshaRow(
            dosha: isTe ? 'పిత్తం (Pitta - Fire & Energy)' : 'Pitta (Fire & Energy - Metabolism)',
            pct: 0.45,
            color: const Color(0xFFF59E0B),
            balance: isTe ? 'మధ్యస్థం (Optimal)' : 'Optimal & Vibrant',
            tip: isTe
                ? 'మధ్యాహ్నం నెయ్యి మరియు దానిమ్మ రసంతో అగ్నిని చల్లబరచండి.'
                : 'Nourish digestive fire with cow ghee, sweet fruits, and pomegranate juice.',
          ),
          const SizedBox(height: 10),
          _buildDoshaRow(
            dosha: isTe ? 'కఫం (Kapha - Earth & Water)' : 'Kapha (Earth & Water - Immunity)',
            pct: 0.20,
            color: const Color(0xFF10B981),
            balance: isTe ? 'స్థిరంగా ఉంది (Steady)' : 'Steady & Grounded',
            tip: isTe
                ? 'ఉదయం నడకతో శ్వాసకోశాలను ఉత్తేజపరచండి.'
                : 'Energize respiratory vitality with an active sunrise morning walk.',
          ),
        ],
      ),
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






