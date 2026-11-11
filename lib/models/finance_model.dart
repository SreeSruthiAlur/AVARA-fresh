/// Data models for the AVARA Finance module.
///
/// Field names mirror the JSON keys returned by Vinya's FastAPI backend
/// (`/api/v1/finance/...`) so [fromJson] / [toJson] require no manual
/// key mapping.
library;

// ---------------------------------------------------------------------------
// Expense
// ---------------------------------------------------------------------------

/// A single recorded expense entry.
///
/// Maps to `ExpenseResponse` in the backend schema (`backend/app/schemas/finance.py`).
class Expense {
  const Expense({
    this.id,
    required this.amount,
    required this.category,
    required this.date,
    this.description,
    this.paymentMethod = 'UPI',
  });

  /// Server-assigned id. `null` before the expense is persisted.
  final int? id;

  /// Transaction amount in ₹ (must be > 0).
  final double amount;

  /// One of the standard categories (Food, Transportation, Shopping,
  /// Education, Entertainment, Healthcare, Bills, Other) or a custom value.
  final String category;

  /// Date of the transaction in `YYYY-MM-DD` format.
  final String date;

  /// Optional free-text note.
  final String? description;

  /// Payment method string (UPI, Cash, Card, …). Defaults to `'UPI'`.
  final String paymentMethod;

  // ---- de-serialisation ---------------------------------------------------

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as int?,
      amount: (json['amount'] as num).toDouble(),
      category: json['category']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      description: json['description']?.toString(),
      paymentMethod: json['payment_method']?.toString() ?? 'UPI',
    );
  }

  // ---- serialisation (sent to POST /finance/expenses) ---------------------

  Map<String, dynamic> toJson() => {
        'amount': amount,
        'category': category,
        'date': date,
        if (description != null && description!.isNotEmpty)
          'description': description,
        'payment_method': paymentMethod,
      };

  @override
  String toString() =>
      'Expense(id: $id, amount: $amount, category: $category, date: $date)';
}

// ---------------------------------------------------------------------------
// CategorySpending
// ---------------------------------------------------------------------------

/// A single row in the dashboard's category-breakdown list.
///
/// Maps to `CategorySpending` in the backend schema.
class CategorySpending {
  const CategorySpending({
    required this.category,
    required this.amount,
    required this.percentage,
    this.budgetLimit,
    this.isOverBudget = false,
  });

  final String category;
  final double amount;

  /// Share of total spending (0–100).
  final double percentage;

  /// Monthly budget cap for this category, or `null` if none is set.
  final double? budgetLimit;

  final bool isOverBudget;

  factory CategorySpending.fromJson(Map<String, dynamic> json) {
    return CategorySpending(
      category: json['category']?.toString() ?? '',
      amount: (json['amount'] as num).toDouble(),
      percentage: (json['percentage'] as num).toDouble(),
      budgetLimit: json['budget_limit'] != null
          ? (json['budget_limit'] as num).toDouble()
          : null,
      isOverBudget: json['is_over_budget'] as bool? ?? false,
    );
  }
}

// ---------------------------------------------------------------------------
// BudgetSummary (derived from FinanceDashboardResponse)
// ---------------------------------------------------------------------------

/// High-level spending / budget summary shown at the top of the Finance screen.
///
/// Extracted from the `FinanceDashboardResponse` JSON returned by
/// `GET /finance/dashboard`. Fields that may not be set (e.g. when no budget
/// has been configured) are nullable.
class BudgetSummary {
  const BudgetSummary({
    required this.currentMonth,
    required this.totalSpentMonth,
    this.totalBudgetMonth,
    this.remainingBudgetMonth,
    this.budgetUtilizationPct,
    this.thresholdAlert,
    this.categoryBreakdown = const [],
    this.recentTransactions = const [],
    this.totalTransactionsCount = 0,
  });

  /// Human-readable month label returned by the backend (e.g. "November 2026").
  final String currentMonth;

  /// Total amount spent in the current calendar month.
  final double totalSpentMonth;

  /// Monthly budget cap (null if not configured).
  final double? totalBudgetMonth;

  /// `totalBudgetMonth - totalSpentMonth`, null if no budget is set.
  final double? remainingBudgetMonth;

  /// 0–100 utilisation percentage, null if no budget is set.
  final double? budgetUtilizationPct;

  /// Warning string from the backend when utilisation exceeds 80 % or 100 %.
  final String? thresholdAlert;

  /// Spending broken down by category, ordered by amount descending.
  final List<CategorySpending> categoryBreakdown;

  /// The most recent expense records (used by the transaction list).
  final List<Expense> recentTransactions;

  final int totalTransactionsCount;

  factory BudgetSummary.fromJson(Map<String, dynamic> json) {
    final rawCats = json['category_breakdown'] as List? ?? [];
    final rawTxs = json['recent_transactions'] as List? ?? [];
    return BudgetSummary(
      currentMonth: json['current_month']?.toString() ?? '',
      totalSpentMonth:
          (json['total_spending_month'] as num?)?.toDouble() ?? 0.0,
      totalBudgetMonth: json['total_budget_month'] != null
          ? (json['total_budget_month'] as num).toDouble()
          : null,
      remainingBudgetMonth: json['remaining_budget_month'] != null
          ? (json['remaining_budget_month'] as num).toDouble()
          : null,
      budgetUtilizationPct: json['budget_utilization_pct'] != null
          ? (json['budget_utilization_pct'] as num).toDouble()
          : null,
      thresholdAlert: json['threshold_alert']?.toString(),
      categoryBreakdown: rawCats
          .map((e) => CategorySpending.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      recentTransactions: rawTxs
          .map((e) => Expense.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      totalTransactionsCount:
          (json['total_transactions_count'] as int?) ?? 0,
    );
  }
}
