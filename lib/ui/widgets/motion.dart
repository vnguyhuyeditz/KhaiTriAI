import 'package:flutter/material.dart';

import '../../settings/settings_controller.dart';
import '../theme/app_theme.dart';

/// Hiện dần và trượt nhẹ lên khi xuất hiện, có thể trễ để tạo hiệu ứng nối tiếp.
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final int delayMs;
  final double dy;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.delayMs = 0,
    this.dy = 16,
  });

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (SettingsScope.of(context).reduceMotion) {
      _c.value = 1;
      return;
    }
    Future<void>.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final k = AppTheme.easeOut.transform(_c.value);
        return Opacity(
          opacity: k,
          child: Transform.translate(
            offset: Offset(0, (1 - k) * widget.dy),
            child: child,
          ),
        );
      },
    );
  }
}

/// Số đếm tăng dần từ 0 đến giá trị.
class CountUp extends StatelessWidget {
  final int value;
  final String suffix;
  final TextStyle? style;

  const CountUp({super.key, required this.value, this.suffix = '', this.style});

  @override
  Widget build(BuildContext context) {
    final reduce = SettingsScope.of(context).reduceMotion;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: reduce ? Duration.zero : const Duration(milliseconds: 900),
      curve: AppTheme.easeOut,
      builder: (context, v, _) => Text('${v.round()}$suffix', style: style),
    );
  }
}

/// Biểu tượng Khai Trí AI (bóng đèn trong ô bo góc), lấy từ file logo của nhóm.
class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({super.key, this.size = 96});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo_icon.png',
      width: size,
      height: size,
      filterQuality: FilterQuality.high,
      semanticLabel: 'Khai Trí AI',
    );
  }
}

/// Chữ "Khai Trí AI" của logo; tự đổi bản sáng/tối theo giao diện.
class AppWordmark extends StatelessWidget {
  final double height;
  const AppWordmark({super.key, required this.height});

  /// Tỉ lệ rộng/cao của ảnh chữ (685 x 448).
  static const double aspect = 685 / 448;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Image.asset(
      dark
          ? 'assets/images/wordmark_dark.png'
          : 'assets/images/wordmark_light.png',
      width: height * aspect,
      height: height,
      filterQuality: FilterQuality.high,
      semanticLabel: 'Khai Trí AI',
    );
  }
}

/// Hai quầng sáng mờ ở nền, làm trang chính bớt phẳng nhưng vẫn nhẹ.
class AmbientBackground extends StatelessWidget {
  final Widget child;
  const AmbientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final a = dark ? 0.22 : 0.16;

    Widget blob(Color c, double size) => IgnorePointer(
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [c.withValues(alpha: a), c.withValues(alpha: 0)],
              ),
            ),
          ),
        );

    return Stack(
      children: [
        Positioned(top: -120, right: -100, child: blob(p.accent, 340)),
        Positioned(top: 320, left: -160, child: blob(const Color(0xFF5E5CE6), 320)),
        Positioned.fill(child: child),
      ],
    );
  }
}
