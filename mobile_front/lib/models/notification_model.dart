class NotificationModel {
  final String id;
  final String message;
  final String? type;
  final String? courseId;
  bool read;
  final DateTime? createdAt;

  NotificationModel({
    required this.id,
    required this.message,
    this.type,
    this.courseId,
    required this.read,
    this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      message: json['message'] ?? '',
      type: json['type'],
      courseId: json['courseId'],
      read: json['read'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}
