import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../logic/scoring.dart';
import '../models/attempt.dart';
import '../settings/settings_controller.dart';
import '../storage/history_store.dart';
import 'compare_screen.dart';
import 'result_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/adaptive.dart';
import 'widgets/pressable.dart';

class HistoryScreen extends StatefulWidget {
  /// Mở thẳng ở chế độ chọn 2 lần để so sánh.
  final bool startInCompareMode;

  const HistoryScreen({super.key, this.startInCompareMode = false});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Attempt>? _list;
  List<Assessment> _assessments = const [];
  bool _selecting = false;
  final List<int> _selected = []; // tối đa 2 chỉ số

  @override
  void initState() {
    super.initState();
    _selecting = widget.startInCompareMode;
    _load();
  }

  Future<void> _load() async {
    final list = await HistoryStore().load();
    if (!mounted) return;
    setState(() {
      _list = list;
      _assessments = [for (final a in list) Assessment.of(a)];
      if (list.length < 2) _selecting = false;
    });
  }

  void _toggle(int i) {
    setState(() {
      if (_selected.contains(i)) {
        _selected.remove(i);
      } else {
        if (_selected.length == 2) _selected.removeAt(0);
        _selected.add(i);
      }
    });
  }

  void _toggleMode() {
    setState(() {
      _selecting = !_selecting;
      _selected.clear();
    });
  }

  Future<void> _compare() async {
    final list = _list!;
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) =>
          CompareScreen(a: list[_selected[0]], b: list[_selected[1]]),
    ));
    if (!mounted) return;
    setState(() {
      _selecting = false;
      _selected.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.text;
    final list = _list;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử'),
        actions: [
          if (list != null && list.length >= 2)
            TextButton(
              onPressed: _toggleMode,
              child: Text(_selecting ? 'Xong' : 'So sánh'),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: list == null
            ? const Center(child: CircularProgressIndicator())
            : list.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.history_rounded,
                              size: 48, color: p.secondary),
                          const SizedBox(height: 16),
                          Text('Chưa có lần làm bài nào',
                              style: t.headline, textAlign: TextAlign.center),
                          const SizedBox(height: 4),
                          Text(
                            'Làm một bài kiểm tra để xem kết quả ở đây.',
                            style: t.subhead.copyWith(color: p.secondary),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: ListView.separated(
                          padding: pagePadding(context, bottom: 24),
                          itemCount: list.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, i) => _HistoryRow(
                            attempt: list[i],
                            assessment: _assessments[i],
                            selecting: _selecting,
                            selected: _selected.contains(i),
                            onTap: () {
                              if (_selecting) {
                                _toggle(i);
                              } else {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => ResultScreen(
                                      attempt: list[i],
                                      previous: i + 1 < list.length
                                          ? list[i + 1]
                                          : null,
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ),
                      if (_selecting) _compareBar(p, t),
                    ],
                  ),
      ),
    );
  }

  Widget _compareBar(AppPalette p, TextTheme t) {
    final ready = _selected.length == 2;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: p.bg.withValues(alpha: 0.78),
            border: Border(top: BorderSide(color: p.border)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: SafeArea(
            top: false,
            child: AppButton(
              label: ready
                  ? 'So sánh 2 lần đã chọn'
                  : 'Chọn 2 lần để so sánh (${_selected.length}/2)',
              icon: Icons.compare_arrows_rounded,
              onPressed: ready ? _compare : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final Attempt attempt;
  final Assessment assessment;
  final bool selecting;
  final bool selected;
  final VoidCallback onTap;

  const _HistoryRow({
    required this.attempt,
    required this.assessment,
    required this.selecting,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.text;
    final reduce = SettingsScope.of(context).reduceMotion;
    final hidden = assessment.quadrants[Quadrant.hiddenMisconception] ?? 0;

    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: reduce ? Duration.zero : const Duration(milliseconds: 200),
        curve: AppTheme.easeOut,
        constraints: const BoxConstraints(minHeight: 72),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? p.accentSoft : p.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? p.accent : p.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            if (selecting) ...[
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? p.accent : p.secondary,
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${assessment.correctCount}/${assessment.total} câu đúng',
                    style: t.headline,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${attempt.subject} · ${formatDate(attempt.date)}',
                    style: t.footnote,
                  ),
                  if (hidden > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      '$hidden câu hiểu sai ngầm',
                      style: t.footnote.copyWith(color: p.danger),
                    ),
                  ],
                ],
              ),
            ),
            if (!selecting)
              Icon(Icons.chevron_right, size: 22, color: p.secondary),
          ],
        ),
      ),
    );
  }
}
