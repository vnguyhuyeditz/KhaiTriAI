import 'package:flutter/material.dart';

import '../../settings/settings_controller.dart';
import 'app_theme.dart';

/// Chuyển trang: trang mới hiện dần, trượt nhẹ lên và phóng từ 0.97 về 1;
/// trang bên dưới lùi nhẹ và mờ đi.
class AppPageTransitionsBuilder extends PageTransitionsBuilder {
  const AppPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (SettingsScope.of(context).reduceMotion) return child;

    final enter = CurvedAnimation(
      parent: animation,
      curve: AppTheme.easeOut,
      reverseCurve: Curves.easeInCubic,
    );
    final cover = CurvedAnimation(
      parent: secondaryAnimation,
      curve: AppTheme.easeOut,
      reverseCurve: Curves.easeInCubic,
    );

    return ScaleTransition(
      scale: Tween<double>(begin: 1.0, end: 0.96).animate(cover),
      child: FadeTransition(
        opacity: Tween<double>(begin: 1.0, end: 0.6).animate(cover),
        child: FadeTransition(
          opacity: enter,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.05),
              end: Offset.zero,
            ).animate(enter),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.97, end: 1.0).animate(enter),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
