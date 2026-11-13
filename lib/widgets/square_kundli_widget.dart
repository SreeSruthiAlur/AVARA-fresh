import 'package:avara_astrology_trial/services/birth_profile_manager.dart';
import 'package:avara_astrology_trial/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// 4x4 South Indian Janma Kundali chart layout.
/// Rasis run clockwise starting with Mesha (0) at top row, second column.
const List<List<int>> _southIndianLayout = [
  [11, 0, 1, 2],
  [10, -1, -1, 3],
  [9, -1, -1, 4],
  [8, 7, 6, 5],
];

const List<String> _teluguRasiNames = [
  'Mesha', 'Vrishabha', 'Mithuna', 'Karkataka',
  'Simha', 'Kanya', 'Tula', 'Vrischika',
  'Dhanassu', 'Makara', 'Kumbha', 'Meena',
];

/// Traditional square South Indian Vedic Astrology (Janma Kundali) widget
/// rendered inline in chat bubbles.
class SquareKundliWidget extends StatelessWidget {
  const SquareKundliWidget({
    super.key,
    this.chartJson,
  });

  /// Structured Vedic chart data from Swiss Ephemeris or BirthProfileManager.
  final Map<String, dynamic>? chartJson;

  Map<String, dynamic>? get _effectiveChart =>
      chartJson ?? BirthProfileManager.instance.cachedChart;

  @override
  Widget build(BuildContext context) {
    final effective = _effectiveChart;
    if (effective == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF0E1530),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white24),
        ),
        child: const Center(
          child: Text(
            'Birth chart data loading...',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
      );
    }

    final lagnaRasi = _getLagnaRasi(effective);
    final moonRasi = _getMoonRasi(effective);

    return Container(
      constraints: const BoxConstraints(maxWidth: 340),
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0F24),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF141B3B),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
              border: Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.auto_awesome, size: 13, color: Color(0xFFFFD700)),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Janma Kundali (South Indian)',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Nirayana Lahiri',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),

          // 4x4 Grid with centered AVARA watermark
          AspectRatio(
            aspectRatio: 1.0,
            child: Stack(
              children: [
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 1.0,
                    crossAxisSpacing: 0,
                    mainAxisSpacing: 0,
                  ),
                  itemCount: 16,
                  itemBuilder: (context, index) {
                    final row = index ~/ 4;
                    final col = index % 4;
                    final rasiIndex = _southIndianLayout[row][col];
                    return _buildCell(
                      rasiIndex: rasiIndex,
                      lagnaRasi: lagnaRasi,
                      moonRasi: moonRasi,
                      chart: effective,
                    );
                  },
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.wb_sunny_outlined, size: 20, color: const Color(0xFFFFD700).withValues(alpha: 0.45)),
                      const SizedBox(height: 3),
                      Text(
                        'AVARA',
                        style: TextStyle(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.7),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Legend footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF0E1530),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceAround,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildLegendItem(const Color(0xFFFFD700), 'As (Lagna)'),
                _buildLegendItem(AppColors.blue, 'Mo (Moon Rasi)'),
                _buildLegendItem(Colors.white70, 'R = Retrograde'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 9),
        ),
      ],
    );
  }

  Widget _buildCell({
    required int rasiIndex,
    required int lagnaRasi,
    required int moonRasi,
    required Map<String, dynamic> chart,
  }) {
    // 2x2 Empty Center Box
    if (rasiIndex == -1) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF090E20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 0.5),
        ),
      );
    }

    final isLagna = rasiIndex == lagnaRasi;
    final isMoon = rasiIndex == moonRasi;
    final planets = _getPlanetsForRasi(rasiIndex, chart);

    Color borderColor = Colors.white.withValues(alpha: 0.15);
    double borderWidth = 0.5;

    if (isLagna) {
      borderColor = const Color(0xFFFFD700);
      borderWidth = 1.8;
    } else if (isMoon) {
      borderColor = AppColors.blue;
      borderWidth = 1.8;
    }

    return Container(
      decoration: BoxDecoration(
        color: isLagna
            ? const Color(0x2BFFD700)
            : (isMoon ? const Color(0x242E71DB) : const Color(0xFF101736)),
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      padding: const EdgeInsets.all(2.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rasi title and number
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  _teluguRasiNames[rasiIndex],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: isLagna || isMoon ? FontWeight.bold : FontWeight.w600,
                    color: isLagna
                        ? const Color(0xFFFFD700)
                        : (isMoon ? const Color(0xFF8AB4F8) : Colors.white.withValues(alpha: 0.85)),
                  ),
                ),
              ),
              Text(
                '${rasiIndex + 1}',
                style: TextStyle(
                  fontSize: 7.5,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 1),
          // Planet chips
          Expanded(
            child: planets.isEmpty
                ? const SizedBox.shrink()
                : SingleChildScrollView(
                    child: Wrap(
                      spacing: 2,
                      runSpacing: 2,
                      children: planets.map(_buildPlanetChip).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanetChip(String abbr) {
    final isLagna = abbr == 'As';
    final isRetro = abbr.endsWith('R');

    final Color bg;
    final Color fg;

    if (isLagna) {
      bg = const Color(0xFFFFD700);
      fg = Colors.black;
    } else if (abbr.startsWith('Mo')) {
      bg = AppColors.blue;
      fg = Colors.white;
    } else {
      bg = Colors.white.withValues(alpha: 0.15);
      fg = isRetro ? const Color(0xFFFFC080) : Colors.white;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 0.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        abbr,
        style: TextStyle(
          fontSize: 7.5,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }

  int _getLagnaRasi(Map<String, dynamic> chart) {
    final lagna = chart['lagna'] as Map<String, dynamic>?;
    return (lagna?['rasi_index'] as num?)?.toInt() ?? -1;
  }

  int _getMoonRasi(Map<String, dynamic> chart) {
    final planets = chart['planets'] as Map<String, dynamic>?;
    final moon = planets?['Moon'] as Map<String, dynamic>?;
    return (moon?['rasi_index'] as num?)?.toInt() ?? -1;
  }

  List<String> _getPlanetsForRasi(int rasiIndex, Map<String, dynamic> chart) {
    // 1. Try pre-grouped rasi_to_planets map (both int and string keys)
    final rasiMap = chart['rasi_to_planets'];
    if (rasiMap is Map) {
      final list = rasiMap[rasiIndex] ?? rasiMap[rasiIndex.toString()];
      if (list is List && list.isNotEmpty) {
        return list.map((e) => e.toString()).toList();
      }
    }

    // 2. Direct planetary lookup from 'planets' and 'lagna'
    final planets = <String>[];
    final planetsMap = chart['planets'] as Map<String, dynamic>?;
    if (planetsMap != null) {
      for (final entry in planetsMap.entries) {
        final p = entry.value as Map<String, dynamic>?;
        if (p != null && (p['rasi_index'] as num?)?.toInt() == rasiIndex) {
          final abbr = p['abbreviation']?.toString() ?? entry.key.substring(0, 2);
          final isRetro = p['is_retrograde'] == true;
          planets.add(isRetro ? '${abbr}R' : abbr);
        }
      }
    }

    final lagna = chart['lagna'] as Map<String, dynamic>?;
    if (lagna != null && (lagna['rasi_index'] as num?)?.toInt() == rasiIndex) {
      if (!planets.contains('As')) {
        planets.add('As');
      }
    }

    return planets;
  }
}
