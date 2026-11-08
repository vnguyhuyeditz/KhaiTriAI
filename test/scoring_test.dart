import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:khai_tri_ai/settings/settings_controller.dart';
import 'package:khai_tri_ai/storage/stats_store.dart';
import 'package:khai_tri_ai/ai/question_generator.dart';
import 'package:khai_tri_ai/data/sample_questions.dart';
import 'package:khai_tri_ai/logic/scoring.dart';
import 'package:khai_tri_ai/models/attempt.dart';
import 'package:khai_tri_ai/models/question.dart';

Attempt _attempt(List<Answer> answers) => Attempt(
      date: DateTime(2026, 11, 3),
      subject: 'Toán 10',
      questions: sampleQuestions.take(answers.length).toList(),
      answers: answers,
    );

void main() {
  test('bộ câu hỏi mẫu hợp lệ và mỗi tiêu chí có 5 câu', () {
    for (final q in sampleQuestions) {
      expect(q.validate(), isNull, reason: 'câu ${q.id} không hợp lệ');
    }
    for (final c in Criterion.values) {
      expect(sampleQuestions.where((q) => q.criterion == c).length, 5);
    }
  });

  test('đúng hết và chắc chắn thì đạt 100 ở mọi tiêu chí', () {
    final answers = [for (final q in sampleQuestions) Answer(q.correct, 2)];
    final a = Assessment.of(_attempt(answers));
    expect(a.correctCount, 20);
    for (final c in Criterion.values) {
      expect(a.byCriterion[c], closeTo(100, 0.001));
    }
    expect(a.calibration, closeTo(100, 0.001));
    expect(a.quadrants[Quadrant.mastered], 20);
  });

  test('sai nhưng chắc chắn là "hiểu sai ngầm" và tự tin chính xác = 0', () {
    final q = sampleQuestions.first;
    final wrong = (q.correct + 1) % 4;
    final a = Assessment.of(_attempt([Answer(wrong, 2)]));
    expect(a.quadrants[Quadrant.hiddenMisconception], 1);
    expect(a.calibration, closeTo(0, 0.001));
    expect(a.reviewOrder, [0]);
  });

  test('sai và đoán là "biết mình chưa biết", tự tin chính xác = 100', () {
    final q = sampleQuestions.first;
    final wrong = (q.correct + 1) % 4;
    final a = Assessment.of(_attempt([Answer(wrong, 0)]));
    expect(a.quadrants[Quadrant.knownGap], 1);
    expect(a.calibration, closeTo(100, 0.001));
  });

  test('đúng nhưng đoán chỉ được 40 điểm', () {
    final q = sampleQuestions.first; // câu ghi nhớ
    final a = Assessment.of(_attempt([Answer(q.correct, 0)]));
    expect(a.byCriterion[Criterion.nho], closeTo(40, 0.001));
    expect(a.quadrants[Quadrant.shaky], 1);
    expect(a.byCriterion[Criterion.hieu], isNull);
  });

  test('câu hiểu sai ngầm được xếp trước trong danh sách xem lại', () {
    final q0 = sampleQuestions[0];
    final q1 = sampleQuestions[1];
    final a = Assessment.of(_attempt([
      Answer((q0.correct + 1) % 4, 0), // sai, đoán
      Answer((q1.correct + 1) % 4, 2), // sai, chắc chắn
    ]));
    expect(a.reviewOrder, [1, 0]);
  });

  test('lưu và đọc lại một lần làm bài giữ nguyên dữ liệu', () {
    final original = _attempt([Answer(1, 2), Answer(0, 1)]);
    final copy = Attempt.fromJson(original.toJson());
    expect(copy.questions.length, 2);
    expect(copy.answers[1].confidence, 1);
    expect(copy.questions[0].misconceptions, original.questions[0].misconceptions);
  });

  group('đọc JSON từ AI', () {
    const source = 'Biệt thức delta bằng b bình phương trừ 4ac. '
        'Nếu delta âm thì phương trình vô nghiệm.';

    String good() => '''
[{
  "cau_hoi": "Biệt thức delta tính thế nào?",
  "dap_an": ["A. b² + 4ac", "B. b² − 4ac", "C. 4ac − b²", "D. b² − 2ac"],
  "dap_an_dung": "B",
  "tieu_chi": "nho",
  "trich_dan": "Biệt thức delta bằng b bình phương trừ 4ac",
  "loi_sai_pho_bien": {"A": "nhầm dấu", "D": "nhầm hệ số"},
  "giai_thich": "Công thức của delta."
}]''';

    test('nhận câu hợp lệ', () {
      final r = parseAiQuestions(good(), source);
      expect(r.valid.length, 1);
      expect(r.rejected, isEmpty);
      expect(r.valid.first.correct, 1);
      expect(r.valid.first.options[1], 'b² − 4ac');
      expect(r.valid.first.misconceptions[0], 'nhầm dấu');
    });

    test('loại câu có trích dẫn không nằm trong tài liệu', () {
      final r = parseAiQuestions(good(), 'Một đoạn văn hoàn toàn khác.');
      expect(r.valid, isEmpty);
      expect(r.rejected.length, 1);
    });

    test('loại câu sai nhãn tiêu chí', () {
      final bad = good().replaceFirst('"nho"', '"khong_ro"');
      expect(parseAiQuestions(bad, source).valid, isEmpty);
    });

    test('loại câu có đáp án trùng nhau', () {
      final bad = good().replaceFirst('"B. b² − 4ac"', '"B. b² + 4ac"');
      expect(parseAiQuestions(bad, source).valid, isEmpty);
    });

    test('xử lý khi AI không trả về JSON', () {
      final r = parseAiQuestions('xin chào', source);
      expect(r.valid, isEmpty);
      expect(r.rejected, isNotEmpty);
    });
  });

  group('so sánh 2 lần', () {
    Attempt at(DateTime d, List<Answer> a) => Attempt(
          date: d,
          subject: 'Toán 10',
          questions: sampleQuestions.take(a.length).toList(),
          answers: a,
        );

    test('tự sắp theo thời gian và tính câu đã sửa', () {
      final q0 = sampleQuestions[0];
      final q1 = sampleQuestions[1];
      final older = at(DateTime(2026, 11, 1), [
        Answer((q0.correct + 1) % 4, 2), // sai
        Answer(q1.correct, 2), // đúng
      ]);
      final newer = at(DateTime(2026, 11, 5), [
        Answer(q0.correct, 2), // đúng
        Answer((q1.correct + 1) % 4, 2), // sai
      ]);
      // truyền ngược thứ tự vẫn đúng
      final c = Comparison.of(newer, older);
      expect(c.beforeAttempt.date, older.date);
      expect(c.commonCount, 2);
      expect(c.fixed.map((q) => q.id), [q0.id]);
      expect(c.regressed.map((q) => q.id), [q1.id]);
      expect(c.stillWrong, isEmpty);
    });

    test('tiêu chí thiếu dữ liệu thì chênh lệch là null', () {
      final q0 = sampleQuestions[0];
      final a1 = at(DateTime(2026, 11, 1), [Answer(q0.correct, 2)]);
      final a2 = at(DateTime(2026, 11, 2), [Answer(q0.correct, 0)]);
      final c = Comparison.of(a1, a2);
      expect(c.deltas.length, 5);
      expect(c.deltas.where((d) => d == null).length, greaterThan(0));
    });
  });

  group('bộ tạo câu hỏi mẫu', () {
    test('đúng số câu, không trùng, cân bằng giữa 4 nhãn', () async {
      final qs = await SampleQuestionGenerator().generate('', count: 10);
      expect(qs.length, 10);
      expect(qs.map((q) => q.id).toSet().length, 10);
      for (final c in Criterion.values) {
        final n = qs.where((q) => q.criterion == c).length;
        expect(n, inInclusiveRange(2, 3));
      }
    });

    test('xin quá nhiều thì trả tối đa bằng kho câu hỏi', () async {
      final qs = await SampleQuestionGenerator().generate('', count: 999);
      expect(qs.length, sampleQuestions.length);
    });
  });

  group('cài đặt', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    test('lưu và đọc lại', () async {
      SharedPreferences.setMockInitialValues({});
      final s = await SettingsController.load();
      s.setThemeMode(ThemeMode.dark);
      s.setFont(AppFont.inter);
      s.setQuestionCount(10);
      s.setTextScale(1.2);
      await Future<void>.delayed(Duration.zero);

      final s2 = await SettingsController.load();
      expect(s2.themeMode, ThemeMode.dark);
      expect(s2.font, AppFont.inter);
      expect(s2.questionCount, 10);
      expect(s2.textScale, closeTo(1.2, 0.001));
    });

    test('bỏ qua giá trị không hợp lệ', () async {
      SharedPreferences.setMockInitialValues({});
      final s = await SettingsController.load();
      s.setQuestionCount(7);
      expect(s.questionCount, 20);
    });
  });

  group('streak và số bài đã làm', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('làm liên tiếp các ngày thì streak tăng, cùng ngày không tăng', () async {
      final st = StatsStore();
      var s = await st.recordAttempt(DateTime(2026, 11, 1, 9));
      expect((s.total, s.streak), (1, 1));
      s = await st.recordAttempt(DateTime(2026, 11, 1, 20)); // cùng ngày
      expect((s.total, s.streak), (2, 1));
      s = await st.recordAttempt(DateTime(2026, 11, 2, 8));
      expect((s.total, s.streak, s.best), (3, 2, 2));
      s = await st.recordAttempt(DateTime(2026, 11, 3, 23));
      expect(s.streak, 3);
    });

    test('bỏ một ngày thì streak về 1 nhưng kỷ lục được giữ', () async {
      final st = StatsStore();
      await st.recordAttempt(DateTime(2026, 11, 1));
      await st.recordAttempt(DateTime(2026, 11, 2));
      final s = await st.recordAttempt(DateTime(2026, 11, 5));
      expect(s.streak, 1);
      expect(s.best, 2);
    });

    test('streak hiển thị còn hiệu lực hôm nay hoặc hôm qua, sau đó về 0', () async {
      final st = StatsStore();
      final s = await st.recordAttempt(DateTime(2026, 11, 1));
      expect(s.currentStreak(DateTime(2026, 11, 1, 22)), 1);
      expect(s.currentStreak(DateTime(2026, 11, 2, 10)), 1); // chưa đứt
      expect(s.currentStreak(DateTime(2026, 11, 3, 10)), 0); // đã đứt
      expect(s.doneToday(DateTime(2026, 11, 1, 23)), isTrue);
      expect(s.doneToday(DateTime(2026, 11, 2)), isFalse);
    });

    test('âm lượng nhạc nền mặc định 50% và bị giới hạn 0–100', () async {
      SharedPreferences.setMockInitialValues({});
      final c = await SettingsController.load();
      expect(c.musicPercent, 50);
      c.setMusicPercent(250);
      expect(c.musicPercent, 100);
      c.setMusicPercent(-5);
      expect(c.musicPercent, 0);
    });
  });
}
