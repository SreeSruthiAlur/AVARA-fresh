import 'package:avara_astrology_trial/models/finance_model.dart';
import 'package:avara_astrology_trial/screens/finance_add_expense_screen.dart';
import 'package:avara_astrology_trial/services/avara_api_client.dart';
import 'package:avara_astrology_trial/services/finance_service.dart';
import 'package:avara_astrology_trial/theme/app_colors.dart';
import 'package:avara_astrology_trial/widgets/avara_surface_card.dart';
import 'package:flutter/material.dart';

/// AVARA Finance dashboard screen.
///
/// Fetches the full [BudgetSummary] on load and whenever the user pulls to
/// refresh. The screen is split into three visual sections:
///
/// 1. **Summary card** — total spending vs budget, utilisation bar.
/// 2. **Category breakdown** — horizontally scrolling pastel cards.
/// 3. **Recent transactions** — a scrollable list with delete support.
///
/// The FAB opens [FinanceAddExpenseScreen] and refreshes the dashboard on
/// return so new expenses appear immediately.
class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  late Future<BudgetSummary> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _load();
  }

  Future<BudgetSummary> _load() => FinanceService.instance.getDashboardSummary();

  Future<void> _refresh() async {
    setState(() => _dashboardFuture = _load());
    // await so RefreshIndicator spinner waits for the actual future
    await _dashboardFuture;
  }

  Future<void> _openAddExpense() async {
    final saved = await Navigator.of(context).push<Expense?>(
      MaterialPageRoute<Expense?>(
        builder: (_) => const FinanceAddExpenseScreen(),
      ),
    );
    if (saved != null && mounted) {
      // Inject the new expense into the current summary immediately so the
      // transaction list updates without a full-reload spinner.
      final current = await _dashboardFuture;
      final updatedTx = List<Expense>.of(current.recentTransactions)
        ..insert(0, saved);
      setState(() {
        _dashboardFuture = Future.value(BudgetSummary(
          currentMonth: current.currentMonth,
          totalSpentMonth: current.totalSpentMonth + saved.amount,
          totalBudgetMonth: current.totalBudgetMonth,
          remainingBudgetMonth: current.remainingBudgetMonth != null
              ? current.remainingBudgetMonth! - saved.amount
              : null,
          budgetUtilizationPct: current.budgetUtilizationPct,
          thresholdAlert: current.thresholdAlert,
          categoryBreakdown: current.categoryBreakdown,
          recentTransactions: updatedTx,
          totalTransactionsCount: current.totalTransactionsCount + 1,
        ));
      });
    }
    // Background refresh to sync accurate server aggregates.
    await _refresh();
  }

  Future<void> _deleteExpense(int id) async {
    try {
      await FinanceService.instance.deleteExpense(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        _snackBar('Expense deleted', isError: false),
      );
      await _refresh();
    } on AvaraApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(_snackBar(e.message));
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('AVARA Finance',
            style: Theme.of(context).textTheme.titleLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refresh,
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddExpense,
        backgroundColor: AppColors.deepNavy,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Expense',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: FutureBuilder<BudgetSummary>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _LoadingView();
          }
          if (snapshot.hasError) {
            final err = snapshot.error;
            final msg = err is AvaraApiException
                ? err.message
                : 'Could not load finance data.';
            return _ErrorView(message: msg, onRetry: _refresh);
          }
          final summary = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _refresh,
            color: AppColors.blue,
            child: _DashboardBody(
              summary: summary,
              onDeleteExpense: _deleteExpense,
            ),
          );
        },
      ),
    );
  }

  SnackBar _snackBar(String message, {bool isError = true}) {
    return SnackBar(
      content: Text(message),
      backgroundColor:
          isError ? const Color(0xFFD32F2F) : AppColors.green,
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}

// ---------------------------------------------------------------------------
// Dashboard body
// ---------------------------------------------------------------------------

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.summary,
    required this.onDeleteExpense,
  });

  final BudgetSummary summary;
  final Future<void> Function(int id) onDeleteExpense;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        _SummaryCard(summary: summary),
        if (summary.categoryBreakdown.isNotEmpty) ...[
          const SizedBox(height: 24),
          _SectionHeader(title: 'Spending Categories'),
          const SizedBox(height: 12),
          _CategoryRow(categories: summary.categoryBreakdown),
        ],
        const SizedBox(height: 24),
        _SectionHeader(
          title: 'Recent Transactions',
          trailing: summary.totalTransactionsCount > 0
              ? Text(
                  '${summary.totalTransactionsCount} total',
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(color: AppColors.secondaryText),
                )
              : null,
        ),
        const SizedBox(height: 12),
        if (summary.recentTransactions.isEmpty)
          _EmptyTransactions()
        else
          ...summary.recentTransactions.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _TransactionTile(
                expense: e,
                onDelete: () {
                  if (e.id != null) onDeleteExpense(e.id!);
                },
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Summary card — total spending + budget utilisation
// ---------------------------------------------------------------------------

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});
  final BudgetSummary summary;

  @override
  Widget build(BuildContext context) {
    final hasBudget = summary.totalBudgetMonth != null;
    final pct = summary.budgetUtilizationPct ?? 0;
    final isOverBudget = pct > 100;
    final isNearBudget = pct > 80 && pct <= 100;

    final barColor = isOverBudget
        ? const Color(0xFFD32F2F)
        : isNearBudget
            ? AppColors.orange
            : AppColors.green;

    return AvaraSurfaceCard(
      backgroundColor: AppColors.lightBlue,
      borderColor: null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(summary.currentMonth,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: AppColors.secondaryText)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${summary.totalSpentMonth.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.deepNavy,
                    ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'Total spending',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.secondaryText),
                ),
              ),
            ],
          ),
          if (hasBudget) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Budget: ₹${summary.totalBudgetMonth!.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                Text(
                  'Remaining: ₹${(summary.remainingBudgetMonth ?? 0).toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: isOverBudget
                            ? const Color(0xFFD32F2F)
                            : AppColors.green,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Utilisation progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (pct / 100).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation(barColor),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${pct.toStringAsFixed(1)}% of monthly limit used',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.secondaryText),
            ),
          ],
          if (summary.thresholdAlert != null) ...[
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.lightOrange,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.orange),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      size: 16, color: AppColors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      summary.thresholdAlert!,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.orange),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Category breakdown row
// ---------------------------------------------------------------------------

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.categories});
  final List<CategorySpending> categories;

  // Pastel backgrounds cycle through the AVARA surface palette.
  static const _backgrounds = [
    AppColors.lightGreen,
    AppColors.lightBlue,
    AppColors.lightOrange,
    AppColors.lightPink,
    AppColors.lightCyan,
    AppColors.lavender,
  ];

  static const _accents = [
    AppColors.green,
    AppColors.blue,
    AppColors.orange,
    AppColors.magentaPurple,
    AppColors.tealBlue,
    AppColors.violet,
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final cat = categories[i];
          final bg = _backgrounds[i % _backgrounds.length];
          final accent = _accents[i % _accents.length];
          return AvaraSurfaceCard(
            backgroundColor: bg,
            borderColor: null,
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: 120,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _iconForCategory(cat.category),
                          size: 16,
                          color: AppColors.white,
                        ),
                      ),
                      const Spacer(),
                      if (cat.isOverBudget)
                        const Icon(Icons.warning_amber_rounded,
                            size: 14, color: AppColors.orange),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    cat.category,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppColors.deepNavy,
                          fontWeight: FontWeight.w700,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₹${cat.amount.toStringAsFixed(0)}  (${cat.percentage.toStringAsFixed(0)}%)',
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _iconForCategory(String cat) {
    switch (cat.toLowerCase()) {
      case 'food':
        return Icons.restaurant_outlined;
      case 'transportation':
        return Icons.directions_bus_outlined;
      case 'shopping':
        return Icons.shopping_bag_outlined;
      case 'education':
        return Icons.school_outlined;
      case 'entertainment':
        return Icons.movie_outlined;
      case 'healthcare':
        return Icons.local_hospital_outlined;
      case 'bills':
        return Icons.receipt_long_outlined;
      default:
        return Icons.category_outlined;
    }
  }
}

