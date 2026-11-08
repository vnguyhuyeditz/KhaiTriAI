import 'package:flutter/material.dart';

import '../logic/scoring.dart';
import '../models/attempt.dart';
import '../models/question.dart';
import '../settings/settings_controller.dart';
import '../storage/history_store.dart';
import 'radar_chart.dart';
import 'theme/app_theme.dart';
import 'widgets/adaptive.dart';
import 'widgets/surfaces.dart';

/// So sánh hai lần làm bài. Truyền hai lần theo thứ tự nào cũng được,
/// màn hình tự xếp "Trước" và "Sau" theo thời gian.
class CompareScreen extends StatefulWidget {
  final Attempt a;
  final Attempt b;

  const CompareScreen({super.key, required this.a, required this.b});

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  late final Comparison _c = Comparison.of(widget.a, widget.b);

  String _summary() {
    int? best;
    int? worst;
    for (var i = 0; i < _c.deltas.length; i++) {
      final d = _c.deltas[i];
      if (d == null) continue;
      if (best == null || d > _c.deltas[best]!) best = i;
      if (worst == null || d < _c.deltas[worst]!) worst = i;
    }
    if (best == null) return 'Chưa đủ dữ liệu để so sánh các tiêu chí.';

    final parts = <String>[];
    final bd = _c.deltas[best]!;
    if (bd >= 1) {
      parts.add('Tiến bộ nhiều nhất ở "${Assessment.fullLabels[best]}" '
          '(+${bd.round()} điểm).');
    }
    final wd = _c.deltas[worst!]!;
    if (wd <= -1) {
      parts.add('Cần chú ý "${Assessment.fullLabels[worst]}" '
          '(${wd.round()} điểm).');
    }
    if (parts.isEmpty) parts.add('Kết quả gần như không đổi giữa hai lần.');
    return parts.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.text;
    final reduce = SettingsScope.of(context).reduceMotion;
    final c = _c;

    final hiddenBefore = c.before.quadrants[Quadrant.hiddenMisconception] ?? 0;
    final hiddenAfter = c.after.quadrants[Quadrant.hiddenMisconception] ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('So sánh 2 lần')),
      body: SafeArea(
        child: ListView(
          padding: pagePadding(context),
          children: [
            // ----- Hai lần làm bài -----
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _AttemptCard(
                      title: 'Trước',
                      attempt: c.beforeAttempt,
                      assessment: c.before,
                      color: p.seriesB,
                      dashed: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _AttemptCard(
                      title: 'Sau',
                      attempt: c.afterAttempt,
                      assessment: c.after,
                      color: p.seriesA,
                      dashed: false,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ----- Radar chồng nhau -----
            SurfaceCard(
              padding: const EdgeInsets.fromLTRB(8, 20, 8, 16),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: 1),
                duration: reduce ? Duration.zero : const Duration(milliseconds: 800),
                curve: AppTheme.easeOut,
                builder: (context, k, _) => RadarChart(
                  labels: Assessment.radarLabels,
                  progress: k,
                  series: [
                    RadarSeries(
                      values: c.before.radarValues,
                      color: p.seriesB,
                      dashed: true,
                    ),
                    RadarSeries(values: c.after.radarValues, color: p.seriesA),
                  ],
                ),
              ),
            ),

            // ----- Tóm tắt -----
            const SectionHeader('Tóm tắt'),
            SurfaceCard(child: Text(_summary(), style: t.body)),

            // ----- Bảng điểm -----
            const SectionHeader('Điểm từng tiêu chí'),
            SurfaceCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(flex: 5, child: Text('Tiêu chí', style: t.caption)),
                      Expanded(
                        flex: 2,
                        child: Text('Trước',
                            textAlign: TextAlign.right, style: t.caption),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text('Sau',
                            textAlign: TextAlign.right, style: t.caption),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text('Thay đổi',
                            textAlign: TextAlign.right, style: t.caption),
                      ),
                    ],
                  ),
                  for (var i = 0; i < 5; i++) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1, color: p.border),
                    ),
                    _TableRow(
                      label: Assessment.fullLabels[i],
                      before: c.before.values[i],
                      after: c.after.values[i],
                      delta: c.deltas[i],
                    ),
                  ],
                ],
              ),
            ),

            // ----- Hiểu sai ngầm -----
            const SectionHeader('Số câu theo nhóm'),
            GroupedList(children: [
              for (final q in Quadrant.values)
                _QuadrantRow(
                  quadrant: q,
                  before: c.before.quadrants[q] ?? 0,
                  after: c.after.quadrants[q] ?? 0,
                ),
            ]),
            if (hiddenBefore > hiddenAfter)
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
                child: Text(
                  'Số câu hiểu sai ngầm giảm từ $hiddenBefore xuống $hiddenAfter.',
                  style: t.footnote,
                ),
              ),

            // ----- Câu hỏi chung -----
            const SectionHeader('Những câu có ở cả hai lần'),
            if (c.commonCount == 0)
              SurfaceCard(
                child: Text(
                  'Hai lần làm bài không có câu hỏi chung nên chưa so sánh '
                  'được từng câu.',
                  style: t.subhead,
                ),
              )
            else ...[
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _StatTile(
                        count: c.fixed.length,
                        label: 'Đã lấp được',
                        color: p.positive,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatTile(
                        count: c.stillWrong.length,
                        label: 'Vẫn còn sai',
                        color: p.warning,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatTile(
                        count: c.regressed.length,
                        label: 'Làm sai lại',
                        color: p.danger,
                      ),
                    ),
                  ],
                ),
              ),
              if (c.stillWrong.isNotEmpty)
                _QuestionList(
                  title: 'Nên ôn tiếp những câu này',
                  questions: c.stillWrong,
                ),
              if (c.regressed.isNotEmpty)
                _QuestionList(
                  title: 'Trước đúng, lần này sai',
                  questions: c.regressed,
                ),
              if (c.fixed.isNotEmpty)
                _QuestionList(
                  title: 'Lỗ hổng đã lấp được',
                  questions: c.fixed,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AttemptCard extends StatelessWidget {
  final String title;
  final Attempt attempt;
  final Assessment assessment;
  final Color color;
  final bool dashed;

  const _AttemptCard({
    required this.title,
    required this.attempt,
    required this.assessment,
    required this.color,
    required this.dashed,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    return SurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 20,
                height: 8,
                child: CustomPaint(painter: _Swatch(color, dashed)),
              ),
              const SizedBox(width: 8),
              Text(title, style: t.footnote),
            ],
          ),
          const SizedBox(height: 8),
          Text('${assessment.correctCount}/${assessment.total}',
              style: t.title1),
          const SizedBox(height: 4),
          Text(formatDate(attempt.date), style: t.footnote),
        ],
      ),
    );
  }
}

