/// Data models for the AVARA Habits module.
///
/// Field names mirror the JSON keys returned by the backend
/// integration contract (`backend/app/schemas/integrations.py`,
/// `HabitsSummaryResponse` / `HabitContractItem`).
library;

// ---------------------------------------------------------------------------
// Habit
// ---------------------------------------------------------------------------

/// A single tracked habit.
///
/// Maps to `HabitContractItem` in the backend integration schema.
class Habit {
  const Habit({
    this.id,
    required this.title,
    required this.frequency,
    this.targetDaysPerWeek = 7,
    this.currentStreak = 0,
    this.isCompletedToday = false,
  });

  /// Server-assigned id. `null` before the habit is persisted.
  final int? id;

  /// Human-readable habit title, e.g. "Read for 20 minutes".
  final String title;

  /// Recurrence: `"daily"` or `"weekly"`.
  final String frequency;

  /// Target number of days per week (1–7).
  final int targetDaysPerWeek;

  /// Consecutive-day completion streak.
  final int currentStreak;

  /// Whether the habit has already been completed today.
  final bool isCompletedToday;

  // ---- de-serialisation ---------------------------------------------------

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'] as int?,
      title: json['title']?.toString() ?? '',
      frequency: json['frequency']?.toString() ?? 'daily',
      targetDaysPerWeek:
          (json['target_days_per_week'] as num?)?.toInt() ?? 7,
      currentStreak: (json['current_streak'] as num?)?.toInt() ?? 0,
      isCompletedToday: json['is_completed_today'] as bool? ?? false,
    );
  }

  // ---- serialisation (sent to POST /habits) --------------------------------

  Map<String, dynamic> toJson() => {
        'title': title,
        'frequency': frequency,
        'target_days_per_week': targetDaysPerWeek,
      };

  /// Returns a copy with [isCompletedToday] toggled.
  Habit copyWithToggle() => Habit(
        id: id,
        title: title,
        frequency: frequency,
        targetDaysPerWeek: targetDaysPerWeek,
        currentStreak: isCompletedToday
            ? (currentStreak - 1).clamp(0, 9999)
            : currentStreak + 1,
        isCompletedToday: !isCompletedToday,
      );
}

// ---------------------------------------------------------------------------
// HabitsSummary
// ---------------------------------------------------------------------------

/// Aggregate habits statistics shown at the top of the Habits screen.
///
/// Maps to `HabitsSummaryResponse` in the integration contract schema.
class HabitsSummary {
  const HabitsSummary({
    required this.status,
    required this.totalActiveHabits,
    this.habits = const [],
    this.completionRatePct = 0.0,
    this.consistencyScore = 0.0,
    this.message = '',
  });

  /// `"ready"`, `"pending"` or `"mock_adapter"`.
  final String status;

  final int totalActiveHabits;
  final List<Habit> habits;

  /// Percentage of habits completed today (0–100).
  final double completionRatePct;

  /// Long-term consistency metric (0.0–1.0).
  final double consistencyScore;

  final String message;

  factory HabitsSummary.fromJson(Map<String, dynamic> json) {
    final rawHabits = json['habits'] as List? ?? [];
    return HabitsSummary(
      status: json['status']?.toString() ?? 'pending',
      totalActiveHabits:
          (json['total_active_habits'] as num?)?.toInt() ?? 0,
      habits: rawHabits
          .map((e) => Habit.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      completionRatePct:
          (json['completion_rate_pct'] as num?)?.toDouble() ?? 0.0,
      consistencyScore:
          (json['consistency_score'] as num?)?.toDouble() ?? 0.0,
      message: json['message']?.toString() ?? '',
    );
  }
}
