import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// Tính năng nào chạy được trên nền tảng hiện tại.
class PlatformSupport {
  PlatformSupport._();

  static bool get isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  static bool get isWindows => !kIsWeb && Platform.isWindows;

  /// Chụp ảnh bằng camera: chỉ có trên điện thoại.
  static bool get camera => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Thông báo nhắc làm bài: chỉ có trên điện thoại.
  static bool get reminders => camera;

  static const String unsupportedOnDesktop = 'Không hỗ trợ trên Windows';
}
