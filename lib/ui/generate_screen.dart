import 'dart:async';

import 'package:flutter/material.dart';

import '../ai/offline/offline_engine.dart';
import '../ai/offline/offline_generator.dart';
import 'question_review_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/pressable.dart';
import 'widgets/surfaces.dart';

/// Chạy AI offline tạo câu hỏi từ các đoạn tài liệu, hiện tiến độ.
class GenerateScreen extends StatefulWidget {
  final String docName;
  final List<String> chunks;
  final int count;

  const GenerateScreen({
    super.key,
    required this.docName,
    required this.chunks,
    required this.count,
  });

  @override
  State<GenerateScreen> createState() => _GenerateScreenState();
}

class _GenerateScreenState extends State<GenerateScreen> {
  final OfflineQuestionGenerator _gen = OfflineQuestionGenerator();
  GenerationProgress? _progress;
  String? _error;
  GenerationResult? _emptyResult;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    unawaited(_start());
  }

  @override
  void dispose() {
    _gen.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() {
      _error = null;
      _emptyResult = null;
    });
    try {
      final r = await _gen.run(
        widget.chunks,
        count: widget.count,
        onProgress: (p) {
          if (mounted && !_leaving) setState(() => _progress = p);
        },
      );
      if (!mounted || _leaving) return;
      if (r.cancelled) {
        Navigator.of(context).pop();
        return;
      }
      if (r.questions.isEmpty) {
        setState(() => _emptyResult = r);
        return;
      }
      await Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
        builder: (_) => QuestionReviewScreen(
          docName: widget.docName,
          questions: r.questions,
          requested: widget.count,
        ),
      ));
    } on OfflineEngineException catch (e) {
      if (mounted && !_leaving) setState(() => _error = e.message);
    } catch (e) {
      if (mounted && !_leaving) {
        setState(() => _error = 'Có lỗi khi tạo câu hỏi: $e');
      }
    }
  }

  Future<void> _confirmCancel() async {
    final stop = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dừng tạo câu hỏi?'),
        content: const Text('Các câu đang tạo sẽ bị bỏ.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Tiếp tục'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Dừng'),
          ),
        ],
      ),
    );
    if (stop == true && mounted) {
      _leaving = true;
      _gen.cancel();
      // Về màn hình trước ngay, không đợi mô hình dừng xong.
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.text;
    final failed = _error != null || _emptyResult != null;
    final prog = _progress;

    return PopScope(
      canPop: failed,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmCancel();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Đang tạo câu hỏi')),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: failed
                ? _failure(p, t)
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 88,
                        height: 88,
                        child: CircularProgressIndicator(
                          strokeWidth: 6,
                          value: (prog == null || prog.attempts == 0)
                              ? null
                              : prog.accepted / prog.target,
                          color: p.accent,
                          backgroundColor: p.accentSoft,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        prog == null ? 'Đang chuẩn bị...' : prog.message,
                        style: t.headline,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      if (prog != null && prog.attempts > 0)
                        Text(
                          'Đã có ${prog.accepted}/${prog.target} câu đạt · '
                          'lần thử thứ ${prog.attempts}',
                          style: t.footnote,
                        ),
                      if (prog?.lastNote != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          prog!.lastNote!,
                          style: t.footnote.copyWith(color: p.warning),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 24),
                      Text(
                        'Mô hình chạy ngay trên máy nên mất vài phút. '
                        'Hãy giữ màn hình sáng và đóng bớt các app khác.',
                        style: t.footnote,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      AppButton(
                        label: 'Dừng',
                        primary: false,
                        onPressed: _confirmCancel,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _failure(AppPalette p, TextTheme t) {
    final reasons = _emptyResult?.rejected.take(4).toList() ?? const <String>[];
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline_rounded, size: 48, color: p.danger),
        const SizedBox(height: 16),
        Text(
          _error ?? 'Chưa tạo được câu hỏi nào đạt yêu cầu',
          style: t.headline,
          textAlign: TextAlign.center,
        ),
        if (reasons.isNotEmpty) ...[
          const SizedBox(height: 12),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Lý do các lần thử bị loại', style: t.footnote),
                const SizedBox(height: 6),
                for (final r in reasons) Text('• $r', style: t.footnote),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Thử lại, cắt nội dung rõ ràng hơn, hoặc dùng chế độ Online cho tài liệu khó.',
            style: t.footnote,
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 24),
        if (_emptyResult != null)
          AppButton(label: 'Thử lại', onPressed: _start),
        if (_emptyResult != null) const SizedBox(height: 8),
        AppButton(
          label: 'Quay lại',
          primary: false,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
