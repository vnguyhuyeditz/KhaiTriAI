import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart' show Printing;
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;
import 'package:xml/xml.dart';

import 'extracted_doc.dart';
import 'ocr_service.dart';
import 'text_cleaner.dart';
import 'text_quality.dart';

typedef ProgressCallback = void Function(String message);

/// Đọc chữ từ mọi loại tài liệu phổ biến, theo thứ tự ưu tiên:
/// lấy chữ trực tiếp (chính xác nhất) -> OCR (khi là ảnh hoặc PDF quét).
class DocumentExtractor {
  DocumentExtractor({OcrService? ocr}) : _ocr = ocr ?? OcrService();

  final OcrService _ocr;

  static const _textExt = {'txt', 'md', 'csv'};
  static const _imageExt = {'png', 'jpg', 'jpeg', 'webp', 'bmp', 'heic', 'heif'};
  static const maxFileBytes = 40 * 1024 * 1024;
  static const maxOcrPages = 40;

  /// Các đuôi file được chấp nhận (dùng cho bộ chọn tệp).
  static const supportedExtensions = [
    'pdf', 'docx', 'pptx', 'txt', 'md', 'csv',
    'png', 'jpg', 'jpeg', 'webp', 'bmp',
  ];

  Future<void> dispose() => _ocr.close();

  // ---------------------------------------------------------------------
  ExtractedDoc fromPastedText(String text) =>
      _finish('Văn bản dán vào', text, const []);

  Future<ExtractedDoc> fromImages(
    List<String> paths, {
    ProgressCallback? onProgress,
  }) async {
    if (paths.isEmpty) throw const ExtractException('Chưa chọn ảnh nào.');
    final parts = <String>[];
    final warnings = <String>[
      'Ảnh được đọc bằng OCR: công thức, hình vẽ và chữ viết tay có thể bị sai hoặc thiếu.',
    ];
    for (var i = 0; i < paths.length; i++) {
      onProgress?.call('Đang đọc ảnh ${i + 1}/${paths.length}...');
      final t = await _ocr.recognizeFile(paths[i]);
      if (t.trim().isEmpty) warnings.add('Ảnh ${i + 1} không đọc được chữ nào.');
      parts.add(t);
    }
    return _finish(
      paths.length == 1 ? _baseName(paths.first) : '${paths.length} ảnh',
      parts.join('\n\n'),
      warnings,
    );
  }

  Future<ExtractedDoc> fromFile(
    String path, {
    String? displayName,
    ProgressCallback? onProgress,
  }) async {
    final file = File(path);
    if (!await file.exists()) {
      throw const ExtractException('Không tìm thấy tệp.');
    }
    if (await file.length() > maxFileBytes) {
      throw const ExtractException('Tệp quá lớn (tối đa 40 MB).');
    }
    final name = displayName ?? _baseName(path);
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';

    if (_textExt.contains(ext)) {
      final text = utf8.decode(await file.readAsBytes(), allowMalformed: true);
      return _finish(name, text, const []);
    }
    if (_imageExt.contains(ext)) {
      return fromImages([path], onProgress: onProgress);
    }
    switch (ext) {
      case 'docx':
        return _docx(name, await file.readAsBytes());
      case 'pptx':
        return _pptx(name, await file.readAsBytes());
      case 'pdf':
        return _pdf(name, await file.readAsBytes(), onProgress);
      case 'doc':
      case 'ppt':
        throw const ExtractException(
          'Định dạng .doc/.ppt cũ chưa được hỗ trợ. '
          'Hãy mở bằng Word/PowerPoint và lưu lại thành .docx/.pptx.',
        );
      default:
        throw ExtractException('Chưa hỗ trợ tệp ".$ext".');
    }
  }

  // ---------------------------------------------------------------------
  ExtractedDoc _finish(String name, String raw, List<String> warnings) {
    final text = cleanText(raw);
    return ExtractedDoc(
      name: name,
      text: text,
      quality: assessText(text),
      warnings: warnings,
    );
  }

  String _baseName(String path) => path.split(RegExp(r'[\\/]')).last;

  Uint8List _bytesOf(ArchiveFile f) =>
      Uint8List.fromList((f.content as List).cast<int>());

  // ---------------------------------------------------------------------
  // Word
  ExtractedDoc _docx(String name, Uint8List bytes) {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (_) {
      throw const ExtractException('Không mở được tệp Word (hỏng hoặc có mật khẩu).');
    }
    final f = archive.findFile('word/document.xml');
    if (f == null) {
      throw const ExtractException('Tệp Word không hợp lệ.');
    }
    final xml = utf8.decode(_bytesOf(f), allowMalformed: true);
    final buf = StringBuffer();
    for (final p in XmlDocument.parse(xml).findAllElements('p', namespaceUri: '*')) {
      final line = p
          .findAllElements('t', namespaceUri: '*')
          .map((e) => e.innerText)
          .join();
      if (line.trim().isNotEmpty) buf.writeln(line);
    }
    final warnings = <String>[
      if (xml.contains('<m:oMath'))
        'Tệp có công thức Toán. Công thức không đọc được thành chữ nên có thể bị thiếu.',
      if (xml.contains('<w:drawing') || xml.contains('<w:pict'))
        'Tệp có hình ảnh. Chữ trong hình không được đọc.',
    ];
    return _finish(name, buf.toString(), warnings);
  }

