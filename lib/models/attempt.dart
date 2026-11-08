import 'question.dart';

/// Câu trả lời của học sinh cho một câu hỏi.
class Answer {
  final int chosen; // đáp án đã chọn, 0..3
  final int confidence; // 0 = Đoán, 1 = Hơi chắc, 2 = Chắc chắn

  const Answer(this.chosen, this.confidence);

  Map<String, dynamic> toJson() => {'c': chosen, 'f': confidence};

  factory Answer.fromJson(Map<String, dynamic> j) =>
      Answer(j['c'] as int, j['f'] as int);
}

/// Một lần làm bài: đề + câu trả lời. Lưu cả đề để xem lại được
/// kể cả khi đề do AI tạo ra.
class Attempt {
  final DateTime date;
  final String subject;
  final List<Question> questions;
  final List<Answer> answers; // cùng thứ tự với questions

  const Attempt({
    required this.date,
    required this.subject,
    required this.questions,
    required this.answers,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'subject': subject,
        'questions': questions.map((q) => q.toJson()).toList(),
        'answers': answers.map((a) => a.toJson()).toList(),
      };

  factory Attempt.fromJson(Map<String, dynamic> j) => Attempt(
        date: DateTime.parse(j['date'] as String),
        subject: j['subject'] as String,
        questions: (j['questions'] as List)
            .map((e) => Question.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        answers: (j['answers'] as List)
            .map((e) => Answer.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}
