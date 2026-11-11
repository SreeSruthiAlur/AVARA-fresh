import 'package:avara_astrology_trial/models/finance_model.dart';
import 'package:avara_astrology_trial/services/avara_api_client.dart';

/// Service for all AVARA Finance API calls.
///
/// Uses [AvaraApiClient.instance] so the JWT is automatically attached and
/// [AvaraApiException] is thrown on non-2xx responses — callers just need to
/// catch that one exception type.
///
/// Endpoint reference (Vinya's backend, `backend/app/api/v1/finance.py`):
/// ```
/// GET  /finance/dashboard            → FinanceDashboardResponse
/// GET  /finance/expenses             → List<ExpenseResponse>
/// POST /finance/expenses             → ExpenseResponse (201)
/// DELETE /finance/expenses/{id}      → { success: true }
/// ```
class FinanceService {
  FinanceService._();

  static final FinanceService instance = FinanceService._();

  final AvaraApiClient _client = AvaraApiClient.instance;

  // ---- Dashboard -----------------------------------------------------------

  /// Fetches the complete Finance dashboard summary for the current month.
  ///
  /// Optionally pass [month] in `YYYY-MM` format to query a different month.
  Future<BudgetSummary> getDashboardSummary({String? month}) async {
    final params = <String, String>{
      // ignore: use_null_aware_elements — SDK version doesn't support null-aware map entries yet
      if (month != null) 'month': month,
    };
    final data = await _client.get(
      '/finance/dashboard',
      queryParams: params.isNotEmpty ? params : null,
    ) as Map<String, dynamic>;
    return BudgetSummary.fromJson(data);
  }

  // ---- Expenses ------------------------------------------------------------

  /// Returns the user's expense list, most-recent first.
  ///
  /// Optional filters:
  /// - [category] — filter to a single category string.
  /// - [search]   — partial match on description or category.
  /// - [limit]    — max records to return (default 50, backend max 500).
  Future<List<Expense>> getRecentExpenses({
    String? category,
    String? search,
    int limit = 50,
  }) async {
    final params = <String, String>{
      'sort_by': 'date',
      'order': 'desc',
      'limit': '$limit',
      if (category != null && category.isNotEmpty) 'category': category,
      if (search != null && search.isNotEmpty) 'search': search,
    };
    final data = await _client.get('/finance/expenses', queryParams: params);
    final list = data as List? ?? [];
    return list
        .map((e) => Expense.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  /// Creates a new expense record.
  ///
  /// Returns the persisted [Expense] with its server-assigned [Expense.id].
  Future<Expense> addExpense(Expense expense) async {
    final data =
        await _client.post('/finance/expenses', body: expense.toJson())
            as Map<String, dynamic>;
    return Expense.fromJson(data);
  }

  /// Deletes an expense by [id].
  ///
  /// Throws [AvaraApiException] (404) if the record does not exist.
  Future<void> deleteExpense(int id) async {
    await _client.delete('/finance/expenses/$id');
  }
}
