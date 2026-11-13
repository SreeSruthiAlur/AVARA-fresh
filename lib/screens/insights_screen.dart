import 'dart:convert';

import 'package:avara_astrology_trial/models/health_model.dart';
import 'package:avara_astrology_trial/models/insights_model.dart';
import 'package:avara_astrology_trial/services/avara_api_client.dart';
import 'package:avara_astrology_trial/services/finance_service.dart';
import 'package:avara_astrology_trial/services/health_service.dart';
import 'package:avara_astrology_trial/services/insights_service.dart';
import 'package:avara_astrology_trial/theme/app_colors.dart';
import 'package:avara_astrology_trial/widgets/avara_surface_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

// ---------------------------------------------------------------------------
// Expense label helper
// ---------------------------------------------------------------------------

/// Maps an ISO date string to a short weekday label starting Sunday
/// (Sun, Mon, Tue, Wed, Thu, Fri, Sat).
String _dayLabel(String isoDate) {
  try {
    final d = DateTime.parse(isoDate);
    // DateTime.weekday: 1=Mon … 7=Sun. Map to Sun-first index.
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return labels[d.weekday - 1];
  } catch (_) {
    return isoDate;
  }
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late Future<InsightsSummary> _summaryFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _summaryFuture = InsightsService.instance.getSummary();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _summaryFuture = InsightsService.instance.getSummary());
    await _summaryFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('AVARA Insights',
            style: Theme.of(context).textTheme.titleLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refresh,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.deepNavy,
          labelColor: AppColors.deepNavy,
          unselectedLabelColor: AppColors.secondaryText,
          tabs: const [
            Tab(text: 'This Week'),
            Tab(text: 'Trends'),
            Tab(text: 'Reflections'),
          ],
        ),
      ),
      body: FutureBuilder<InsightsSummary>(
        future: _summaryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.magentaPurple));
          }
          if (snapshot.hasError) {
            final msg = snapshot.error is AvaraApiException
                ? (snapshot.error as AvaraApiException).message
                : 'Could not load insights.';
            return _ErrorView(message: msg, onRetry: _refresh);
          }
          final summary = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _refresh,
            color: AppColors.magentaPurple,
            child: TabBarView(
              controller: _tabController,
              children: [
                _ThisWeekTab(summary: summary),
                const _TrendsTab(),
                const _ReflectionsTab(),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// This Week tab (unchanged structure)
// ---------------------------------------------------------------------------

class _ThisWeekTab extends StatelessWidget {
  const _ThisWeekTab({required this.summary});
  final InsightsSummary summary;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        _ReflectionCard(summary: summary),
        const SizedBox(height: 24),
        if (summary.keyObservations.isNotEmpty) ...[
          Text('Patterns you can explore',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          ...summary.keyObservations.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PatternTile(pattern: p),
            ),
          ),
        ],
        if (summary.practicalSuggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('Suggestions',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ...summary.practicalSuggestions.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.tips_and_updates_outlined,
                      size: 16, color: AppColors.blue),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(s,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),
        Text(
          'Insights reflect tracked activity, not a diagnosis or certainty.',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppColors.secondaryText),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Reflection card
// ---------------------------------------------------------------------------

class _ReflectionCard extends StatelessWidget {
  const _ReflectionCard({required this.summary});
  final InsightsSummary summary;

  @override
  Widget build(BuildContext context) {
    return AvaraSurfaceCard(
      backgroundColor: AppColors.lavender,
      borderColor: null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'YOUR REFLECTION THIS WEEK',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.secondaryText,
                  letterSpacing: 1.2,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            summary.reflectionSummary.isNotEmpty
                ? summary.reflectionSummary
                : 'Keep going — your data is building up.',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.deepNavy,
                ),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Icon(Icons.nightlight_round, size: 22, color: AppColors.indigo),
              SizedBox(width: 10),
              Icon(Icons.auto_awesome_outlined,
                  size: 18, color: AppColors.violet),
              SizedBox(width: 10),
              Icon(Icons.auto_awesome, size: 22, color: AppColors.brightPurple),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pattern tile
// ---------------------------------------------------------------------------

class _PatternTile extends StatelessWidget {
  const _PatternTile({required this.pattern});
  final InsightPattern pattern;

  @override
  Widget build(BuildContext context) {
    // ignore: non_const_argument_for_const_parameter
    final iconData = IconData(pattern.iconCode, fontFamily: 'MaterialIcons');
    return AvaraSurfaceCard(
      backgroundColor: AppColors.white,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.lavender,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(iconData, size: 20, color: AppColors.violet),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pattern.title,
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 3),
                Text(pattern.observation,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.secondaryText)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Trends tab — real data with Timeframe + Category filters
// ---------------------------------------------------------------------------

/// Available expense categories for the filter dropdown.
const List<String> _kExpenseCategories = [
  'All',
  'Food',
  'Transportation',
  'Shopping',
  'Education',
  'Entertainment',
  'Healthcare',
  'Bills',
  'Other',
];

class _TrendsTab extends StatefulWidget {
  const _TrendsTab();

  @override
  State<_TrendsTab> createState() => _TrendsTabState();
}

class _TrendsTabState extends State<_TrendsTab> {
  String _timeframe = 'Weekly';
  String _category = 'All';

  List<_WeeklyExpense> _expenses = [];
  List<_MoodPoint> _moodPoints = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  /// Returns a short label for the Monthly chart's X-axis (e.g. "14/11").
  ///
  /// For the Weekly view [_dayLabel] (the top-level helper) is used instead.
  /// This instance method handles Monthly labels as "day/month" strings and
  /// safely falls back to an empty string for unparseable input.
  String _shortDateLabel(String dateString) {
    if (dateString.isEmpty) return '';
    try {
      final d = DateTime.parse(dateString);
      return '${d.day}/${d.month}';
    } catch (_) {
      return '';
    }
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final int limit = _timeframe == 'Weekly' ? 7 : 30;

      // Fetch real expenses and mood entries in parallel.
      final results = await Future.wait([
        FinanceService.instance.getRecentExpenses(limit: limit),
        HealthService.instance.getEntries(limit: limit),
      ]);

      final rawExpenses = results[0] as List;
      final rawHealth = results[1] as List;

      // Fixed chronological skeleton — Mon through Sun for Weekly,
      // or the last 30 calendar-day labels for Monthly.
      // All days start at 0 so gaps render as blank bars/points rather
      // than being omitted and causing out-of-order rendering.
      final List<String> orderedLabels;
      if (_timeframe == 'Weekly') {
        orderedLabels = const [
          'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'
        ];
      } else {
        // For Monthly, build the last 30 calendar days ordered oldest→newest.
        final today = DateTime.now();
        orderedLabels = List.generate(30, (i) {
          final d = today.subtract(Duration(days: 29 - i));
          return '${d.day}/${d.month}';
        });
      }

      // --- Aggregate expense amounts into the ordered skeleton ---
      final expMap = <String, double>{
        for (final lbl in orderedLabels) lbl: 0.0,
      };
      for (final e in rawExpenses) {
        final exp = e as dynamic;
        final label = _timeframe == 'Weekly'
            ? _dayLabel(exp.date as String? ?? '')
            : _shortDateLabel(exp.date as String? ?? '');
        final amount = (exp.amount as num?)?.toDouble() ?? 0.0;
        final cat = (exp.category as String?)?.toLowerCase() ?? '';
        if (_category == 'All' || cat == _category.toLowerCase()) {
          if (expMap.containsKey(label)) {
            expMap[label] = (expMap[label] ?? 0) + amount;
          }
        }
      }

      // --- Aggregate mood scores into the ordered skeleton (null = no data) ---
      final moodMap = <String, List<double>>{
        for (final lbl in orderedLabels) lbl: [],
      };
      for (final h in rawHealth) {
        final entry = h as WellnessEntry;
        final label = _timeframe == 'Weekly'
            ? _dayLabel(entry.date)
            : _shortDateLabel(entry.date);
        moodMap[label]?.add(entry.moodScore.toDouble());
      }

      setState(() {
        // Preserve fixed order from orderedLabels.
        _expenses = orderedLabels
            .map((lbl) => _WeeklyExpense(lbl, expMap[lbl] ?? 0))
            .toList();
        _moodPoints = orderedLabels
            .map((lbl) {
              final scores = moodMap[lbl] ?? [];
              if (scores.isEmpty) return _MoodPoint(lbl, 0);
              final avg = scores.reduce((a, b) => a + b) / scores.length;
              return _MoodPoint(lbl, avg);
            })
            .toList();
        _loading = false;
      });
    } on AvaraApiException catch (e) {
      setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.blue));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.secondaryText),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton(onPressed: _fetch, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        // --- Filters row ---
        Row(
          children: [
            Expanded(
              child: _FilterDropdown<String>(
                label: 'Timeframe',
                value: _timeframe,
                items: const ['Weekly', 'Monthly'],
                onChanged: (v) {
                  if (v == null || v == _timeframe) return;
                  setState(() => _timeframe = v);
                  _fetch();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _FilterDropdown<String>(
                label: 'Category',
                value: _category,
                items: _kExpenseCategories,
                onChanged: (v) {
                  if (v == null || v == _category) return;
                  setState(() => _category = v);
                  _fetch();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // --- Expense bar chart ---
        Text(
          _timeframe == 'Weekly'
              ? 'Expenses this week (₹)'
              : 'Expenses this month (₹)',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(
          _category == 'All'
              ? 'All categories'
              : 'Category: $_category',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppColors.secondaryText),
        ),
        const SizedBox(height: 12),
        _expenses.isEmpty
            ? _NoDataCard(message: 'No expense data for this filter.')
            : AvaraSurfaceCard(
                backgroundColor: AppColors.white,
                child: _BarChart(
                  data: _expenses,
                  maxValue: _expenses
                      .map((e) => e.amount)
                      .reduce((a, b) => a > b ? a : b),
                  barColor: AppColors.blue,
                  valueLabel: (v) => '₹${v.toStringAsFixed(0)}',
                ),
              ),
        const SizedBox(height: 28),
        // --- Mood line chart ---
        Text('Mood Trend (1–5)',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          _timeframe == 'Weekly'
              ? 'Average daily mood · this week'
              : 'Average daily mood · this month',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppColors.secondaryText),
        ),
        const SizedBox(height: 12),
        _moodPoints.isEmpty
            ? _NoDataCard(message: 'No mood data logged yet.')
            : AvaraSurfaceCard(
                backgroundColor: AppColors.white,
                child: _LineChart(
                  data: _moodPoints,
                  maxValue: 5,
                  lineColor: AppColors.violet,
                ),
              ),
        const SizedBox(height: 20),
        Text(
          'Charts reflect your actual tracked data.',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppColors.secondaryText),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Small filter dropdown
// ---------------------------------------------------------------------------

class _FilterDropdown<T> extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> items;
  final void Function(T?) onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: AppColors.secondaryText)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButton<T>(
            value: value,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.deepNavy),
            items: items
                .map((item) => DropdownMenuItem<T>(
                      value: item,
                      child: Text(item.toString()),
                    ))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Reflections tab — dynamic AI-generated insights
// ---------------------------------------------------------------------------

/// Insight category definitions: icon, colour palette, and the AI prompt label.
class _ReflectionCategory {
  const _ReflectionCategory({
    required this.title,
    required this.promptKey,
    required this.iconData,
    required this.iconColor,
    required this.iconBg,
  });

  final String title;
  final String promptKey; // used in the Groq prompt
  final IconData iconData;
  final Color iconColor;
  final Color iconBg;
}

const List<_ReflectionCategory> _kReflectionCategories = [
  _ReflectionCategory(
    title: 'Wellness Consistency',
    promptKey: 'wellness',
    iconData: Icons.favorite,
    iconColor: AppColors.tealBlue,
    iconBg: AppColors.lightCyan,
  ),
  _ReflectionCategory(
    title: 'Habit Momentum',
    promptKey: 'habits',
    iconData: Icons.track_changes,
    iconColor: AppColors.orange,
    iconBg: AppColors.lightOrange,
  ),
  _ReflectionCategory(
    title: 'Spending Awareness',
    promptKey: 'spending',
    iconData: Icons.account_balance_wallet_outlined,
    iconColor: AppColors.green,
    iconBg: AppColors.lightGreen,
  ),
];

class _ReflectionsTab extends StatefulWidget {
  const _ReflectionsTab();

  @override
  State<_ReflectionsTab> createState() => _ReflectionsTabState();
}

class _ReflectionsTabState extends State<_ReflectionsTab> {
  /// Generated text per category (key = promptKey).
  final Map<String, String?> _insights = {};
  bool _loading = true;
  String? _globalError;

  @override
  void initState() {
    super.initState();
    _generateInsights();
  }

  // ---------------------------------------------------------------------------
  // Data aggregation + Groq call
  // ---------------------------------------------------------------------------

  Future<void> _generateInsights() async {
    setState(() { _loading = true; _globalError = null; });

    try {
      // 1. Gather real weekly data in parallel.
      final results = await Future.wait([
        FinanceService.instance.getRecentExpenses(limit: 7),
        HealthService.instance.getEntries(limit: 7),
      ]);

      final expenses = results[0] as List;
      final healthEntries = results[1] as List<WellnessEntry>;

      final totalSpend = expenses.fold<double>(
        0, (sum, e) => sum + ((e as dynamic).amount as num).toDouble());
      final moodScores = healthEntries.map((e) => e.moodScore).toList();
      final avgMood = moodScores.isEmpty
          ? 'no data'
          : (moodScores.reduce((a, b) => a + b) / moodScores.length)
              .toStringAsFixed(1);
      final sleepValues =
          healthEntries.where((e) => e.sleepHours != null).toList();
      final avgSleep = sleepValues.isEmpty
          ? 'no data'
          : (sleepValues.map((e) => e.sleepHours!).reduce((a, b) => a + b) /
                  sleepValues.length)
              .toStringAsFixed(1);

      // 2. Build a single prompt that requests all three categories at once.
      final prompt = '''
You are AVARA, a personal growth AI. Based on the user's last 7 days of data,
write ONE concise sentence (max 25 words) of insight for EACH of these three
categories. Return ONLY a JSON object with exactly these keys:
  "wellness" - insight about mood (avg $avgMood/5) and sleep (avg ${avgSleep}h)
  "habits"   - insight about habit consistency and momentum
  "spending" - insight about total spending ₹${totalSpend.toStringAsFixed(0)} this week

Rules: Be specific, encouraging, and grounded in the numbers. No fluffy generic advice.
Output format (strict JSON, no markdown): {"wellness":"...","habits":"...","spending":"..."}
''';

      // 3. Call Groq directly via the OpenAI-compatible REST endpoint.
      final rawKey = dotenv.env['GROQ_API_KEY'] ?? '';
      final apiKey = rawKey.replaceAll('"', '').replaceAll("'", '').trim();
      if (apiKey.isEmpty) {
        throw Exception('GROQ_API_KEY not set in .env');
      }
      final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
      final response = await http
          .post(
            url,
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': 'openai/gpt-oss-20b',
              'messages': [
                {
                  'role': 'user',
                  'content': prompt,
                },
              ],
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        Map<String, dynamic>? errJson;
        try {
          errJson = jsonDecode(response.body) as Map<String, dynamic>?;
        } catch (_) {}
        final msg = errJson?['error']?['message']?.toString() ?? response.body;
        throw Exception('Groq error: $msg');
      }

      // 4. Parse the text → JSON.
      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      final rawText = jsonResponse['choices']?[0]?['message']?['content']
              ?.toString() ??
          '';
      // Strip any accidental markdown fences.
      final cleaned =
          rawText.replaceAll('```json', '').replaceAll('```', '').trim();
      final Map<String, dynamic> parsed;
      try {
        parsed = jsonDecode(cleaned) as Map<String, dynamic>;
      } catch (_) {
        throw Exception(
            'Groq returned unexpected format. Raw:\n$rawText');
      }

      setState(() {
        for (final cat in _kReflectionCategories) {
          _insights[cat.promptKey] = parsed[cat.promptKey]?.toString();
        }
        _loading = false;
      });
    } on AvaraApiException catch (e) {
      setState(() { _globalError = e.message; _loading = false; });
    } catch (e) {
      setState(() { _globalError = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        // Hero reflection banner
        AvaraSurfaceCard(
          backgroundColor: AppColors.lavender,
          borderColor: null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'YOUR REFLECTIONS',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.secondaryText,
                      letterSpacing: 1.2,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Small steps are adding up.',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.deepNavy,
                    ),
              ),
              const SizedBox(height: 14),
              const Row(
                children: [
                  Icon(Icons.nightlight_round,
                      size: 20, color: AppColors.indigo),
                  SizedBox(width: 8),
                  Icon(Icons.auto_awesome_outlined,
                      size: 16, color: AppColors.violet),
                  SizedBox(width: 8),
                  Icon(Icons.auto_awesome,
                      size: 20, color: AppColors.brightPurple),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text('Weekly Insights',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 14),

        // Global error state
        if (_globalError != null && !_loading)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AvaraSurfaceCard(
              backgroundColor: AppColors.lightOrange,
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: AppColors.orange),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Could not generate AI insights.',
                            style: Theme.of(context).textTheme.titleSmall),
                        Text(_globalError!,
                            style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _generateInsights,
                          child: const Text('Try again'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

        // One card per category
        for (final cat in _kReflectionCategories)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _DynamicReflectionCard(
              category: cat,
              insightText: _loading ? null : (_insights[cat.promptKey] ?? ''),
              isLoading: _loading,
            ),
          ),

        const SizedBox(height: 16),
        Text(
          'Insights are generated by AI from your tracked data. '
          'They are personal observations, not clinical advice.',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppColors.secondaryText),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _DynamicReflectionCard extends StatelessWidget {
  const _DynamicReflectionCard({
    required this.category,
    required this.insightText,
    required this.isLoading,
  });

  final _ReflectionCategory category;
  final String? insightText; // null while loading
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return AvaraSurfaceCard(
      backgroundColor: AppColors.white,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: category.iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(category.iconData,
                color: category.iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category.title,
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                if (isLoading)
                  Row(
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.secondaryText,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('Generating insight…',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                  color: AppColors.secondaryText,
                                  fontStyle: FontStyle.italic)),
                    ],
                  )
                else
                  Text(
                    insightText != null && insightText!.isNotEmpty
                        ? insightText!
                        : 'Keep logging daily to unlock this insight.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.secondaryText),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Native Flutter bar chart
// ---------------------------------------------------------------------------

class _WeeklyExpense {
  const _WeeklyExpense(this.label, this.amount);
  final String label;
  final double amount;
}

class _MoodPoint {
  const _MoodPoint(this.label, this.score);
  final String label;
  final double score;
}

class _BarChart extends StatelessWidget {
  const _BarChart({
    required this.data,
    required this.maxValue,
    required this.barColor,
    required this.valueLabel,
  });

  final List<_WeeklyExpense> data;
  final double maxValue;
  final Color barColor;
  final String Function(double) valueLabel;

  static const double _chartHeight = 160;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: _chartHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: data.map((item) {
              final fraction =
                  maxValue > 0 ? (item.amount / maxValue).clamp(0.0, 1.0) : 0.0;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        valueLabel(item.amount),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.deepNavy,
                              fontWeight: FontWeight.w700,
                            ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4)),
                        child: Container(
                          height: _chartHeight * fraction * 0.80,
                          decoration: BoxDecoration(
                            color: barColor,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: data
              .map((item) => Expanded(
                    child: Text(
                      item.label,
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: AppColors.secondaryText),
                      textAlign: TextAlign.center,
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Native Flutter line chart
// ---------------------------------------------------------------------------

class _LineChart extends StatelessWidget {
  const _LineChart({
    required this.data,
    required this.maxValue,
    required this.lineColor,
  });

  final List<_MoodPoint> data;
  final double maxValue;
  final Color lineColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 140,
          child: CustomPaint(
            painter: _LineChartPainter(
              data: data.map((d) => d.score).toList(),
              maxValue: maxValue,
              lineColor: lineColor,
            ),
            child: const SizedBox.expand(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: data
              .map((item) => Expanded(
                    child: Text(
                      item.label,
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: AppColors.secondaryText),
                      textAlign: TextAlign.center,
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({
    required this.data,
    required this.maxValue,
    required this.lineColor,
  });

  final List<double> data;
  final double maxValue;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || data.length < 2) return;
    const padding = 12.0;
    final w = size.width - padding * 2;
    final h = size.height - padding * 2;

    final pointPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..color = lineColor.withValues(alpha: 0.75)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    final fillPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.10)
      ..style = PaintingStyle.fill;

    final points = <Offset>[];
    for (var i = 0; i < data.length; i++) {
      final x = padding + (i / (data.length - 1)) * w;
      final y = padding + h - (data[i] / maxValue).clamp(0.0, 1.0) * h;
      points.add(Offset(x, y));
    }

    final fillPath = Path()..moveTo(points.first.dx, padding + h);
    for (final p in points) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath.lineTo(points.last.dx, padding + h);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(linePath, linePaint);

    for (final p in points) {
      canvas.drawCircle(p, 4, pointPaint);
      canvas.drawCircle(
          p,
          4,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5);
    }
  }

  @override
  bool shouldRepaint(_LineChartPainter old) =>
      old.data != data ||
      old.maxValue != maxValue ||
      old.lineColor != lineColor;
}

// ---------------------------------------------------------------------------
// Shared empty-data card
// ---------------------------------------------------------------------------

class _NoDataCard extends StatelessWidget {
  const _NoDataCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return AvaraSurfaceCard(
      backgroundColor: AppColors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(
            message,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.secondaryText),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error state
// ---------------------------------------------------------------------------

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
