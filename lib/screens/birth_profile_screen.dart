import 'dart:convert';
import 'dart:typed_data';

import 'package:avara_astrology_trial/services/avara_api_client.dart';
import 'package:avara_astrology_trial/theme/app_colors.dart';
import 'package:avara_astrology_trial/screens/astrology_chat_screen.dart';
import 'package:avara_astrology_trial/telugu_kundali.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:sweph/sweph.dart' show AssetLoader;

/// Bundled Swiss Ephemeris files (packaged with the sweph plugin) used to run
/// the calculations on Flutter without external ephemeris downloads.
const List<String> _kEpheAssets = [
  'packages/sweph/assets/ephe/sepl_18.se1',
  'packages/sweph/assets/ephe/semo_18.se1',
  'packages/sweph/assets/ephe/seas_18.se1',
  'packages/sweph/assets/ephe/sefstars.txt',
  'packages/sweph/assets/ephe/seleapsec.txt',
  'packages/sweph/assets/ephe/seasnam.txt',
  'packages/sweph/assets/ephe/seorbel.txt',
];

/// South Indian chart layout: each cell is a Rasi index (0-11) or -1 (the empty
/// 2x2 center). Rasis run clockwise from the top-middle (Mesha = 0).
const List<List<int>> _southIndianLayout = [
  [11, 0, 1, 2],
  [10, -1, -1, 3],
  [9, -1, -1, 4],
  [8, 7, 6, 5],
];

const List<String> _teluguRasiNames = [
  'Mesha', 'Vrishabha', 'Mithuna', 'Karkataka', 'Simha', 'Kanya',
  'Tula', 'Vrischika', 'Dhanassu', 'Makara', 'Kumbha', 'Meena',
];

/// Common timezone offsets with human-readable labels. Defaults to IST (+5:30)
/// since this is a Telugu (Indian) astrology tool.
const List<MapEntry<double, String>> _tzOptions = [
  MapEntry(5.5, 'UTC +5:30 (IST)'),
  MapEntry(5.75, 'UTC +5:45 (Nepal)'),
  MapEntry(5.0, 'UTC +5:00 (PKT)'),
  MapEntry(4.0, 'UTC +4:00 (GST)'),
  MapEntry(3.5, 'UTC +3:30 (Iran)'),
  MapEntry(3.0, 'UTC +3:00 (MSK)'),
  MapEntry(2.0, 'UTC +2:00 (EET)'),
  MapEntry(1.0, 'UTC +1:00 (CET)'),
  MapEntry(0.0, 'UTC +0:00 (GMT)'),
  MapEntry(6.0, 'UTC +6:00 (BST)'),
  MapEntry(6.5, 'UTC +6:30 (Myanmar)'),
  MapEntry(7.0, 'UTC +7:00 (ICT)'),
  MapEntry(8.0, 'UTC +8:00 (CST)'),
  MapEntry(9.0, 'UTC +9:00 (JST)'),
  MapEntry(9.5, 'UTC +9:30 (ACST)'),
  MapEntry(10.0, 'UTC +10:00 (AEST)'),
  MapEntry(-3.0, 'UTC -3:00 (BRT)'),
  MapEntry(-4.0, 'UTC -4:00 (AST)'),
  MapEntry(-5.0, 'UTC -5:00 (EST)'),
  MapEntry(-6.0, 'UTC -6:00 (CST US)'),
  MapEntry(-7.0, 'UTC -7:00 (MST)'),
  MapEntry(-8.0, 'UTC -8:00 (PST)'),
  MapEntry(-9.0, 'UTC -9:00 (AKST)'),
  MapEntry(-10.0, 'UTC -10:00 (HST)'),
];

/// Loads the bundled ephe assets via Flutter's [rootBundle] for sweph.
class RootBundleAssetLoader implements AssetLoader {
  @override
  Future<Uint8List> load(String assetPath) async {
    final byteData = await rootBundle.load(assetPath);
    return byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
  }
}

