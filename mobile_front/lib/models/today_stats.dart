class TodayStats {
  final int newStudents;
  final int newInstructorApplications;
  final int newCourses;
  final int totalEnrollmentsToday;
  final int paidEnrollmentsToday;
  final int freeEnrollmentsToday;
  final int revenueTodayCents;
  final Map<String, int> enrollmentsByCategoryToday;

  TodayStats({
    required this.newStudents,
    required this.newInstructorApplications,
    required this.newCourses,
    required this.totalEnrollmentsToday,
    required this.paidEnrollmentsToday,
    required this.freeEnrollmentsToday,
    required this.revenueTodayCents,
    required this.enrollmentsByCategoryToday,
  });

  factory TodayStats.fromJson(Map<String, dynamic> json) {
    final enrollByCatRaw = json['enrollmentsByCategoryToday'] as Map<String, dynamic>? ?? {};
    final enrollByCat = enrollByCatRaw.map((key, value) => MapEntry(key, value as int));

    return TodayStats(
      newStudents: (json['newStudents'] ?? 0) as int,
      newInstructorApplications: (json['newInstructorApplications'] ?? 0) as int,
      newCourses: (json['newCourses'] ?? 0) as int,
      totalEnrollmentsToday: (json['totalEnrollmentsToday'] ?? 0) as int,
      paidEnrollmentsToday: (json['paidEnrollmentsToday'] ?? 0) as int,
      freeEnrollmentsToday: (json['freeEnrollmentsToday'] ?? 0) as int,
      revenueTodayCents: (json['revenueTodayCents'] ?? 0) as int,
      enrollmentsByCategoryToday: enrollByCat,
    );
  }

  double get revenueTodayDollars => revenueTodayCents / 100.0;
}