/// Mẫu màu nhỏ: nét liền hoặc nét đứt, khớp với đường trên radar.
class _Swatch extends CustomPainter {
  final Color color;
  final bool dashed;
  _Swatch(this.color, this.dashed);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final y = size.height / 2;
    if (!dashed) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      return;
    }
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, y), Offset((x + 5).clamp(0, size.width).toDouble(), y), paint);
      x += 8;
    }
  }

  @override
  bool shouldRepaint(covariant _Swatch old) =>
      old.color != color || old.dashed != dashed;
}

class _TableRow extends StatelessWidget {
  final String label;
  final double? before;
  final double? after;
  final double? delta;

  const _TableRow({
    required this.label,
    required this.before,
    required this.after,
    required this.delta,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.text;
    String pct(double? v) => v == null ? '—' : '${v.round()}%';

    final Widget change;
    if (delta == null) {
      change = Text('—', style: t.subhead.copyWith(color: p.secondary));
    } else {
      final d = delta!.round();
      final IconData icon;
      final Color color;
      if (d > 0) {
        icon = Icons.arrow_upward_rounded;
        color = p.positive;
      } else if (d < 0) {
        icon = Icons.arrow_downward_rounded;
        color = p.danger;
      } else {
        icon = Icons.remove_rounded;
        color = p.secondary;
      }
      change = Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 2),
          Text(
            '${d.abs()}',
            style: t.subhead.copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(flex: 5, child: Text(label, style: t.subhead)),
        Expanded(
          flex: 2,
          child: Text(pct(before),
              textAlign: TextAlign.right,
              style: t.subhead.copyWith(color: p.secondary)),
        ),
        Expanded(
          flex: 2,
          child: Text(pct(after),
              textAlign: TextAlign.right,
              style: t.subhead.copyWith(fontWeight: FontWeight.w600)),
        ),
        Expanded(flex: 3, child: change),
      ],
    );
  }
}

class _QuadrantRow extends StatelessWidget {
  final Quadrant quadrant;
  final int before;
  final int after;

  const _QuadrantRow({
    required this.quadrant,
    required this.before,
    required this.after,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.text;
    // Với "hiểu sai ngầm" và "biết mình chưa biết", giảm là tốt.
    final lowerIsBetter = quadrant == Quadrant.hiddenMisconception ||
        quadrant == Quadrant.knownGap;
    final diff = after - before;
    final good = diff == 0 ? null : (lowerIsBetter ? diff < 0 : diff > 0);

    return ListRow(
      title: quadrant.label,
      subtitle: quadrant.hint,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$before', style: t.body.copyWith(color: p.secondary)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Icon(Icons.arrow_forward_rounded, size: 16, color: p.secondary),
          ),
          Text(
            '$after',
            style: t.body.copyWith(
              fontWeight: FontWeight.w600,
              color: good == null
                  ? p.label
                  : (good ? p.positive : p.danger),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final int count;
  final String label;
  final Color color;

  const _StatTile({
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    return SurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$count', style: t.title1.copyWith(color: color)),
          const SizedBox(height: 4),
          Text(label, style: t.footnote),
        ],
      ),
    );
  }
}

class _QuestionList extends StatelessWidget {
  final String title;
  final List<Question> questions;

  const _QuestionList({required this.title, required this.questions});

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title),
        GroupedList(children: [
          for (final q in questions)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SizedBox(
                width: double.infinity,
                child: Text(q.text, style: t.subhead),
              ),
            ),
        ]),
      ],
    );
  }
}
