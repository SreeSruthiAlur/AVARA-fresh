import 'package:avara_astrology_trial/models/habits_model.dart';
import 'package:avara_astrology_trial/services/avara_api_client.dart';

/// Service for the AVARA Habits module.
///
/// All endpoints are exposed through Vinya's integration contract layer:
/// ```
/// GET  /integrations/habits/summary  → HabitsSummaryResponse
/// POST /habits                        → HabitContractItem  (create)
/// POST /habits/{id}/toggle            → HabitContractItem  (mark done/undone)
/// DELETE /habits/{id}                 → { success: true }
/// ```
///
/// Note: the backend currently routes habit business logic through
/// `/integrations/habits/summary` (Teammate 2's contract endpoint).
/// Direct CRUD endpoints (`POST /habits`, etc.) will go live once the
/// concrete adapter is wired.  The service already sends the correct
/// payloads so no UI changes will be needed when those routes land.
class HabitsService {
  HabitsService._();
  static final HabitsService instance = HabitsService._();

  final AvaraApiClient _client = AvaraApiClient.instance;

  // ---- Summary (via integration contract) ----------------------------------

  /// Fetches the habits summary from the integration adapter.
  Future<HabitsSummary> getSummary() async {
    final data = await _client.get('/integrations/habits/summary')
        as Map<String, dynamic>;
    return HabitsSummary.fromJson(data);
  }

  // ---- CRUD (direct habit routes — live once concrete adapter lands) -------

  /// Creates a new habit.
  Future<Habit> addHabit(Habit habit) async {
    final data = await _client.post('/habits', body: habit.toJson())
        as Map<String, dynamic>;
    return Habit.fromJson(data);
  }

  /// Toggles the completion state of a habit by [id].
  Future<Habit> toggleHabit(int id) async {
    final data =
        await _client.post('/habits/$id/toggle') as Map<String, dynamic>;
    return Habit.fromJson(data);
  }

  /// Deletes a habit by [id].
  Future<void> deleteHabit(int id) async {
    await _client.delete('/habits/$id');
  }
}
