import 'dart:convert';
import 'dart:math';

import '../data/sample_questions.dart';
import '../models/question.dart';

/// Kết quả đọc JSON từ AI: câu hợp lệ và lý do các câu bị loại.
class ParseResult {
  final List<Question> valid;
  final List<String> rejected;
  const ParseResult(this.valid, this.rejected);
}

/// Đọc chuỗi JSON (mảng các câu hỏi) do AI trả về, kiểm tra từng câu.
/// [sourceText] là đoạn tài liệu gốc để đối chiếu trích dẫn.
/// Lưu ý: [idPrefix] phải khác nhau giữa các lần tạo (ví dụ thêm mốc thời gian)
/// để chức năng so sánh 2 lần không nhầm câu của lần này với lần khác.
ParseResult parseAiQuestions(String jsonText, String sourceText,
    {String idPrefix = 'ai', Criterion? forcedCriterion}) {
  final valid = <Question>[];
  final rejected = <String>[];

  dynamic decoded;
  try {
    decoded = jsonDecode(jsonText);
  } catch (_) {
    return const ParseResult([], ['AI không trả về JSON hợp lệ']);
  }
  if (decoded is! List) {
    return const ParseResult([], ['JSON phải là một mảng các câu hỏi']);
  }

  for (var i = 0; i < decoded.length; i++) {
    final item = decoded[i];
    if (item is! Map) {
      rejected.add('Câu ${i + 1}: sai cấu trúc');
      continue;
    }
    final parsed = Question.parseAi(
        Map<String, dynamic>.from(item), '$idPrefix${i + 1}',
        forced: forcedCriterion);
    final q = parsed.question;
    if (q == null) {
      rejected.add('Câu ${i + 1}: ${parsed.reason}');
      continue;
    }
    final reason = q.validate(sourceText: sourceText);
    if (reason != null) {
      rejected.add('Câu ${i + 1}: $reason');
      continue;
    }
    valid.add(q);
  }
  return ParseResult(valid, rejected);
}

/// Giao diện chung để sau này thay bằng AI chạy trên máy.
abstract class QuestionGenerator {
  Future<List<Question>> generate(
    String sourceText, {
    int count = 10,
    bool shuffle = false,
  });
}

/// Bản tạm: lấy từ bộ câu hỏi viết tay. Khi gắn AI (Bước 5), tạo một lớp
/// khác cài đặt [QuestionGenerator], gọi mô hình, rồi dùng
/// [parseAiQuestions] để kiểm tra kết quả. Nếu lỗi thì quay về bản này.
class SampleQuestionGenerator implements QuestionGenerator {
  @override
  Future<List<Question>> generate(
    String sourceText, {
    int count = 10,
    bool shuffle = false,
  }) async {
    final n = count.clamp(1, sampleQuestions.length).toInt();

    // Chọn xoay vòng giữa 4 nhãn để bài ngắn vẫn cân bằng.
    final groups = {
      for (final c in Criterion.values)
        c: sampleQuestions.where((q) => q.criterion == c).toList(),
    };
    final picked = <Question>[];
    var round = 0;
    while (picked.length < n) {
      var added = false;
      for (final c in Criterion.values) {
        final g = groups[c]!;
        if (round < g.length && picked.length < n) {
          picked.add(g[round]);
          added = true;
        }
      }
      if (!added) break;
      round++;
    }

    picked.sort((a, b) =>
        sampleQuestions.indexOf(a).compareTo(sampleQuestions.indexOf(b)));
    if (shuffle) picked.shuffle(Random());
    return picked;
  }
}
