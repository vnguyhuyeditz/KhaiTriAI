import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../notifications/reminder_service.dart';
import '../platform_support.dart';
import '../settings/settings_controller.dart';
import '../storage/history_store.dart';
import '../storage/stats_store.dart';
import 'theme/app_theme.dart';
import 'widgets/surfaces.dart';

/// Mở bảng cài đặt dạng tờ giấy trượt từ dưới lên.
Future<void> showSettingsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    // Nền để trong suốt; màu nền thật được vẽ trong SettingsSheet
    // để đổi theo theme ngay lập tức (không bị "đóng băng" lúc mở).
    backgroundColor: Colors.transparent,
    elevation: 0,
    builder: (_) => const FractionallySizedBox(
      heightFactor: 0.92,
      child: SettingsSheet(),
    ),
  );
}

class SettingsSheet extends StatelessWidget {
  const SettingsSheet({super.key});

  String _themeLabel(ThemeMode m) {
    switch (m) {
      case ThemeMode.system:
        return 'Tự động';
      case ThemeMode.light:
        return 'Sáng';
      case ThemeMode.dark:
        return 'Tối';
    }
  }

  Future<void> _toggleReminder(SettingsController s, bool on) async {
    s.setReminderOn(on);
    if (on) await ReminderService.instance.requestPermission();
    final stats = await StatsStore().load();
    await ReminderService.instance
        .sync(enabled: on, doneToday: stats.doneToday(DateTime.now()));
  }

  Future<void> _pickAiMode(BuildContext context, SettingsController s, AiMode m) async {
    if (m == s.aiMode) return;
    if (m == AiMode.online) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Bật chế độ Online?'),
          content: const Text(
            'Nội dung tài liệu và ảnh bạn chọn sẽ được gửi qua Internet cho '
            'mô hình AI để đọc và tạo câu hỏi. Đừng dùng với tài liệu riêng tư.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Đồng ý'),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    s.setAiMode(m);
  }

