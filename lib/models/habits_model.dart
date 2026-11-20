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
    this.originalStruggle,
    this.upgradedHabit,
    this.scientificFact,
    this.neuralScore,
    this.upgradeTier,
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

  /// The original suboptimal habit/struggle the user wanted to transform.
  final String? originalStruggle;

  /// The upgraded, optimized version suggested by AVARA's self-help engine.
  final String? upgradedHabit;

  /// Behavioral science or Vedic chronobiology fact explaining why this habit works.
  final String? scientificFact;

  /// Neural habit formation pathway strength (0 - 100%).
  final int? neuralScore;

  /// Tier of the habit: 1 (Micro-Step), 2 (Steady), 3 (Mastery).
  final int? upgradeTier;

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
      originalStruggle: json['original_struggle']?.toString(),
      upgradedHabit: json['upgraded_habit']?.toString(),
      scientificFact: json['scientific_fact']?.toString(),
      neuralScore: (json['neural_score'] as num?)?.toInt(),
      upgradeTier: (json['upgrade_tier'] as num?)?.toInt(),
    );
  }

  // ---- serialisation (sent to POST /habits) --------------------------------

  Map<String, dynamic> toJson() => {
        'title': title,
        'frequency': frequency,
        'target_days_per_week': targetDaysPerWeek,
        if (originalStruggle != null) 'original_struggle': originalStruggle,
        if (upgradedHabit != null) 'upgraded_habit': upgradedHabit,
        if (scientificFact != null) 'scientific_fact': scientificFact,
        if (neuralScore != null) 'neural_score': neuralScore,
        if (upgradeTier != null) 'upgrade_tier': upgradeTier,
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
        originalStruggle: originalStruggle,
        upgradedHabit: upgradedHabit,
        scientificFact: scientificFact,
        neuralScore: isCompletedToday
            ? ((neuralScore ?? 40) - 4).clamp(10, 100)
            : ((neuralScore ?? 40) + 6).clamp(10, 100),
        upgradeTier: upgradeTier,
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
