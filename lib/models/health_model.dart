/// Data models for the AVARA Health & Wellness module.
///
/// Field names mirror the JSON keys returned by the backend
/// (`backend/app/schemas/health.py`).
library;

// ---------------------------------------------------------------------------
// Mood constants
// ---------------------------------------------------------------------------

/// Canonical mood labels accepted by the backend.
const List<String> kMoodLabels = [
  'Great',
  'Good',
  'Neutral',
  'Low',
  'Stressed',
];

/// Maps a [moodScore] (1–5) to its emoji representation.
String moodEmoji(int score) {
  switch (score) {
    case 5:
      return '🤩';
    case 4:
      return '😊';
    case 3:
      return '😐';
    case 2:
      return '😔';
    case 1:
      return '😫';
    default:
      return '✨';
  }
}

// ---------------------------------------------------------------------------
// WellnessEntry
// ---------------------------------------------------------------------------

/// A single daily wellness check-in record.
///
/// Maps to `WellnessEntryResponse` in the backend schema.
class WellnessEntry {
  const WellnessEntry({
    this.id,
    required this.date,
    required this.mood,
    required this.moodScore,
    required this.energyLevel,
    this.sleepHours,
    this.activityMinutes,
    this.wellnessGoals,
    this.notes,
  });

  /// Server-assigned id. `null` before the entry is persisted.
  final int? id;

  /// Date of the check-in in `YYYY-MM-DD` format.
  final String date;

  /// Mood label — one of [kMoodLabels].
  final String mood;

  /// Mood intensity on a 1–5 scale.
  final int moodScore;

  /// Energy level on a 1–5 scale.
  final int energyLevel;

  /// Hours slept (0–24), optional.
  final double? sleepHours;

  /// Minutes of physical activity (0–1440), optional.
  final int? activityMinutes;

  /// Personal wellness goal for the day, optional.
  final String? wellnessGoals;

  /// Free-text reflective note, optional.
  final String? notes;

  // ---- de-serialisation ---------------------------------------------------

  factory WellnessEntry.fromJson(Map<String, dynamic> json) {
    return WellnessEntry(
      id: json['id'] as int?,
      date: json['date']?.toString() ?? '',
      mood: json['mood']?.toString() ?? 'Neutral',
      moodScore: (json['mood_score'] as num?)?.toInt() ?? 3,
      energyLevel: (json['energy_level'] as num?)?.toInt() ?? 3,
      sleepHours: json['sleep_hours'] != null
          ? (json['sleep_hours'] as num).toDouble()
          : null,
      activityMinutes: json['activity_minutes'] as int?,
      wellnessGoals: json['wellness_goals']?.toString(),
      notes: json['notes']?.toString(),
    );
  }

  // ---- serialisation (sent to POST /health/entries) -----------------------

  Map<String, dynamic> toJson() {
    final today = DateTime.now();
    final dateStr = date.isNotEmpty
        ? date
        : '${today.year}-'
            '${today.month.toString().padLeft(2, '0')}-'
            '${today.day.toString().padLeft(2, '0')}';
    return {
      'date': dateStr,
      'mood': mood,
      'mood_score': moodScore,
      'energy_level': energyLevel,
      if (sleepHours != null) 'sleep_hours': sleepHours,
      if (activityMinutes != null) 'activity_minutes': activityMinutes,
      if (wellnessGoals != null && wellnessGoals!.isNotEmpty)
        'wellness_goals': wellnessGoals,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };
  }
}

// ---------------------------------------------------------------------------
// HealthSummary
// ---------------------------------------------------------------------------

/// Aggregate wellness statistics shown at the top of the Health screen.
///
/// Maps to `HealthSummaryResponse` in the backend schema.
class HealthSummary {
  const HealthSummary({
    required this.totalEntries,
    this.averageMoodScore,
    this.averageEnergyLevel,
    this.averageSleepHours,
    this.totalActivityMinutes = 0,
    this.recentEntries = const [],
    this.wellnessStreakDays = 0,
  });

  final int totalEntries;

  /// Average mood score (1.0–5.0), null if no entries yet.
  final double? averageMoodScore;

  /// Average energy level (1.0–5.0), null if no entries yet.
  final double? averageEnergyLevel;

  /// Average nightly sleep hours, null if never logged.
  final double? averageSleepHours;

  /// Sum of all logged activity minutes.
  final int totalActivityMinutes;

  /// Most recent check-in records.
  final List<WellnessEntry> recentEntries;

  /// Consecutive days with at least one entry.
  final int wellnessStreakDays;

  factory HealthSummary.fromJson(Map<String, dynamic> json) {
    final raw = json['recent_entries'] as List? ?? [];
    return HealthSummary(
      totalEntries: (json['total_entries'] as num?)?.toInt() ?? 0,
      averageMoodScore: json['average_mood_score'] != null
          ? (json['average_mood_score'] as num).toDouble()
          : null,
      averageEnergyLevel: json['average_energy_level'] != null
          ? (json['average_energy_level'] as num).toDouble()
          : null,
      averageSleepHours: json['average_sleep_hours'] != null
          ? (json['average_sleep_hours'] as num).toDouble()
          : null,
      totalActivityMinutes:
          (json['total_activity_minutes'] as num?)?.toInt() ?? 0,
      recentEntries: raw
          .map((e) => WellnessEntry.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      wellnessStreakDays:
          (json['wellness_streak_days'] as num?)?.toInt() ?? 0,
    );
  }
}
