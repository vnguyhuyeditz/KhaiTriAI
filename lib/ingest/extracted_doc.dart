import 'text_quality.dart';

/// Kết quả đọc một tài liệu: chữ đã làm sạch + đánh giá chất lượng.
class ExtractedDoc {
  final String name;
  final String text;
  final TextQuality quality;

  /// Cảnh báo bằng tiếng Việt (ví dụ "có công thức, có thể thiếu").
  final List<String> warnings;

  const ExtractedDoc({
    required this.name,
    required this.text,
    required this.quality,
    this.warnings = const [],
  });
}

/// Lỗi có thông điệp thân thiện để hiện thẳng cho người dùng.
class ExtractException implements Exception {
  final String message;
  const ExtractException(this.message);

  @override
  String toString() => message;
}
