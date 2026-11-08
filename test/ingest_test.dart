import 'package:flutter_test/flutter_test.dart';
import 'package:khai_tri_ai/ai/question_checks.dart';
import 'package:khai_tri_ai/ingest/text_cleaner.dart';
import 'package:khai_tri_ai/ingest/text_quality.dart';
import 'package:khai_tri_ai/models/question.dart';

const _viText =
    'Quang hợp là quá trình cây xanh hấp thụ ánh sáng để tạo ra chất hữu cơ. '
    'Quá trình này diễn ra chủ yếu ở lá cây. Khí oxi được thải ra môi trường '
    'trong khi cây lấy khí cacbonic từ không khí. Nhờ đó con người và động vật '
    'có oxi để thở và có thức ăn để sinh trưởng.';

Question _q({
  String text = 'Quá trình nào giúp cây xanh tạo ra chất hữu cơ từ ánh sáng?',
  String quote = 'quá trình cây xanh hấp thụ ánh sáng',
}) =>
    Question(
      id: 'x',
      text: text,
      options: const ['Quang hợp', 'Hô hấp', 'Thoát hơi nước', 'Tiêu hóa'],
      correct: 0,
      criterion: Criterion.nho,
      explanation: 'Quang hợp giúp cây tạo chất hữu cơ nhờ ánh sáng.',
      sourceQuote: quote,
    );

void main() {
  group('chất lượng chữ', () {
    test('đoạn tiếng Việt bình thường là tốt', () {
      expect(assessText(_viText).level, QualityLevel.good);
    });

    test('rỗng hoặc toàn ký hiệu là tệ', () {
      expect(assessText('').level, QualityLevel.poor);
      expect(assessText('@@## \$\$%% ^^&& **(( ))__ ++== @@## \$\$%% ^^&& **(( ))__ ++== '
              '@@## \$\$%% ^^&& **(( ))__ ++== @@## \$\$%% ^^&& **(( ))__ ++== '
              '@@## \$\$%% ^^&& **(( ))__ ++== @@## \$\$%% ^^&& **(( ))__ ++==')
          .level, QualityLevel.poor);
    });

    test('looksGarbled', () {
      expect(looksGarbled(''), isTrue);
      expect(looksGarbled('ab'), isTrue);
      expect(looksGarbled(_viText), isFalse);
      expect(looksGarbled('abc\u{FFFD}\u{FFFD}\u{FFFD}\u{FFFD} def ghi jkl mno pqr stu'), isTrue);
    });
  });

  group('làm sạch chữ', () {
    test('nối dòng bị ngắt, bỏ số trang', () {
      final out = cleanText('Dòng một của đoạn\nvăn bị ngắt dòng.\n\n12\n\nĐoạn hai.');
      expect(out, 'Dòng một của đoạn văn bị ngắt dòng.\nĐoạn hai.');
    });

    test('nối từ bị ngắt bằng gạch nối', () {
      expect(cleanText('This is informa-\ntion about it.'),
          'This is information about it.');
    });

    test('bỏ tiêu đề lặp lại nhiều lần', () {
      final out = cleanText('Tiêu đề chương 1\nNội dung A.\nTiêu đề chương 1\n'
          'Nội dung B.\nTiêu đề chương 1\nNội dung C.');
      expect(out.contains('Tiêu đề'), isFalse);
      expect(out, 'Nội dung A.\nNội dung B.\nNội dung C.');
    });

    test('giữ dòng bắt đầu bằng gạch đầu dòng hoặc số thứ tự', () {
      final out = cleanText('Các bước gồm\n- Bước một\n- Bước hai');
      expect(out, 'Các bước gồm\n- Bước một\n- Bước hai');
    });
  });

  group('cắt đoạn', () {
    final sentences = [
      for (var i = 1; i <= 30; i++) 'Đây là câu số $i của bài kiểm tra thử nghiệm.'
    ];
    final text = sentences.join(' ');

    test('không đoạn nào quá dài, không cắt giữa câu, không mất chữ', () {
      final chunks = chunkText(text);
      expect(chunks.length, greaterThanOrEqualTo(2));
      for (final c in chunks) {
        expect(c.length, lessThanOrEqualTo(900));
        expect(c.endsWith('.'), isTrue);
      }
      expect(chunks.join(' '), text);
    });

    test('văn bản ngắn thành một đoạn, rỗng thành không đoạn', () {
      expect(chunkText('Chỉ có một câu ngắn.').length, 1);
      expect(chunkText('   \n  '), isEmpty);
    });

    test('một câu cực dài vẫn được cắt nhỏ', () {
      final long = List.filled(400, 'từ').join(' ');
      final chunks = chunkText(long);
      expect(chunks.every((c) => c.length <= 900), isTrue);
    });
  });

  group('kiểm tra câu hỏi', () {
    test('nhận diện tiếng Việt', () {
      expect(isLikelyVietnamese(_viText), isTrue);
      expect(isLikelyVietnamese('This is an English sentence about plants.'), isFalse);
      expect(isLikelyVietnamese('12345 + 678'), isFalse);
    });

    test('nhận câu hợp lệ', () {
      final r = checkQuestions([_q()], sourceText: _viText);
      expect(r.accepted.length, 1);
      expect(r.rejected, isEmpty);
    });

    test('loại câu có trích dẫn không có trong tài liệu', () {
      final r = checkQuestions([_q(quote: 'câu này không hề có trong nguồn')],
          sourceText: _viText);
      expect(r.accepted, isEmpty);
      expect(r.rejected.length, 1);
    });

    test('loại câu hỏi viết bằng tiếng Anh khi tài liệu là tiếng Việt', () {
      final r = checkQuestions(
          [_q(text: 'Which process lets green plants make food from light?')],
          sourceText: _viText);
      expect(r.accepted, isEmpty);
    });

    test('loại câu trùng nhau và trùng câu đã có', () {
      final r = checkQuestions([_q(), _q()], sourceText: _viText);
      expect(r.accepted.length, 1);
      final r2 = checkQuestions([_q()], sourceText: _viText, existing: [_q()]);
      expect(r2.accepted, isEmpty);
    });
  });
}
