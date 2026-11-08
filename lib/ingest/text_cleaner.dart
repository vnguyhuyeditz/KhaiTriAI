// Làm sạch chữ đọc từ tài liệu và cắt thành các đoạn ngắn để đưa cho AI.
// Thuần Dart.

final RegExp _pageNumberLine = RegExp(
  r'^\s*(?:[-–—]\s*)?(?:trang|page|p\.)?\s*\d{1,4}\s*(?:[-–—]\s*)?(?:/\s*\d{1,4})?\s*$',
  caseSensitive: false,
);
final RegExp _bulletStart = RegExp(
  r'^\s*(?:[-•*·▪●■□○]|\d{1,3}[\.\)]|[A-Da-d][\.\)]|\(\d{1,3}\)|Câu\s+\d+)\s',
  caseSensitive: false,
);
final RegExp _sentenceEnd = RegExp(r'[.!?…:;]["”’)\]]?\s*$');
final RegExp _hyphenBreak = RegExp(r'(\p{L})-\n(\p{Ll})', unicode: true);

String cleanText(String raw) {
  var s = raw
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .replaceAll(RegExp('[​-‍﻿­]'), '')
      .replaceAll(' ', ' ')
      .replaceAll('\t', ' ')
      .replaceAll(RegExp(r'[ ]{2,}'), ' ');

  var lines = s.split('\n').map((l) => l.trimRight()).toList();

  // Bỏ dòng chỉ có số trang.
  lines = lines.where((l) => !_pageNumberLine.hasMatch(l) || l.trim().isEmpty).toList();

  // Bỏ tiêu đề đầu/chân trang lặp lại (dòng ngắn xuất hiện từ 3 lần).
  final counts = <String, int>{};
  for (final l in lines) {
    final k = l.trim().toLowerCase();
    if (k.length >= 8 && k.length <= 60) counts[k] = (counts[k] ?? 0) + 1;
  }
  lines = lines.where((l) {
    final k = l.trim().toLowerCase();
    return !(k.length >= 8 && k.length <= 60 && (counts[k] ?? 0) >= 3);
  }).toList();

  // Nối từ bị ngắt bằng gạch nối cuối dòng.
  s = lines.join('\n').replaceAllMapped(_hyphenBreak, (m) => '${m[1]}${m[2]}');
  lines = s.split('\n');

  // Dựng lại đoạn văn: nối các dòng bị ngắt giữa câu.
  final paragraphs = <StringBuffer>[];
  StringBuffer? cur;
  for (final line in lines) {
    final t = line.trim();
    if (t.isEmpty) {
      cur = null;
      continue;
    }
    final startsNew = _bulletStart.hasMatch(line);
    if (cur == null || startsNew) {
      cur = StringBuffer(t);
      paragraphs.add(cur);
      continue;
    }
    final prev = cur.toString();
    if (_sentenceEnd.hasMatch(prev)) {
      cur = StringBuffer(t);
      paragraphs.add(cur);
    } else {
      cur.write(' $t');
    }
  }
  return paragraphs.map((b) => b.toString()).join('\n').trim();
}

/// Cắt văn bản đã làm sạch thành các đoạn khoảng [target] ký tự,
/// không cắt giữa câu (trừ khi một câu dài hơn [max]).
List<String> chunkText(
  String text, {
  int target = 700,
  int max = 900,
  int min = 200,
}) {
  final units = <String>[];
  final sentenceSplit = RegExp(r'(?<=[.!?…])\s+');
  for (final line in text.split('\n')) {
    final t = line.trim();
    if (t.isEmpty) continue;
    for (final sent in t.split(sentenceSplit)) {
      final u = sent.trim();
      if (u.isEmpty) continue;
      units.addAll(_hardSplit(u, max));
    }
  }

  final chunks = <String>[];
  var cur = StringBuffer();
  void flush() {
    final c = cur.toString().trim();
    if (c.isNotEmpty) chunks.add(c);
    cur = StringBuffer();
  }

  for (final u in units) {
    if (cur.length > 0 && cur.length + u.length + 1 > target && cur.length >= min) {
      flush();
    }
    if (cur.length > 0) cur.write(' ');
    cur.write(u);
  }
  flush();

  // Đoạn cuối quá ngắn thì gộp vào đoạn trước nếu không vượt quá max.
  if (chunks.length >= 2 && chunks.last.length < min) {
    final last = chunks.removeLast();
    if (chunks.last.length + last.length + 1 <= max + min) {
      chunks[chunks.length - 1] = '${chunks.last} $last';
    } else {
      chunks.add(last);
    }
  }
  return chunks;
}

List<String> _hardSplit(String s, int max) {
  if (s.length <= max) return [s];
  final out = <String>[];
  var rest = s;
  while (rest.length > max) {
    var cut = rest.lastIndexOf(' ', max);
    if (cut < max ~/ 2) cut = max;
    out.add(rest.substring(0, cut).trim());
    rest = rest.substring(cut).trim();
  }
  if (rest.isNotEmpty) out.add(rest);
  return out;
}
