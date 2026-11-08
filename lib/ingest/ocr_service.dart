import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Đọc chữ trong ảnh hoàn toàn trên máy (Google ML Kit).
/// Dùng bộ nhận dạng Latin, đọc được tiếng Việt có dấu.
class OcrService {
  TextRecognizer? _recognizer;

  Future<String> recognizeFile(String path) async {
    final r = _recognizer ??= TextRecognizer(script: TextRecognitionScript.latin);
    final result = await r.processImage(InputImage.fromFilePath(path));
    return result.blocks
        .map((b) => b.lines.map((l) => l.text).join('\n'))
        .join('\n\n');
  }

  Future<void> close() async {
    await _recognizer?.close();
    _recognizer = null;
  }
}