  Future<void> _confirmClear(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa lịch sử?'),
        content: const Text(
          'Toàn bộ kết quả đã lưu trên máy sẽ bị xóa. '
          'Số bài đã làm và streak vẫn được giữ.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await HistoryStore().clear();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa lịch sử')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = SettingsScope.of(context);
    final p = context.palette;
    final t = context.text;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: AppTheme.easeOut,
      decoration: BoxDecoration(
        color: p.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
            padding: const EdgeInsets.fromLTRB(20, 0, 12, 8),
            child: Row(
              children: [
                Expanded(child: Text('Cài đặt', style: t.title2)),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Xong'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              children: [
                // ----- Giao diện -----
                const SectionHeader('Giao diện'),
                SurfaceCard(
                  child: SegmentedChoice<ThemeMode>(
                    values: ThemeMode.values,
                    selected: s.themeMode,
                    labelOf: _themeLabel,
                    onChanged: s.setThemeMode,
                  ),
                ),
                const SectionHeader('Phông chữ'),
                GroupedList(children: [
                  for (final f in AppFont.values)
                    ListRow(
                      title: f.label,
                      subtitle: f.description,
                      onTap: () => s.setFont(f),
                      trailing: s.font == f
                          ? Icon(Icons.check_rounded, color: p.accent)
                          : null,
                    ),
                ]),
                const SectionHeader('Cỡ chữ'),
                SurfaceCard(
                  child: Row(
                    children: [
                      Text('A', style: t.footnote),
                      Expanded(
                        child: Slider(
                          value: s.textScale,
                          min: 0.9,
                          max: 1.3,
                          divisions: 4,
                          label: '${(s.textScale * 100).round()}%',
                          onChanged: s.setTextScale,
                        ),
                      ),
                      Text('A', style: t.title2),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                GroupedList(children: [
                  ListRow(
                    title: 'Giảm chuyển động',
                    subtitle: 'Tắt hiệu ứng trượt, intro và chuyển cảnh',
                    trailing: AppSwitch(
                      value: s.reduceMotion,
                      onChanged: s.setReduceMotion,
                    ),
                  ),
                  ListRow(
                    title: 'Màn hình intro',
                    subtitle: 'Logo hiện ra mỗi lần mở app',
                    trailing: AppSwitch(
                      value: s.showIntro,
                      onChanged: s.setShowIntro,
                    ),
                  ),
                ]),

                // ----- Chế độ AI -----
                const SectionHeader('Chế độ AI'),
                SurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SegmentedChoice<AiMode>(
                        values: AiMode.values,
                        selected: s.aiMode,
                        labelOf: (m) => m.label,
                        onChanged: (m) => unawaited(_pickAiMode(context, s, m)),
                      ),
                      const SizedBox(height: 12),
                      Text(s.aiMode.summary, style: t.footnote),
                      if (s.aiMode == AiMode.offline) ...[
                        const SizedBox(height: 8),
                        Text(
                          AiModeInfo.offlineLimits,
                          style: t.footnote.copyWith(color: p.warning),
                        ),
                      ],
                    ],
                  ),
                ),

                // ----- Âm thanh -----
                const SectionHeader('Âm thanh'),
                GroupedList(children: [
                  ListRow(
                    title: 'Âm thanh hiệu ứng',
                    subtitle: 'Tiếng chạm, chuyển trang, kết quả',
                    trailing: AppSwitch(
                      value: s.sfxOn,
                      onChanged: s.setSfxOn,
                    ),
                  ),
                  ListRow(
                    title: 'Nhạc nền',
                    subtitle: 'Nhạc nhẹ khi dùng app',
                    trailing: AppSwitch(
                      value: s.musicOn,
                      onChanged: s.setMusicOn,
                    ),
                  ),
                  _MusicVolumeRow(settings: s),
                  ListRow(
                    title: 'Rung khi chạm',
                    subtitle: 'Phản hồi nhẹ khi bấm nút và chọn đáp án',
                    trailing: AppSwitch(
                      value: s.haptics,
                      onChanged: s.setHaptics,
                    ),
                  ),
                ]),

                // ----- Nhắc nhở -----
                const SectionHeader('Nhắc nhở'),
                GroupedList(children: [
                  ListRow(
                    title: 'Nhắc làm bài lúc 19:00',
                    subtitle: PlatformSupport.reminders
                        ? 'Chỉ nhắc khi hôm nay bạn chưa làm bài nào'
                        : PlatformSupport.unsupportedOnDesktop,
                    enabled: PlatformSupport.reminders,
                    trailing: AppSwitch(
                      value: PlatformSupport.reminders && s.reminderOn,
                      onChanged: PlatformSupport.reminders
                          ? (v) => unawaited(_toggleReminder(s, v))
                          : null,
                    ),
                  ),
                  ListRow(
                    title: 'Gửi thử thông báo',
                    subtitle: PlatformSupport.reminders
                        ? 'Kiểm tra quyền và âm thanh thông báo'
                        : PlatformSupport.unsupportedOnDesktop,
                    enabled: PlatformSupport.reminders,
                    onTap: () async {
                      await ReminderService.instance.requestPermission();
                      await ReminderService.instance.showTest();
                    },
                  ),
                ]),

                // ----- Bài kiểm tra -----
                const SectionHeader('Bài kiểm tra'),
                SurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Số câu mỗi bài', style: t.body),
                      const SizedBox(height: 12),
                      SegmentedChoice<int>(
                        values: SettingsController.questionCountOptions,
                        selected: s.questionCount,
                        labelOf: (v) => '$v câu',
                        onChanged: s.setQuestionCount,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                GroupedList(children: [
                  ListRow(
                    title: 'Xáo trộn thứ tự câu hỏi',
                    subtitle: 'Mỗi lần làm là một thứ tự khác',
                    trailing: AppSwitch(
                      value: s.shuffle,
                      onChanged: s.setShuffle,
                    ),
                  ),
                ]),

                // ----- Dữ liệu -----
                const SectionHeader('Dữ liệu'),
                GroupedList(children: [
                  ListRow(
                    title: 'Xóa lịch sử làm bài',
                    subtitle: 'Dữ liệu chỉ lưu trên máy của bạn',
                    titleColor: p.danger,
                    onTap: () => _confirmClear(context),
                  ),
                ]),

                // ----- Giới thiệu -----
                const SectionHeader('Giới thiệu'),
                const GroupedList(children: [
                  ListRow(
                    title: 'Khai Trí AI',
                    subtitle: 'Phiên bản 0.5.5 (v11) · Sáng Tạo Cùng AI',
                  ),
                  ListRow(
                    title: 'Mô hình AI offline',
                    subtitle: 'Gemma của Google, dùng theo Gemma Terms of Use',
                  ),
                  ListRow(
                    title: 'Nhóm',
                    subtitle:
                        'Việt Huy, Minh Khải, Gia Huy · THPT Phan Châu Trinh',
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Thanh trượt âm lượng nhạc nền + ô số để gõ tay (0–100%, mặc định 50%).
class _MusicVolumeRow extends StatelessWidget {
  final SettingsController settings;
  const _MusicVolumeRow({required this.settings});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final on = settings.musicOn;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          Icon(Icons.volume_down_rounded, color: on ? p.secondary : p.border),
          Expanded(
            child: Slider(
              value: settings.musicPercent.toDouble(),
              min: 0,
              max: 100,
              divisions: 100,
              label: '${settings.musicPercent}%',
              onChanged: on ? (v) => settings.setMusicPercent(v.round()) : null,
            ),
          ),
          PercentField(
            value: settings.musicPercent,
            enabled: on,
            onChanged: settings.setMusicPercent,
          ),
        ],
      ),
    );
  }
}

/// Ô nhập số phần trăm: chạm vào để gõ, xong thì tự giới hạn trong 0–100.
class PercentField extends StatefulWidget {
  final int value;
  final bool enabled;
  final ValueChanged<int> onChanged;

  const PercentField({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  State<PercentField> createState() => _PercentFieldState();
}

class _PercentFieldState extends State<PercentField> {
  late final TextEditingController _text =
      TextEditingController(text: '${widget.value}');
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus) _commit();
    });
  }

  @override
  void didUpdateWidget(PercentField old) {
    super.didUpdateWidget(old);
    // Khi kéo thanh trượt, cập nhật số (trừ lúc đang gõ).
    if (!_focus.hasFocus && widget.value != old.value) {
      _text.text = '${widget.value}';
    }
  }

  void _commit() {
    final n = int.tryParse(_text.text);
    final v = (n ?? widget.value).clamp(0, 100).toInt();
    _text.text = '$v';
    if (v != widget.value) widget.onChanged(v);
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.text;
    return Container(
      width: 72,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: p.label.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _text,
              focusNode: _focus,
              enabled: widget.enabled,
              textAlign: TextAlign.right,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
              style: t.headline,
              decoration: const InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                filled: false,
              ),
              onSubmitted: (_) => _commit(),
              onTapOutside: (_) => _focus.unfocus(),
            ),
          ),
          const SizedBox(width: 2),
          Text('%', style: t.footnote),
        ],
      ),
    );
  }
}
