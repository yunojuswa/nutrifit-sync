import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'meal_log.dart';
import 'wearable_service.dart';

void main() => runApp(const NutriFitApp());

class NutriFitApp extends StatelessWidget {
  const NutriFitApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'NutriFit Sync',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF14213D)),
          scaffoldBackgroundColor: const Color(0xFFF2F5F9),
        ),
        home: const HomeShell(),
      );
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final _api = WearableService(); // swap in Postman mock URL here
  final List<Meal> _meals = [];
  List<DailyActivity> _days = [];
  bool _loading = false;
  String? _error;
  DateTime? _syncedAt;
  String? _connectedWatch;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  Future<void> _sync() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _api.fetchDaily();
      if (!mounted) return;
      setState(() {
        _days = data;
        _syncedAt = DateTime.now();
      });
    } catch (e) {
      if (mounted)
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardPage(
        days: _days,
        meals: _meals,
        loading: _loading,
        error: _error,
        syncedAt: _syncedAt,
        connectedWatch: _connectedWatch,
        onWatchConnected: (watch) => setState(() => _connectedWatch = watch),
        onSync: _sync,
      ),
      MealLogPage(meals: _meals, onAdd: (m) => setState(() => _meals.add(m))),
    ];
    return Scaffold(
      appBar: AppBar(
          title: const Text('NutriFit Sync'),
          backgroundColor: Colors.transparent),
      body: SafeArea(child: pages[_tab]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.favorite_border),
              selectedIcon: Icon(Icons.favorite),
              label: 'Activity'),
          NavigationDestination(
              icon: Icon(Icons.restaurant_outlined),
              selectedIcon: Icon(Icons.restaurant),
              label: 'Meals'),
        ],
      ),
    );
  }
}
