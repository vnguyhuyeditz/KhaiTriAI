import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../audio/audio_service.dart';
import '../settings/settings_controller.dart';
import 'theme/app_theme.dart';
import 'widgets/motion.dart';

/// Hiện màn hình intro đè lên trang chính; xong thì tự biến mất.
class IntroGate extends StatefulWidget {
  final Widget home;
  const IntroGate({super.key, required this.home});

  @override
  State<IntroGate> createState() => _IntroGateState();
}

class _IntroGateState extends State<IntroGate> {
  bool _init = false;
  bool _introActive = false;
  bool _showHome = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_init) return;
    _init = true;
    final s = SettingsScope.of(context);
    _introActive = s.showIntro && !s.reduceMotion;
    _showHome = !_introActive;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_showHome) widget.home,
        if (_introActive)
          IntroScreen(
            onReveal: () {
              if (mounted) setState(() => _showHome = true);
            },
            onDone: () {
              if (mounted) setState(() => _introActive = false);
            },
          ),
      ],
    );
  }
}

/// Intro: biểu tượng bật lên kèm quầng sáng, trượt sang trái, chữ "Khai Trí AI"
/// trượt ra bên phải, rồi một vệt sáng quét qua cả logo.
class IntroScreen extends StatefulWidget {
  final VoidCallback onReveal;
  final VoidCallback onDone;
  const IntroScreen({super.key, required this.onReveal, required this.onDone});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3800),
  );
  bool _sweepSound = false;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    AudioService.instance.play(Sfx.introPop);
    _c.addListener(_tick);
    _c.forward().whenComplete(widget.onDone);
  }

  void _tick() {
    if (!_sweepSound && _c.value >= 0.55) {
      _sweepSound = true;
      AudioService.instance.play(Sfx.introSweep);
    }
    if (!_revealed && _c.value >= 0.84) {
      _revealed = true;
      widget.onReveal();
      AudioService.instance.fadeOut(Sfx.introSweep, ms: 500);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double _seg(double a, double b, Curve curve) =>
      curve.transform(((_c.value - a) / (b - a)).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.text;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.sizeOf(context).width;

    // Kích thước: icon S, khoảng cách 50/448 S, chữ 685/448 S (theo file SVG gốc).
    final s = math.min(150.0, (width - 48) / 2.64);
    final gap = s * 50 / 448;
    final wordW = s * 685 / 448;
    final lockW = s + gap + wordW;

    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final pop = _seg(0.0, 0.20, Curves.easeOutBack);
        final fade = _seg(0.0, 0.08, Curves.easeOut);
        final glow = _seg(0.04, 0.30, Curves.easeOut);
        final slide = _seg(0.30, 0.52, Curves.easeInOutCubic);
        final tagIn = _seg(0.50, 0.64, AppTheme.easeOut);
        final sweep = _seg(0.56, 0.80, Curves.easeInOut);
        final out = _seg(0.84, 1.0, Curves.easeIn);
        final glowK = glow * (0.92 + 0.08 * math.sin(_c.value * math.pi * 6));

        final iconLeft = lerpDouble((lockW - s) / 2, 0, slide)!;
        final iconRight = iconLeft + s;
        final wordStart = (lockW - s) / 2 + s * 0.35; // nằm sau icon
        final wordLeft = lerpDouble(wordStart, s + gap, slide)!;

        final glowColor = dark ? Colors.white : p.accent;

        final lockup = SizedBox(
          width: lockW,
          height: s,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Chữ: chỉ thấy phần nằm bên phải icon, như trượt ra từ phía sau.
              Positioned.fill(
                child: ClipRect(
                  clipper: _RightOf(iconRight - s * 0.05),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: wordLeft,
                        top: 0,
                        child: Opacity(
                          opacity: slide,
                          child: AppWordmark(height: s),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Biểu tượng: bật lên ở giữa, rồi trượt sang trái.
              Positioned(
                left: iconLeft,
                top: 0,
                child: Transform.scale(
                  scale: 0.4 + 0.6 * pop,
                  child: Opacity(
                    opacity: fade,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(s * 0.232),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                                alpha: dark ? 0.0 : 0.20),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: AppLogo(size: s),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );

        // Vệt sáng chéo quét từ trái sang phải qua logo và chữ.
        final swept = (sweep > 0 && sweep < 1)
            ? ShaderMask(
                blendMode: BlendMode.srcATop,
                shaderCallback: (rect) {
                  final c = -0.3 + sweep * 1.6;
                  double st(double v) => v.clamp(0.0, 1.0).toDouble();
                  return LinearGradient(
                    begin: const Alignment(-1, -0.4),
                    end: const Alignment(1, 0.4),
                    colors: [
                      Colors.white.withValues(alpha: 0),
                      Colors.white.withValues(alpha: 0.85),
                      Colors.white.withValues(alpha: 0),
                    ],
                    stops: [st(c - 0.16), st(c), st(c + 0.16)],
                  ).createShader(rect);
                },
                child: lockup,
              )
            : lockup;

        // Quầng sáng phía sau: tròn lúc đầu, giãn ngang khi logo mở ra.
        final glowSize = s * (1.5 + 1.2 * glow);
        final glowLayer = SizedBox(
          width: 0,
          height: 0,
          child: OverflowBox(
            maxWidth: double.infinity,
            maxHeight: double.infinity,
            child: Transform.scale(
              scaleX: 1 + 1.1 * slide,
              child: Container(
                width: glowSize,
                height: glowSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    glowColor.withValues(alpha: 0.30 * glowK),
                    glowColor.withValues(alpha: 0),
                  ]),
                ),
              ),
            ),
          ),
        );

        return IgnorePointer(
          ignoring: out > 0.3,
          child: Opacity(
            opacity: 1 - out,
            child: Material(
              color: p.bg,
              child: SizedBox.expand(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [glowLayer, swept],
                      ),
                      const SizedBox(height: 28),
                      Opacity(
                        opacity: tagIn,
                        child: Transform.translate(
                          offset: Offset(0, (1 - tagIn) * 10),
                          child: Text(
                            'Đối mặt cái lỗ, đánh đổ cái ngu',
                            style: t.subhead.copyWith(color: p.secondary),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Chỉ cho vẽ phần nằm bên phải một đường dọc.
class _RightOf extends CustomClipper<Rect> {
  final double left;
  const _RightOf(this.left);

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(left, -size.height, size.width + size.height, size.height * 2);

  @override
  bool shouldReclip(_RightOf old) => old.left != left;
}
