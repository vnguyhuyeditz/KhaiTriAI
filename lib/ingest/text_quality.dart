/// Chấm điểm chất lượng chữ vừa đọc được (từ PDF, Word, OCR...).
/// Thuần Dart, không phụ thuộc thư viện nào nên test được dễ dàng.
enum QualityLevel { good, fair, poor }

class TextQuality {
  /// 0.0 (rất tệ) đến 1.0 (rất tốt).
  final double score;
  final QualityLevel level;

  /// Lý do bằng tiếng Việt, hiện cho người dùng.
  final List<String> issues;

  const TextQuality(this.score, this.level, this.issues);

  static const empty = TextQuality(0, QualityLevel.poor, ['Không đọc được chữ nào']);
}

final RegExp _letter = RegExp(r'\p{L}', unicode: true);
final RegExp _weird = RegExp('[\u{FFFD}\u{E000}-\u{F8FF}\u{0000}-\u{0008}\u{000B}\u{000C}\u{000E}-\u{001F}]');

int _count(RegExp re, String s) => re.allMatches(s).length;

/// Đếm ký tự không phải khoảng trắng.
int _nonSpace(String s) => s.replaceAll(RegExp(r'\s+'), '').length;

TextQuality assessText(String text) {
  final n = _nonSpace(text);
  if (n == 0) return TextQuality.empty;

  final issues = <String>[];
  var score = 1.0;

  final letterRatio = _count(_letter, text) / n;
  if (letterRatio < 0.7) {
    score -= (0.7 - letterRatio) * 1.5;
    if (letterRatio < 0.55) {
      issues.add('Có nhiều ký hiệu hoặc số hơn chữ (công thức, bảng biểu?)');
    }
  }

  final weirdRatio = _count(_weird, text) / n;
  if (weirdRatio > 0) {
    score -= (weirdRatio * 20).clamp(0.0, 0.5).toDouble();
    if (weirdRatio > 0.005) issues.add('Có ký tự lạ, có thể bị lỗi mã hóa');
  }

  final tokens = text.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
  if (tokens.isNotEmpty) {
    final longRatio = tokens.where((w) => w.length > 25).length / tokens.length;
    if (longRatio > 0.05) {
      score -= 0.2;
      issues.add('Nhiều từ dính liền nhau bất thường');
    }
    final singles = tokens
        .where((w) => w.length == 1 && _count(_letter, w) == 1)
        .length;
    if (tokens.length >= 20 && singles / tokens.length > 0.3) {
      score -= 0.25;
      issues.add('Nhiều chữ cái đứng lẻ, có thể ảnh bị mờ hoặc nghiêng');
    }
  }

  if (n < 150) {
    score -= 0.3;
    issues.add('Văn bản quá ngắn để tạo nhiều câu hỏi');
  }

  score = score.clamp(0.0, 1.0).toDouble();
  final level = score >= 0.75
      ? QualityLevel.good
      : (score >= 0.5 ? QualityLevel.fair : QualityLevel.poor);
  return TextQuality(score, level, issues);
}

/// Một trang PDF có "lớp chữ" bị hỏng hoặc không có (ảnh quét) thì cần OCR.
bool looksGarbled(String pageText) {
  final n = _nonSpace(pageText);
  if (n < 20) return true;
  if (_count(_weird, pageText) / n > 0.02) return true;
  if (_count(_letter, pageText) / n < 0.5) return true;
  return false;
}
