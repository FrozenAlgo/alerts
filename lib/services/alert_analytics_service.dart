import 'package:cloud_firestore/cloud_firestore.dart';

class AlertAnalytics {
  final double safetyScorePercent;
  final int totalAlerts;
  final int criticalAlerts;
  final int manualSosCount;
  final int autoCrashCount;
  final List<int> weeklyCounts;
  final List<String> weeklyLabels;
  final int daysSinceLastAlert;

  const AlertAnalytics({
    required this.safetyScorePercent,
    required this.totalAlerts,
    required this.criticalAlerts,
    required this.manualSosCount,
    required this.autoCrashCount,
    required this.weeklyCounts,
    required this.weeklyLabels,
    required this.daysSinceLastAlert,
  });

  static const empty = AlertAnalytics(
    safetyScorePercent: 100,
    totalAlerts: 0,
    criticalAlerts: 0,
    manualSosCount: 0,
    autoCrashCount: 0,
    weeklyCounts: [0, 0, 0, 0, 0, 0, 0],
    weeklyLabels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
    daysSinceLastAlert: -1,
  );
}

class AlertAnalyticsService {
  AlertAnalyticsService._();
  static final AlertAnalyticsService instance = AlertAnalyticsService._();

  static const _weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  AlertAnalytics compute(List<Map<String, dynamic>> alerts) {
    if (alerts.isEmpty) return AlertAnalytics.empty;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final timestamps = <DateTime>[];
    int manual = 0;
    int auto = 0;

    for (final alert in alerts) {
      final ts = _parseTimestamp(alert['timestamp']);
      if (ts != null) timestamps.add(ts);

      final type = (alert['type'] ?? '').toString().toLowerCase();
      if (type.contains('manual') || type.contains('sos')) {
        manual++;
      } else if (type.contains('auto') || type.contains('crash') || type.contains('accident')) {
        auto++;
      }
    }

    timestamps.sort((a, b) => b.compareTo(a));
    final daysSinceLast = timestamps.isEmpty
        ? -1
        : today.difference(DateTime(timestamps.first.year, timestamps.first.month, timestamps.first.day)).inDays;

    final weeklyCounts = List<int>.filled(7, 0);
    final weeklyLabels = <String>[];

    for (var i = 6; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      weeklyLabels.add(_weekdayLabels[day.weekday - 1]);
      for (final ts in timestamps) {
        final d = DateTime(ts.year, ts.month, ts.day);
        if (d == day) weeklyCounts[6 - i]++;
      }
    }

    final last30 = timestamps.where((t) => today.difference(DateTime(t.year, t.month, t.day)).inDays <= 30).length;
    final safetyScore = (100 - (last30 * 8).clamp(0, 40) - (daysSinceLast == 0 ? 10 : 0)).toDouble().clamp(60.0, 100.0);

    return AlertAnalytics(
      safetyScorePercent: double.parse(safetyScore.toStringAsFixed(1)),
      totalAlerts: alerts.length,
      criticalAlerts: auto + manual,
      manualSosCount: manual,
      autoCrashCount: auto,
      weeklyCounts: weeklyCounts,
      weeklyLabels: weeklyLabels,
      daysSinceLastAlert: daysSinceLast,
    );
  }

  DateTime? _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
