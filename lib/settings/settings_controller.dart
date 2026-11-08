import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Các phông chữ có thể chọn.
enum AppFont { system, inter, spotify }

extension AppFontInfo on AppFont {
  String get label {
    switch (this) {
      case AppFont.system:
        return 'Hệ thống';
      case AppFont.inter:
        return 'Inter';
      case AppFont.spotify:
        return 'Spotify Mix UI';
    }
  }

  String get description {
    switch (this) {
      case AppFont.system:
        return 'SF Pro trên iPhone, Roboto trên Android';
      case AppFont.inter:
        return 'Gần với SF Pro, rất dễ đọc';
      case AppFont.spotify:
        return 'Phông của nhóm';
    }
  }

  /// Tên họ phông khai báo trong pubspec.yaml (null = phông hệ thống).
  String? get family {
    switch (this) {
      case AppFont.system:
        return null;
      case AppFont.inter:
        return 'Inter';
      case AppFont.spotify:
        return 'SpotifyMixUI';
    }
  }
}

/// Hai cách AI hoạt động: trên máy hoặc qua mạng.
enum AiMode { offline, online }

extension AiModeInfo on AiMode {
  String get label => this == AiMode.offline ? 'Offline' : 'Online';

  String get summary => this == AiMode.offline
      ? 'Chạy hoàn toàn trên máy, không cần mạng, tài liệu không rời khỏi máy.'
      : 'Gửi nội dung tài liệu qua mạng cho mô hình lớn. Đọc được tài liệu khó hơn, cần Internet.';

  /// Hiện rõ trong app khi dùng chế độ Offline.
  static const offlineLimits =
      'Chế độ Offline đọc tốt tài liệu có chữ rõ. Công thức, hình vẽ, đồ thị, '
      'chữ viết tay và ảnh mờ có thể bị đọc sai hoặc bỏ sót. Câu hỏi do mô hình '
      'nhỏ tạo ra nên được xem lại trước khi dùng. Cần đọc tài liệu khó hơn, '
      'hãy chuyển sang chế độ Online.';
}

/// Toàn bộ cài đặt của app, tự lưu vào bộ nhớ máy mỗi khi đổi.
class SettingsController extends ChangeNotifier {
  SettingsController._(this._prefs) {
    themeMode = ThemeMode.values[_int('theme', 0, 0, 2)];
    font = AppFont.values[_int('font', 0, 0, AppFont.values.length - 1)];
    textScale = (_prefs.getDouble('textScale') ?? 1.0).clamp(0.9, 1.3).toDouble();
    musicOn = _prefs.getBool('musicOn') ?? true;
    musicPercent = (_prefs.getInt('musicPercent') ?? 50).clamp(0, 100).toInt();
    sfxOn = _prefs.getBool('sfxOn') ?? true;
    showIntro = _prefs.getBool('showIntro') ?? true;
    reminderOn = _prefs.getBool('reminderOn') ?? true;
    haptics = _prefs.getBool('haptics') ?? true;
    reduceMotion = _prefs.getBool('reduceMotion') ?? false;
    final qc = _prefs.getInt('questionCount') ?? 20;
    questionCount = questionCountOptions.contains(qc) ? qc : 20;
    shuffle = _prefs.getBool('shuffle') ?? false;
    aiMode = AiMode.values[_int('aiMode', 0, 0, AiMode.values.length - 1)];
  }

  static const questionCountOptions = [10, 15, 20];

  final SharedPreferences _prefs;

  late ThemeMode themeMode;
  late AppFont font;
  late double textScale;
  late bool musicOn;

  /// Âm lượng nhạc nền theo %, 0–100 (mặc định 50, ở giữa).
  late int musicPercent;
  late bool sfxOn;
  late bool showIntro;
  late bool reminderOn;
  late bool haptics;
  late bool reduceMotion;
  late int questionCount;
  late bool shuffle;
  late AiMode aiMode;

  static Future<SettingsController> load() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsController._(prefs);
  }

  int _int(String key, int fallback, int min, int max) {
    final v = _prefs.getInt(key) ?? fallback;
    return v < min || v > max ? fallback : v;
  }

  void setThemeMode(ThemeMode v) {
    themeMode = v;
    _prefs.setInt('theme', v.index);
    notifyListeners();
  }

  void setFont(AppFont v) {
    font = v;
    _prefs.setInt('font', v.index);
    notifyListeners();
  }

  void setTextScale(double v) {
    textScale = v.clamp(0.9, 1.3).toDouble();
    _prefs.setDouble('textScale', textScale);
    notifyListeners();
  }

  void setMusicOn(bool v) {
    musicOn = v;
    _prefs.setBool('musicOn', v);
    notifyListeners();
  }

  void setMusicPercent(int v) {
    musicPercent = v.clamp(0, 100).toInt();
    _prefs.setInt('musicPercent', musicPercent);
    notifyListeners();
  }

  void setSfxOn(bool v) {
    sfxOn = v;
    _prefs.setBool('sfxOn', v);
    notifyListeners();
  }

  void setShowIntro(bool v) {
    showIntro = v;
    _prefs.setBool('showIntro', v);
    notifyListeners();
  }

  void setReminderOn(bool v) {
    reminderOn = v;
    _prefs.setBool('reminderOn', v);
    notifyListeners();
  }

  void setHaptics(bool v) {
    haptics = v;
    _prefs.setBool('haptics', v);
    notifyListeners();
  }

  void setReduceMotion(bool v) {
    reduceMotion = v;
    _prefs.setBool('reduceMotion', v);
    notifyListeners();
  }

  void setQuestionCount(int v) {
    if (!questionCountOptions.contains(v)) return;
    questionCount = v;
    _prefs.setInt('questionCount', v);
    notifyListeners();
  }

  void setAiMode(AiMode v) {
    aiMode = v;
    _prefs.setInt('aiMode', v.index);
    notifyListeners();
  }

  void setShuffle(bool v) {
    shuffle = v;
    _prefs.setBool('shuffle', v);
    notifyListeners();
  }
}

/// Cho mọi màn hình đọc cài đặt bằng `SettingsScope.of(context)`.
class SettingsScope extends InheritedNotifier<SettingsController> {
  const SettingsScope({
    super.key,
    required SettingsController controller,
    required super.child,
  }) : super(notifier: controller);

  static SettingsController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SettingsScope>();
    assert(scope != null, 'Thiếu SettingsScope phía trên cây widget');
    return scope!.notifier!;
  }
}
