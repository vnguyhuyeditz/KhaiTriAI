import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart' show debugPrint;

import '../../models/question.dart';
import '../question_checks.dart';
import 'offline_engine.dart';
import 'prompt_builder.dart';

class GenerationProgress {
  final int accepted;
  final int target;
  final int attempts;
  final String message;

  /// Lý do gần nhất một lần thử bị loại (để người dùng thấy app không bị treo).
  final String? lastNote;
  const GenerationProgress(this.accepted, this.target, this.attempts, this.message,
      [this.lastNote]);
}

class GenerationResult {
  final List<Question> questions;
  final List<String> rejected;
  final bool cancelled;
  const GenerationResult(this.questions, this.rejected, this.cancelled);
}

class _Cancelled implements Exception {
  const _Cancelled();
}

/// Tạo câu hỏi bằng mô hình chạy trên máy: mỗi lần một đoạn, một câu,
/// kiểm tra từng câu, câu hỏng thì bỏ và thử đoạn khác.
class OfflineQuestionGenerator {
  OfflineQuestionGenerator([OfflineEngine? engine])
      : _engine = engine ?? OfflineEngine();

  final OfflineEngine _engine;
  bool _cancelled = false;
  final Completer<void> _cancelSignal = Completer<void>();

  /// Dừng ngay: các bước đang chờ mô hình bị bỏ, run() trả về liền.
  void cancel() {
    _cancelled = true;
    if (!_cancelSignal.isCompleted) _cancelSignal.complete();
  }

  /// Chờ [task], nhưng nếu người dùng bấm Dừng thì thoát ngay (không đợi mô hình).
  Future<T> _orCancel<T>(Future<T> task) {
    // Tránh lỗi "chưa xử lý" nếu task xong sau khi đã dừng.
    task.ignore();
    return Future.any<T>([
      task,
      _cancelSignal.future.then<T>((_) => throw const _Cancelled()),
    ]);
  }

  Future<GenerationResult> run(
    List<String> chunks, {
    required int count,
    required void Function(GenerationProgress) onProgress,
  }) async {
    if (chunks.isEmpty) {
      throw const OfflineEngineException('Chưa có nội dung để tạo câu hỏi.');
    }

    final accepted = <Question>[];
    final rejected = <String>[];
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final maxAttempts = (count * 3).clamp(3, 60).toInt();
    var attempt = 0;
    var engineErrors = 0; // số lần liên tiếp mô hình báo lỗi
    String? lastNote;

    // Tài liệu dài: bỏ đoạn quá ngắn (tiêu đề, mục lục) rồi xáo trộn để câu hỏi
    // trải đều toàn bộ tài liệu, không chỉ vài trang đầu.
    var pool = chunks.where((c) => c.length >= 150).toList();
    if (pool.isEmpty) pool = List.of(chunks);
    pool.shuffle(Random(stamp));

    onProgress(GenerationProgress(0, count, 0, 'Đang chuẩn bị mô hình...'));
    try {
      await _orCancel(_engine.prepare(
        onStatus: (m) {
          if (!_cancelled) onProgress(GenerationProgress(0, count, 0, m));
        },
      ));

      while (accepted.length < count && attempt < maxAttempts && !_cancelled) {
        final chunk = pool[attempt % pool.length];
        final criterion = Criterion.values[accepted.length % Criterion.values.length];
        attempt++;
        onProgress(GenerationProgress(
          accepted.length,
          count,
          attempt,
          'Đang tạo câu ${accepted.length + 1}/$count...',
          lastNote,
        ));

        String reply;
        try {
          reply = await _orCancel(_engine
              .generate(buildQuestionPrompt(chunk, criterion),
                  shouldStop: () => _cancelled)
              .timeout(const Duration(minutes: 3)));
          engineErrors = 0;
        } on _Cancelled {
          break;
        } catch (e) {
          engineErrors++;
          lastNote = 'Mô hình báo lỗi: $e';
          rejected.add(lastNote);
          debugPrint('[AI] lỗi mô hình: $e');
          if (engineErrors >= 3) {
            throw OfflineEngineException(
              'Mô hình AI báo lỗi liên tục ($e). Thiết bị này có thể chưa hỗ trợ '
              'AI offline (hiện chỉ thiết kế cho điện thoại Android). '
              'Hãy thử trên điện thoại.',
            );
          }
          continue;
        }
        if (_cancelled) break;
        debugPrint('[AI] lần $attempt trả lời: $reply');

        final parsed = parseModelReply(reply, chunk, 'g${stamp}_${attempt}_',
            criterion: criterion);
        final checked = checkQuestions(
          parsed.valid,
          sourceText: chunk,
          existing: accepted,
        );
        final why = [...parsed.rejected, ...checked.rejected];
        rejected.addAll(why);
        if (checked.accepted.isNotEmpty) {
          accepted.add(checked.accepted.first);
          lastNote = null;
        } else if (why.isNotEmpty) {
          lastNote = 'Lần thử $attempt bị loại: ${why.first}';
        }
      }
    } on _Cancelled {
      // Người dùng bấm Dừng khi đang nạp mô hình.
    } finally {
      // Không chờ: đóng mô hình ở nền để màn hình thoát ngay.
      unawaited(_engine.close());
    }
    return GenerationResult(accepted, rejected, _cancelled);
  }
}
