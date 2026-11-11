import 'package:avara_astrology_trial/models/health_model.dart';
import 'package:avara_astrology_trial/screens/health_add_entry_screen.dart';
import 'package:avara_astrology_trial/services/avara_api_client.dart';
import 'package:avara_astrology_trial/services/health_service.dart';
import 'package:avara_astrology_trial/theme/app_colors.dart';
import 'package:avara_astrology_trial/widgets/avara_surface_card.dart';
import 'package:flutter/material.dart';

/// AVARA Health & Wellness dashboard screen.
///
/// Layout:
/// 1. **4-metric summary grid** — streak, average mood, average sleep,
///    total activity — using pastel [AvaraSurfaceCard] tiles.
/// 2. **Daily check-in prompt** — tappable card that opens
///    [HealthAddEntryScreen].
/// 3. **Check-in history** — scrollable list with swipe-to-delete and
///    mood emoji leading icons.
class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  late Future<HealthSummary> _summaryFuture;

  @override
  void initState() {
    super.initState();
    _summaryFuture = HealthService.instance.getSummary();
  }

  Future<void> _refresh() async {
    setState(() =>
        _summaryFuture = HealthService.instance.getSummary());
    await _summaryFuture;
  }

  Future<void> _openAddEntry() async {
    final saved = await Navigator.of(context).push<WellnessEntry?>(
      MaterialPageRoute<WellnessEntry?>(
          builder: (_) => const HealthAddEntryScreen()),
    );
    if (saved != null && mounted) {
      final current = await _summaryFuture;
      final updated = List<WellnessEntry>.of(current.recentEntries)
        ..insert(0, saved);
      setState(() {
        _summaryFuture = Future.value(HealthSummary(
          totalEntries: current.totalEntries + 1,
          averageMoodScore: current.averageMoodScore,
          averageEnergyLevel: current.averageEnergyLevel,
          averageSleepHours: current.averageSleepHours,
          totalActivityMinutes: current.totalActivityMinutes +
              (saved.activityMinutes ?? 0),
          recentEntries: updated,
          // Recalculate streak locally from the updated entry list so the
          // tile updates immediately without waiting for the server refresh.
          wellnessStreakDays: _calcStreak(updated),
        ));
      });
    }
    await _refresh();
  }

  /// Counts how many consecutive calendar days (ending today or yesterday)
  /// have at least one wellness entry.
  ///
  /// Algorithm:
  /// 1. Parse each entry's `date` string → bare `DateTime` (no time component).
  /// 2. Deduplicate so multiple entries on the same calendar day count as one.
  /// 3. Sort descending (most recent first).
  /// 4. If the most recent day is neither today nor yesterday, the streak is 0
  ///    (the user has a gap before today).
  /// 5. Otherwise walk backward from `sorted.first`, incrementing streak for
  ///    each consecutive day found, stopping at the first missing day.
  static int _calcStreak(List<WellnessEntry> entries) {
    if (entries.isEmpty) return 0;

    // 1 & 2 — strip time, deduplicate.
    final days = <DateTime>{};
    for (final e in entries) {
      final parts = e.date.split('-');
      if (parts.length != 3) continue;
      final y = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final d = int.tryParse(parts[2]);
      if (y == null || m == null || d == null) continue;
      days.add(DateTime(y, m, d));
    }
    if (days.isEmpty) return 0;

    // 3 — sort descending.
    final sorted = days.toList()..sort((a, b) => b.compareTo(a));

    // 4 — anchor check: streak only continues to today if the latest entry
    //     is today or yesterday (allow yesterday for timezone edge cases).
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final mostRecent = sorted.first;

    if (mostRecent != today && mostRecent != yesterday) {
      return 0; // gap before today — no active streak
    }

    // 5 — count consecutive days backward from the most recent entry.
    int streak = 0;
    DateTime expected = mostRecent;
    for (final day in sorted) {
      if (day == expected) {
        streak++;
        expected = expected.subtract(const Duration(days: 1));
      } else {
        break; // gap found — streak ends
      }
    }
    return streak;
  }

  Future<void> _deleteEntry(int id) async {
    try {
      await HealthService.instance.deleteEntry(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(_snack(
          'Entry deleted', isError: false));
      await _refresh();
    } on AvaraApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(_snack(e.message));
    }
  }

  SnackBar _snack(String msg, {bool isError = true}) => SnackBar(
        content: Text(msg),
        backgroundColor:
            isError ? const Color(0xFFD32F2F) : AppColors.tealBlue,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      );

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('AVARA Health',
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
        onPressed: _openAddEntry,
        backgroundColor: AppColors.tealBlue,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add),
        label: const Text('Log Today',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: FutureBuilder<HealthSummary>(
        future: _summaryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.tealBlue));
          }
          if (snapshot.hasError) {
            final msg = snapshot.error is AvaraApiException
                ? (snapshot.error as AvaraApiException).message
                : 'Could not load wellness data.';
            return _ErrorView(message: msg, onRetry: _refresh);
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            color: AppColors.tealBlue,
            child: _HealthBody(
              summary: snapshot.data!,
              onAddEntry: _openAddEntry,
              onDeleteEntry: _deleteEntry,
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dashboard body
// ---------------------------------------------------------------------------

class _HealthBody extends StatelessWidget {
  const _HealthBody({
    required this.summary,
    required this.onAddEntry,
    required this.onDeleteEntry,
  });

  final HealthSummary summary;
  final VoidCallback onAddEntry;
  final Future<void> Function(int id) onDeleteEntry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        // 4-metric grid
        _MetricGrid(summary: summary),
        const SizedBox(height: 20),
        // Daily check-in prompt
        _CheckInPrompt(onTap: onAddEntry),
        const SizedBox(height: 24),
        // History
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Check-in History',
                style: Theme.of(context).textTheme.titleLarge),
            if (summary.totalEntries > 0)
              Text(
                '${summary.totalEntries} total',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: AppColors.secondaryText),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (summary.recentEntries.isEmpty)
          _EmptyEntries(onAdd: onAddEntry)
        else
          ...summary.recentEntries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _EntryTile(
                  entry: e,
                  onDelete: () {
                    if (e.id != null) onDeleteEntry(e.id!);
                  },
                ),
              )),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 4-metric summary grid
