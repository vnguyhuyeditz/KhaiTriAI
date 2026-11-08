import '../../models/question.dart';
import '../question_generator.dart';

/// Lời dặn cho từng loại tiêu chí để mô hình nhỏ hỏi đúng kiểu.
String criterionGuide(Criterion c) {
  switch (c) {
    case Criterion.nho:
      return 'GHI NHỚ: hỏi lại một thông tin, định nghĩa hoặc sự kiện có ghi rõ trong đoạn văn.';
    case Criterion.hieu:
      return 'HIỂU BẢN CHẤT: hỏi vì sao, nghĩa là gì, hoặc ý chính của đoạn văn.';
    case Criterion.vanDung:
      return 'VẬN DỤNG: đưa ra một tình huống ngắn mới, hỏi áp dụng ý trong đoạn văn vào đó.';
    case Criterion.phanTich:
      return 'PHÂN TÍCH: hỏi so sánh, nguyên nhân và kết quả, hoặc điểm khác nhau giữa các ý trong đoạn văn.';
  }
}

/// Lệnh gửi cho mô hình: ngắn, có ví dụ định dạng, mỗi lần chỉ xin 1 câu.
String buildQuestionPrompt(String chunk, Criterion c) {
  return '''Bạn là giáo viên tạo câu hỏi trắc nghiệm bằng tiếng Việt.
Đọc ĐOẠN VĂN rồi tạo đúng 1 câu hỏi trắc nghiệm, chỉ dựa vào đoạn văn đó.

Yêu cầu:
- Có 4 đáp án, chỉ 1 đáp án đúng, 3 đáp án sai nghe hợp lý nhưng khác nhau.
- Loại câu hỏi: ${criterionGuide(c)}
- Viết đủ cả 4 đáp án A, B, C, D, không bỏ đáp án nào.
- "dap_an_dung" chỉ ghi MỘT chữ cái: A, B, C hoặc D.
- "trich_dan" là MỘT câu chép NGUYÊN VĂN từ đoạn văn, chứng minh đáp án đúng.
- "giai_thich" giải thích ngắn (1 câu) vì sao đáp án đúng là đúng.
- Chỉ trả về JSON, không viết gì khác.

Mẫu định dạng:
{"cau_hoi": "...", "A": "...", "B": "...", "C": "...", "D": "...", "dap_an_dung": "B", "giai_thich": "...", "trich_dan": "..."}

ĐOẠN VĂN:
"""
$chunk
"""

JSON:''';
}

/// Lấy object JSON đầu tiên trong câu trả lời của mô hình. Chịu được rào ```,
/// chữ thừa trước/sau, dấu ngoặc nằm trong chuỗi. Trả về null nếu không có.
String? extractJsonObject(String reply) {
  final start = reply.indexOf('{');
  if (start < 0) return null;
  var depth = 0;
  var inString = false;
  var escaped = false;
  for (var i = start; i < reply.length; i++) {
    final ch = reply[i];
    if (inString) {
      if (escaped) {
        escaped = false;
      } else if (ch == r'\') {
        escaped = true;
      } else if (ch == '"') {
        inString = false;
      }
      continue;
    }
    if (ch == '"') {
      inString = true;
    } else if (ch == '{') {
      depth++;
    } else if (ch == '}') {
      depth--;
      if (depth == 0) return reply.substring(start, i + 1);
    }
  }
  return null;
}

/// Đọc câu trả lời của mô hình thành câu hỏi và kiểm tra cơ bản.
/// [criterion] là loại câu app đã xin: dùng luôn, không tin nhãn mô hình tự ghi.
ParseResult parseModelReply(String reply, String chunk, String idPrefix,
    {Criterion? criterion}) {
  final json = extractJsonObject(reply);
  if (json == null) {
    return ParseResult([], [
      reply.contains('{')
          ? 'Mô hình trả lời bị cắt dở (JSON chưa đóng)'
          : 'Mô hình không trả về JSON',
    ]);
  }
  return parseAiQuestions('[$json]', chunk,
      idPrefix: idPrefix, forcedCriterion: criterion);
}
