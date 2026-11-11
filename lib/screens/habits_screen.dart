import 'package:avara_astrology_trial/models/habits_model.dart';
import 'package:avara_astrology_trial/services/avara_api_client.dart';
import 'package:avara_astrology_trial/services/habits_service.dart';
import 'package:avara_astrology_trial/theme/app_colors.dart';
import 'package:avara_astrology_trial/theme/app_theme.dart';
import 'package:avara_astrology_trial/widgets/avara_surface_card.dart';
import 'package:flutter/material.dart';

/// AVARA Habits & Goals screen — mirrors "08 — AVARA Habits & Goals" Figma.
///
/// Layout:
/// - Tab bar (Today / This Week / Goals)
/// - Date stepper
/// - Weekly progress bar + completion ratio
/// - Habit checklist tiles (tap to toggle; swipe-to-delete)
/// - Deep-navy "Add a Habit" FAB / bottom button
class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late Future<HabitsSummary> _summaryFuture;

  // Optimistic local state — toggled habits update instantly in the list.
  List<Habit> _habits = [];
  bool _dataLoaded = false;

  // Goals are stored locally until a dedicated backend route lands.
  final List<String> _goals = [];

  // Tracks which goal indices (by position in _goals) have been marked done
  // today. Resets when the screen is disposed or rebuilt from a full refresh.
  final Set<int> _goalDoneToday = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _summaryFuture = _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<HabitsSummary> _load() async {
    final summary = await HabitsService.instance.getSummary();
    if (mounted) {
      setState(() {
        _habits = List<Habit>.from(summary.habits);
        _dataLoaded = true;
      });
    }
    return summary;
  }

  Future<void> _refresh() async {
    setState(() => _summaryFuture = _load());
    await _summaryFuture;
  }

  // ---- Habit actions -------------------------------------------------------

  void _toggleHabit(int index) {
    // Optimistic update — reflect change immediately in the UI.
    setState(() => _habits[index] = _habits[index].copyWithToggle());

    final habit = _habits[index];
    if (habit.id != null) {
      HabitsService.instance.toggleHabit(habit.id!).catchError((Object e) {
        // 404 means the backend toggle route isn't live yet.
        // Keep the optimistic toggle in memory for this session — no rollback,
        // no visible error. Log to the debug console only.
        if (e is AvaraApiException && e.statusCode == 404) {
          print('TOGGLE HABIT [id=${habit.id}]: 404 — backend route pending, '
              'keeping optimistic local state.');
          return _habits[index]; // satisfy return type; state already updated
        }
        // Any other error: log, roll back, show snackbar.
        print('TOGGLE HABIT ERROR [id=${habit.id}]: $e');
        if (mounted) {
          setState(() => _habits[index] = _habits[index].copyWithToggle());
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Could not update habit: $e'),
            behavior: SnackBarBehavior.floating,
          ));
        }
        return _habits[index];
      });
    } else {
      // habit.id is null — optimistic toggle already applied above.
      print('TOGGLE HABIT: id is null — local-only toggle (backend route pending).');
    }
  }

  Future<void> _deleteHabit(int index) async {
    final habit = _habits[index];
    setState(() => _habits.removeAt(index));
    if (habit.id != null) {
      try {
        await HabitsService.instance.deleteHabit(habit.id!);
      } on AvaraApiException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(e.message)));
          await _refresh();
        }
      }
    }
  }

  void _showAddGoalSheet() {
    final controller = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        margin: const EdgeInsets.only(top: 80),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20, right: 20, top: 20,
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('New Goal',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Goal description',
                    hintText: 'e.g. Sleep before 11 PM every day',
                    prefixIcon: Icon(Icons.flag_outlined,
                        color: AppColors.secondaryText),
                  ),
                  onSubmitted: (_) {
                    final text = controller.text.trim();
                    if (text.isEmpty) return;
                    Navigator.of(sheetCtx).pop();
                    // Inject into local state immediately — no backend round-trip needed.
                    setState(() => _goals.add(text));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Goal added'),
                      behavior: SnackBarBehavior.floating,
                    ));
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: AppTheme.buttonHeight,
                  child: ElevatedButton(
                    onPressed: () {
                      final text = controller.text.trim();
                      if (text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Goal description cannot be empty.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }
                      Navigator.of(sheetCtx).pop();
                      // Inject immediately into local UI state + call setState.
                      setState(() => _goals.add(text));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Goal added'),
                        behavior: SnackBarBehavior.floating,
                      ));
                    },
                    child: const Text('Save Goal'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).whenComplete(() => controller.dispose());
  }

  void _toggleGoalToday(int goalIndex) {
    setState(() {
      if (_goalDoneToday.contains(goalIndex)) {
        _goalDoneToday.remove(goalIndex);
      } else {
        _goalDoneToday.add(goalIndex);
      }
    });
  }

  void _deleteGoal(int index) {
    setState(() => _goals.removeAt(index));
  }

  void _showAddHabitSheet() {    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddHabitSheet(
        onAdded: (habit) async {
          try {
            final saved = await HabitsService.instance.addHabit(habit);
            if (mounted) setState(() => _habits.add(saved));
          } on AvaraApiException {
            // If the backend CRUD route isn't live yet, show the habit locally.
            if (mounted) setState(() => _habits.add(habit));
          }
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title:
            Text('AVARA Habits', style: Theme.of(context).textTheme.titleLarge),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.deepNavy,
          labelColor: AppColors.deepNavy,
          unselectedLabelColor: AppColors.secondaryText,
          tabs: const [
            Tab(text: 'Today'),
            Tab(text: 'This Week'),
            Tab(text: 'Goals'),
          ],
        ),
      ),
      body: FutureBuilder<HabitsSummary>(
        future: _summaryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !_dataLoaded) {
            return const Center(
                child:
                    CircularProgressIndicator(color: AppColors.deepNavy));
          }
          if (snapshot.hasError && !_dataLoaded) {
            final msg = snapshot.error is AvaraApiException
                ? (snapshot.error as AvaraApiException).message
                : 'Could not load habits.';
            return _ErrorView(message: msg, onRetry: _refresh);
          }

          final summary = snapshot.data;
          return RefreshIndicator(
            onRefresh: _refresh,
            color: AppColors.deepNavy,
            child: TabBarView(
              controller: _tabController,
              children: [
                // Today tab — habits + goals merged
                _TodayTab(
                  summary: summary,
                  habits: _habits,
                  onToggle: _toggleHabit,
                  onDelete: _deleteHabit,
                  goals: _goals,
                  goalDoneToday: _goalDoneToday,
                  onToggleGoal: _toggleGoalToday,
                ),
                // This Week — static placeholder until weekly rollup lands
                _ComingSoonTab(label: 'Weekly view'),
                // Goals tab — functional create/delete list
                _GoalsTab(
                  goals: _goals,
                  onAdd: _showAddGoalSheet,
                  onDelete: _deleteGoal,
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            height: AppTheme.buttonHeight,
            child: ElevatedButton.icon(
              onPressed: _showAddHabitSheet,
              icon: const Icon(Icons.add),
              label: const Text('Add a Habit'),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Today tab
// ---------------------------------------------------------------------------

class _TodayTab extends StatefulWidget {
  const _TodayTab({
    required this.summary,
    required this.habits,
    required this.onToggle,
    required this.onDelete,
    required this.goals,
    required this.goalDoneToday,
    required this.onToggleGoal,
  });

  final HabitsSummary? summary;
  final List<Habit> habits;
  final void Function(int index) onToggle;
  final Future<void> Function(int index) onDelete;
  final List<String> goals;
  final Set<int> goalDoneToday;
  final void Function(int goalIndex) onToggleGoal;

  @override
  State<_TodayTab> createState() => _TodayTabState();
}

class _TodayTabState extends State<_TodayTab> {
  // The date whose habits/goals are shown. Starts at today; tapping the
  // chevrons shifts it backward or forward by one day.
  DateTime _selectedDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  void _shiftDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
  }

  @override
  Widget build(BuildContext context) {
    final dayName = [
      'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
    ][_selectedDate.weekday - 1];
    final dateLabel =
        '$dayName, ${_selectedDate.day} ${_monthName(_selectedDate.month)} ${_selectedDate.year}';

    final completed = widget.habits.where((h) => h.isCompletedToday).length
        + widget.goalDoneToday.length;
    final total = widget.habits.length + widget.goals.length;
    final progress = total > 0 ? completed / total : 0.0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        // Date stepper row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => _shiftDate(-1),
              child: const Icon(Icons.chevron_left,
                  color: AppColors.secondaryText),
            ),
            const SizedBox(width: 8),
            Text(dateLabel,
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _shiftDate(1),
              child: const Icon(Icons.chevron_right,
                  color: AppColors.secondaryText),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Progress card
        AvaraSurfaceCard(
          backgroundColor: AppColors.lavender,
          borderColor: null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your weekly progress ✦',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(
                '$completed of $total habits completed today',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.secondaryText),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: AppColors.border,
                  valueColor: const AlwaysStoppedAnimation(AppColors.deepNavy),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Habit list + merged goals
        if (widget.habits.isEmpty && widget.goals.isEmpty)
          _EmptyHabits()
        else ...[
          if (widget.habits.isNotEmpty) ...[
            ...widget.habits.asMap().entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _HabitTile(
                      habit: e.value,
                      onToggle: () => widget.onToggle(e.key),
                      onDelete: () => widget.onDelete(e.key),
                    ),
                  ),
                ),
          ],
          if (widget.goals.isNotEmpty) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                'Goals',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondaryText,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            ...widget.goals.asMap().entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _GoalTodayTile(
                      title: e.value,
                      isDone: widget.goalDoneToday.contains(e.key),
                      onToggle: () => widget.onToggleGoal(e.key),
                    ),
                  ),
                ),
          ],
        ],
      ],
    );
  }

  String _monthName(int m) => const [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m];
}
// ---------------------------------------------------------------------------
// Habit tile
// ---------------------------------------------------------------------------

