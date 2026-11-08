import 'package:flutter_test/flutter_test.dart';
import 'package:khai_tri_ai/ai/offline/prompt_builder.dart';
import 'package:khai_tri_ai/models/question.dart';

const _chunk =
    'Quang hợp là quá trình cây xanh hấp thụ ánh sáng để tạo ra chất hữu cơ. '
    'Quá trình này diễn ra chủ yếu ở lá cây.';

const _json =
    '{"cau_hoi":"Quá trình nào giúp cây tạo ra chất hữu cơ?",'
    '"dap_an":["A. Quang hợp","B. Hô hấp","C. Tiêu hóa","D. Bài tiết"],'
    '"dap_an_dung":"A","tieu_chi":"nho","giai_thich":"Quang hợp tạo chất hữu cơ.",'
    '"trich_dan":"Quang hợp là quá trình cây xanh hấp thụ ánh sáng"}';

void main() {
  test('prompt chứa đoạn văn, loại câu hỏi và nhãn tiêu chí', () {
    final p = buildQuestionPrompt(_chunk, Criterion.hieu);
    expect(p.contains(_chunk), isTrue);
    expect(p.contains('HIỂU BẢN CHẤT'), isTrue);
    expect(p.contains('"dap_an_dung"'), isTrue);
  });

  group('tách JSON từ câu trả lời của mô hình', () {
    test('bỏ rào ``` và chữ thừa', () {
      final reply = 'Đây là câu hỏi:\n```json\n$_json\n```\nHy vọng giúp ích.';
      expect(extractJsonObject(reply), _json);
    });

    test('dấu ngoặc nằm trong chuỗi không làm hỏng việc tách', () {
      const obj = '{"a":"chuỗi có } và { bên trong","b":"dấu \\" nháy"}';
      expect(extractJsonObject('xx $obj yy'), obj);
    });

    test('JSON bị cụt hoặc không có thì trả null', () {
      expect(extractJsonObject('không có gì'), isNull);
      expect(extractJsonObject('{"a": "chưa đóng"'), isNull);
    });
  });

  group('đọc câu trả lời thành câu hỏi', () {
    test('đáp án viết thành khóa A,B,C,D và không có nhãn tiêu chí', () {
      const flat =
          '{"cau_hoi":"Quá trình nào giúp cây tạo ra chất hữu cơ?",'
          '"A":"Quang hợp","B":"Hô hấp","C":"Tiêu hóa","D":"Bài tiết",'
          '"dap_an_dung":"Đáp án A.","giai_thich":"Quang hợp tạo chất hữu cơ.",'
          '"trich_dan":"Quang hợp là quá trình cây xanh hấp thụ ánh sáng"}';
      final r = parseModelReply(flat, _chunk, 'g1_', criterion: Criterion.hieu);
      expect(r.valid.length, 1);
      expect(r.valid.first.criterion, Criterion.hieu);
      expect(r.valid.first.correct, 0);
    });

    test('thiếu đáp án thì báo đúng lý do', () {
      const few =
          '{"cau_hoi":"Quá trình nào giúp cây tạo ra chất hữu cơ?",'
          '"A":"Quang hợp","B":"Hô hấp","dap_an_dung":"A",'
          '"trich_dan":"Quang hợp là quá trình cây xanh hấp thụ ánh sáng"}';
      final r = parseModelReply(few, _chunk, 'g1_', criterion: Criterion.nho);
      expect(r.valid, isEmpty);
      expect(r.rejected.first.contains('2/4 đáp án'), isTrue);
    });

    test('câu hợp lệ', () {
      final r = parseModelReply('```json\n$_json\n```', _chunk, 'g1_');
      expect(r.valid.length, 1);
      expect(r.valid.first.correct, 0);
      expect(r.valid.first.options.first, 'Quang hợp'); // đã bỏ "A. "
    });

    test('trích dẫn không có trong đoạn thì bị loại', () {
      final bad = _json.replaceFirst(
          'Quang hợp là quá trình cây xanh hấp thụ ánh sáng', 'câu bịa');
      final r = parseModelReply(bad, _chunk, 'g1_');
      expect(r.valid, isEmpty);
      expect(r.rejected, isNotEmpty);
    });

    test('không có JSON thì có lý do loại', () {
      final r = parseModelReply('Xin lỗi tôi không biết', _chunk, 'g1_');
      expect(r.valid, isEmpty);
      expect(r.rejected.length, 1);
    });
  });
}
