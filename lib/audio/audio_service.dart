import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../settings/settings_controller.dart';

/// Các hiệu ứng âm thanh (file nằm trong assets/audio).
enum Sfx {
  tap('tap.mp3', true),
  select('select.mp3', true),
  toggle('toggle.mp3', true),
  whoosh('whoosh.mp3', true),
  whooshClose('whoosh_close.mp3', true), // whoosh đã hạ cao độ, dùng khi đóng
  result('result.mp3', false),
  introPop('intro_pop.mp3', false),
  introSweep('intro_sweep.mp3', false);

  final String file;

  /// Âm ngắn dùng chế độ độ trễ thấp; âm dài dùng trình phát thường.
  final bool short;
  const Sfx(this.file, this.short);
}

/// Phát hiệu ứng và nhạc nền. Mọi lỗi âm thanh đều được nuốt để
/// không bao giờ làm app bị crash chỉ vì thiếu file hoặc máy không hỗ trợ.
class AudioService with WidgetsBindingObserver {
  AudioService._();
  static final AudioService instance = AudioService._();

  /// Âm lượng nhạc nền tối đa khi thanh trượt ở 100%.
  /// Cố tình để nhỏ: ở 50% (mặc định) chỉ còn 15% âm lượng thật.
  static const double musicMaxGain = 0.30;

  /// Âm lượng chung của hiệu ứng (file đã được chuẩn hóa đều nhau).
  static const double sfxGain = 0.9;

  static const _musicAsset = 'audio/bgm.mp3';

  SettingsController? _settings;
  final Map<Sfx, AudioPlayer> _players = {};
  AudioPlayer? _music;
  bool _musicChecked = false;
  bool _musicAvailable = false;
  bool _musicPlaying = false;
  bool _inBackground = false;
  DateTime _lastWhoosh = DateTime.fromMillisecondsSinceEpoch(0);

  Future<void> init(SettingsController settings) async {
    _settings = settings;
    settings.addListener(_onSettings);
    WidgetsBinding.instance.addObserver(this);
    try {
      // Cho phép hiệu ứng phát chồng lên nhạc nền, không giành quyền âm thanh.
      await AudioPlayer.global.setAudioContext(
        AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers).build(),
      );
    } catch (e) {
      debugPrint('Audio context: $e');
    }
    unawaited(_onSettings());
  }

  AudioPlayer _playerFor(Sfx sfx) {
    return _players.putIfAbsent(sfx, () {
      final p = AudioPlayer();
      unawaited(p.setReleaseMode(ReleaseMode.stop));
      unawaited(p.setPlayerMode(
        sfx.short ? PlayerMode.lowLatency : PlayerMode.mediaPlayer,
      ));
      return p;
    });
  }

  /// Phát một hiệu ứng (bỏ qua nếu người dùng đã tắt âm thanh hiệu ứng).
  Future<void> play(Sfx sfx) async {
    final s = _settings;
    if (s == null || !s.sfxOn) return;

    // Chống chồng nhiều tiếng whoosh khi đóng liên tiếp nhiều trang.
    if (sfx == Sfx.whoosh || sfx == Sfx.whooshClose) {
      final now = DateTime.now();
      if (now.difference(_lastWhoosh).inMilliseconds < 150) return;
      _lastWhoosh = now;
    }

    try {
      final p = _playerFor(sfx);
      await p.stop();
      await p.play(AssetSource('audio/${sfx.file}'), volume: sfxGain);
    } catch (e) {
      debugPrint('Sfx ${sfx.file}: $e');
    }
  }

  /// Giảm dần rồi dừng một hiệu ứng dài (dùng cho tiếng quét sáng ở intro).
  Future<void> fadeOut(Sfx sfx, {int ms = 300}) async {
    final p = _players[sfx];
    if (p == null) return;
    try {
      const steps = 6;
      for (var i = steps - 1; i >= 0; i--) {
        await p.setVolume(sfxGain * i / steps);
        await Future<void>.delayed(Duration(milliseconds: ms ~/ steps));
      }
      await p.stop();
    } catch (_) {}
  }

  // ---------------- Nhạc nền ----------------

  double get _musicVolume =>
      musicMaxGain * (_settings?.musicPercent ?? 50).clamp(0, 100) / 100.0;

  Future<void> _checkMusic() async {
    if (_musicChecked) return;
    _musicChecked = true;
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      _musicAvailable = manifest.listAssets().contains('assets/$_musicAsset');
    } catch (_) {
      _musicAvailable = false;
    }
  }

  Future<void> _onSettings() async {
    final s = _settings;
    if (s == null) return;
    await _checkMusic();
    if (!_musicAvailable) return;

    try {
      final wantPlay = s.musicOn && s.musicPercent > 0 && !_inBackground;
      if (wantPlay) {
        final m = _music ??= AudioPlayer();
        if (!_musicPlaying) {
          await m.setReleaseMode(ReleaseMode.loop);
          await m.play(AssetSource(_musicAsset), volume: _musicVolume);
          _musicPlaying = true;
        } else {
          await m.setVolume(_musicVolume);
        }
      } else if (_musicPlaying) {
        await _music?.pause();
        _musicPlaying = false;
      }
    } catch (e) {
      debugPrint('Music: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final bg = state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached;
    if (bg == _inBackground) return;
    _inBackground = bg;
    unawaited(_onSettings());
  }
}
