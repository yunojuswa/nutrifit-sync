import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class DailyActivity {
  DailyActivity(this.date, this.steps, this.activeKcal);
  final DateTime date;
  final int steps;
  final double activeKcal;

  factory DailyActivity.fromJson(Map<String, dynamic> j) => DailyActivity(
        DateTime.parse(j['date'] as String),
        (j['steps'] as num).toInt(),
        (j['activeEnergyKcal'] as num).toDouble(),
      );
}

/// Talks to a Google Fit / HealthKit-style REST endpoint.
/// By default an in-app MockClient answers, so no server is needed.
/// To use a Postman mock server instead:
///   WearableService(baseUrl: 'https://<id>.mock.pstmn.io', client: http.Client())
class WearableService {
  WearableService({this.baseUrl = 'https://mock.wearable.api', http.Client? client})
      : _client = client ?? _mockClient();

  final String baseUrl;
  final http.Client _client;
  static const _token = 'demo-token';

  static http.Client _mockClient() => MockClient((req) async {
        await Future.delayed(const Duration(milliseconds: 800)); // network latency
        if (req.headers['Authorization'] != 'Bearer $_token') {
          return http.Response(jsonEncode({'error': 'unauthorized'}), 401);
        }
        final days = int.tryParse(req.url.queryParameters['days'] ?? '7') ?? 7;
        final rnd = Random(7);
        final now = DateTime.now();
        final data = List.generate(days, (i) {
          final d = now.subtract(Duration(days: days - 1 - i));
          return {
            'date': d.toIso8601String().substring(0, 10),
            'steps': 4000 + rnd.nextInt(8000),
            'activeEnergyKcal': 150 + rnd.nextInt(450),
          };
        });
        return http.Response(jsonEncode({'source': 'MockFit', 'data': data}), 200,
            headers: {'content-type': 'application/json'});
      });

  Future<List<DailyActivity>> fetchDaily({int days = 7}) async {
    final res = await _client.get(
      Uri.parse('$baseUrl/v1/users/me/activity/daily?days=$days'),
      headers: {'Authorization': 'Bearer $_token'},
    );
    if (res.statusCode != 200) {
      throw Exception('Sync failed (HTTP ${res.statusCode}). Check your token.');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return (body['data'] as List).map((e) => DailyActivity.fromJson(e)).toList();
  }
}
