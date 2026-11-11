import 'package:avara_astrology_trial/models/health_model.dart';
import 'package:avara_astrology_trial/services/avara_api_client.dart';

/// Service for all AVARA Health & Wellness API calls.
///
/// Endpoint reference (`backend/app/api/v1/health.py`):
/// ```
/// GET  /health/summary    → HealthSummaryResponse
/// GET  /health/entries    → List<WellnessEntryResponse>
/// POST /health/entries    → WellnessEntryResponse (201)
/// DELETE /health/entries/{id}
/// ```
class HealthService {
  HealthService._();
  static final HealthService instance = HealthService._();

  final AvaraApiClient _client = AvaraApiClient.instance;

  // ---- Summary -------------------------------------------------------------

  /// Fetches aggregated wellness stats and recent entries.
  Future<HealthSummary> getSummary() async {
    final data =
        await _client.get('/health/summary') as Map<String, dynamic>;
    return HealthSummary.fromJson(data);
  }

  // ---- Entries -------------------------------------------------------------

  /// Returns the user's wellness history, most recent first.
  Future<List<WellnessEntry>> getEntries({int limit = 30}) async {
    final data = await _client.get(
      '/health/entries',
      queryParams: {'limit': '$limit'},
    );
    final list = data as List? ?? [];
    return list
        .map((e) => WellnessEntry.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  /// Creates a new daily wellness check-in.
  ///
  /// Returns the persisted [WellnessEntry] with its server-assigned id.
  Future<WellnessEntry> addEntry(WellnessEntry entry) async {
    final data = await _client.post('/health/entries', body: entry.toJson())
        as Map<String, dynamic>;
    return WellnessEntry.fromJson(data);
  }

  /// Deletes a wellness entry by [id].
  Future<void> deleteEntry(int id) async {
    await _client.delete('/health/entries/$id');
  }
}