// ---------------------------------------------------------------------------

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.summary});
  final HealthSummary summary;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _MetricTile(
        label: 'Streak',
        value: '🔥 ${summary.wellnessStreakDays}',
        sub: 'days logged',
        bg: AppColors.lightOrange,
        accent: AppColors.orange,
      ),
      _MetricTile(
        label: 'Avg Mood',
        value: summary.averageMoodScore != null
            ? '${summary.averageMoodScore!.toStringAsFixed(1)}/5'
            : '—',
        sub: 'scale 1–5',
        bg: AppColors.lightPink,
        accent: AppColors.magentaPurple,
      ),
      _MetricTile(
        label: 'Avg Sleep',
        value: summary.averageSleepHours != null
            ? '${summary.averageSleepHours!.toStringAsFixed(1)}h'
            : '—',
        sub: 'hours/night',
        bg: AppColors.lightBlue,
        accent: AppColors.secondaryBlue,
      ),
      _MetricTile(
        label: 'Activity',
        value: '${summary.totalActivityMinutes}m',
        sub: 'total minutes',
        bg: AppColors.lightCyan,
        accent: AppColors.tealBlue,
      ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: tiles,
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.sub,
    required this.bg,
    required this.accent,
  });

  final String label;
  final String value;
  final String sub;
  final Color bg;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return AvaraSurfaceCard(
      backgroundColor: bg,
      borderColor: null,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: AppColors.secondaryText)),
          Text(value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w800,
                  )),
          Text(sub,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.secondaryText)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Check-in prompt
// ---------------------------------------------------------------------------

class _CheckInPrompt extends StatelessWidget {
  const _CheckInPrompt({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AvaraSurfaceCard(
      backgroundColor: AppColors.lightCyan,
      borderColor: null,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.tealBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.favorite,
                size: 22, color: AppColors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Record Today\'s Wellness',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 2),
                Text('How are you feeling physically and mentally today?',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.secondaryText)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right,
              color: AppColors.secondaryText, size: 20),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Entry tile
// ---------------------------------------------------------------------------

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry, required this.onDelete});
  final WellnessEntry entry;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('wellness_${entry.id}'),
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
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => onDelete(),
      child: AvaraSurfaceCard(
        backgroundColor: AppColors.white,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(moodEmoji(entry.moodScore),
                style: const TextStyle(fontSize: 30)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry.mood,
                          style: Theme.of(context).textTheme.titleSmall),
                      Text(entry.date,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.secondaryText)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _Badge(
                          'Energy ${entry.energyLevel}/5',
                          AppColors.lightBlue),
                      if (entry.sleepHours != null)
                        _Badge(
                            'Sleep ${entry.sleepHours!.toStringAsFixed(1)}h',
                            AppColors.lightCyan),
                      if (entry.activityMinutes != null)
                        _Badge(
                            'Activity ${entry.activityMinutes}m',
                            AppColors.lightGreen),
                    ],
                  ),
                  if (entry.notes != null && entry.notes!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      '"${entry.notes}"',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                              fontStyle: FontStyle.italic,
                              color: AppColors.secondaryText),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: const Text('Delete Entry'),
          content: const Text(
              'Remove this wellness record? This cannot be undone.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete',
                    style: TextStyle(color: Color(0xFFD32F2F)))),
          ],
        ),
      );
}

class _Badge extends StatelessWidget {
  const _Badge(this.label, this.bg);
  final String label;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: AppColors.deepNavy)),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty / error states
// ---------------------------------------------------------------------------

class _EmptyEntries extends StatelessWidget {
  const _EmptyEntries({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return AvaraSurfaceCard(
      backgroundColor: AppColors.white,
      child: Column(
        children: [
          const Icon(Icons.self_improvement,
              size: 48, color: AppColors.border),
          const SizedBox(height: 12),
          Text('No check-ins yet',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text('Tap "Log Today" to start tracking your wellness.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.secondaryText),
              textAlign: TextAlign.center),
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Log First Check-in'),
          ),
        ],
      ),
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
            Text(message,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.secondaryText)),
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