/// AVARA Birth Profile & Astrology Evidence screen.
///
/// Collects birth details (date, local time, timezone, place), geocodes the
/// place, converts local time to UTC, runs the [TeluguKundaliCalculator] and
/// displays the resulting Telugu Rasi / Nakshatra evidence plus a 4x4 South
/// Indian chart.
class BirthProfileScreen extends StatefulWidget {
  const BirthProfileScreen({super.key});

  @override
  State<BirthProfileScreen> createState() => _BirthProfileScreenState();
}

class _BirthProfileScreenState extends State<BirthProfileScreen> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  double _timezoneOffset = 5.5; // default IST
  final TextEditingController _placeController = TextEditingController();
  int _ayanamsaChoice = 1; // 1: Lahiri, 2: Raman, 3: KP

  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _kundali;
  String? _resolvedPlace;

  @override
  void dispose() {
    _placeController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Input pickers
  // ---------------------------------------------------------------------------

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000, 6, 15),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 12, minute: 0),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  // ---------------------------------------------------------------------------
  // Generate: geocode -> UTC conversion -> kundali calculation
  // ---------------------------------------------------------------------------

  Future<void> _generateChart() async {
    final hasInputs = _selectedDate != null &&
        _selectedTime != null &&
        _placeController.text.trim().isNotEmpty;
    if (!hasInputs) {
      setState(() {
        _errorMessage = 'Please enter date, time, and place of birth.';
        _kundali = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Geocode the place of birth using Nominatim (OpenStreetMap).
      final place = _placeController.text.trim();
      final encoded = Uri.encodeComponent(place);
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$encoded&format=json&limit=1',
      );
      final response = await http.get(url, headers: {
        'User-Agent': 'AVARA-Astrology/1.0 (contact@avara.example)',
      });
      if (response.statusCode != 200) {
        throw Exception('Geocoding failed (HTTP ${response.statusCode}).');
      }
      final results = json.decode(response.body) as List;
      if (results.isEmpty) {
        throw Exception('Could not find coordinates for "$place".');
      }
      final lat = double.parse(results[0]['lat'].toString());
      final lon = double.parse(results[0]['lon'].toString());
      final displayName = results[0]['display_name']?.toString() ?? place;

      // 2. Convert local time of birth to UTC (handles day rollover).
      int year = _selectedDate!.year;
      int month = _selectedDate!.month;
      int day = _selectedDate!.day;
      final localMinutes = _selectedTime!.hour * 60 + _selectedTime!.minute;
      final offsetMinutes = (_timezoneOffset * 60).round();
      int utcMinutes = localMinutes - offsetMinutes;
      int dayDelta = 0;
      while (utcMinutes < 0) {
        utcMinutes += 24 * 60;
        dayDelta -= 1;
      }
      while (utcMinutes >= 24 * 60) {
        utcMinutes -= 24 * 60;
        dayDelta += 1;
      }
      final utcHour = utcMinutes ~/ 60;
      final utcMinute = utcMinutes % 60;
      final hourDecimal = utcHour + utcMinute / 60.0;
      if (dayDelta != 0) {
        final adjusted =
            DateTime.utc(year, month, day).add(Duration(days: dayDelta));
        year = adjusted.year;
        month = adjusted.month;
        day = adjusted.day;
      }

      // 3. Run the kundali calculation, loading bundled ephemeris files.
      final calculator = TeluguKundaliCalculator(
        ayanamsa: _ayanamsaChoice,
        epheAssets: _kEpheAssets,
        assetLoader: RootBundleAssetLoader(),
        epheFilesPath: 'ephe_files',
      );
      final result = await calculator.calculateFullKundali(
        year,
        month,
        day,
        hourDecimal,
        lat,
        lon,
      );

      setState(() {
        _kundali = result;
        _resolvedPlace = displayName;
      });

      // Persist birth details to the backend silently — errors are swallowed
      // so they never interrupt the user's astrology flow.
      _persistBirthDetails(displayName);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _kundali = null;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Background persist — does not block or surface errors to the user
  // ---------------------------------------------------------------------------

  /// Saves the confirmed birth details to the user profile on the backend.
  ///
  /// Called only after a successful kundali generation so the data is
  /// guaranteed to be valid. Network or auth errors are silently caught so
  /// they never interrupt the astrology flow.
  Future<void> _persistBirthDetails(String resolvedPlace) async {
    if (_selectedDate == null || _selectedTime == null) return;

    final birthDateIso =
        '${_selectedDate!.year}-'
        '${_selectedDate!.month.toString().padLeft(2, '0')}-'
        '${_selectedDate!.day.toString().padLeft(2, '0')}';
    final birthTime = _formatTime(_selectedTime!); // HH:MM local time

    try {
      await AvaraApiClient.instance.patch('/profile/me', body: {
        'birth_date': birthDateIso,
        'birth_time': birthTime,
        'birth_place': resolvedPlace,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Birth profile saved'),
            backgroundColor: AppColors.green,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (_) {
      // Intentionally swallowed — backend availability must never block the
      // local astrology calculation that already succeeded.
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers to read the result map defensively
  // ---------------------------------------------------------------------------

  int _rasiIndexOf(String key) {
    final k = _kundali;
    if (k == null) return -1;
    if (key == 'Lagna') {
      final lagna = k['lagna'];
      if (lagna is Map) {
        final idx = lagna['rasi_index'];
        if (idx is int) return idx;
      }
      return -1;
    }
    final planets = k['planets'];
    if (planets is Map) {
      final body = planets[key];
      if (body is Map) {
        final idx = body['rasi_index'];
        if (idx is int) return idx;
      }
    }
    return -1;
  }

  List<String> _planetsForRasi(int rasiIndex) {
    final raw = _kundali?['rasi_to_planets'];
    if (raw is Map) {
      final list = raw[rasiIndex];
      if (list is List) {
        return list.map((e) => e.toString()).toList(growable: false);
      }
    }
    return const <String>[];
  }

  /// The kundali contains a `Map<int, List<String>>` (`rasi_to_planets`) whose
  /// integer keys are not valid JSON, so we recursively stringify every map
  /// key before encoding.
  dynamic _jsonSafe(dynamic value) {
    if (value is Map) {
      return value.map((dynamic k, dynamic v) =>
          MapEntry(k.toString(), _jsonSafe(v)));
    }
    if (value is List) {
      return value.map(_jsonSafe).toList(growable: false);
    }
    return value;
  }

  String _encodeEvidence() {
    if (_kundali == null) return '';
    try {
      return const JsonEncoder.withIndent('  ').convert(_jsonSafe(_kundali));
    } catch (_) {
      return _kundali.toString();
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Birth Profile & Astrology Evidence'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildFormCard(),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  _buildError(),
                ],
                if (_kundali != null) ...[
                  const SizedBox(height: 20),
                  _buildResultsSummary(),
                  const SizedBox(height: 16),
                  _buildChartCard(),
                  const SizedBox(height: 16),
                  _buildRawEvidence(),
                  const SizedBox(height: 16),
                  _buildChatWithAiButton(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Form
  // ---------------------------------------------------------------------------

  InputDecoration _fieldDecoration(String label, [IconData? icon]) {
    final base = InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.deepNavy),
      isDense: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.blue, width: 1.5),
      ),
    );
    if (icon == null) return base;
    return base.copyWith(
      suffixIcon: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Icon(icon, color: AppColors.blue, size: 20),
      ),
      suffixIconConstraints: const BoxConstraints(minWidth: 28),
    );
  }

  Widget _buildFormCard() {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Birth Details',
              style: TextStyle(
                color: AppColors.deepNavy,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Date of Birth
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(8),
              child: InputDecorator(
                decoration: _fieldDecoration('Date of Birth', Icons.calendar_today),
                child: Text(
                  _selectedDate == null
                      ? 'Select date'
                      : _formatDate(_selectedDate!),
                  style: TextStyle(
                    color:
                        _selectedDate == null ? Colors.grey : AppColors.deepNavy,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Time of Birth (local)
            InkWell(
              onTap: _pickTime,
              borderRadius: BorderRadius.circular(8),
              child: InputDecorator(
                decoration:
                    _fieldDecoration('Time of Birth (Local)', Icons.access_time),
                child: Text(
                  _selectedTime == null
                      ? 'Select time'
                      : _formatTime(_selectedTime!),
                  style: TextStyle(
                    color:
                        _selectedTime == null ? Colors.grey : AppColors.deepNavy,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Timezone offset
            DropdownButtonFormField<double>(
              initialValue: _timezoneOffset,
              decoration: _fieldDecoration('Timezone Offset'),
              items: [
                for (final e in _tzOptions)
                  DropdownMenuItem<double>(value: e.key, child: Text(e.value)),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _timezoneOffset = v);
              },
            ),
            const SizedBox(height: 12),
            // Place of birth
            TextFormField(
              controller: _placeController,
              textInputAction: TextInputAction.done,
              decoration:
                  _fieldDecoration('Place of Birth (City, State)', Icons.place),
            ),
            const SizedBox(height: 12),
            // Ayanamsa (backend supports Lahiri / Raman / KP)
            DropdownButtonFormField<int>(
              initialValue: _ayanamsaChoice,
              decoration: _fieldDecoration('Ayanamsa'),
              items: const [
                DropdownMenuItem(value: 1, child: Text('Lahiri')),
                DropdownMenuItem(value: 2, child: Text('Raman')),
                DropdownMenuItem(value: 3, child: Text('KP')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _ayanamsaChoice = v);
              },
            ),
            const SizedBox(height: 22),
            _buildGenerateButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _generateChart,
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Text(
                'Generate Evidence Chart',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE57373)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: Colors.red[700], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage ?? '',
              style: TextStyle(color: Colors.red[900], fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Results summary
  // ---------------------------------------------------------------------------

  Widget _buildResultsSummary() {
    final k = _kundali!;
    final planets = k['planets'] as Map<String, dynamic>;
    final moon = planets['Moon'] as Map<String, dynamic>;
    final lagna = k['lagna'] as Map<String, dynamic>;
    final location = k['location'] as Map<String, dynamic>;
    final ayanamsaName = k['ayanamsa_name'] as String;
    final ayanamsaVal = k['ayanamsa'] as double;
    final timestamp = k['timestamp_utc'] as String;

    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rasi & Nakshatra',
              style: TextStyle(
                color: AppColors.deepNavy,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _summaryRow(
              'Telugu Rasi (Moon)',
              '${moon['rasi_name_telugu']}  (${moon['rasi_name_sanskrit']})',
              prominent: true,
            ),
            _summaryRow(
              'Nakshatra',
              '${moon['nakshatra_name_telugu']}  (${moon['nakshatra_name_sanskrit']})',
              prominent: true,
            ),
            _summaryRow('Pada', '${moon['pada']}'),
            _summaryRow('Nakshatra Lord', '${moon['nakshatra_lord']}'),
            _summaryRow(
              'Lagna (Ascendant)',
              '${lagna['rasi_name_telugu']}  (${lagna['rasi_name_sanskrit']})',
            ),
            const Divider(height: 24),
            _summaryRow(
              'Ayanamsa',
              '$ayanamsaName  (${ayanamsaVal.toStringAsFixed(4)}°)',
            ),
            _summaryRow(
              'Coordinates',
              '${location['latitude']}, ${location['longitude']}',
            ),
            _summaryRow('UTC Time', timestamp),
            if (_resolvedPlace != null)
              _summaryRow('Resolved Place', _resolvedPlace!),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool prominent = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: AppColors.deepNavy,
                fontSize: prominent ? 16 : 14,
                fontWeight: prominent ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // South Indian chart (4x4, empty 2x2 center)
  // ---------------------------------------------------------------------------

  Widget _buildChartCard() {
    final moonRasi = _rasiIndexOf('Moon');
    final lagnaRasi = _rasiIndexOf('Lagna');

    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Janma Kundali — South Indian Chart',
              style: TextStyle(
                color: AppColors.deepNavy,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Blue border = Moon Rasi (birth rasi)  •  Navy border = Lagna',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 12),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
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
                    return _buildChartCell(
                      rasiIndex,
                      moonRasi: moonRasi,
                      lagnaRasi: lagnaRasi,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCell(int rasiIndex, {required int moonRasi, required int lagnaRasi}) {
    // Empty center (2x2) — let the page background show through.
    if (rasiIndex == -1) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
      );
    }

    final planets = _planetsForRasi(rasiIndex);
    final isMoonRasi = rasiIndex == moonRasi;
    final isLagnaRasi = rasiIndex == lagnaRasi;

    final Color borderColor;
    final double borderWidth;
    if (isMoonRasi) {
      borderColor = AppColors.blue;
      borderWidth = 2.0;
    } else if (isLagnaRasi) {
      borderColor = AppColors.deepNavy;
      borderWidth = 2.0;
    } else {
      borderColor = AppColors.border;
      borderWidth = 0.5;
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.lightBlue,
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _teluguRasiNames[rasiIndex],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.deepNavy,
                    ),
                  ),
                ),
                Text(
                  '${rasiIndex + 1}',
                  style: TextStyle(
                    fontSize: 8,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Expanded(
              child: planets.isEmpty
                  ? const SizedBox.shrink()
                  : Wrap(
                      spacing: 2,
                      runSpacing: 2,
                      children: [for (final p in planets) _planetChip(p)],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _planetChip(String abbr) {
    final isLagna = abbr == 'As';
    final isRetro = abbr.endsWith('R');
    final bg = isLagna ? const Color(0x24100960) : const Color(0x1F2E71DB);
    final fg = isLagna ? AppColors.deepNavy : AppColors.blue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        abbr,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: fg,
          decoration: isRetro ? TextDecoration.overline : TextDecoration.none,
        ),
      ),
    );
  }

  Widget _buildLegend() {
    const entries = <(String, Color, String)>[
      ('Su', Color(0x1F2E71DB), 'Sun'),
      ('Mo', Color(0x1F2E71DB), 'Moon'),
      ('Ma', Color(0x1F2E71DB), 'Mars'),
      ('Me', Color(0x1F2E71DB), 'Mercury'),
      ('Ju', Color(0x1F2E71DB), 'Jupiter'),
      ('Ve', Color(0x1F2E71DB), 'Venus'),
      ('Sa', Color(0x1F2E71DB), 'Saturn'),
      ('Ra', Color(0x1F2E71DB), 'Rahu'),
      ('Ke', Color(0x1F2E71DB), 'Ketu'),
      ('As', Color(0x24100960), 'Lagna'),
    ];
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: [
        for (final e in entries) _legendChip(e.$1, e.$2, e.$3),
        Text(
          '  R = retrograde (e.g. MaR)',
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _legendChip(String abbr, Color bg, String name) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            abbr,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.blue,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(name, style: TextStyle(fontSize: 11, color: Colors.grey[700])),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Chat with AI button
  // ---------------------------------------------------------------------------

  Widget _buildChatWithAiButton() {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => AstrologyChatScreen(
                chartJson: _kundali!,
                // ← PASTE YOUR GEMINI API KEY BETWEEN THE QUOTES BELOW
                // Get one free at: https://aistudio.google.com/app/apikey
                apiKey: '',
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.deepNavy,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome, size: 20),
            SizedBox(width: 10),
            Text(
              'Chat with AI  —  Ask your Kundali',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Raw JSON evidence
  // ---------------------------------------------------------------------------

  Widget _buildRawEvidence() {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          title: const Text(
            'Raw Evidence (JSON Payload)',
            style: TextStyle(
              color: AppColors.deepNavy,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            'Full calculation payload returned by the engine',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          children: [
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 280),
              padding: const EdgeInsets.all(10),
              color: const Color(0xFFF5F7FA),
              child: SingleChildScrollView(
                child: SelectableText(
                  _encodeEvidence(),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Formatting helpers
  // ---------------------------------------------------------------------------

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.year}';

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}';
}
