import 'dart:math';

import 'package:flutter/material.dart';

import 'theme/app_theme.dart';

/// Một đường trên biểu đồ radar.
class RadarSeries {
  final List<double> values; // 0..100
  final Color color;
  final bool dashed;

  const RadarSeries({
    required this.values,
    required this.color,
    this.dashed = false,
  });
}

/// Radar 5 trục. [progress] từ 0 đến 1 để chạy hiệu ứng nở ra.
class RadarChart extends StatelessWidget {
  final List<String> labels;
  final List<RadarSeries> series;
  final double progress;

  const RadarChart({
    super.key,
    required this.labels,
    required this.series,
    this.progress = 1,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final family = Theme.of(context).textTheme.bodyMedium?.fontFamily;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: AspectRatio(
          aspectRatio: 1,
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _RadarPainter(
                labels: labels,
                series: series,
                progress: progress,
                gridColor: p.label.withValues(alpha: 0.12),
                labelColor: p.label,
                fontFamily: family,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final List<String> labels;
  final List<RadarSeries> series;
  final double progress;
  final Color gridColor;
  final Color labelColor;
  final String? fontFamily;

  _RadarPainter({
    required this.labels,
    required this.series,
    required this.progress,
    required this.gridColor,
    required this.labelColor,
    required this.fontFamily,
  });

  double _angle(int i, int n) => -pi / 2 + 2 * pi * i / n;

  Offset _point(Offset c, double r, int i, int n, double value) {
    final len = r * value.clamp(0.0, 100.0) / 100;
    final a = _angle(i, n);
    return Offset(c.dx + cos(a) * len, c.dy + sin(a) * len);
  }

  Path _polygon(Offset c, double r, List<double> vals, double k) {
    final n = vals.length;
    final path = Path();
    for (var i = 0; i < n; i++) {
      final pt = _point(c, r, i, n, vals[i] * k);
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    path.close();
    return path;
  }

  void _dashed(Canvas canvas, Path path, Paint paint) {
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 6), paint);
        d += 10;
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final n = labels.length;
    final center = Offset(size.width / 2, size.height / 2);
    // Chừa chỗ cho nhãn ở mép; nhãn được căn theo hướng của trục.
    final radius = max(48.0, min(size.width, size.height) / 2 - 64);

    final grid = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = gridColor;
    for (final level in [25.0, 50.0, 75.0, 100.0]) {
      canvas.drawPath(_polygon(center, radius, List.filled(n, level), 1), grid);
    }
    for (var i = 0; i < n; i++) {
      canvas.drawLine(center, _point(center, radius, i, n, 100), grid);
    }

    for (final s in series) {
      if (s.values.length != n) continue;
      final path = _polygon(center, radius, s.values, progress);
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.fill
          ..color = s.color.withValues(alpha: 0.14),
      );
      final stroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..color = s.color;
      if (s.dashed) {
        _dashed(canvas, path, stroke);
      } else {
        canvas.drawPath(path, stroke);
        for (var i = 0; i < n; i++) {
          canvas.drawCircle(
            _point(center, radius, i, n, s.values[i] * progress),
            3.5,
            Paint()..color = s.color,
          );
        }
      }
    }

    for (var i = 0; i < n; i++) {
      final a = _angle(i, n);
      final dx = cos(a);
      final dy = sin(a);
      final anchor = Offset(
        center.dx + dx * (radius + 10),
        center.dy + dy * (radius + 10),
      );
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            fontFamily: fontFamily,
            color: labelColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.13,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();

      double x;
      if (dx > 0.3) {
        x = anchor.dx;
      } else if (dx < -0.3) {
        x = anchor.dx - tp.width;
      } else {
        x = anchor.dx - tp.width / 2;
      }
      double y;
      if (dy > 0.3) {
        y = anchor.dy;
      } else if (dy < -0.3) {
        y = anchor.dy - tp.height;
      } else {
        y = anchor.dy - tp.height / 2;
      }
      x = x.clamp(0.0, max(0.0, size.width - tp.width)).toDouble();
      y = y.clamp(0.0, max(0.0, size.height - tp.height)).toDouble();
      tp.paint(canvas, Offset(x, y));
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter old) =>
      old.progress != progress ||
      old.series != series ||
      old.gridColor != gridColor ||
      old.labelColor != labelColor ||
      old.fontFamily != fontFamily;
}
