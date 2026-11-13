/// Structured result of parsing birth details from free-form text.
class ParsedBirthDetails {
  const ParsedBirthDetails({
    required this.hasDate,
    this.year,
    this.month,
    this.day,
    required this.hasTime,
    this.hour,
    this.minute,
    required this.hasPlace,
    this.place,
  });

  final bool hasDate;
  final int? year;
  final int? month;
  final int? day;

  final bool hasTime;
  final int? hour;
  final int? minute;

  final bool hasPlace;
  final String? place;

  /// True if DOB, TOB, and POB were all extracted.
  bool get isComplete => hasDate && hasTime && hasPlace;

  /// Formatted ISO date `YYYY-MM-DD`.
  String? get isoDate {
    if (!hasDate || year == null || month == null || day == null) return null;
    return '${year.toString().padLeft(4, '0')}-'
        '${month.toString().padLeft(2, '0')}-'
        '${day.toString().padLeft(2, '0')}';
  }

  /// Formatted 24-hr time `HH:MM`.
  String? get formattedTime {
    if (!hasTime || hour == null || minute == null) return null;
    return '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}';
  }

  @override
  String toString() =>
      'ParsedBirthDetails(date: $isoDate, time: $formattedTime, place: $place, complete: $isComplete)';
}

/// Robust extractor of Date, Time, and Place of birth from user chat messages.
class BirthDetailsParser {
  BirthDetailsParser._();

  static const Map<String, int> _monthNames = {
    'january': 1, 'jan': 1,
    'february': 2, 'feb': 2,
    'march': 3, 'mar': 3,
    'april': 4, 'apr': 4,
    'may': 5,
    'june': 6, 'jun': 6,
    'july': 7, 'jul': 7,
    'august': 8, 'aug': 8,
    'september': 9, 'sep': 9, 'sept': 9,
    'october': 10, 'oct': 10,
    'november': 11, 'nov': 11,
    'december': 12, 'dec': 12,
  };

