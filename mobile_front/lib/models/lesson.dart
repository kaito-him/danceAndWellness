class Lesson {
  final String lessonId;
  final String title;
  final int duration;
  final String? mediaUrl;
  final String? description;

  Lesson({
    required this.lessonId,
    required this.title,
    required this.duration,
    this.mediaUrl,
    this.description,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      lessonId: json['lessonId'] ?? '',
      title: json['title'] ?? '',
      duration: json['duration'] ?? 0,
      mediaUrl: json['mediaUrl'],
      description: json['description'],
    );
  }
}
