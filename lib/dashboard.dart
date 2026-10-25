import 'package:flutter/material.dart';
import 'meal_log.dart';
import 'wearable_service.dart';

const stepGoal = 10000;
const activeGoal = 500.0;

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    super.key, required this.days, required this.meals, required this.loading,
    required this.error, required this.syncedAt, required this.onSync,
  });
  final List<DailyActivity> days;
  final List<Meal> meals;
  final bool loading;
  final String? error;
  final DateTime? syncedAt;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final eaten = meals.fold<int>(0, (s, m) => s + m.kcal);
    final today = days.isEmpty ? null : days.last;
    final maxSteps = days.isEmpty ? 1 : days.map((d) => d.steps).reduce((a, b) => a > b ? a : b);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: RefreshIndicator(
          onRefresh: () async => onSync(),
          child: ListView(padding: const EdgeInsets.all(16), children: [
            Row(children: [
              Expanded(child: Text('Today', style: t.headlineSmall)),
              FilledButton.tonalIcon(
                onPressed: loading ? null : onSync,
                icon: loading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.sync),
                label: Text(loading ? 'Syncing' : 'Sync watch'),
              ),
            ]),
            const SizedBox(height: 4),
            Text(syncedAt == null
                ? 'Not synced yet'
                : 'Last synced ${TimeOfDay.fromDateTime(syncedAt!).format(context)}'),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            const SizedBox(height: 16),
            if (today != null) ...[
              _Metric(label: 'Steps', value: '${today.steps}', unit: 'of $stepGoal',
                  progress: today.steps / stepGoal, color: const Color(0xFF2EC4B6)),
              const SizedBox(height: 12),
              _Metric(label: 'Active energy', value: today.activeKcal.round().toString(), unit: 'of ${activeGoal.round()} kcal',
                  progress: today.activeKcal / activeGoal, color: const Color(0xFFFFB703)),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.restaurant_menu),
                  title: Text('$eaten kcal eaten'),
                  subtitle: Text('${today.activeKcal.round()} kcal burned through activity'),
                ),
              ),
              const SizedBox(height: 24),
              Text('Last 7 days', style: t.titleMedium),
              const SizedBox(height: 12),
              SizedBox(
                height: 130,
                child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  for (final d in days)
                    Expanded(
                      child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                        Container(
                          height: 100 * d.steps / maxSteps,
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2EC4B6),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text('MTWTFSS'[d.date.weekday - 1]),
                      ]),
                    ),
                ]),
              ),
            ] else if (!loading)
              const Text('No activity yet. Tap Sync watch to pull your steps and active energy.'),
          ]),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.unit, required this.progress, required this.color});
  final String label, value, unit;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label),
            const SizedBox(height: 4),
            Text.rich(TextSpan(children: [
              TextSpan(text: value, style: Theme.of(context).textTheme.headlineMedium),
              TextSpan(text: '  $unit'),
            ])),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(value: progress.clamp(0, 1), minHeight: 10, color: color,
                  backgroundColor: color.withOpacity(0.15)),
            ),
          ]),
        ),
      );
}
