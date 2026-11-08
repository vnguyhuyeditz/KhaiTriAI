import 'package:flutter/services.dart';
import 'package:flutter_edge_ai/flutter_edge_ai.dart';
import 'package:flutter_edge_ai_litertlm/flutter_edge_ai_litertlm.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineEngineException implements Exception {
  final String message;
  const OfflineEngineException(this.message);

  @override
  String toString() => message;
}

/// Bọc mô hình AI chạy trên máy (Gemma 3 1B, định dạng LiteRT-LM).
/// Mô hình được đóng gói sẵn trong app tại [assetPath].
class OfflineEngine {
  static const assetPath = 'assets/models/gemma3-1b-it-int4.litertlm';
  static const _installedKey = 'offlineModelInstalled_v1';

  bool _initialized = false;

  // Dùng dynamic để không phụ thuộc tên lớp nội bộ của thư viện.
  dynamic _model;

  bool get isReady => _model != null;

  /// Kiểm tra file mô hình có trong app không (không nạp nó lên RAM).
  static Future<bool> isBundled() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      return manifest.listAssets().contains(assetPath);
    } catch (_) {
      return false;
    }
  }

  /// Nạp mô hình lên RAM. Lần đầu sẽ sao chép từ app vào bộ nhớ máy (chậm hơn).
  Future<void> prepare({void Function(String message)? onStatus}) async {
    if (_model != null) return;

    if (!await isBundled()) {
      throw const OfflineEngineException(
        'App chưa có file mô hình AI offline. Hãy đặt file '
        'gemma3-1b-it-int4.litertlm vào assets/models/ rồi build lại app.',
      );
    }

    try {
      if (!_initialized) {
        await FlutterEdgeAi.initialize(inferenceEngines: [LiteRtLmEngine()]);
        _initialized = true;
      }

      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_installedKey) != true) {
        onStatus?.call('Lần đầu: đang nạp mô hình vào máy, có thể mất 1-2 phút...');
        await FlutterEdgeAi.installModel(
          modelType: ModelType.gemmaIt,
          fileType: ModelFileType.litertlm, // bắt buộc khai báo rõ
        ).fromAsset(assetPath).install();
        await prefs.setBool(_installedKey, true);
      }

      onStatus?.call('Đang khởi động mô hình...');
      _model = await FlutterEdgeAi.getActiveModel(maxTokens: 2048);
    } catch (e) {
      _model = null;
      throw OfflineEngineException('Không nạp được mô hình AI: $e');
    }
  }

  /// Gửi một lệnh, nhận toàn bộ câu trả lời (mỗi lần dùng một cuộc trò chuyện mới).
  Future<String> generate(String prompt,
      {bool Function()? shouldStop}) async {
    final model = _model;
    if (model == null) {
      throw const OfflineEngineException('Mô hình chưa được nạp.');
    }
    final chat = await model.createChat(maxOutputTokens: 512);
    try {
      await chat.addQueryChunk(Message.text(text: prompt, isUser: true));
      final reply = StringBuffer();
      await for (final response in chat.generateChatResponseAsync()) {
        if (response is TextResponse) reply.write(response.token);
        // Bấm Dừng: thoát vòng lặp (hủy luồng sinh chữ) thay vì chờ mô hình xong.
        if (shouldStop != null && shouldStop()) break;
      }
      return reply.toString();
    } finally {
      try {
        await chat.close();
      } catch (_) {}
    }
  }

  /// Giải phóng RAM.
  Future<void> close() async {
    try {
      await _model?.close();
    } catch (_) {}
    _model = null;
  }
}
