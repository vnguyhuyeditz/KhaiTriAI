import 'dart:math';

import '../models/attempt.dart';
import '../models/question.dart';

/// So sánh hai lần làm bài: [before] là lần cũ, [after] là lần mới.
class Comparison {
  final Attempt beforeAttempt;
  final Attempt afterAttempt;
  final Assessment before;
  final Assessment after;

  /// Chênh lệch 5 tiêu chí (sau trừ trước); null nếu một bên thiếu dữ liệu.
  final List<double?> deltas;

  /// Các câu xuất hiện ở cả hai lần (cùng mã và cùng nội dung):
  /// trước sai nay đúng / vẫn sai / trước đúng nay sai.
  final List<Question> fixed;
  final List<Question> stillWrong;
  final List<Question> regressed;
  final int commonCount;

  const Comparison._({
    required this.beforeAttempt,
    required this.afterAttempt,
    required this.before,
    required this.after,
    required this.deltas,
    required this.fixed,
    required this.stillWrong,
    required this.regressed,
    required this.commonCount,
  });

  /// Tự sắp xếp theo thời gian, nên truyền hai lần theo thứ tự nào cũng được.
  factory Comparison.of(Attempt x, Attempt y) {
    final older = x.date.isAfter(y.date) ? y : x;
    final newer = identical(older, x) ? y : x;
    final b = Assessment.of(older);
    final a = Assessment.of(newer);

    final bv = b.values;
    final av = a.values;
    final deltas = <double?>[
      for (var i = 0; i < av.length; i++)
        (bv[i] == null || av[i] == null) ? null : av[i]! - bv[i]!,
    ];

    final beforeRight = <String, bool>{};
    final n0 = min(older.questions.length, older.answers.length);
    for (var i = 0; i < n0; i++) {
      final q = older.questions[i];
      beforeRight['${q.id}|${q.text}'] = older.answers[i].chosen == q.correct;
    }

    final fixed = <Question>[];
    final still = <Question>[];
    final regressed = <Question>[];
    var common = 0;
    final n1 = min(newer.questions.length, newer.answers.length);
    for (var i = 0; i < n1; i++) {
      final q = newer.questions[i];
      final was = beforeRight['${q.id}|${q.text}'];
      if (was == null) continue;
      common++;
      final now = newer.answers[i].chosen == q.correct;
      if (!was && now) {
        fixed.add(q);
      } else if (!was && !now) {
        still.add(q);
      } else if (was && !now) {
        regressed.add(q);
      }
    }

    return Comparison._(
      beforeAttempt: older,
      afterAttempt: newer,
      before: b,
      after: a,
      deltas: deltas,
      fixed: fixed,
      stillWrong: still,
      regressed: regressed,
      commonCount: common,
    );
  }
}

/// 4 nhóm kết quả khi kết hợp đúng/sai với mức tự tin.
enum Quadrant { mastered, shaky, hiddenMisconception, knownGap }

extension QuadrantInfo on Quadrant {
  String get label {
    switch (this) {
      case Quadrant.mastered:
        return 'Đã nắm vững';
      case Quadrant.shaky:
        return 'Còn lung lay';
      case Quadrant.hiddenMisconception:
        return 'Hiểu sai ngầm';
      case Quadrant.knownGap:
        return 'Biết mình chưa biết';
    }
  }

  String get hint {
    switch (this) {
      case Quadrant.mastered:
        return 'Đúng và tự tin';
      case Quadrant.shaky:
        return 'Đúng nhưng đoán';
      case Quadrant.hiddenMisconception:
        return 'Sai nhưng tự tin';
      case Quadrant.knownGap:
        return 'Sai và đoán';
    }
  }
}

class Assessment {
  /// Điểm 0..100 cho 4 tiêu chí; null nếu đề không có câu nào thuộc tiêu chí đó.
  final Map<Criterion, double?> byCriterion;

  /// Tiêu chí 5: mức tự tin khớp với kết quả, 0..100.
  final double? calibration;

  final int correctCount;
  final int total;
  final Map<Quadrant, int> quadrants;

  /// Chỉ số các câu làm sai; câu "hiểu sai ngầm" xếp trước.
  final List<int> reviewOrder;

  const Assessment._({
    required this.byCriterion,
    required this.calibration,
    required this.correctCount,
    required this.total,
    required this.quadrants,
    required this.reviewOrder,
  });

  /// Nhãn ngắn để đặt quanh radar cho khỏi bị cắt.
  static const radarLabels = [
    'Ghi nhớ',
    'Hiểu',
    'Vận dụng',
    'Phân tích',
    'Tự tin',
  ];

