import 'lesson.dart';
import 'quiz.dart';

class Course {
  final String courseId;
  final String title;
  final bool isFree;
  final double? price;
  final String? level;
  final String? status;
  final String? thumbnailUrl;
  final String? categoryId;
  final String? description;
  final CourseInstructor? instructor;
  final int lessonCount;
  final int quizCount;
  final List<Lesson> lessons;
  final List<Quiz> quizzes;
  final String? archivedAt;
  final String? archiveReason;
  final bool archivedByAdmin;

  Course({
    required this.courseId,
    required this.title,
    required this.isFree,
    this.price,
    this.level,
    this.status,
    this.thumbnailUrl,
    this.categoryId,
    this.description,
    this.instructor,
    this.lessonCount = 0,
    this.quizCount = 0,
    this.lessons = const [],
    this.quizzes = const [],
    this.archivedAt,
    this.archiveReason,
    this.archivedByAdmin = false,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    final lessonsJson = json['lessons'] as List<dynamic>?;
    final lessonsList = lessonsJson != null
        ? lessonsJson.map((e) => Lesson.fromJson(e)).toList()
        : <Lesson>[];

    final quizzesJson = json['quizzes'] as List<dynamic>?;
    final quizzesList = quizzesJson != null
        ? quizzesJson.map((e) => Quiz.fromJson(e)).toList()
        : <Quiz>[];

    return Course(
      courseId: json['courseId'] ?? '',
      title: json['title'] ?? '',
      isFree: json['isFree'] ?? false,
      price: (json['price'] as num?)?.toDouble(),
      level: json['level'],
      status: json['status'],
      thumbnailUrl: json['thumbnailUrl'],
      categoryId: json['categoryId'],
      description: json['description'],
      instructor: json['instructor'] != null
          ? CourseInstructor.fromJson(json['instructor'])
          : null,
      lessonCount: lessonsList.length,
      quizCount: quizzesList.length,
      lessons: lessonsList,
      quizzes: quizzesList,
      archivedAt: json['archivedAt']?.toString(),
      archiveReason: json['archiveReason'],
      archivedByAdmin: json['archivedByAdmin'] ?? false,
    );
  }
}

class CourseInstructor {
  final String? id;
  final String? userId;
  final String? username;
  final String? specialization;
  final String? photo;

  CourseInstructor({
    this.id,
    this.userId,
    this.username,
    this.specialization,
    this.photo,
  });

  factory CourseInstructor.fromJson(Map<String, dynamic> json) {
    return CourseInstructor(
      id: json['id'],
      userId: json['userId'],
      username: json['username'],
      specialization: json['specialization'],
      photo: json['photo'],
    );
  }
}
