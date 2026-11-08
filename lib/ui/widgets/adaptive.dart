import 'package:flutter/material.dart';

/// Màn hình đủ rộng để chia 2 cột (cửa sổ Windows, máy tính bảng ngang).
bool isWide(BuildContext context) => MediaQuery.sizeOf(context).width >= 900;

/// Lề hai bên cho một cột nội dung rộng tối đa [maxWidth], căn giữa.
/// Dùng làm `padding` của ListView để thanh cuộn vẫn nằm sát mép cửa sổ.
EdgeInsets pagePadding(
  BuildContext context, {
  double maxWidth = 760,
  double top = 8,
  double bottom = 32,
}) {
  final w = MediaQuery.sizeOf(context).width;
  final side = ((w - maxWidth) / 2).clamp(0.0, double.infinity) + 20;
  return EdgeInsets.fromLTRB(side, top, side, bottom);
}

/// Chiều rộng tối đa của bố cục 2 cột.
const double kWideMax = 1180;
