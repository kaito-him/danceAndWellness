class AppUser {
  final String userId;
  final String? id; // studentId or instructorId
  final String username;
  final String email;
  final String role;
  final String? photo;
  final String accountStatus;
  final bool featured;
  
  // Instructor specific
  final String? specialization;
  final int totalCourses;
  final String? yearsOfExperience;
  final String? linkedIn;
  final String? website;

  // Student specific
  final String? lastLoginDate;
  final String? createdAt;
  final List<String> badgeIds;

  AppUser({
    required this.userId,
    this.id,
    required this.username,
    required this.email,
    required this.role,
    this.photo,
    required this.accountStatus,
    this.featured = false,
    this.specialization,
    this.totalCourses = 0,
    this.yearsOfExperience,
    this.linkedIn,
    this.website,
    this.lastLoginDate,
    this.createdAt,
    this.badgeIds = const [],
  });

  factory AppUser.fromJson(Map<String, dynamic> json, String role) {
    return AppUser(
      userId: json['userId'] ?? '',
      id: json['id'],
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      role: role,
      photo: json['photo'],
      accountStatus: json['accountStatus'] ?? 'PENDING',
      featured: json['featured'] ?? false,
      specialization: json['specialization'],
      totalCourses: json['totalCourses'] ?? 0,
      yearsOfExperience: json['yearsOfExperience'],
      linkedIn: json['linkedIn'],
      website: json['website'],
      lastLoginDate: json['lastLoginDate'],
      createdAt: json['createdAt'],
      badgeIds: json['badgeIds'] != null ? List<String>.from(json['badgeIds']) : [],
    );
  }
}
