import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../audio/audio_service.dart';
import '../../settings/settings_controller.dart';
import '../theme/app_theme.dart';

/// Bọc bất kỳ widget nào để có phản hồi chạm kiểu Apple:
/// thu nhỏ nhẹ xuống 0.97 ngay khi chạm, trả về mượt khi nhả.
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;

  /// Tiếng phát khi bấm (null = im lặng).
  final Sfx? sound;

  const Pressable({
    super.key,
    required this.child,
    required this.onTap,
    this.pressedScale = 0.97,
    this.sound = Sfx.tap,
  });

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v && mounted) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsScope.of(context);
    final enabled = widget.onTap != null;
    final duration =
        settings.reduceMotion ? Duration.zero : const Duration(milliseconds: 140);

    return MergeSemantics(
      child: Semantics(
        button: true,
        enabled: enabled,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled ? (_) => _set(true) : null,
          onTapUp: enabled ? (_) => _set(false) : null,
          onTapCancel: enabled ? () => _set(false) : null,
          onTap: enabled
              ? () {
                  if (settings.haptics) HapticFeedback.selectionClick();
                  if (widget.sound != null) {
                    AudioService.instance.play(widget.sound!);
                  }
                  widget.onTap!();
                }
              : null,
          child: AnimatedScale(
            scale: _down ? widget.pressedScale : 1.0,
            duration: duration,
            curve: AppTheme.easeOut,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Nút bấm chính (nền màu nhấn) hoặc phụ (nền nhạt).
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool primary;
  final IconData? icon;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.primary = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final enabled = onPressed != null;
    final Color bg;
    final Color fg;
    if (!enabled) {
      bg = p.border;
      fg = p.secondary;
    } else if (primary) {
      bg = p.accent;
      fg = p.onAccent;
    } else {
      bg = p.accentSoft;
      fg = p.accent;
    }

    return Pressable(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: fg),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: context.text.button.copyWith(color: fg),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
