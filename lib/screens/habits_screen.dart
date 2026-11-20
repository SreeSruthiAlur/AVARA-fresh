import 'package:avara_astrology_trial/models/habits_model.dart';
import 'package:avara_astrology_trial/services/age_profile_service.dart';
import 'package:avara_astrology_trial/services/app_language_service.dart';
import 'package:avara_astrology_trial/services/avara_api_client.dart';
import 'package:avara_astrology_trial/services/habits_service.dart';
import 'package:avara_astrology_trial/theme/app_colors.dart';
import 'package:avara_astrology_trial/theme/app_theme.dart';
import 'package:avara_astrology_trial/widgets/avara_surface_card.dart';
import 'package:avara_astrology_trial/widgets/creative_graphics.dart';
import 'package:avara_astrology_trial/widgets/fact_popup.dart';
import 'package:avara_astrology_trial/widgets/language_selector_sheet.dart';
import 'package:avara_astrology_trial/widgets/voice_input_button.dart';
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
        if (_habits.isEmpty) {
          _habits = [
            const Habit(
              title: '10 PM Digital Sunset',
              frequency: 'daily',
              currentStreak: 4,
              isCompletedToday: false,
              originalStruggle: 'Late night phone scrolling in bed',
              upgradedHabit: 'Put phone outside bedroom at 10 PM & read 5 pages',
              scientificFact: 'Cutting blue light 30 min before bed increases deep delta sleep by 38%.',
              neuralScore: 68,
              upgradeTier: 2,
            ),
            const Habit(
              title: 'Morning Sun & Hydration',
              frequency: 'daily',
              currentStreak: 6,
              isCompletedToday: true,
              originalStruggle: 'Hitting snooze 3 times & waking sluggish',
              upgradedHabit: 'Drink 1 glass of water & look at natural sky light for 5 min',
              scientificFact: 'Morning photons on retinal melanopsin trigger natural cortisol wakefulness.',
              neuralScore: 84,
              upgradeTier: 3,
            ),
            const Habit(
              title: '25-Min Deep Focus Sprint',
              frequency: 'daily',
              currentStreak: 2,
              isCompletedToday: false,
              originalStruggle: 'Procrastinating on important study/work',
              upgradedHabit: 'Set timer for 25 mins of deep focus with phone on silent',
              scientificFact: 'Cognitive load theory shows 25 min sprints avoid prefrontal fatigue.',
              neuralScore: 55,
              upgradeTier: 1,
            ),
          ];
        }
        _dataLoaded = true;
      });
    }
    return summary;
  }

  void _showHabitOptimizerSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _HabitOptimizerSheet(
        onAdopt: (newHabit) {
          setState(() => _habits.insert(0, newHabit));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎉 Upgraded habit adopted: "${newHabit.title}"'),
              backgroundColor: const Color(0xFF6C5CE7),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
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
    final tr = AppLanguageService.instance.tr;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(tr('habits_title'),
            style: Theme.of(context).textTheme.titleLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.lightbulb_outline_rounded, color: AppColors.blue),
            tooltip: 'Samskaras & Neuroplasticity Facts',
            onPressed: () => FactPopup.show(context, category: 'habits'),
          ),
          IconButton(
            icon: const Icon(Icons.language_rounded),
            onPressed: () => LanguageSelectorSheet.show(context),
            tooltip: tr('lang_switch_title'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.deepNavy,
          labelColor: AppColors.deepNavy,
          unselectedLabelColor: AppColors.secondaryText,
          tabs: [
            Tab(text: tr('habits_tab_today')),
            Tab(text: tr('habits_tab_week')),
            Tab(text: tr('habits_tab_goals')),
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
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showAddHabitSheet,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add Simple'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _showHabitOptimizerSheet,
                  icon: const Icon(Icons.bolt_rounded, size: 20),
                  label: const Text('⚡ Transform a Habit', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C5CE7),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
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
        const SizedBox(height: 16),
        // Creative Graphic: Neural Synapse Habit Formation Network
        NeuralSynapseGrowthMap(
          neuralScore: widget.habits.isEmpty
              ? 50
              : (widget.habits.fold<int>(0, (sum, h) => sum + (h.neuralScore ?? 45)) ~/ widget.habits.length),
          habitCount: widget.habits.length,
          activeStreak: widget.habits.fold<int>(0, (maxStreak, h) => h.currentStreak > maxStreak ? h.currentStreak : maxStreak),
        ),
        const SizedBox(height: 18),
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
                          fontWeight: FontWeight.bold,
                          decoration: habit.isCompletedToday
                              ? TextDecoration.lineThrough
                              : null,
                          color: habit.isCompletedToday
                              ? AppColors.secondaryText
                              : AppColors.deepNavy,
                        ),
                  ),
                  if (habit.originalStruggle != null && habit.upgradedHabit != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.arrow_downward_rounded, size: 12, color: Colors.red),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Old Habit: ${habit.originalStruggle}',
                                  style: const TextStyle(fontSize: 10.5, color: Colors.red, fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.arrow_upward_rounded, size: 12, color: Color(0xFF00B894)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Better Upgrade: ${habit.upgradedHabit}',
                                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF00B894), fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (habit.neuralScore != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: (habit.neuralScore! / 100).clamp(0.05, 1.0),
                              minHeight: 4,
                              backgroundColor: AppColors.border,
                              valueColor: const AlwaysStoppedAnimation(Color(0xFF6C5CE7)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${habit.neuralScore}% neural pathway',
                          style: const TextStyle(fontSize: 10, color: AppColors.secondaryText),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (habit.currentStreak > 0)
                        Text(
                          '🔥 ${habit.currentStreak}d streak',
                          style: const TextStyle(fontSize: 11, color: AppColors.orange, fontWeight: FontWeight.bold),
                        ),
                      if (habit.scientificFact != null) ...[
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () => FactPopup.show(context, category: 'habits'),
                          child: const Text(
                            '💡 Why it works',
                            style: TextStyle(fontSize: 11, color: AppColors.blue, fontWeight: FontWeight.w600, decoration: TextDecoration.underline),
                          ),
                        ),
                      ],
                    ],
                  ),
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
                decoration: InputDecoration(
                  labelText: AppLanguageService.instance.tr('habits_name'),
                  hintText: AppLanguageService.instance.tr('habits_name_hint'),
                  prefixIcon: const Icon(Icons.edit_outlined,
                      color: AppColors.secondaryText),
                  suffixIcon: VoiceInputButton(
                    controller: _titleController,
                    size: 20,
                  ),
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

// ---------------------------------------------------------------------------
// Habit Optimizer & Transformation Sheet (Point 8)
// ---------------------------------------------------------------------------

class _HabitOptimizerSheet extends StatefulWidget {
  const _HabitOptimizerSheet({required this.onAdopt});
  final void Function(Habit habit) onAdopt;

  @override
  State<_HabitOptimizerSheet> createState() => _HabitOptimizerSheetState();
}

class _HabitOptimizerSheetState extends State<_HabitOptimizerSheet> {
  final _inputController = TextEditingController();
  int _selectedPresetIndex = -1;
  int _selectedTier = 2;

  List<Map<String, dynamic>> get _presets {
    final group = AgeProfileService.instance.ageGroup;
    switch (group) {
      case AgeGroup.youth:
        return const [
          {
            'struggle': 'Endless phone scrolling & gaming till 1 AM',
            'title': '10:30 PM Digital Sunset & Mind Reset',
            'tier1': 'Charge phone away from the bedside table',
            'tier2': 'Turn off notifications 30 min before bed with soft ambient sound',
            'tier3': 'Complete 8 hours restorative sleep and wake up refreshed',
            'fact': 'Prefrontal cortex myelination accelerates during unhindered deep sleep cycles.',
            'neural': 75,
          },
          {
            'struggle': 'Procrastinating on exam revision & study',
            'title': '25-Min Pomodoro Study Sprint',
            'tier1': 'Open study material and focus for just 5 minutes',
            'tier2': 'Complete one 25-minute Pomodoro sprint with phone out of room',
            'tier3': 'Two 45-minute deep focus study blocks with active recall',
            'fact': 'Short interval bursts prevent cognitive fatigue and increase hippocampus retention by 40%.',
            'neural': 84,
          },
          {
            'struggle': 'Exam anxiety & morning panic',
            'title': '5-Min Alpha Breath & Mental Calm',
            'tier1': 'Take 3 deep belly breaths before touching study desk',
            'tier2': 'Practice 5 min box breathing and recite 1 positive affirmation',
            'tier3': 'Calm pre-exam morning routine with balanced hydration and focus',
            'fact': 'Slow diaphragmatic exhalations stimulate the vagus nerve, reducing exam cortisol.',
            'neural': 68,
          },
        ];

      case AgeGroup.adult:
        return const [
          {
            'struggle': 'Workplace stress & evening mental fatigue',
            'title': 'Evening Mindful Decompression',
            'tier1': 'Close work laptop and take 5 deep cleansing breaths',
            'tier2': '15-minute screen-free transition walk after work hours',
            'tier3': 'Total boundary between career execution and peaceful family recharge',
            'fact': 'A clear shutdown ritual allows default mode network recovery and lowers burnout risk.',
            'neural': 80,
          },
          {
            'struggle': 'Impulsive online purchases & retail spending',
            'title': '24-Hour Cooling Window',
            'tier1': 'Move impulse items to wishlist instead of instant checkout',
            'tier2': 'Wait 24 hours and review monthly investment targets first',
            'tier3': 'Disciplined wealth growth: 20% automated investment on payday',
            'fact': 'Delaying purchase gratification lets dopamine settle, cutting impulse spending by 68%.',
            'neural': 74,
          },
          {
            'struggle': 'Hitting snooze 3 times & morning brain fog',
            'title': 'Brahma Muhurtha Solar Awakening',
            'tier1': 'Place alarm across the room so you must stand up',
            'tier2': 'Drink 500ml water and view natural morning sunlight for 10 min',
            'tier3': 'Consistent 6 AM wakefulness with 20 min morning focus planning',
            'fact': 'Sunlight hitting retinal ganglion cells synchronizes master circadian clock within 10 minutes.',
            'neural': 86,
          },
        ];

      case AgeGroup.senior:
        return const [
          {
            'struggle': 'Restless sleep & waking up at odd hours',
            'title': 'Ayurvedic Evening Warmth & Quietude',
            'tier1': 'Sip warm water or herbal infusion 1 hour before sleeping',
            'tier2': 'Gentle 10-minute quiet meditation or peaceful sloka chanting',
            'tier3': 'Deep uninterrupted 7-hour peaceful sleep with calm mind',
            'fact': 'Warm herbal hydration calms nervous system vata dosha, facilitating deep sleep.',
            'neural': 78,
          },
          {
            'struggle': 'Joint stiffness & sluggish daytime digestion',
            'title': 'Brahma Muhurtha Gentle Stretch & Stride',
            'tier1': 'Drink 1 glass of warm water upon waking seated comfortably',
            'tier2': '15-minute gentle morning walk in pleasant fresh air',
            'tier3': 'Daily 30-minute joint mobilization and mindful breathing routine',
            'fact': 'Gentle morning movement lubricates synovial joint fluid and activates digestion.',
            'neural': 88,
          },
          {
            'struggle': 'Constant worrying about family & grandchildren',
            'title': 'Santosha & Prayer Sanctuary',
            'tier1': 'Pause and take 3 gentle conscious breaths when worry arises',
            'tier2': 'Dedicate 10 minutes to peaceful prayer and sending loving blessings',
            'tier3': 'Rooted contentment (Santosha), trusting divine timing and harmony',
            'fact': 'Cultivating gratitude and blessings lowers resting heart rate and boosts emotional immunity.',
            'neural': 82,
          },
        ];
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeData = _selectedPresetIndex >= 0 ? _presets[_selectedPresetIndex] : null;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.bolt_rounded, color: Color(0xFF6C5CE7), size: 24),
                SizedBox(width: 8),
                Text(
                  'Self-Help Habit Transformer',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.deepNavy),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Tell us your struggle or current bad habit — AVARA will optimize it into a better daily habit.',
              style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
            ),
            const SizedBox(height: 16),
            const Text('Choose a Common Struggle to Transform:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.deepNavy)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(_presets.length, (i) {
                final isSel = _selectedPresetIndex == i;
                return ChoiceChip(
                  label: Text(_presets[i]['struggle'] as String, style: TextStyle(fontSize: 11, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                  selected: isSel,
                  selectedColor: const Color(0xFF6C5CE7).withValues(alpha: 0.15),
                  onSelected: (val) {
                    setState(() {
                      _selectedPresetIndex = val ? i : -1;
                      if (val) _inputController.text = _presets[i]['struggle'] as String;
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _inputController,
              decoration: InputDecoration(
                labelText: 'Or describe your struggle in your words',
                hintText: 'e.g. Eating junk food at 4 PM...',
                prefixIcon: const Icon(Icons.edit_note_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                isDense: true,
              ),
            ),
            const SizedBox(height: 16),
            if (activeData != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F0FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFD6C9FF)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: Color(0xFF6C5CE7), size: 18),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Optimized Upgrade: ${activeData['title']}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF4834D4)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _tierChoice(1, 'Level 1: Micro-Step', activeData['tier1'] as String),
                    const SizedBox(height: 6),
                    _tierChoice(2, 'Level 2: Progressive Habit', activeData['tier2'] as String),
                    const SizedBox(height: 6),
                    _tierChoice(3, 'Level 3: Master Identity', activeData['tier3'] as String),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.science_rounded, size: 14, color: Color(0xFF00B894)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            activeData['fact'] as String,
                            style: const TextStyle(fontSize: 10.5, fontStyle: FontStyle.italic, color: AppColors.secondaryText),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            ElevatedButton(
              onPressed: () {
                final struggle = _inputController.text.trim();
                if (struggle.isEmpty && activeData == null) return;

                final title = activeData != null ? activeData['title'] as String : 'Mindful $struggle Transformation';
                final upgraded = activeData != null
                    ? (_selectedTier == 1 ? activeData['tier1'] : (_selectedTier == 2 ? activeData['tier2'] : activeData['tier3'])) as String
                    : 'Practice 2-minute mindful pause whenever the urge to $struggle arises';
                final fact = activeData != null ? activeData['fact'] as String : 'Rewiring habits requires replacing old cues with positive micro-rewards.';
                final neural = activeData != null ? activeData['neural'] as int : 60;

                widget.onAdopt(
                  Habit(
                    title: title,
                    frequency: 'daily',
                    currentStreak: 1,
                    isCompletedToday: false,
                    originalStruggle: struggle.isNotEmpty ? struggle : (activeData?['struggle'] as String? ?? 'Old habit'),
                    upgradedHabit: upgraded,
                    scientificFact: fact,
                    neuralScore: neural,
                    upgradeTier: _selectedTier,
                  ),
                );
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C5CE7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Adopt this Upgraded Habit', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tierChoice(int tier, String label, String text) {
    final isSel = _selectedTier == tier;
    return GestureDetector(
      onTap: () => setState(() => _selectedTier = tier),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSel ? Colors.white : Colors.white60,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSel ? const Color(0xFF6C5CE7) : AppColors.border, width: isSel ? 1.5 : 1.0),
        ),
        child: Row(
          children: [
            Icon(isSel ? Icons.radio_button_checked : Icons.radio_button_off, size: 16, color: isSel ? const Color(0xFF6C5CE7) : AppColors.secondaryText),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: isSel ? const Color(0xFF4834D4) : AppColors.secondaryText)),
                  Text(text, style: const TextStyle(fontSize: 11.5, color: AppColors.deepNavy, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
