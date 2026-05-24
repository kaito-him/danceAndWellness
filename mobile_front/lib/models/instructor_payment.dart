class InstructorEnrollmentRow {
  final String enrollmentId;
  final String courseId;
  final String studentId;
  final String studentName;
  final String studentEmail;
  final String courseTitle;
  final String enrollmentType;
  final int amountPaidCents;
  final int instructorShareCents;
  final DateTime enrolledAt;

  InstructorEnrollmentRow({
    required this.enrollmentId,
    required this.courseId,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    required this.courseTitle,
    required this.enrollmentType,
    required this.amountPaidCents,
    required this.instructorShareCents,
    required this.enrolledAt,
  });

  factory InstructorEnrollmentRow.fromJson(Map<String, dynamic> json) {
    return InstructorEnrollmentRow(
      enrollmentId: json['enrollmentId']?.toString() ?? '',
      courseId: json['courseId']?.toString() ?? '',
      studentId: json['studentId']?.toString() ?? '',
      studentName: json['studentName']?.toString() ?? 'Unknown Student',
      studentEmail: json['studentEmail']?.toString() ?? '',
      courseTitle: json['courseTitle']?.toString() ?? 'Unknown Course',
      enrollmentType: json['enrollmentType']?.toString() ?? 'FREE',
      amountPaidCents: (json['amountPaidCents'] as num?)?.toInt() ?? 0,
      instructorShareCents: (json['instructorShareCents'] as num?)?.toInt() ?? 0,
      enrolledAt: json['enrolledAt'] != null 
          ? DateTime.parse(json['enrolledAt'].toString()) 
          : DateTime.now(),
    );
  }
}

class StripeStatus {
  final bool hasAccount;
  final bool chargesEnabled;
  final bool detailsSubmitted;
  final String? accountId;

  StripeStatus({
    required this.hasAccount,
    required this.chargesEnabled,
    required this.detailsSubmitted,
    this.accountId,
  });

  factory StripeStatus.fromJson(Map<String, dynamic> json) {
    return StripeStatus(
      hasAccount: json['hasAccount'] ?? false,
      chargesEnabled: json['chargesEnabled'] ?? false,
      detailsSubmitted: json['detailsSubmitted'] ?? false,
      accountId: json['accountId']?.toString(),
    );
  }
}
