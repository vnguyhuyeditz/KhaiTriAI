import 'package:flutter/material.dart';

import '../../audio/audio_service.dart';

import '../theme/app_theme.dart';
import 'pressable.dart';

/// Thẻ phẳng: nền màu thẻ, viền 1px rất mỏng, không đổ bóng.
class SurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;

  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor ?? p.border, width: 1),
      ),
      child: child,
    );
  }
}

/// Tiêu đề nhóm nhỏ phía trên một thẻ.
class SectionHeader extends StatelessWidget {
  final String text;
  const SectionHeader(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 32, 4, 8),
      child: Text(
        text,
        style: context.text.footnote.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Nhóm các hàng trong một thẻ, ngăn cách bằng đường kẻ mảnh.
class GroupedList extends StatelessWidget {
  final List<Widget> children;
  const GroupedList({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        rows.add(Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Divider(height: 1, thickness: 1, color: p.border),
        ));
      }
      rows.add(children[i]);
    }
    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: Column(children: rows),
      ),
    );
  }
}

/// Một hàng trong [GroupedList]: tiêu đề, mô tả, phần cuối tùy ý.
class ListRow extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool chevron;
  final Color? titleColor;

  /// false: làm mờ và không cho bấm (tính năng không hỗ trợ trên máy này).
  final bool enabled;

  const ListRow({
    super.key,
    required this.title,
    this.icon,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.chevron = false,
    this.titleColor,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.text;

    final content = Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 22, color: p.accent),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title,
                    style: t.body.copyWith(color: titleColor ?? p.label)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: t.footnote),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            trailing!,
          ],
          if (chevron) ...[
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, size: 22, color: p.secondary),
          ],
        ],
      ),
    ));

    if (onTap == null || !enabled) return content;
    return Pressable(onTap: onTap, pressedScale: 0.985, child: content);
  }
}

/// Bộ chọn dạng phân đoạn (ví dụ: Sáng / Tối).
class SegmentedChoice<T> extends StatelessWidget {
  final List<T> values;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;

  const SegmentedChoice({
    super.key,
    required this.values,
    required this.selected,
    required this.labelOf,
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
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (final v in values)
            Expanded(
              child: Pressable(
                onTap: () => onChanged(v),
                pressedScale: 0.97,
                sound: Sfx.toggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: AppTheme.easeOut,
                  constraints: const BoxConstraints(minHeight: 40),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: v == selected ? p.card : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: v == selected ? p.border : Colors.transparent,
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      labelOf(v),
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      style: t.subhead.copyWith(
                        fontWeight:
                            v == selected ? FontWeight.w600 : FontWeight.w400,
                      ),
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


/// Công tắc có tiếng "tách" khi bật/tắt.
class AppSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  const AppSwitch({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Switch.adaptive(
      value: value,
      onChanged: onChanged == null
          ? null
          : (v) {
              AudioService.instance.play(Sfx.toggle);
              onChanged!(v);
            },
    );
  }
}
