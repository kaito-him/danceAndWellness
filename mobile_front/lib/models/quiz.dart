class AnswerOption {
  final String text;
  final bool isCorrect;

  AnswerOption({required this.text, required this.isCorrect});

  factory AnswerOption.fromJson(Map<String, dynamic> json) {
    return AnswerOption(
      text: json['text'] ?? '',
      isCorrect: json['isCorrect'] ?? false,
    );
  }
}

class Question {
  final String questionId;
  final String text;
  final List<AnswerOption> options;

  Question({
    required this.questionId,
    required this.text,
    required this.options,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    final optionsJson = json['options'] as List<dynamic>?;
    return Question(
      questionId: json['questionId'] ?? '',
      text: json['text'] ?? '',
      options: optionsJson != null
          ? optionsJson.map((e) => AnswerOption.fromJson(e)).toList()
          : <AnswerOption>[],
    );
  }
}

class Quiz {
  final String quizId;
  final String title;
  final List<Question> questions;

  Quiz({required this.quizId, required this.title, required this.questions});

  factory Quiz.fromJson(Map<String, dynamic> json) {
    final questionsJson = json['questions'] as List<dynamic>?;
    return Quiz(
      quizId: json['quizId'] ?? '',
      title: json['title'] ?? '',
      questions: questionsJson != null
          ? questionsJson.map((e) => Question.fromJson(e)).toList()
          : <Question>[],
    );
  }
}
