import 'package:flutter/material.dart';

import '../audio/audio_service.dart';

import '../logic/scoring.dart';
import '../models/attempt.dart';
import '../models/question.dart';
import '../settings/settings_controller.dart';
import '../storage/history_store.dart';
import 'compare_screen.dart';
import 'radar_chart.dart';
import 'theme/app_theme.dart';
import 'widgets/adaptive.dart';
import 'widgets/motion.dart';
import 'widgets/pressable.dart';
import 'widgets/surfaces.dart';

class ResultScreen extends StatefulWidget {
  final Attempt attempt;
  final Attempt? previous;

  const ResultScreen({super.key, required this.attempt, this.previous});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late final Assessment _a = Assessment.of(widget.attempt);

  @override
  void initState() {
    super.initState();
    // Tiếng "ting" nhẹ khi kết quả hiện ra (sau tiếng whoosh chuyển trang).
    Future<void>.delayed(const Duration(milliseconds: 350), () {
      if (mounted) AudioService.instance.play(Sfx.result);
    });
  }

  Duration _dur(BuildContext context, int ms) =>
      SettingsScope.of(context).reduceMotion
          ? Duration.zero
          : Duration(milliseconds: ms);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.text;
    final a = _a;
    final suggestions = a.suggestions();

    final partA = <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                CountUp(value: a.correctCount, style: t.largeTitle),
                Text('/${a.total}', style: t.largeTitle),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'câu đúng · ${widget.attempt.subject} · '
              '${formatDate(widget.attempt.date)}',
              style: t.footnote,
            ),
            const SizedBox(height: 24),

            // ----- Radar -----
            SurfaceCard(
              padding: const EdgeInsets.fromLTRB(8, 20, 8, 16),
              child: Column(
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: _dur(context, 800),
                    curve: AppTheme.easeOut,
                    builder: (context, k, _) => RadarChart(
                      labels: Assessment.radarLabels,
                      progress: k,
                      series: [
                        RadarSeries(values: a.radarValues, color: p.seriesA),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ước lượng từ các câu bạn vừa làm',
                    style: t.caption,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // ----- Điểm từng tiêu chí -----
            const SectionHeader('Điểm theo tiêu chí'),
            SurfaceCard(
              child: Column(
                children: [
                  for (var i = 0; i < 5; i++) ...[
                    if (i > 0) const SizedBox(height: 16),
                    _ScoreRow(
                      label: Assessment.fullLabels[i],
                      score: a.values[i],
                      duration: _dur(context, 700),
                    ),
                  ],
                ],
              ),
            ),

    ];
    final partB = <Widget>[
            // ----- Tự tin x kết quả -----
            const SectionHeader('Tự tin và kết quả'),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _QuadrantTile(q: Quadrant.mastered, count: a.quadrants[Quadrant.mastered] ?? 0)),
                  const SizedBox(width: 8),
                  Expanded(child: _QuadrantTile(q: Quadrant.shaky, count: a.quadrants[Quadrant.shaky] ?? 0)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _QuadrantTile(q: Quadrant.hiddenMisconception, count: a.quadrants[Quadrant.hiddenMisconception] ?? 0)),
                  const SizedBox(width: 8),
                  Expanded(child: _QuadrantTile(q: Quadrant.knownGap, count: a.quadrants[Quadrant.knownGap] ?? 0)),
                ],
              ),
            ),

            // ----- Gợi ý -----
            const SectionHeader('Gợi ý ôn tập'),
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < suggestions.length; i++) ...[
                    if (i > 0) const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 8, right: 12),
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: p.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Expanded(child: Text(suggestions[i], style: t.body)),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // ----- Câu cần xem lại -----
            if (a.reviewOrder.isNotEmpty) ...[
              SectionHeader('Câu cần xem lại (${a.reviewOrder.length})'),
              for (final i in a.reviewOrder)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ReviewTile(
                    question: widget.attempt.questions[i],
                    answer: widget.attempt.answers[i],
                  ),
                ),
            ],

    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Kết quả')),
      body: SafeArea(
        child: ListView(
          padding: pagePadding(context,
              maxWidth: isWide(context) ? kWideMax : 760, bottom: 32),
          children: [
            if (isWide(context))
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: partA)),
                  const SizedBox(width: 32),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: partB)),
                ],
              )
            else ...[...partA, ...partB],
            const SizedBox(height: 24),
            if (widget.previous != null) ...[
              AppButton(
                label: 'So sánh với lần trước',
                icon: Icons.compare_arrows_rounded,
                primary: false,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CompareScreen(
                      a: widget.previous!,
                      b: widget.attempt,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            AppButton(
              label: 'Về trang chính',
              onPressed: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
            ),
            const SizedBox(height: 16),
            Text(
              'Bản đồ năng lực chỉ là ước lượng để gợi ý ôn tập, '
              'không phải kết luận về khả năng của bạn.',
              style: t.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final String label;
  final double? score;
  final Duration duration;

  const _ScoreRow({
    required this.label,
    required this.score,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.text;
    final target = (score ?? 0) / 100;
    final low = score != null && score! < 60;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(child: Text(label, style: t.subhead)),
            const SizedBox(width: 12),
            Text(
              score == null ? '—' : '${score!.round()}%',
              style: t.headline.copyWith(color: low ? p.warning : p.label),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: target),
            duration: duration,
            curve: AppTheme.easeOut,
            builder: (context, v, _) => LinearProgressIndicator(
              value: v,
              minHeight: 6,
              color: low ? p.warning : p.accent,
              backgroundColor: p.label.withValues(alpha: 0.08),
            ),
          ),
        ),
        if (score == null) ...[
          const SizedBox(height: 4),
          Text('Bài này không có câu thuộc tiêu chí này', style: t.caption),
        ],
      ],
    );
  }
}

