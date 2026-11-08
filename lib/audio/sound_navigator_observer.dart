import 'package:flutter/material.dart';

import 'audio_service.dart';

/// Phát tiếng whoosh khi mở trang, và bản hạ cao độ khi đóng trang.
class SoundNavigatorObserver extends NavigatorObserver {
  bool _counts(Route<dynamic> r) =>
      r is PageRoute || r is ModalBottomSheetRoute;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // Trang đầu tiên (màn hình chính) không có tiếng.
    if (previousRoute == null || !_counts(route)) return;
    AudioService.instance.play(Sfx.whoosh);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null && _counts(newRoute)) {
      AudioService.instance.play(Sfx.whoosh);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (!_counts(route)) return;
    AudioService.instance.play(Sfx.whooshClose);
  }
}
