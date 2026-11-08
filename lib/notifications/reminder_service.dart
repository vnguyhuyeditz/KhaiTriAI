import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Nhắc làm bài lúc 19:00 mỗi ngày, nhưng chỉ khi hôm nay chưa làm bài nào.
///
/// Cách hoạt động: luôn đặt MỘT thông báo lặp hằng ngày lúc 19:00.
/// Mỗi lần mở app hoặc làm xong bài, [sync] đặt lại; nếu hôm nay đã làm
/// rồi thì lần nhắc đầu tiên được dời sang ngày mai, nên hôm nay không bị nhắc.
class ReminderService {
  ReminderService._();
  static final ReminderService instance = ReminderService._();

  static const int hour = 19;
  static const int _id = 1901;
  // Đổi tên kênh nếu muốn đổi âm thanh (Android không cho sửa kênh đã tạo).
  static const String _channelId = 'daily_reminder_v1';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return;
    try {
      tzdata.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));

      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      );
      await _plugin.initialize(settings);
      _ready = true;
    } catch (e) {
      debugPrint('Reminder init: $e');
    }
  }

  /// Xin quyền hiện thông báo (Android 13+ và iPhone). Trả về true nếu được cấp.
  Future<bool> requestPermission() async {
    if (!_ready) return false;
    try {
      if (Platform.isAndroid) {
        final android = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        return await android?.requestNotificationsPermission() ?? true;
      }
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      return await ios?.requestPermissions(
              alert: true, badge: true, sound: true) ??
          false;
    } catch (e) {
      debugPrint('Reminder permission: $e');
      return false;
    }
  }

  static const NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      'Nhắc làm bài',
      channelDescription: 'Nhắc làm bài lúc 19:00 nếu hôm nay chưa làm',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      // File android/app/src/main/res/raw/notification_sound.mp3
      sound: RawResourceAndroidNotificationSound('notification_sound'),
    ),
    iOS: DarwinNotificationDetails(presentSound: true),
  );

  /// Hiện ngay một thông báo thử để kiểm tra quyền và âm thanh.
  Future<void> showTest() async {
    if (!_ready) return;
    try {
      await _plugin.show(
        _id + 1,
        'Khai Trí AI',
        'Đây là thông báo thử. Lời nhắc thật sẽ đến lúc 19:00.',
        _details,
      );
    } catch (e) {
      debugPrint('Reminder test: $e');
    }
  }

  Future<void> sync({required bool enabled, required bool doneToday}) async {
    if (!_ready) return;
    try {
      await _plugin.cancel(_id);
      if (!enabled) return;

      final now = tz.TZDateTime.now(tz.local);
      var first = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour);
      if (doneToday || !first.isAfter(now)) {
        first = first.add(const Duration(days: 1));
      }

      await _plugin.zonedSchedule(
        _id,
        'Khai Trí AI',
        'Hôm nay bạn chưa làm bài nào. Làm một bài để giữ streak nhé!',
        first,
        _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('Reminder sync: $e');
    }
  }
}
