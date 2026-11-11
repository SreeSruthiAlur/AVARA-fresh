/// Data models for the AVARA Insights module.
///
/// Field names mirror the JSON keys returned by the backend
/// integration contract (`backend/app/schemas/integrations.py`,
/// `InsightsSummaryResponse` / `InsightObservation`).
library;

// ---------------------------------------------------------------------------
// Category → icon mapping
// ---------------------------------------------------------------------------

/// Maps a backend [category] string to a Material icon codepoint.
///
/// The codepoint is serialised as an `int` in [InsightPattern.iconCode] so
/// the model stays a pure Dart data class with no Flutter import. The screen
/// reconstructs the [IconData] via `IconData(pattern.iconCode, ...)`.
int iconCodeForCategory(String category) {
  switch (category.toLowerCase()) {
    case 'wellness':
      return 0xe87d; // Icons.favorite
    case 'discipline':
      return 0xe8ec; // Icons.track_changes
    case 'routine':
      return 0xe192; // Icons.repeat
    case 'astrology_link':
      return 0xe532; // Icons.nightlight_round
    case 'spending':
    case 'finance':
      return 0xe227; // Icons.account_balance_wallet_outlined
    case 'habits':
      return 0xe8ec; // Icons.track_changes
    case 'health':
      return 0xe87d; // Icons.favorite
    case 'integration':
      return 0xe1b1; // Icons.settings
    default:
      return 0xe336; // Icons.auto_awesome
  }
}

// ---------------------------------------------------------------------------
// InsightPattern  (was InsightObservation in the backend contract)
// ---------------------------------------------------------------------------

/// A single pattern or observation surfaced by the Insights engine.
///
/// Maps to `InsightObservation` in `InsightsSummaryResponse`.
class InsightPattern {
  const InsightPattern({
    required this.category,
    required this.title,
    required this.observation,
    required this.iconCode,
    this.confidence = 1.0,
  });

  /// Domain category, e.g. `"wellness"`, `"discipline"`, `"astrology_link"`.
  final String category;

  /// Short headline for the pattern card.
  final String title;

  /// One-sentence observation body.
  final String observation;

  /// Material icon codepoint — use [iconCodeForCategory] when creating from
  /// backend JSON. Build the widget with
  /// `IconData(pattern.iconCode, fontFamily: 'MaterialIcons')`.
  final int iconCode;

  /// Confidence score 0.0–1.0 (informational only, not displayed in the UI).
  final double confidence;

  factory InsightPattern.fromJson(Map<String, dynamic> json) {
    final cat = json['category']?.toString() ?? 'general';
    return InsightPattern(
      category: cat,
      title: json['title']?.toString() ?? '',
      observation: json['observation']?.toString() ?? '',
      iconCode: iconCodeForCategory(cat),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

// ---------------------------------------------------------------------------
// InsightsSummary
// ---------------------------------------------------------------------------

/// The full insights payload returned by `GET /integrations/insights/summary`.
///
/// Maps to `InsightsSummaryResponse` in the backend contract.
class InsightsSummary {
  const InsightsSummary({
    required this.status,
    required this.reflectionSummary,
    this.keyObservations = const [],
    this.practicalSuggestions = const [],
    this.message = '',
  });

  /// `"ready"`, `"pending"` or `"mock_adapter"`.
  final String status;

  /// Weekly reflection headline, e.g. "Small steps are adding up."
  final String reflectionSummary;

  /// List of patterns the user can explore.
  final List<InsightPattern> keyObservations;

  /// Actionable suggestions.
  final List<String> practicalSuggestions;

  final String message;

  factory InsightsSummary.fromJson(Map<String, dynamic> json) {
    final rawObs = json['key_observations'] as List? ?? [];
    final rawSug = json['practical_suggestions'] as List? ?? [];
    return InsightsSummary(
      status: json['status']?.toString() ?? 'pending',
      reflectionSummary:
          json['reflection_summary']?.toString() ?? '',
      keyObservations: rawObs
          .map((e) =>
              InsightPattern.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      practicalSuggestions: rawSug
          .map((e) => e?.toString() ?? '')
          .toList(growable: false),
      message: json['message']?.toString() ?? '',
    );
  }
}
