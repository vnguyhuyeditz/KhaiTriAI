import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/attempt.dart';

/// Lưu lịch sử các lần làm bài ngay trên điện thoại (không gửi đi đâu).
class HistoryStore {
  static const _key = 'attempts_v1';

  /// Trả về danh sách, lần mới nhất đứng đầu.
  Future<List<Attempt>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? <String>[];
    final out = <Attempt>[];
    for (final s in raw) {
      try {
        out.add(Attempt.fromJson(Map<String, dynamic>.from(jsonDecode(s) as Map)));
      } catch (_) {
        // Bỏ qua bản ghi hỏng thay vì làm app bị lỗi.
      }
    }
    return out;
  }

  Future<void> add(Attempt attempt) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? <String>[];
    raw.insert(0, jsonEncode(attempt.toJson()));
    await prefs.setStringList(_key, raw);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

String formatDate(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
}
