import 'package:avara_astrology_trial/models/insights_model.dart';
import 'package:avara_astrology_trial/services/avara_api_client.dart';

/// Service for the AVARA Insights module.
///
/// All data is served through the integration contract endpoint:
/// ```
/// GET /integrations/insights/summary  → InsightsSummaryResponse
/// ```
class InsightsService {
  InsightsService._();
  static final InsightsService instance = InsightsService._();

  final AvaraApiClient _client = AvaraApiClient.instance;

  /// Fetches the weekly insights summary.
  Future<InsightsSummary> getSummary() async {
    final data = await _client.get('/integrations/insights/summary')
        as Map<String, dynamic>;
    return InsightsSummary.fromJson(data);
  }
}