  /// Tên đầy đủ của 5 tiêu chí, dùng trong bảng điểm.
  static const fullLabels = [
    'Ghi nhớ',
    'Hiểu bản chất',
    'Vận dụng',
    'Phân tích',
    'Tự tin chính xác',
  ];

  /// Điểm cho một câu: đúng + chắc chắn được nhiều nhất,
  /// đúng nhưng đoán chỉ được ít, sai thì gần như không có điểm.
  static double points(bool correct, int confidence) {
    const right = [0.4, 0.7, 1.0];
    const wrong = [0.1, 0.05, 0.0];
    return correct ? right[confidence] : wrong[confidence];
  }

  /// Độ khớp giữa tự tin và kết quả cho một câu (0..1):
  /// đúng + chắc chắn = 1, sai + đoán = 1, sai + chắc chắn = 0.
  static double calibrationFor(bool correct, int confidence) {
    return 1 - ((correct ? 1.0 : 0.0) - confidence / 2).abs();
  }

  static Quadrant quadrantOf(bool correct, int confidence) {
    final confident = confidence >= 1;
    if (correct) return confident ? Quadrant.mastered : Quadrant.shaky;
    return confident ? Quadrant.hiddenMisconception : Quadrant.knownGap;
  }

  factory Assessment.of(Attempt a) {
    final n = min(a.questions.length, a.answers.length);
    final sums = <Criterion, double>{};
    final counts = <Criterion, int>{};
    final quad = {for (final q in Quadrant.values) q: 0};
    final hidden = <int>[];
    final others = <int>[];
    var calibSum = 0.0;
    var correctCount = 0;

    for (var i = 0; i < n; i++) {
      final q = a.questions[i];
      final ans = a.answers[i];
      final isRight = ans.chosen == q.correct;
      final int conf = ans.confidence.clamp(0, 2).toInt();
      if (isRight) correctCount++;

      sums[q.criterion] = (sums[q.criterion] ?? 0) + points(isRight, conf);
      counts[q.criterion] = (counts[q.criterion] ?? 0) + 1;
      calibSum += calibrationFor(isRight, conf);

      final qd = quadrantOf(isRight, conf);
      quad[qd] = quad[qd]! + 1;
      if (!isRight) {
        if (qd == Quadrant.hiddenMisconception) {
          hidden.add(i);
        } else {
          others.add(i);
        }
      }
    }

    final byCriterion = <Criterion, double?>{
      for (final c in Criterion.values)
        c: (counts[c] ?? 0) == 0 ? null : sums[c]! / counts[c]! * 100,
    };

    return Assessment._(
      byCriterion: byCriterion,
      calibration: n == 0 ? null : calibSum / n * 100,
      correctCount: correctCount,
      total: n,
      quadrants: quad,
      reviewOrder: [...hidden, ...others],
    );
  }

  /// 5 giá trị để vẽ radar, theo thứ tự của [radarLabels].
  List<double> get radarValues => [
        for (final c in Criterion.values) byCriterion[c] ?? 0,
        calibration ?? 0,
      ];

  /// Như [radarValues] nhưng giữ null khi không có dữ liệu.
  List<double?> get values => [
        for (final c in Criterion.values) byCriterion[c],
        calibration,
      ];

  /// Lời gợi ý ôn tập, tạo bằng quy tắc (không dùng AI).
  List<String> suggestions() {
    final out = <String>[];
    final hiddenCount = quadrants[Quadrant.hiddenMisconception] ?? 0;
    if (hiddenCount > 0) {
      out.add('Ưu tiên xem lại $hiddenCount câu bạn tự tin nhưng làm sai. '
          'Đây là chỗ hiểu sai mà bạn chưa nhận ra.');
    }

    Criterion? weakest;
    double? weakestScore;
    for (final c in Criterion.values) {
      final s = byCriterion[c];
      if (s != null && (weakestScore == null || s < weakestScore)) {
        weakest = c;
        weakestScore = s;
      }
    }
    if (weakest != null && weakestScore! < 70) {
      out.add('Luyện thêm kỹ năng "${weakest.label}" '
          '(đang ở mức ${weakestScore.round()}%).');
    }

    final shaky = quadrants[Quadrant.shaky] ?? 0;
    if (shaky > 0) {
      out.add('Có $shaky câu đúng nhưng bạn chỉ đoán. '
          'Hãy ôn lại để chắc hơn.');
    }

    if (calibration != null && calibration! < 60) {
      out.add('Mức tự tin của bạn chưa khớp với kết quả. '
          'Thử ghi "Đoán" khi chưa chắc để app đánh giá chính xác hơn.');
    }

    if (out.isEmpty) {
      out.add('Bạn làm rất tốt. Hãy thử một bộ câu hỏi khó hơn.');
    }
    return out;
  }
}
