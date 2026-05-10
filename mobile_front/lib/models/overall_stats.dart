class OverallStats {
  final int totalCourses;
  final int publishedCourses;
  final int archivedCourses;
  final int draftCourses;
  final int totalStudents;
  final int totalInstructors;
  final int activeAccounts;
  final int bannedAccounts;
  final int pendingInstructorApplications;
  final int totalEnrollments;
  final int paidEnrollments;
  final int freeEnrollments;
  final int totalRevenueCents;

  OverallStats({
    required this.totalCourses,
    required this.publishedCourses,
    required this.archivedCourses,
    required this.draftCourses,
    required this.totalStudents,
    required this.totalInstructors,
    required this.activeAccounts,
    required this.bannedAccounts,
    required this.pendingInstructorApplications,
    required this.totalEnrollments,
    required this.paidEnrollments,
    required this.freeEnrollments,
    required this.totalRevenueCents,
  });

  factory OverallStats.fromJson(Map<String, dynamic> json) {
    return OverallStats(
      totalCourses: (json['totalCourses'] ?? 0) as int,
      publishedCourses: (json['publishedCourses'] ?? 0) as int,
      archivedCourses: (json['archivedCourses'] ?? 0) as int,
      draftCourses: (json['draftCourses'] ?? 0) as int,
      totalStudents: (json['totalStudents'] ?? 0) as int,
      totalInstructors: (json['totalInstructors'] ?? 0) as int,
      activeAccounts: (json['activeAccounts'] ?? 0) as int,
      bannedAccounts: (json['bannedAccounts'] ?? 0) as int,
      pendingInstructorApplications:
          (json['pendingInstructorApplications'] ?? 0) as int,
      totalEnrollments: (json['totalEnrollments'] ?? 0) as int,
      paidEnrollments: (json['paidEnrollments'] ?? 0) as int,
      freeEnrollments: (json['freeEnrollments'] ?? 0) as int,
      totalRevenueCents: (json['totalRevenueCents'] ?? 0) as int,
    );
  }

  double get totalRevenueDollars => totalRevenueCents / 100.0;
}

class PendingInstructor {
  final String id;
  final String userId;
  final String username;
  final String email;
  final String? specialization;
  final String? yearsOfExperience;
  final String? studioName;
  final String? bio;
  final String? photo;

  PendingInstructor({
    required this.id,
    required this.userId,
    required this.username,
    required this.email,
    this.specialization,
    this.yearsOfExperience,
    this.studioName,
    this.bio,
    this.photo,
  });

  factory PendingInstructor.fromJson(Map<String, dynamic> json) {
    return PendingInstructor(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      username: json['username'] ?? json['email'] ?? '',
      email: json['email'] ?? '',
      specialization: json['specialization'],
      yearsOfExperience: json['yearsOfExperience'],
      studioName: json['studioName'],
      bio: json['bio'],
      photo: json['photo'],
    );
  }
}
