import 'package:flutter/material.dart';
import 'meal_log.dart';
import 'wearable_service.dart';

const stepGoal = 10000;
const activeGoal = 500.0;

class DashboardPage extends StatefulWidget {
  const DashboardPage({
    super.key,
    required this.days,
    required this.meals,
    required this.loading,
    required this.error,
    required this.syncedAt,
    required this.connectedWatch,
    required this.onWatchConnected,
    required this.onSync,
  });

  final List<DailyActivity> days;
  final List<Meal> meals;
  final bool loading;
  final String? error;
  final DateTime? syncedAt;
  final String? connectedWatch;
  final ValueChanged<String> onWatchConnected;
  final VoidCallback onSync;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  static const _watches = [
    'Apple Watch Series 9',
    'Garmin Venu 3',
    'Fitbit Charge 6',
  ];

  Future<void> _selectWatchAndSync() async {
    String? candidate = widget.connectedWatch;
    final watch = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Choose a watch',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                const Text(
                    'Select a demo device to connect and sync activity.'),
                const SizedBox(height: 12),
                for (final watch in _watches)
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    value: watch,
                    groupValue: candidate,
                    onChanged: (value) =>
                        setSheetState(() => candidate = value),
                    secondary: const Icon(Icons.watch),
                    title: Text(watch),
                    subtitle: Text(watch == widget.connectedWatch
                        ? 'Currently connected'
                        : 'Demo device'),
                  ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: candidate == null
                        ? null
                        : () => Navigator.pop(context, candidate),
                    icon: const Icon(Icons.sync),
                    label: Text(candidate == widget.connectedWatch
                        ? 'Sync this watch'
                        : 'Connect & sync'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (watch == null || !mounted) return;
    widget.onWatchConnected(watch);
    widget.onSync();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final eaten = widget.meals.fold<int>(0, (sum, meal) => sum + meal.kcal);
    final today = widget.days.isEmpty ? null : widget.days.last;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: RefreshIndicator(
          onRefresh: () async => widget.onSync(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(child: Text('Today', style: t.headlineSmall)),
                  FilledButton.tonalIcon(
                    onPressed: widget.loading ? null : _selectWatchAndSync,
                    icon: widget.loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.sync),
                    label: Text(widget.loading ? 'Syncing' : 'Sync watch'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(widget.syncedAt == null
                  ? 'Not synced yet'
                  : 'Last synced ${TimeOfDay.fromDateTime(widget.syncedAt!).format(context)}'),
              if (widget.connectedWatch != null) ...[
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.watch, color: Color(0xFF169C91)),
                    title: Text(widget.connectedWatch!),
                    subtitle: const Text('Demo connection · MockFit activity data'),
                    trailing: const Icon(Icons.check_circle,
                        color: Color(0xFF169C91)),
                  ),
                ),
              ],
              if (widget.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(widget.error!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                ),
              const SizedBox(height: 16),
              if (today != null) ...[
                _Metric(
                  label: 'Steps',
                  value: '${today.steps}',
                  unit: 'of $stepGoal',
                  progress: today.steps / stepGoal,
                  color: const Color(0xFF2EC4B6),
                ),
                const SizedBox(height: 12),
                _Metric(
                  label: 'Active energy',
                  value: today.activeKcal.round().toString(),
                  unit: 'of ${activeGoal.round()} kcal',
                  progress: today.activeKcal / activeGoal,
                  color: const Color(0xFFFFB703),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.restaurant_menu),
                    title: Text('$eaten kcal eaten'),
                    subtitle: Text(
                        '${today.activeKcal.round()} kcal burned through activity'),
                  ),
                ),
                const SizedBox(height: 20),
                _WeeklyStepsChart(days: widget.days),
              ] else if (!widget.loading)
                const Text(
                    'No activity yet. Tap Sync watch to choose a demo watch and load activity.'),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeeklyStepsChart extends StatelessWidget {
  const _WeeklyStepsChart({required this.days});

  final List<DailyActivity> days;

  @override
  Widget build(BuildContext context) {
    final week = days.length > 7 ? days.sublist(days.length - 7) : days;
    final maxSteps = week
        .map((day) => day.steps)
        .fold<int>(stepGoal, (a, b) => a > b ? a : b);
    final total = week.fold<int>(0, (sum, day) => sum + day.steps);
    final average = week.isEmpty ? 0 : (total / week.length).round();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Last 7 days', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            const Text('Daily steps from your connected watch'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 20,
              runSpacing: 4,
              children: [
                _ChartSummary(
                    label: 'Weekly total',
                    value: '${_formatSteps(total)} steps'),
                _ChartSummary(
                    label: 'Daily average',
                    value: '${_formatSteps(average)} steps'),
                const _ChartSummary(label: 'Daily goal', value: '10,000 steps'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final day in week)
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(_formatSteps(day.steps),
                              style: Theme.of(context).textTheme.labelSmall),
                          const SizedBox(height: 4),
                          Flexible(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: FractionallySizedBox(
                                heightFactor:
                                    (day.steps / maxSteps).clamp(0.08, 1.0),
                                child: Container(
                                  width: double.infinity,
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2EC4B6),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(_weekday(day.date.weekday),
                              style: Theme.of(context).textTheme.labelMedium),
                          Text('${day.date.day}',
                              style: Theme.of(context).textTheme.labelSmall),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Each bar is one day. Taller bars mean more steps; the labels show the step count.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  static String _weekday(int weekday) =>
      const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][weekday - 1];

  static String _formatSteps(int steps) => steps >= 1000
      ? '${(steps / 1000).toStringAsFixed(steps % 1000 == 0 ? 0 : 1)}k'
      : '$steps';
}

class _ChartSummary extends StatelessWidget {
  const _ChartSummary({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          Text(value, style: Theme.of(context).textTheme.labelLarge),
        ],
      );
}

class _Metric extends StatelessWidget {
  const _Metric(
      {required this.label,
      required this.value,
      required this.unit,
      required this.progress,
      required this.color});

  final String label, value, unit;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label),
              const SizedBox(height: 4),
              Text.rich(TextSpan(children: [
                TextSpan(
                    text: value,
                    style: Theme.of(context).textTheme.headlineMedium),
                TextSpan(text: '  $unit'),
              ])),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress.clamp(0, 1),
                  minHeight: 10,
                  color: color,
                  backgroundColor: color.withOpacity(0.15),
                ),
              ),
            ],
          ),
        ),
      );
}
