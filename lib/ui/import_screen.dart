import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../platform_support.dart';
import '../ingest/document_extractor.dart';
import '../ingest/extracted_doc.dart';
import '../ingest/text_quality.dart';
import '../settings/settings_controller.dart';
import 'review_text_screen.dart';
import 'settings_sheet.dart';
import 'theme/app_theme.dart';
import 'widgets/adaptive.dart';
import 'widgets/motion.dart';
import 'widgets/surfaces.dart';

/// Bước 1: chọn tài liệu (ảnh, PDF, Word, PowerPoint, văn bản).
class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  final DocumentExtractor _extractor = DocumentExtractor();
  final ImagePicker _images = ImagePicker();

  bool _busy = false;
  String _progress = '';
  String? _error;

  @override
  void dispose() {
    unawaited(_extractor.dispose());
    super.dispose();
  }

  Future<void> _run(Future<ExtractedDoc?> Function() job) async {
    setState(() {
      _busy = true;
      _error = null;
      _progress = 'Đang chuẩn bị...';
    });
    try {
      final doc = await job();
      if (doc == null || !mounted) return;
      await Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => ReviewTextScreen(doc: doc),
      ));
    } on ExtractException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'Không đọc được tài liệu. ($e)');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _setProgress(String m) {
    if (mounted) setState(() => _progress = m);
  }

  Future<void> _camera() => _run(() async {
        final x = await _images.pickImage(
            source: ImageSource.camera, imageQuality: 92);
        if (x == null) return null;
        return _extractor.fromImages([x.path], onProgress: _setProgress);
      });

  Future<void> _gallery() => _run(() async {
        final xs = await _images.pickMultiImage(imageQuality: 92, limit: 10);
        if (xs.isEmpty) return null;
        return _extractor.fromImages(xs.map((e) => e.path).toList(),
            onProgress: _setProgress);
      });

  Future<void> _file() => _run(() async {
        // Bản file_picker mới trả về danh sách tệp (rỗng nếu người dùng hủy).
        final files = await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: DocumentExtractor.supportedExtensions,
        );
        if (files.isEmpty) return null;
        final f = files.first;
        if (f.path == null) return null;
        return _extractor.fromFile(f.path!,
            displayName: f.name, onProgress: _setProgress);
      });

  Future<void> _paste() async {
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => ReviewTextScreen(
        doc: const ExtractedDoc(
          name: 'Văn bản dán vào',
          text: '',
          quality: TextQuality.empty,
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.text;
    final s = SettingsScope.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Tạo bộ đề')),
      body: SafeArea(
        child: AbsorbPointer(
          absorbing: _busy,
          child: ListView(
            padding: pagePadding(context),
            children: [
              FadeSlideIn(
                child: Text('Chọn tài liệu để học', style: t.title1),
              ),
              const SizedBox(height: 8),
              Text(
                'Ảnh chụp trang sách, PDF, Word, PowerPoint hoặc văn bản. '
                'App đọc chữ rồi bạn xem và sửa lại trước khi tạo câu hỏi.',
                style: t.footnote,
              ),
              const SizedBox(height: 24),

              // Chế độ AI hiện tại
              SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          s.aiMode == AiMode.offline
                              ? Icons.phone_android_rounded
                              : Icons.cloud_outlined,
                          size: 20,
                          color: p.accent,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('Chế độ ${s.aiMode.label}',
                              style: t.headline),
                        ),
                        TextButton(
                          onPressed: () => showSettingsSheet(context),
                          child: const Text('Đổi'),
                        ),
                      ],
                    ),
                    if (s.aiMode == AiMode.offline) ...[
                      const SizedBox(height: 4),
                      Text(
                        AiModeInfo.offlineLimits,
                        style: t.footnote.copyWith(color: p.warning),
                      ),
                    ] else
                      Text(s.aiMode.summary, style: t.footnote),
                  ],
                ),
              ),

              const SectionHeader('Nguồn tài liệu'),
              GroupedList(children: [
                ListRow(
                  icon: Icons.photo_camera_rounded,
                  title: 'Chụp ảnh',
                  subtitle: PlatformSupport.camera
                      ? 'Chụp trang sách hoặc vở'
                      : PlatformSupport.unsupportedOnDesktop,
                  chevron: PlatformSupport.camera,
                  enabled: PlatformSupport.camera,
                  onTap: _camera,
                ),
                ListRow(
                  icon: Icons.photo_library_rounded,
                  title: 'Ảnh từ thư viện',
                  subtitle: 'Chọn một hoặc nhiều ảnh (tối đa 10)',
                  chevron: true,
                  onTap: _gallery,
                ),
                ListRow(
                  icon: Icons.description_rounded,
                  title: 'Tệp PDF, Word, PowerPoint',
                  subtitle: 'Cũng nhận .txt, .md, .csv',
                  chevron: true,
                  onTap: _file,
                ),
                ListRow(
                  icon: Icons.edit_note_rounded,
                  title: 'Dán hoặc gõ văn bản',
                  subtitle: 'Không cần đọc, đi thẳng tới bước xem lại',
                  chevron: true,
                  onTap: _paste,
                ),
              ]),

              if (_busy) ...[
                const SizedBox(height: 24),
                SurfaceCard(
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                      const SizedBox(width: 16),
                      Expanded(child: Text(_progress, style: t.subhead)),
                    ],
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 24),
                SurfaceCard(
                  borderColor: p.danger.withValues(alpha: 0.5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.error_outline_rounded,
                          size: 20, color: p.danger),
                      const SizedBox(width: 12),
                      Expanded(child: Text(_error!, style: t.subhead)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
