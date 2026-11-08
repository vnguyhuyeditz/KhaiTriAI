import 'package:flutter/material.dart';

import '../models/question.dart';
import 'quiz_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/adaptive.dart';
import 'widgets/pressable.dart';
import 'widgets/surfaces.dart';

/// Duyệt các câu hỏi AI vừa tạo: xóa câu không ưng, rồi làm bài.
class QuestionReviewScreen extends StatefulWidget {
  final String docName;
  final List<Question> questions;
  final int requested;

  const QuestionReviewScreen({
    super.key,
    required this.docName,
    required this.questions,
    required this.requested,
  });

  @override
  State<QuestionReviewScreen> createState() => _QuestionReviewScreenState();
}

class _QuestionReviewScreenState extends State<QuestionReviewScreen> {
  late final List<Question> _list = List.of(widget.questions);

  void _start() {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => QuizScreen(subject: widget.docName, questions: List.of(_list)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.text;

    return Scaffold(
      appBar: AppBar(title: const Text('Duyệt câu hỏi')),
      body: SafeArea(
        child: ListView(
          padding: pagePadding(context),
          children: [
            Text(
              widget.questions.length < widget.requested
                  ? 'Tạo được ${widget.questions.length}/${widget.requested} câu đạt yêu cầu.'
                  : 'Đã tạo ${widget.questions.length} câu.',
              style: t.footnote,
            ),
            const SizedBox(height: 4),
            Text(
              'Câu do AI nhỏ tạo ra có thể sai. Hãy xem lại và xóa câu không ưng.',
              style: t.footnote.copyWith(color: p.warning),
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < _list.length; i++) ...[
              _QuestionCard(
                index: i + 1,
                question: _list[i],
                onDelete: () => setState(() => _list.removeAt(i)),
              ),
              const SizedBox(height: 8),
            ],
            if (_list.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  'Bạn đã xóa hết câu hỏi.',
                  style: t.subhead,
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 16),
            AppButton(
              label: 'Làm bài với ${_list.length} câu',
              icon: Icons.play_arrow_rounded,
              onPressed: _list.isEmpty ? null : _start,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final int index;
  final Question question;
  final VoidCallback onDelete;

  const _QuestionCard({
    required this.index,
    required this.question,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.text;
    final q = question;

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Câu $index · ${q.criterion.label}', style: t.footnote),
              ),
              IconButton(
                tooltip: 'Xóa câu này',
                onPressed: onDelete,
                icon: Icon(Icons.delete_outline_rounded, color: p.danger),
              ),
            ],
          ),
          Text(q.text, style: t.headline),
          const SizedBox(height: 12),
          for (var i = 0; i < q.options.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    i == q.correct
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    size: 18,
                    color: i == q.correct ? p.positive : p.secondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${'ABCD'[i]}. ${q.options[i]}',
                      style: t.subhead.copyWith(
                        fontWeight:
                            i == q.correct ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 6),
          Text('Giải thích', style: t.caption),
          Text(q.explanation, style: t.footnote.copyWith(color: p.label)),
          if (q.sourceQuote != null && q.sourceQuote!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Trích từ tài liệu', style: t.caption),
            Text('“${q.sourceQuote}”', style: t.footnote),
          ],
        ],
      ),
    );
  }
}
