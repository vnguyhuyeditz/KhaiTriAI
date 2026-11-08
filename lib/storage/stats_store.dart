import 'package:shared_preferences/shared_preferences.dart';

import 'history_store.dart';

/// Mã ngày dạng yyyy-MM-dd theo giờ địa phương.
String dayKey(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year}-${two(d.month)}-${two(d.day)}';
}

DateTime _dayStart(DateTime d) => DateTime(d.year, d.month, d.day);

/// Số liệu thành tích: tổng số bài đã làm và chuỗi ngày liên tiếp (streak).
class Stats {
  final int total;
  final int streak; // chuỗi lưu lại, chỉ còn hiệu lực nếu chưa đứt
  final int best;
  final String? lastDay;

  const Stats({
    required this.total,
    required this.streak,
    required this.best,
    required this.lastDay,
  });

  static const empty = Stats(total: 0, streak: 0, best: 0, lastDay: null);

  bool doneToday(DateTime now) => lastDay == dayKey(now);

  /// Chuỗi hiện tại: còn nếu hôm nay hoặc hôm qua có làm bài, ngược lại là 0.
  int currentStreak(DateTime now) {
    if (lastDay == null) return 0;
    final today = _dayStart(now);
    final yesterday = DateTime(today.year, today.month, today.day - 1);
    if (lastDay == dayKey(today) || lastDay == dayKey(yesterday)) return streak;
    return 0;
  }
}

/// Lưu thành tích riêng với lịch sử, nên xóa lịch sử không làm mất streak.
class StatsStore {
  static const _kTotal = 'stats_total';
  static const _kStreak = 'stats_streak';
  static const _kBest = 'stats_best';
  static const _kLast = 'stats_last';

  Future<Stats> load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_kTotal)) {
      // Lần đầu có tính năng này: dựng lại từ lịch sử đã có.
      final stats = await _fromHistory();
      await _save(prefs, stats);
      return stats;
    }
    return Stats(
      total: prefs.getInt(_kTotal) ?? 0,
      streak: prefs.getInt(_kStreak) ?? 0,
      best: prefs.getInt(_kBest) ?? 0,
      lastDay: prefs.getString(_kLast),
    );
  }

  /// Gọi mỗi khi hoàn thành một bài.
  Future<Stats> recordAttempt(DateTime when) async {
    final prefs = await SharedPreferences.getInstance();
    final old = await load();
    final today = dayKey(when);
    final yesterday =
        dayKey(DateTime(when.year, when.month, when.day - 1));

    int streak;
    if (old.lastDay == today) {
      streak = old.streak < 1 ? 1 : old.streak;
    } else if (old.lastDay == yesterday) {
      streak = old.streak + 1;
    } else {
      streak = 1;
    }
    final next = Stats(
      total: old.total + 1,
      streak: streak,
      best: streak > old.best ? streak : old.best,
      lastDay: today,
    );
    await _save(prefs, next);
    return next;
  }

  Future<Stats> _fromHistory() async {
    final list = await HistoryStore().load();
    if (list.isEmpty) return Stats.empty;

    final days = <DateTime>{for (final a in list) _dayStart(a.date)}.toList()
      ..sort();
    var best = 1;
    var run = 1;
    for (var i = 1; i < days.length; i++) {
      final gap = days[i].difference(days[i - 1]).inDays;
      run = gap == 1 ? run + 1 : 1;
      if (run > best) best = run;
    }
    return Stats(total: list.length, streak: run, best: best, lastDay: dayKey(days.last));
  }

  Future<void> _save(SharedPreferences prefs, Stats s) async {
    await prefs.setInt(_kTotal, s.total);
    await prefs.setInt(_kStreak, s.streak);
    await prefs.setInt(_kBest, s.best);
    if (s.lastDay != null) await prefs.setString(_kLast, s.lastDay!);
  }
}
