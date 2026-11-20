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

