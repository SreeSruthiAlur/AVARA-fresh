import 'package:avara_astrology_trial/models/health_model.dart';
import 'package:avara_astrology_trial/services/avara_api_client.dart';
import 'package:avara_astrology_trial/services/health_service.dart';
import 'package:avara_astrology_trial/theme/app_colors.dart';
import 'package:avara_astrology_trial/theme/app_theme.dart';
import 'package:avara_astrology_trial/widgets/avara_surface_card.dart';
import 'package:flutter/material.dart';

/// Add-wellness-entry form screen.
///
/// Collects mood, energy, sleep, activity, goals, and notes.
/// On success shows a SnackBar and pops with `true` so [HealthScreen]
/// knows to refresh.
class HealthAddEntryScreen extends StatefulWidget {
  const HealthAddEntryScreen({super.key});

  @override
  State<HealthAddEntryScreen> createState() => _HealthAddEntryScreenState();
}

class _HealthAddEntryScreenState extends State<HealthAddEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _sleepController = TextEditingController();
  final _activityController = TextEditingController();
  final _goalsController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedMood = kMoodLabels[1]; // 'Good'
  int _moodScore = 4;
  int _energyLevel = 3;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void dispose() {
    _sleepController.dispose();
    _activityController.dispose();
    _goalsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Date picker
  // ---------------------------------------------------------------------------

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context)
              .colorScheme
              .copyWith(primary: AppColors.deepNavy),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  String get _formattedDate =>
      '${_selectedDate.year}-'
      '${_selectedDate.month.toString().padLeft(2, '0')}-'
      '${_selectedDate.day.toString().padLeft(2, '0')}';

  // ---------------------------------------------------------------------------
  // Submit
  // ---------------------------------------------------------------------------

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_isLoading) return;

    setState(() => _isLoading = true);

    final entry = WellnessEntry(
      date: _formattedDate,
      mood: _selectedMood,
      moodScore: _moodScore,
      energyLevel: _energyLevel,
      sleepHours: _sleepController.text.trim().isNotEmpty
          ? double.tryParse(_sleepController.text.trim())
          : null,
      activityMinutes: _activityController.text.trim().isNotEmpty
          ? int.tryParse(_activityController.text.trim())
          : null,
      wellnessGoals: _goalsController.text.trim().isNotEmpty
          ? _goalsController.text.trim()
          : null,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
    );

    try {
      await HealthService.instance.addEntry(entry);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Wellness check-in recorded'),
        backgroundColor: AppColors.tealBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      // Pop with the saved entry so HealthScreen can inject it
      // into the list immediately (no spinner flash).
      Navigator.of(context).pop(entry);
    } on AvaraApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message),
        backgroundColor: const Color(0xFFD32F2F),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Unexpected error. Please try again.'),
        backgroundColor: Color(0xFFD32F2F),
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
        title: Text('Log Wellness',
            style: Theme.of(context).textTheme.titleLarge),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: AppColors.deepNavy),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AvaraSurfaceCard(
                  backgroundColor: AppColors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date
                      InkWell(
                        onTap: _pickDate,
                        borderRadius:
                            BorderRadius.circular(AppTheme.buttonRadius),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date',
                            prefixIcon: Icon(Icons.calendar_today_outlined,
                                color: AppColors.secondaryText),
                          ),
                          child: Text(_formattedDate,
                              style: Theme.of(context).textTheme.bodyMedium),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Mood picker
                      _SectionLabel(label: 'How are you feeling?'),
                      const SizedBox(height: 10),
                      _MoodSelector(
                        selected: _selectedMood,
                        onChanged: (mood, score) => setState(() {
                          _selectedMood = mood;
                          _moodScore = score;
                        }),
                      ),
                      const SizedBox(height: 20),
                      // Energy level slider
                      _SectionLabel(
                          label:
                              'Energy Level — $_energyLevel / 5'),
                      Slider(
                        value: _energyLevel.toDouble(),
                        min: 1,
                        max: 5,
                        divisions: 4,
                        activeColor: AppColors.tealBlue,
                        inactiveColor: AppColors.border,
                        onChanged: (v) =>
                            setState(() => _energyLevel = v.toInt()),
                      ),
                      const SizedBox(height: 8),
                      // Sleep hours
                      TextFormField(
                        controller: _sleepController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Sleep Hours (optional)',
                          hintText: 'e.g. 7.5',
                          prefixIcon: Icon(Icons.bedtime_outlined,
                              color: AppColors.secondaryText),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          final n = double.tryParse(v.trim());
                          if (n == null || n < 0 || n > 24) {
                            return 'Enter a value between 0 and 24';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Activity minutes
                      TextFormField(
                        controller: _activityController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Activity Minutes (optional)',
                          hintText: 'e.g. 30',
                          prefixIcon: Icon(Icons.directions_walk_outlined,
                              color: AppColors.secondaryText),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          final n = int.tryParse(v.trim());
                          if (n == null || n < 0) {
                            return 'Enter a valid number of minutes';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Wellness goal
                      TextFormField(
                        controller: _goalsController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Wellness Goal (optional)',
                          hintText: 'e.g. Drink 2L water',
                          prefixIcon: Icon(Icons.track_changes,
                              color: AppColors.secondaryText),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Notes
                      TextFormField(
                        controller: _notesController,
                        maxLines: 3,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'Notes / Reflection (optional)',
                          hintText: 'How was your day?',
                          prefixIcon: Icon(Icons.notes_outlined,
                              color: AppColors.secondaryText),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  height: AppTheme.buttonHeight,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Text('Save Check-in'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mood selector widget
// ---------------------------------------------------------------------------

class _MoodSelector extends StatelessWidget {
  const _MoodSelector({required this.selected, required this.onChanged});

  final String selected;
  final void Function(String mood, int score) onChanged;

  static const _items = [
    (label: 'Great', score: 5, emoji: '🤩'),
    (label: 'Good', score: 4, emoji: '😊'),
    (label: 'Neutral', score: 3, emoji: '😐'),
    (label: 'Low', score: 2, emoji: '😔'),
    (label: 'Stressed', score: 1, emoji: '😫'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final item in _items)
          _MoodChip(
            emoji: item.emoji,
            label: item.label,
            isSelected: selected == item.label,
            onTap: () => onChanged(item.label, item.score),
          ),
      ],
    );
  }
}

class _MoodChip extends StatelessWidget {
  const _MoodChip({
    required this.emoji,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.lightCyan : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.tealBlue : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isSelected
                        ? AppColors.tealBlue
                        : AppColors.secondaryText,
                    fontWeight: isSelected
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context)
          .textTheme
          .labelLarge
          ?.copyWith(color: AppColors.deepNavy),
    );
  }
}
