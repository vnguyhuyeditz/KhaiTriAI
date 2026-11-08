/// 4 tiêu chí đo bằng nhãn câu hỏi. Tiêu chí thứ 5 (tự tin chính xác)
/// được tính từ mức tự tin của học sinh, không cần nhãn.
enum Criterion { nho, hieu, vanDung, phanTich }

extension CriterionInfo on Criterion {
  String get label {
    switch (this) {
      case Criterion.nho:
        return 'Ghi nhớ';
      case Criterion.hieu:
        return 'Hiểu bản chất';
      case Criterion.vanDung:
        return 'Vận dụng';
      case Criterion.phanTich:
        return 'Phân tích';
    }
  }

  /// Tên nhãn mà AI phải trả về trong JSON.
  String get aiKey {
    switch (this) {
      case Criterion.nho:
        return 'nho';
      case Criterion.hieu:
        return 'hieu';
      case Criterion.vanDung:
        return 'van_dung';
      case Criterion.phanTich:
        return 'phan_tich';
    }
  }
}

Criterion? criterionFromAiKey(String key) {
  final k = key.trim().toLowerCase();
  for (final c in Criterion.values) {
    if (c.aiKey == k) return c;
  }
  return null;
}

class Question {
  final String id;
  final String text;
  final List<String> options; // đúng 4 đáp án
  final int correct; // 0..3
  final Criterion criterion;
  final String explanation;

  /// Mỗi đáp án sai gắn với một kiểu hiểu sai (chỉ số đáp án -> mô tả).
  final Map<int, String> misconceptions;

  /// Đoạn nguyên văn trong tài liệu chứng minh đáp án đúng (câu do AI tạo).
  final String? sourceQuote;

