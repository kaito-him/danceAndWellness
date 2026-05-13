class Quiz {
  final String quizId;
  final String title;
  final List<Question> questions;

  Quiz({required this.quizId, required this.title, required this.questions});

  factory Quiz.fromJson(Map<String, dynamic> json) {
    final qs = json['questions'] as List<dynamic>? ?? [];
    return Quiz(
      quizId: json['quizId'] ?? '',
      title: json['title'] ?? 'Untitled Quiz',
      questions: qs.map((q) => Question.fromJson(q)).toList(),
    );
  }
}

class Question {
  final String questionId;
  final String text;
  final List<AnswerOption> options;

  Question({required this.questionId, required this.text, required this.options});

  factory Question.fromJson(Map<String, dynamic> json) {
    final opts = json['options'] as List<dynamic>? ?? [];
    return Question(
      questionId: json['questionId'] ?? '',
      text: json['text'] ?? '',
      options: opts.map((o) => AnswerOption.fromJson(o)).toList(),
    );
  }
}

class AnswerOption {
  final String text;
  final bool isCorrect;

  AnswerOption({required this.text, required this.isCorrect});

  factory AnswerOption.fromJson(Map<String, dynamic> json) {
    return AnswerOption(
      text: json['text'] ?? '',
      isCorrect: json['isCorrect'] ?? json['correct'] ?? false,
    );
  }
}