// ---------------------------------------------------------------------------
// Transaction tile with swipe-to-delete
// ---------------------------------------------------------------------------

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.expense, required this.onDelete});
  final Expense expense;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('expense_${expense.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: Color(0xFFD32F2F)),
      ),
      confirmDismiss: (_) async => _confirmDelete(context),
      onDismissed: (_) => onDelete(),
      child: AvaraSurfaceCard(
        backgroundColor: AppColors.white,
        child: Row(
          children: [
            // Category icon badge
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.lightGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _categoryIcon(expense.category),
                size: 20,
                color: AppColors.green,
              ),
            ),
            const SizedBox(width: 12),
            // Description + date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.category,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  if (expense.description != null &&
                      expense.description!.isNotEmpty)
                    Text(
                      expense.description!,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 2),
                  Text(
                    '${expense.date}  ·  ${expense.paymentMethod}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.secondaryText),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Amount
            Text(
              '−₹${expense.amount.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: const Color(0xFFD32F2F),
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Expense'),
        content:
            const Text('Remove this transaction? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: Color(0xFFD32F2F))),
          ),
        ],
      ),
    );
  }

  IconData _categoryIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'food':
        return Icons.restaurant_outlined;
      case 'transportation':
        return Icons.directions_bus_outlined;
      case 'shopping':
        return Icons.shopping_bag_outlined;
      case 'education':
        return Icons.school_outlined;
      case 'entertainment':
        return Icons.movie_outlined;
      case 'healthcare':
        return Icons.local_hospital_outlined;
      case 'bills':
        return Icons.receipt_long_outlined;
      default:
        return Icons.category_outlined;
    }
  }
}

// ---------------------------------------------------------------------------
// Section header
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        ...?( trailing != null ? [trailing!] : null ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Empty / loading / error states
// ---------------------------------------------------------------------------

class _EmptyTransactions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AvaraSurfaceCard(
      backgroundColor: AppColors.white,
      child: Column(
        children: [
          const Icon(Icons.receipt_long_outlined,
              size: 48, color: AppColors.border),
          const SizedBox(height: 12),
          Text('No transactions yet',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            'Tap "Add Expense" to record your first transaction.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.secondaryText),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.blue),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined,
                size: 56, color: AppColors.border),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.secondaryText),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
