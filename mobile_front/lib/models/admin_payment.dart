class AdminTransaction {
  final String id;
  final String studentName;
  final String studentId;
  final String courseTitle;
  final String? courseId;
  final String instructorName;
  final String instructorId;
  final int totalAmountCents;
  final int platformFeeCents;
  final String enrolledAt;

  AdminTransaction({
    required this.id,
    required this.studentName,
    required this.studentId,
    required this.courseTitle,
    this.courseId,
    required this.instructorName,
    required this.instructorId,
    required this.totalAmountCents,
    required this.platformFeeCents,
    required this.enrolledAt,
  });

  factory AdminTransaction.fromJson(Map<String, dynamic> json) {
    return AdminTransaction(
      id: json['id'] ?? '',
      studentName: json['studentName'] ?? 'Unknown',
      studentId: json['studentId'] ?? '',
      courseTitle: json['courseTitle'] ?? 'Unknown Course',
      courseId: json['courseId'],
      instructorName: json['instructorName'] ?? 'Unknown',
      instructorId: json['instructorId'] ?? '',
      totalAmountCents: json['totalAmountCents'] ?? 0,
      platformFeeCents: json['platformFeeCents'] ?? 0,
      enrolledAt: json['enrolledAt'] ?? '',
    );
  }

  double get totalAmount => totalAmountCents / 100.0;
  double get platformFee => platformFeeCents / 100.0;
  DateTime get date => DateTime.parse(enrolledAt);
}

class AdminRevenueSummary {
  final int totalPlatformRevenueCents;
  final int todayPlatformRevenueCents;
  final int totalTransactionsCount;

  AdminRevenueSummary({
    required this.totalPlatformRevenueCents,
    required this.todayPlatformRevenueCents,
    required this.totalTransactionsCount,
  });

  factory AdminRevenueSummary.fromJson(Map<String, dynamic> json) {
    return AdminRevenueSummary(
      totalPlatformRevenueCents: json['totalPlatformRevenueCents'] ?? 0,
      todayPlatformRevenueCents: json['todayPlatformRevenueCents'] ?? 0,
      totalTransactionsCount: json['totalTransactionsCount'] ?? 0,
    );
  }

  double get totalRevenue => totalPlatformRevenueCents / 100.0;
  double get todayRevenue => todayPlatformRevenueCents / 100.0;
}