class _QuadrantTile extends StatelessWidget {
  final Quadrant q;
  final int count;

  const _QuadrantTile({required this.q, required this.count});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.text;
    final alert = q == Quadrant.hiddenMisconception && count > 0;

    return SurfaceCard(
      padding: const EdgeInsets.all(16),
      borderColor: alert ? p.danger.withValues(alpha: 0.5) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$count',
            style: t.title1.copyWith(color: alert ? p.danger : p.label),
          ),
          const SizedBox(height: 4),
          Text(q.label, style: t.subhead.copyWith(fontWeight: FontWeight.w600)),
          Text(q.hint, style: t.footnote),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final Question question;
  final Answer answer;

  const _ReviewTile({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.text;
    final hidden = answer.confidence >= 1;
    final why = question.misconceptions[answer.chosen];

    return Container(
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          iconColor: p.secondary,
          collapsedIconColor: p.secondary,
          title: Text(
            question.text,
            style: t.subhead.copyWith(fontWeight: FontWeight.w600),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              hidden ? 'Hiểu sai ngầm: tự tin nhưng làm sai' : 'Làm sai',
              style: t.footnote.copyWith(
                color: hidden ? p.danger : p.secondary,
                fontWeight: hidden ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          children: [
            _line(t, 'Bạn chọn',
                '${'ABCD'[answer.chosen]}. ${question.options[answer.chosen]}'),
            const SizedBox(height: 8),
            _line(t, 'Đáp án đúng',
                '${'ABCD'[question.correct]}. ${question.options[question.correct]}',
                strong: true),
            if (why != null) ...[
              const SizedBox(height: 8),
              _line(t, 'Lỗi thường gặp', why),
            ],
            const SizedBox(height: 8),
            _line(t, 'Giải thích', question.explanation),
          ],
        ),
      ),
    );
  }

  Widget _line(TextTheme t, String title, String value, {bool strong = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: t.caption),
        const SizedBox(height: 2),
        Text(
          value,
          style: t.subhead.copyWith(
            fontWeight: strong ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