  /// Parses [text] and extracts any birth date, time, and place found.
  static ParsedBirthDetails parse(String text) {
    int? year;
    int? month;
    int? day;

    int? hour;
    int? minute;

    String? place;

    String workingText = text;

    // -------------------------------------------------------------------------
    // 1. Extract Date
    // -------------------------------------------------------------------------

    // Pattern A: "15 December 2006" or "15 Dec 2006" or "15th Dec 2006"
    final dateNamedPattern1 = RegExp(
      r'\b(\d{1,2})(?:st|nd|rd|th)?\s+([A-Za-z]+)[,\s]+(\d{4})\b',
      caseSensitive: false,
    );
    final matchDateNamed1 = dateNamedPattern1.firstMatch(workingText);

    // Pattern B: "December 15 2006" or "Dec 15, 2006"
    final dateNamedPattern2 = RegExp(
      r'\b([A-Za-z]+)\s+(\d{1,2})(?:st|nd|rd|th)?[,\s]+(\d{4})\b',
      caseSensitive: false,
    );
    final matchDateNamed2 = dateNamedPattern2.firstMatch(workingText);

    // Pattern C: "15-12-2006" or "15/12/2006" or "2006-12-15"
    final dateNumericPattern = RegExp(
      r'\b(\d{1,4})[-/\.](\d{1,2})[-/\.](\d{1,4})\b',
    );

    if (matchDateNamed1 != null &&
        _monthNames.containsKey(matchDateNamed1.group(2)!.toLowerCase())) {
      day = int.tryParse(matchDateNamed1.group(1)!);
      month = _monthNames[matchDateNamed1.group(2)!.toLowerCase()];
      year = int.tryParse(matchDateNamed1.group(3)!);
      workingText = workingText.replaceFirst(matchDateNamed1.group(0)!, ' ');
    } else if (matchDateNamed2 != null &&
        _monthNames.containsKey(matchDateNamed2.group(1)!.toLowerCase())) {
      month = _monthNames[matchDateNamed2.group(1)!.toLowerCase()];
      day = int.tryParse(matchDateNamed2.group(2)!);
      year = int.tryParse(matchDateNamed2.group(3)!);
      workingText = workingText.replaceFirst(matchDateNamed2.group(0)!, ' ');
    } else {
      final matchDateNumeric = dateNumericPattern.firstMatch(workingText);
      if (matchDateNumeric != null) {
        final p1 = int.tryParse(matchDateNumeric.group(1)!);
        final p2 = int.tryParse(matchDateNumeric.group(2)!);
        final p3 = int.tryParse(matchDateNumeric.group(3)!);

        if (p1 != null && p2 != null && p3 != null) {
          if (p1 > 1000) {
            // YYYY-MM-DD
            year = p1;
            month = p2;
            day = p3;
          } else {
            // DD-MM-YYYY
            day = p1;
            month = p2;
            year = p3;
          }
          workingText =
              workingText.replaceFirst(matchDateNumeric.group(0)!, ' ');
        }
      }
    }

    // -------------------------------------------------------------------------
    // 2. Extract Time
    // -------------------------------------------------------------------------

    // Pattern A: "7:30 AM", "07:30 pm", "14:30"
    final timePattern = RegExp(
      r'\b(\d{1,2}):(\d{2})(?::\d{2})?\s*(AM|PM|am|pm)?\b',
    );
    final matchTime = timePattern.firstMatch(workingText);

    // Pattern B: "7 AM", "7 pm"
    final timeSimplePattern = RegExp(
      r'\b(\d{1,2})\s*(AM|PM|am|pm)\b',
    );
    final matchTimeSimple = timeSimplePattern.firstMatch(workingText);

    if (matchTime != null) {
      final h = int.tryParse(matchTime.group(1)!);
      final m = int.tryParse(matchTime.group(2)!);
      final ampm = matchTime.group(3)?.toUpperCase();

      if (h != null && m != null) {
        if (ampm == 'PM' && h < 12) {
          hour = h + 12;
        } else if (ampm == 'AM' && h == 12) {
          hour = 0;
        } else {
          hour = h;
        }
        minute = m;
        workingText = workingText.replaceFirst(matchTime.group(0)!, ' ');
      }
    } else if (matchTimeSimple != null) {
      final h = int.tryParse(matchTimeSimple.group(1)!);
      final ampm = matchTimeSimple.group(2)?.toUpperCase();

      if (h != null) {
        if (ampm == 'PM' && h < 12) {
          hour = h + 12;
        } else if (ampm == 'AM' && h == 12) {
          hour = 0;
        } else {
          hour = h;
        }
        minute = 0;
        workingText = workingText.replaceFirst(matchTimeSimple.group(0)!, ' ');
      }
    }

    // -------------------------------------------------------------------------
    // 3. Extract Place
    // -------------------------------------------------------------------------

    // Check for explicit markers: "POB: ...", "Place: ...", "born in ...", "at ..."
    final placeExplicit = RegExp(
      r'\b(?:POB|place\s*of\s*birth|birth\s*place|place|city|location|born\s+in)\s*[:=-]?\s*([A-Za-z\s,]+)',
      caseSensitive: false,
    );
    final matchExplicitPlace = placeExplicit.firstMatch(workingText);

    if (matchExplicitPlace != null) {
      final candidate = matchExplicitPlace.group(1)?.trim();
      if (candidate != null && candidate.isNotEmpty) {
        place = _cleanPlace(candidate);
      }
    }

    if (place == null || place.isEmpty) {
      // Clean working text of common labels and punctuation
      var cleaned = workingText
          .replaceAll(RegExp(r'\b(DOB|TOB|POB|Date\s+of\s+birth|Time\s+of\s+birth|Place\s+of\s+birth|birth|born|at|on|details)\b', caseSensitive: false), ' ')
          .replaceAll(RegExp(r'[:;=]'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      // Remove leading/trailing commas
      cleaned = cleaned.replaceAll(RegExp(r'^[\s,]+|[\s,]+$'), '');

      if (cleaned.length >= 2 && RegExp(r'[a-zA-Z]').hasMatch(cleaned)) {
        place = _cleanPlace(cleaned);
      }
    }

    final hasDate = year != null && month != null && day != null && month >= 1 && month <= 12 && day >= 1 && day <= 31;
    final hasTime = hour != null && minute != null && hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59;
    final hasPlace = place != null && place.trim().isNotEmpty;

    return ParsedBirthDetails(
      hasDate: hasDate,
      year: hasDate ? year : null,
      month: hasDate ? month : null,
      day: hasDate ? day : null,
      hasTime: hasTime,
      hour: hasTime ? hour : null,
      minute: hasTime ? minute : null,
      hasPlace: hasPlace,
      place: hasPlace ? place : null,
    );
  }

  static String _cleanPlace(String raw) {
    return raw
        .replaceAll(RegExp(r'\b(my|chart|kundali|horoscope|jathakam|details|is|was)\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'[\r\n\t]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'^[\s,]+|[\s,]+$'), '')
        .trim();
  }
}
