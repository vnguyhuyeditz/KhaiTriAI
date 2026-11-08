import '../models/question.dart';

// Kiểm tra sâu hơn `Question.validate`, dùng chung cho AI offline và online.
// Thuần Dart.

final RegExp _viChars = RegExp(
  '[ăâđêôơưàáảãạằắẳẵặầấẩẫậèéẻẽẹềếểễệìíỉĩịòóỏõọồốổỗộờớởỡợùúủũụừứửữựỳýỷỹỵ]',
);
const Set<String> _viWords = {
  'là', 'của', 'và', 'không', 'được', 'trong', 'một', 'các', 'có', 'cho',
  'với', 'này', 'khi', 'để', 'những', 'nào', 'đúng', 'sai', 'nếu', 'thì',
};

List<String> _tokens(String s) => s
    .toLowerCase()
    .split(RegExp(r'[^\p{L}\p{N}]+', unicode: true))
    .where((e) => e.isNotEmpty)
    .toList();

/// Đoán một đoạn chữ có phải tiếng Việt không (không cần thư viện nhận diện).
bool isLikelyVietnamese(String s) {
  final lower = s.toLowerCase();
  final letters = RegExp(r'\p{L}', unicode: true).allMatches(lower).length;
  if (letters == 0) return false;
  if (_viChars.allMatches(lower).length / letters >= 0.03) return true;
  return _tokens(lower).where(_viWords.contains).length >= 2;
}

double _jaccard(Set<String> a, Set<String> b) {
  if (a.isEmpty || b.isEmpty) return 0;
  final inter = a.intersection(b).length;
  return inter / (a.length + b.length - inter);
}

String _normOpt(String s) =>
    _tokens(s).join(' ');

class CheckResult {
  final List<Question> accepted;
  final List<String> rejected;
  const CheckResult(this.accepted, this.rejected);
}

/// Lọc danh sách câu hỏi ứng viên. [existing] là các câu đã có từ trước
/// (để loại câu trùng). [sourceText] là đoạn tài liệu gốc.
CheckResult checkQuestions(
  List<Question> candidates, {
  String? sourceText,
  List<Question> existing = const [],
}) {
  final accepted = <Question>[];
  final rejected = <String>[];
  final seen = <Set<String>>[
    for (final q in existing) _tokens(q.text).toSet(),
  ];
  final sourceIsVi = sourceText != null && isLikelyVietnamese(sourceText);

  for (var i = 0; i < candidates.length; i++) {
    final q = candidates[i];
    final tag = 'Câu ${i + 1}';

    final base = q.validate(sourceText: sourceText);
    if (base != null) {
      rejected.add('$tag: $base');
      continue;
    }
    if (q.text.trim().length < 10) {
      rejected.add('$tag: câu hỏi quá ngắn');
      continue;
    }
    if (q.text.length > 400) {
      rejected.add('$tag: câu hỏi quá dài');
      continue;
    }
    if (q.options.any((o) => o.trim().isEmpty || o.length > 200)) {
      rejected.add('$tag: đáp án rỗng hoặc quá dài');
      continue;
    }
    final norm = q.options.map(_normOpt).toList();
    if (norm.toSet().length != norm.length) {
      rejected.add('$tag: có đáp án giống nhau sau khi bỏ dấu câu');
      continue;
    }
    if (q.explanation.trim().length < 10) {
      rejected.add('$tag: thiếu lời giải thích');
      continue;
    }
    if (sourceIsVi && !isLikelyVietnamese(q.text)) {
      rejected.add('$tag: câu hỏi không viết bằng tiếng Việt');
      continue;
    }
    final words = _tokens(q.text).toSet();
    if (seen.any((s) => _jaccard(s, words) > 0.8)) {
      rejected.add('$tag: trùng với câu đã có');
      continue;
    }
    seen.add(words);
    accepted.add(q);
  }
  return CheckResult(accepted, rejected);
}