  // ---------------------------------------------------------------------
  // PowerPoint
  ExtractedDoc _pptx(String name, Uint8List bytes) {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (_) {
      throw const ExtractException('Không mở được tệp PowerPoint (hỏng hoặc có mật khẩu).');
    }
    final re = RegExp(r'^ppt/slides/slide(\d+)\.xml$');
    final slides = <int, ArchiveFile>{};
    for (final f in archive.files) {
      final m = re.firstMatch(f.name);
      if (m != null) slides[int.parse(m.group(1)!)] = f;
    }
    if (slides.isEmpty) throw const ExtractException('Tệp PowerPoint không có slide nào.');

    final buf = StringBuffer();
    var hasPictures = false;
    for (final i in (slides.keys.toList()..sort())) {
      final xml = utf8.decode(_bytesOf(slides[i]!), allowMalformed: true);
      if (xml.contains('<p:pic')) hasPictures = true;
      for (final p in XmlDocument.parse(xml).findAllElements('p', namespaceUri: '*')) {
        final line = p
            .findAllElements('t', namespaceUri: '*')
            .map((e) => e.innerText)
            .join();
        if (line.trim().isNotEmpty) buf.writeln(line);
      }
      buf.writeln();
    }
    return _finish(name, buf.toString(), [
      if (hasPictures) 'Slide có hình ảnh. Chữ trong hình không được đọc.',
    ]);
  }

  // ---------------------------------------------------------------------
  // PDF: lấy chữ trực tiếp; trang nào hỏng/ảnh quét thì OCR.
  Future<ExtractedDoc> _pdf(
    String name,
    Uint8List bytes,
    ProgressCallback? onProgress,
  ) async {
    final sf.PdfDocument doc;
    try {
      doc = sf.PdfDocument(inputBytes: bytes);
    } catch (_) {
      throw const ExtractException('Không mở được PDF (hỏng hoặc có mật khẩu).');
    }

    final pages = <String>[];
    var ocrCount = 0;
    var skipped = 0;
    var n = 0;
    try {
      n = doc.pages.count;
      final extractor = sf.PdfTextExtractor(doc);
      for (var i = 0; i < n; i++) {
        onProgress?.call('Đang đọc trang ${i + 1}/$n...');
        var t = '';
        try {
          t = extractor.extractText(startPageIndex: i, endPageIndex: i);
        } catch (_) {}
        if (looksGarbled(t)) {
          if (ocrCount < maxOcrPages) {
            onProgress?.call('Trang ${i + 1}/$n là ảnh, đang OCR...');
            t = await _ocrPdfPage(bytes, i);
            ocrCount++;
          } else {
            skipped++;
          }
        }
        pages.add(t);
        await Future<void>.delayed(Duration.zero); // nhường giao diện cập nhật
      }
    } finally {
      doc.dispose();
    }

    final warnings = <String>[];
    var text = pages.join('\n\n');

    // Lớp chữ của PDF tệ mà chưa OCR trang nào: thử OCR toàn bộ rồi chọn bản tốt hơn.
    if (ocrCount == 0 && n <= maxOcrPages && assessText(cleanText(text)).level == QualityLevel.poor) {
      onProgress?.call('Chữ trong PDF kém, đang thử OCR toàn bộ...');
      final ocrPages = <String>[];
      for (var i = 0; i < n; i++) {
        onProgress?.call('OCR trang ${i + 1}/$n...');
        ocrPages.add(await _ocrPdfPage(bytes, i));
        await Future<void>.delayed(Duration.zero);
      }
      final ocrText = ocrPages.join('\n\n');
      if (assessText(cleanText(ocrText)).score > assessText(cleanText(text)).score) {
        text = ocrText;
        ocrCount = n;
      }
    }

    if (ocrCount > 0) {
      warnings.add('$ocrCount trang được đọc bằng OCR nên có thể có lỗi chính tả hoặc thiếu công thức.');
    }
    if (skipped > 0) {
      warnings.add('$skipped trang ảnh bị bỏ qua vì tài liệu quá dài (tối đa $maxOcrPages trang OCR).');
    }
    return _finish(name, text, warnings);
  }

  Future<String> _ocrPdfPage(Uint8List pdfBytes, int pageIndex) async {
    final dir = await getTemporaryDirectory();
    await for (final raster
        in Printing.raster(pdfBytes, pages: [pageIndex], dpi: 160)) {
      final png = await raster.toPng();
      final tmp = File('${dir.path}/ocr_page_$pageIndex.png');
      await tmp.writeAsBytes(png, flush: true);
      try {
        return await _ocr.recognizeFile(tmp.path);
      } finally {
        if (await tmp.exists()) await tmp.delete();
      }
    }
    return '';
  }
}