  const Question({
    required this.id,
    required this.text,
    required this.options,
    required this.correct,
    required this.criterion,
    required this.explanation,
    this.misconceptions = const {},
    this.sourceQuote,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'options': options,
        'correct': correct,
        'criterion': criterion.name,
        'explanation': explanation,
        'misconceptions': misconceptions.map((k, v) => MapEntry('$k', v)),
        'sourceQuote': sourceQuote,
      };

  factory Question.fromJson(Map<String, dynamic> j) {
    final mis = <int, String>{};
    final raw = j['misconceptions'];
    if (raw is Map) {
      raw.forEach((k, v) {
        final i = int.tryParse(k.toString());
        if (i != null) mis[i] = v.toString();
      });
    }
    return Question(
      id: j['id'] as String,
      text: j['text'] as String,
      options: (j['options'] as List).map((e) => e.toString()).toList(),
      correct: j['correct'] as int,
      criterion: Criterion.values.byName(j['criterion'] as String),
      explanation: (j['explanation'] ?? '') as String,
      misconceptions: mis,
      sourceQuote: j['sourceQuote'] as String?,
    );
  }

  /// Đọc một câu hỏi từ JSON do AI trả về. Trả về null nếu thiếu hoặc sai
  /// cấu trúc (muốn biết lý do cụ thể thì dùng [parseAi]).
  static Question? fromAiJson(Map<String, dynamic> j, String id) =>
      parseAi(j, id).question;

  /// Đọc câu hỏi từ JSON của AI, chịu được nhiều kiểu viết của mô hình nhỏ:
  /// - đáp án là mảng `dap_an` hoặc các khóa riêng `A`,`B`,`C`,`D` (hoặc `dap_an_a`...)
  /// - đáp án đúng viết "B", "B.", "Đáp án B" hoặc chép nguyên văn đáp án
  /// - nếu truyền [forced] thì dùng luôn nhãn tiêu chí đó (app đã biết mình xin
  ///   loại câu nào, không cần tin vào nhãn do mô hình tự ghi).
  /// Khi lỗi, trả về lý do cụ thể để hiện cho người dùng.
  static AiParse parseAi(Map<String, dynamic> j, String id,
      {Criterion? forced}) {
    String? str(dynamic v) {
      if (v == null) return null;
      final t = v.toString().trim();
      return t.isEmpty ? null : t;
    }

    // Tìm giá trị theo nhiều tên khóa, không phân biệt hoa thường.
    final lower = {for (final e in j.entries) e.key.toLowerCase().trim(): e.value};
    dynamic pick(List<String> keys) {
      for (final k in keys) {
        if (lower[k] != null) return lower[k];
      }
      return null;
    }

    final text = str(pick(['cau_hoi', 'cau hoi', 'question', 'cauhoi']));
    if (text == null) return const AiParse.fail('thiếu nội dung câu hỏi');

    // ----- Đáp án -----
    final prefix = RegExp(r'^\s*[A-Da-d]\s*[\.\):\-]\s*');
    final options = <String>[];
    final rawOpts = pick(['dap_an', 'dap an', 'options', 'lua_chon']);
    if (rawOpts is List) {
      for (final e in rawOpts) {
        final t = str(e);
        if (t != null) options.add(t.replaceFirst(prefix, '').trim());
      }
    } else if (rawOpts is Map) {
      final m = {
        for (final e in rawOpts.entries) e.key.toString().toUpperCase().trim(): e.value
      };
      for (final l in ['A', 'B', 'C', 'D']) {
        final t = str(m[l]);
        if (t != null) options.add(t.replaceFirst(prefix, '').trim());
      }
    }
    if (options.length < 4) {
      // Khóa riêng: A, B, C, D hoặc dap_an_a, option_a...
      final byKey = <String>[];
      for (final l in ['a', 'b', 'c', 'd']) {
        final t = str(pick([l, 'dap_an_$l', 'option_$l', 'lua_chon_$l']));
        if (t != null) byKey.add(t.replaceFirst(prefix, '').trim());
      }
      if (byKey.length > options.length) {
        options
          ..clear()
          ..addAll(byKey);
      }
    }
    if (options.length < 4) {
      return AiParse.fail('chỉ có ${options.length}/4 đáp án');
    }
    if (options.length > 4) options.removeRange(4, options.length);

    // ----- Đáp án đúng -----
    final rawCorrect = str(pick(
        ['dap_an_dung', 'dap an dung', 'correct', 'dap_an_chinh_xac', 'dung']));
    if (rawCorrect == null) return const AiParse.fail('thiếu đáp án đúng');
    var correct = -1;
    final m = RegExp(r'^\W*(?:đáp án|dap an)?\W*([A-Da-d])(?![\p{L}\p{N}])',
            caseSensitive: false, unicode: true)
        .firstMatch(rawCorrect);
    if (m != null) {
      correct = 'ABCD'.indexOf(m.group(1)!.toUpperCase());
    } else {
      final norm = rawCorrect.toLowerCase();
      correct = options.indexWhere((o) => o.toLowerCase() == norm);
    }
    if (correct < 0) return AiParse.fail('không rõ đáp án đúng ("$rawCorrect")');

    // ----- Tiêu chí -----
    Criterion? criterion = forced;
    if (criterion == null) {
      final label = str(pick(['tieu_chi', 'tieu chi', 'criterion']));
      if (label == null) return const AiParse.fail('thiếu nhãn tiêu chí');
      criterion = criterionFromAiKey(label) ?? _criterionFromLoose(label);
      if (criterion == null) {
        return AiParse.fail('nhãn tiêu chí sai ("$label")');
      }
    }

    final mis = <int, String>{};
    final raw = pick(['loi_sai_pho_bien', 'loi_sai']);
    if (raw is Map) {
      raw.forEach((k, v) {
        final ks = k.toString().trim().toUpperCase();
        if (ks.isEmpty) return;
        final i = 'ABCD'.indexOf(ks[0]);
        final d = str(v);
        if (i >= 0 && i != correct && d != null) mis[i] = d;
      });
    }

    return AiParse.ok(Question(
      id: id,
      text: text,
      options: options,
      correct: correct,
      criterion: criterion,
      explanation: str(pick(['giai_thich', 'giai thich', 'explanation'])) ?? '',
      misconceptions: mis,
      sourceQuote: str(pick(['trich_dan', 'trich dan', 'quote'])),
    ));
  }

  /// Nhận các cách viết gần giống: "ghi nhớ", "Vận dụng", "phân tích"...
  static Criterion? _criterionFromLoose(String label) {
    final k = label.toLowerCase().replaceAll(RegExp(r'[\s_\-]+'), '');
    const map = {
      'nho': Criterion.nho, 'ghinho': Criterion.nho, 'ghinhớ': Criterion.nho,
      'hieu': Criterion.hieu, 'hiểu': Criterion.hieu,
      'hieubanchat': Criterion.hieu, 'hiểubảnchất': Criterion.hieu,
      'vandung': Criterion.vanDung, 'vậndụng': Criterion.vanDung,
      'phantich': Criterion.phanTich, 'phântích': Criterion.phanTich,
    };
    return map[k];
  }

  /// Trả về null nếu câu hỏi hợp lệ, ngược lại trả về lý do bị loại.
  /// Truyền [sourceText] để kiểm tra trích dẫn có nằm trong tài liệu gốc.
  String? validate({String? sourceText}) {
    if (text.trim().isEmpty) return 'Thiếu nội dung câu hỏi';
    if (options.length != 4) return 'Phải có đúng 4 đáp án';
    if (options.map((e) => e.trim()).toSet().length != 4) {
      return 'Các đáp án bị trùng nhau';
    }
    if (correct < 0 || correct > 3) return 'Đáp án đúng không hợp lệ';
    if (sourceText != null) {
      final quote = _norm(sourceQuote ?? '');
      if (quote.isEmpty || !_norm(sourceText).contains(quote)) {
        return 'Trích dẫn không có trong tài liệu';
      }
    }
    return null;
  }

  static String _norm(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// Kết quả đọc một câu hỏi từ JSON của AI: hoặc có câu hỏi, hoặc có lý do lỗi.
class AiParse {
  final Question? question;
  final String? reason;
  const AiParse.ok(Question this.question) : reason = null;
  const AiParse.fail(String this.reason) : question = null;
}
