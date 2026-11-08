import 'dart:async';

import 'package:flutter/material.dart';

import '../ingest/extracted_doc.dart';
import '../ingest/text_cleaner.dart';
import '../ingest/text_quality.dart';
import '../settings/settings_controller.dart';
import 'generate_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/adaptive.dart';
import 'widgets/pressable.dart';
import 'widgets/surfaces.dart';

/// Bước 2: xem chữ đã đọc, sửa tay, kiểm tra chất lượng, xem các đoạn đã cắt.
class ReviewTextScreen extends StatefulWidget {
  final ExtractedDoc doc;
  const ReviewTextScreen({super.key, required this.doc});

  @override
  State<ReviewTextScreen> createState() => _ReviewTextScreenState();
}

class _ReviewTextScreenState extends State<ReviewTextScreen> {
  late final TextEditingController _text =
      TextEditingController(text: widget.doc.text);
  late TextQuality _quality = widget.doc.quality;
  late List<String> _chunks = chunkText(widget.doc.text);
  Timer? _debounce;
  int _count = 10;

  @override
  void dispose() {
    _debounce?.cancel();
    _text.dispose();
    super.dispose();
  }

  void _onChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      final cleaned = cleanText(_text.text);
      setState(() {
        _quality = assessText(cleaned);
        _chunks = chunkText(cleaned);
      });
    });
  }

  Future<void> _generate() async {
    final s = SettingsScope.of(context);
    if (s.aiMode == AiMode.online) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Chế độ Online chưa có'),
          content: const Text(
            'Chế độ Online sẽ được thêm ở bản sau. Hãy chuyển sang chế độ '
            'Offline trong Cài đặt để tạo câu hỏi bằng AI trên máy.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Đã hiểu'),
            ),
          ],
        ),
      );
      return;
    }
    // Chốt lại nội dung vừa sửa trước khi tạo.
    final chunks = chunkText(cleanText(_text.text));
    if (chunks.isEmpty || !mounted) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => GenerateScreen(
        docName: widget.doc.name,
        chunks: chunks,
        count: _count,
      ),
    ));
  }

  void _showChunks() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final p = ctx.palette;
        final t = ctx.text;
        return FractionallySizedBox(
          heightFactor: 0.85,
          child: Container(
            decoration: BoxDecoration(
              color: p.bg,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(top: BorderSide(color: p.border)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 14),
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: p.secondary.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('${_chunks.length} đoạn sẽ đưa cho AI',
                        style: t.title2),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: pagePadding(context),
                    itemCount: _chunks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => SurfaceCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Đoạn ${i + 1} · ${_chunks[i].length} ký tự',
                              style: t.footnote),
                          const SizedBox(height: 6),
                          Text(_chunks[i], style: t.subhead),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.text;

    final Color tone;
    final IconData icon;
    final String title;
    switch (_quality.level) {
      case QualityLevel.good:
        tone = p.positive;
        icon = Icons.check_circle_rounded;
        title = 'Chữ đọc khá tốt';
      case QualityLevel.fair:
        tone = p.warning;
        icon = Icons.info_rounded;
        title = 'Chữ đọc tạm được, nên xem lại';
      case QualityLevel.poor:
        tone = p.danger;
        icon = Icons.warning_rounded;
        title = 'Chữ đọc chưa tốt';
    }
    final notes = [..._quality.issues, ...widget.doc.warnings];
    final chars = _text.text.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Xem lại chữ đã đọc')),
      body: SafeArea(
        child: ListView(
          padding: pagePadding(context),
          children: [
            Text(widget.doc.name, style: t.footnote),
            const SizedBox(height: 12),
            SurfaceCard(
              borderColor: tone.withValues(alpha: 0.5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: tone, size: 22),
                      const SizedBox(width: 8),
                      Expanded(child: Text(title, style: t.headline)),
                    ],
                  ),
                  for (final n in notes) ...[
                    const SizedBox(height: 8),
                    Text('• $n', style: t.footnote),
                  ],
                  if (_quality.level == QualityLevel.poor) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Gợi ý: chụp lại rõ và thẳng hơn, sửa chữ ở khung bên dưới, '
                      'hoặc dùng chế độ Online cho tài liệu khó.',
                      style: t.footnote.copyWith(color: p.label),
                    ),
                  ],
                ],
              ),
            ),
            const SectionHeader('Nội dung (chạm vào để sửa)'),
            SurfaceCard(
              child: TextField(
                controller: _text,
                onChanged: _onChanged,
                minLines: 10,
                maxLines: 20,
                keyboardType: TextInputType.multiline,
                style: t.body,
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  hintText: 'Dán hoặc gõ nội dung vào đây...',
                  hintStyle: t.body.copyWith(color: p.secondary),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text('$chars ký tự · ${_chunks.length} đoạn', style: t.footnote),
            const SizedBox(height: 16),
            AppButton(
              label: 'Xem các đoạn đã cắt',
              icon: Icons.view_agenda_outlined,
              primary: false,
              onPressed: _chunks.isEmpty ? null : _showChunks,
            ),
            const SizedBox(height: 8),
            const SectionHeader('Số câu muốn tạo'),
            SegmentedChoice<int>(
              values: const [5, 10, 15],
              selected: _count,
              labelOf: (v) => '$v câu',
              onChanged: (v) => setState(() => _count = v),
            ),
            const SizedBox(height: 16),
            AppButton(
              label: 'Tạo câu hỏi bằng AI',
              icon: Icons.auto_awesome_rounded,
              onPressed: _chunks.isEmpty ? null : _generate,
            ),
            const SizedBox(height: 8),
            Text(
              'AI chạy ngay trên máy, mất vài phút. Cần file mô hình đã đóng gói trong app.',
              style: t.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