class _HabitTile extends StatelessWidget {
  const _HabitTile({
    required this.habit,
    required this.onToggle,
    required this.onDelete,
  });

  final Habit habit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('habit_${habit.id ?? habit.title}'),
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
      onDismissed: (_) => onDelete(),
      child: AvaraSurfaceCard(
        backgroundColor: AppColors.white,
        child: Row(
          children: [
            // Completion toggle
            GestureDetector(
              onTap: onToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: habit.isCompletedToday
                      ? AppColors.green
                      : AppColors.background,
                  border: Border.all(
                    color: habit.isCompletedToday
                        ? AppColors.green
                        : AppColors.border,
                    width: 2,
                  ),
                ),
                child: habit.isCompletedToday
                    ? const Icon(Icons.check, size: 16, color: AppColors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          decoration: habit.isCompletedToday
                              ? TextDecoration.lineThrough
                              : null,
                          color: habit.isCompletedToday
                              ? AppColors.secondaryText
                              : AppColors.deepNavy,
                        ),
                  ),
                  if (habit.currentStreak > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      '🔥 ${habit.currentStreak}-day streak',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.orange),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Frequency badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.lightBlue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                habit.frequency,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: AppColors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Goal tile for the Today view (same toggle UI as HabitTile, no delete)
// ---------------------------------------------------------------------------

class _GoalTodayTile extends StatelessWidget {
  const _GoalTodayTile({
    required this.title,
    required this.isDone,
    required this.onToggle,
  });

  final String title;
  final bool isDone;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return AvaraSurfaceCard(
      backgroundColor: AppColors.white,
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone ? AppColors.violet : AppColors.background,
                border: Border.all(
                  color: isDone ? AppColors.violet : AppColors.border,
                  width: 2,
                ),
              ),
              child: isDone
                  ? const Icon(Icons.check, size: 16, color: AppColors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    decoration:
                        isDone ? TextDecoration.lineThrough : null,
                    color: isDone
                        ? AppColors.secondaryText
                        : AppColors.deepNavy,
                  ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.lightPink,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'goal',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: AppColors.violet),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Add habit bottom sheet
// ---------------------------------------------------------------------------

class _AddHabitSheet extends StatefulWidget {
  const _AddHabitSheet({required this.onAdded});
  final void Function(Habit habit) onAdded;

  @override
  State<_AddHabitSheet> createState() => _AddHabitSheetState();
}

class _AddHabitSheetState extends State<_AddHabitSheet> {
  final _titleController = TextEditingController();
  String _frequency = 'daily';
  int _targetDays = 7;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Habit name cannot be empty.'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    Navigator.of(context).pop();
    widget.onAdded(Habit(
      title: title,
      frequency: _frequency,
      targetDaysPerWeek: _targetDays,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 80),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('New Habit',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Habit name',
                  hintText: 'e.g. Read for 20 minutes',
                  prefixIcon: Icon(Icons.edit_outlined,
                      color: AppColors.secondaryText),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _frequency,
                decoration: const InputDecoration(labelText: 'Frequency'),
                items: const [
                  DropdownMenuItem(value: 'daily', child: Text('Daily')),
                  DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _frequency = v);
                },
              ),
              const SizedBox(height: 12),
              Text('Target: $_targetDays days/week',
                  style: Theme.of(context).textTheme.labelLarge),
              Slider(
                value: _targetDays.toDouble(),
                min: 1, max: 7, divisions: 6,
                activeColor: AppColors.deepNavy,
                inactiveColor: AppColors.border,
                onChanged: (v) => setState(() => _targetDays = v.toInt()),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: AppTheme.buttonHeight,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Save Habit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty / error / placeholder states
// ---------------------------------------------------------------------------

class _EmptyHabits extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AvaraSurfaceCard(
      backgroundColor: AppColors.white,
      child: Column(
        children: [
          const Icon(Icons.track_changes, size: 48, color: AppColors.border),
          const SizedBox(height: 12),
          Text('No habits yet',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text('Tap "Add a Habit" to start building consistency.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.secondaryText),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Goals tab — create, list, delete goals
// ---------------------------------------------------------------------------

class _GoalsTab extends StatelessWidget {
  const _GoalsTab({
    required this.goals,
    required this.onAdd,
    required this.onDelete,
  });

  final List<String> goals;
  final VoidCallback onAdd;
  final void Function(int index) onDelete;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('My Goals',
                style: Theme.of(context).textTheme.titleLarge),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Goal'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (goals.isEmpty)
          AvaraSurfaceCard(
            backgroundColor: AppColors.white,
            child: Column(
              children: [
                const Icon(Icons.flag_outlined,
                    size: 48, color: AppColors.border),
                const SizedBox(height: 12),
                Text('No goals yet',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text('Tap "Add Goal" to set your first intention.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.secondaryText),
                    textAlign: TextAlign.center),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add First Goal'),
                ),
              ],
            ),
          )
        else
          ...goals.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Dismissible(
                  key: Key('goal_${e.key}_${e.value}'),
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
                  onDismissed: (_) => onDelete(e.key),
                  child: AvaraSurfaceCard(
                    backgroundColor: AppColors.white,
                    child: Row(
                      children: [
                        const Icon(Icons.flag_rounded,
                            color: AppColors.violet, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(e.value,
                              style:
                                  Theme.of(context).textTheme.bodyLarge),
                        ),
                      ],
                    ),
                  ),
                ),
              )),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Placeholder / coming-soon tab
// ---------------------------------------------------------------------------

class _ComingSoonTab extends StatelessWidget {
  const _ComingSoonTab({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.calendar_today_outlined,
              size: 56, color: AppColors.border),
          const SizedBox(height: 16),
          Text(label, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('Coming soon',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.secondaryText)),
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
