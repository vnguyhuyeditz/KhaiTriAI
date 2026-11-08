import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../audio/audio_service.dart';
import '../models/attempt.dart';
import '../models/question.dart';
import '../notifications/reminder_service.dart';
import '../settings/settings_controller.dart';
import '../storage/history_store.dart';
import '../storage/stats_store.dart';
import 'result_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/adaptive.dart';
import 'widgets/pressable.dart';

class QuizScreen extends StatefulWidget {
  final String subject;
  final List<Question> questions;

  const QuizScreen({super.key, required this.subject, required this.questions});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  static const _confidenceLabels = ['Đoán', 'Hơi chắc', 'Chắc chắn'];

  int _index = 0;
  int? _chosen;
  int? _confidence;
  bool _saving = false;
  final List<Answer> _answers = [];

  Future<void> _confirmExit() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thoát bài kiểm tra?'),
        content: const Text('Kết quả của bài này sẽ không được lưu.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Tiếp tục làm'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Thoát'),
          ),
        ],
      ),
    );
    if (leave == true && mounted) Navigator.of(context).pop();
  }

  Future<void> _next() async {
    _answers.add(Answer(_chosen!, _confidence!));

    if (_index + 1 < widget.questions.length) {
      setState(() {
        _index++;
        _chosen = null;
        _confidence = null;
      });
      return;
    }

    setState(() => _saving = true);
    final attempt = Attempt(
      date: DateTime.now(),
      subject: widget.subject,
      questions: widget.questions,
      answers: _answers,
    );
    final store = HistoryStore();
    final history = await store.load();
    await store.add(attempt);
    final stats = await StatsStore().recordAttempt(attempt.date);
    if (!mounted) return;
    // Hôm nay đã làm bài: dời lời nhắc 19h sang ngày mai.
    final s = SettingsScope.of(context);
    unawaited(ReminderService.instance.sync(
      enabled: s.reminderOn,
      doneToday: stats.doneToday(DateTime.now()),
    ));
    Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
      builder: (_) => ResultScreen(
        attempt: attempt,
        previous: history.isEmpty ? null : history.first,
      ),
    ));
  }

  /// Các đáp án và phần chọn mức tự tin.
  Widget _answers_(Question q, TextTheme t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < q.options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _OptionTile(
              letter: 'ABCD'[i],
              text: q.options[i],
              selected: _chosen == i,
              onTap: () => setState(() => _chosen = i),
            ),
          ),
        const SizedBox(height: 24),
        Text('Bạn chắc chắn đến đâu?', style: t.headline),
        const SizedBox(height: 4),
        Text(
          'Trả lời thật lòng để app đánh giá đúng hơn.',
          style: t.footnote,
        ),
        const SizedBox(height: 12),
        _ConfidencePicker(
          labels: _confidenceLabels,
          selected: _confidence,
          onChanged: (v) => setState(() => _confidence = v),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.text;
    final reduce = SettingsScope.of(context).reduceMotion;
    final total = widget.questions.length;
    final q = widget.questions[_index];
    final canContinue = _chosen != null && _confidence != null && !_saving;
    final isLast = _index + 1 == total;
    final wide = isWide(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmExit();
      },
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Thoát',
                      constraints:
                          const BoxConstraints(minWidth: 48, minHeight: 48),
                      icon: Icon(Icons.close_rounded, color: p.label),
                      onPressed: _confirmExit,
                    ),
                    Expanded(
                      child: Text(
                        'Câu ${_index + 1} / $total',
                        textAlign: TextAlign.center,
                        style: t.subhead.copyWith(color: p.secondary),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Padding(
                padding: pagePadding(context,
                    maxWidth: wide ? kWideMax : 760, top: 0, bottom: 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: (_index + 1) / total),
                    duration:
                        reduce ? Duration.zero : const Duration(milliseconds: 400),
                    curve: AppTheme.easeOut,
                    builder: (context, v, _) => LinearProgressIndicator(
                      value: v,
                      minHeight: 4,
                      color: p.accent,
                      backgroundColor: p.accentSoft,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration:
                      reduce ? Duration.zero : const Duration(milliseconds: 250),
                  switchInCurve: AppTheme.easeOut,
                  child: KeyedSubtree(
                    key: ValueKey<int>(_index),
                    child: wide
                        ? Padding(
                            padding: pagePadding(context,
                                maxWidth: kWideMax, top: 32, bottom: 32),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: SingleChildScrollView(
                                    child: Text(q.text, style: t.title1),
                                  ),
                                ),
                                const SizedBox(width: 48),
                                Expanded(
                                  child: SingleChildScrollView(
                                    child: _answers_(q, t),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : SingleChildScrollView(
                            padding: pagePadding(context, top: 32, bottom: 32),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(q.text, style: t.title2),
                                const SizedBox(height: 24),
                                _answers_(q, t),
                              ],
                            ),
                          ),
                  ),
                ),
              ),
              ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: p.bg.withValues(alpha: 0.78),
                      border: Border(top: BorderSide(color: p.border)),
                    ),
                    padding: pagePadding(context,
                        maxWidth: wide ? 520 : 760, top: 12, bottom: 12),
                    child: SafeArea(
                      top: false,
                      child: AppButton(
                        label: _saving
                            ? 'Đang lưu...'
                            : (isLast ? 'Xem kết quả' : 'Câu tiếp theo'),
                        onPressed: canContinue ? _next : null,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String letter;
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const _OptionTile({
    required this.letter,
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.text;
    return Pressable(
      onTap: onTap,
      sound: Sfx.select,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: AppTheme.easeOut,
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? p.accentSoft : p.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? p.accent : p.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: AppTheme.easeOut,
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? p.accent : p.bg,
                shape: BoxShape.circle,
              ),
              child: Text(
                letter,
                style: t.footnote.copyWith(
                  fontWeight: FontWeight.w600,
                  color: selected ? p.onAccent : p.label,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(text, style: t.body)),
          ],
        ),
      ),
    );
  }
}

class _ConfidencePicker extends StatelessWidget {
  final List<String> labels;
  final int? selected;
  final ValueChanged<int> onChanged;

  const _ConfidencePicker({
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.text;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: p.label.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: Pressable(
                onTap: () => onChanged(i),
                sound: Sfx.select,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: AppTheme.easeOut,
                  constraints: const BoxConstraints(minHeight: 44),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected == i ? p.card : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      color: selected == i ? p.border : Colors.transparent,
                    ),
                  ),
                  child: Text(
                    labels[i],
                    textAlign: TextAlign.center,
                    style: t.subhead.copyWith(
                      fontWeight:
                          selected == i ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
