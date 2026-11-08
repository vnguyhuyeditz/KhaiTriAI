import 'dart:async';

import 'package:flutter/material.dart';

import '../ai/question_generator.dart';
import '../logic/scoring.dart';
import '../models/attempt.dart';
import '../notifications/reminder_service.dart';
import '../settings/settings_controller.dart';
import '../storage/history_store.dart';
import '../storage/stats_store.dart';
import 'history_screen.dart';
import 'import_screen.dart';
import 'quiz_screen.dart';
import 'result_screen.dart';
import 'settings_sheet.dart';
import 'theme/app_theme.dart';
import 'widgets/adaptive.dart';
import 'widgets/motion.dart';
import 'widgets/pressable.dart';
import 'widgets/surfaces.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Attempt> _history = const [];
  Stats _stats = Stats.empty;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final list = await HistoryStore().load();
    final stats = await StatsStore().load();
    if (!mounted) return;
    setState(() {
      _history = list;
      _stats = stats;
    });
    unawaited(_syncReminder(stats));
  }

  /// Đặt lại lời nhắc 19h: hôm nay làm rồi thì dời sang ngày mai.
  Future<void> _syncReminder(Stats stats) async {
    final s = SettingsScope.of(context);
    if (s.reminderOn) await ReminderService.instance.requestPermission();
    await ReminderService.instance.sync(
      enabled: s.reminderOn,
      doneToday: stats.doneToday(DateTime.now()),
    );
  }

  Future<void> _start() async {
    final s = SettingsScope.of(context);
    setState(() => _starting = true);
    // Bước 5 sẽ thay SampleQuestionGenerator bằng bộ tạo câu hỏi dùng AI.
    final QuestionGenerator generator = SampleQuestionGenerator();
    final questions = await generator.generate(
      '',
      count: s.questionCount,
      shuffle: s.shuffle,
    );
    if (!mounted) return;
    setState(() => _starting = false);
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => QuizScreen(subject: 'Toán 10', questions: questions),
    ));
    _reload();
  }

  Future<void> _open(Widget screen) async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => screen));
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.text;
    final s = SettingsScope.of(context);
    final canCompare = _history.length >= 2;

    final wide = isWide(context);

    final header = <Widget>[
      Align(
        alignment: Alignment.centerRight,
        child: IconButton(
          tooltip: 'Cài đặt',
          iconSize: 24,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          icon: Icon(Icons.tune_rounded, color: p.label),
          onPressed: () => showSettingsSheet(context),
        ),
      ),
      SizedBox(height: wide ? 0 : 16),
      FadeSlideIn(
        child: Row(
          children: [
            AppLogo(size: wide ? 56 : 44),
            const SizedBox(width: 12),
            Expanded(child: Text('Khai Trí AI', style: t.largeTitle)),
          ],
        ),
      ),
      const SizedBox(height: 8),
      FadeSlideIn(
        delayMs: 80,
        child: Text(
          'Đối mặt cái lỗ, đánh đổ cái ngu',
          style: t.body.copyWith(color: p.secondary),
        ),
      ),
      const SizedBox(height: 24),
    ];

    final main = <Widget>[
      FadeSlideIn(delayMs: 160, child: _StatsCard(stats: _stats)),
      const SizedBox(height: 24),
      if (_history.isNotEmpty) ...[
        _LatestCard(
          attempt: _history.first,
          onTap: () => _open(ResultScreen(
            attempt: _history.first,
            previous: _history.length > 1 ? _history[1] : null,
          )),
        ),
        const SizedBox(height: 24),
      ],
      AppButton(
        label: _starting ? 'Đang chuẩn bị...' : 'Bắt đầu kiểm tra',
        onPressed: _starting ? null : _start,
      ),
      const SizedBox(height: 8),
      Center(
        child: Text(
          'Toán 10 · ${s.questionCount} câu',
          style: t.footnote,
        ),
      ),
    ];

    final menu = <Widget>[
      if (!wide) const SectionHeader('Khám phá'),
      GroupedList(children: [
        ListRow(
          icon: Icons.document_scanner_rounded,
          title: 'Tạo bộ đề từ tài liệu',
          subtitle: 'Ảnh, PDF, Word, PowerPoint',
          chevron: true,
          onTap: () => _open(const ImportScreen()),
        ),
        ListRow(
          icon: Icons.history_rounded,
          title: 'Lịch sử làm bài',
          subtitle:
              _history.isEmpty ? 'Chưa có lần nào' : '${_history.length} lần',
          chevron: true,
          onTap: () => _open(const HistoryScreen()),
        ),
        ListRow(
          icon: Icons.compare_arrows_rounded,
          title: 'So sánh 2 lần kiểm tra',
          subtitle: canCompare
              ? 'Xem mình tiến bộ ở đâu'
              : 'Cần ít nhất 2 lần làm bài',
          chevron: canCompare,
          onTap: canCompare
              ? () => _open(const HistoryScreen(startInCompareMode: true))
              : null,
        ),
        ListRow(
          icon: Icons.tune_rounded,
          title: 'Cài đặt',
          subtitle: 'Giao diện, phông chữ, âm thanh',
          chevron: true,
          onTap: () => showSettingsSheet(context),
        ),
      ]),
    ];

    return Scaffold(
      body: AmbientBackground(
        child: SafeArea(
          child: ListView(
            padding: pagePadding(context,
                maxWidth: wide ? kWideMax : 760, top: 8, bottom: 32),
            children: wide
                ? [
                    ...header,
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: main,
                          ),
                        ),
                        const SizedBox(width: 32),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 4, bottom: 8),
                                child: Text('Khám phá', style: t.footnote),
                              ),
                              ...menu,
                            ],
                          ),
                        ),
                      ],
                    ),
                  ]
                : [...header, ...main, ...menu],
          ),
        ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final Stats stats;
  const _StatsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.text;
    final streak = stats.currentStreak(DateTime.now());
    final done = stats.doneToday(DateTime.now());

    Widget cell(Widget value, String label) => Expanded(
          child: Column(
            children: [
              value,
              const SizedBox(height: 4),
              Text(label, style: t.footnote, textAlign: TextAlign.center),
            ],
          ),
        );

    return SurfaceCard(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      child: Column(
        children: [
          Row(
            children: [
              cell(CountUp(value: stats.total, style: t.title1), 'Bài đã làm'),
              cell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_fire_department_rounded,
                        size: 26, color: streak > 0 ? p.warning : p.secondary),
                    const SizedBox(width: 4),
                    CountUp(value: streak, style: t.title1),
                  ],
                ),
                'Streak (ngày)',
              ),
              cell(CountUp(value: stats.best, style: t.title1), 'Kỷ lục'),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            done
                ? 'Hôm nay bạn đã làm bài rồi. Giữ vững nhé!'
                : (streak > 0
                    ? 'Làm một bài hôm nay để giữ streak $streak ngày'
                    : 'Làm một bài hôm nay để bắt đầu streak'),
            style: t.footnote.copyWith(
              color: done ? p.positive : p.secondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _LatestCard extends StatelessWidget {
  final Attempt attempt;
  final VoidCallback onTap;

  const _LatestCard({required this.attempt, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.text;
    final a = Assessment.of(attempt);
    final hidden = a.quadrants[Quadrant.hiddenMisconception] ?? 0;

    return Pressable(
      onTap: onTap,
      child: SurfaceCard(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Lần gần nhất', style: t.footnote),
                  const SizedBox(height: 4),
                  Text('${a.correctCount}/${a.total} câu đúng',
                      style: t.title2),
                  const SizedBox(height: 4),
                  Text(
                    hidden > 0
                        ? '$hidden câu hiểu sai ngầm cần xem lại'
                        : 'Không có chỗ hiểu sai ngầm',
                    style: t.subhead.copyWith(
                      color: hidden > 0 ? p.danger : p.secondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.chevron_right, color: p.secondary),
          ],
        ),
      ),
    );
  }
}
