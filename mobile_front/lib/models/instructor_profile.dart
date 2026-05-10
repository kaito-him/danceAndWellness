class InstructorProfile {
  final String id;
  final String userId;
  final String username;
  final String email;
  final String? specialization;
  final String? studioName;
  final String? bio;
  final String? yearsOfExperience;
  final String? linkedIn;
  final String? website;
  final String? photo;
  final bool featured;
  final int totalCourses;

  InstructorProfile({
    required this.id,
    required this.userId,
    required this.username,
    required this.email,
    this.specialization,
    this.studioName,
    this.bio,
    this.yearsOfExperience,
    this.linkedIn,
    this.website,
    this.photo,
    this.featured = false,
    this.totalCourses = 0,
  });

  factory InstructorProfile.fromJson(Map<String, dynamic> json) {
    return InstructorProfile(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      specialization: json['specialization'],
      studioName: json['studioName'],
      bio: json['bio'],
      yearsOfExperience: json['yearsOfExperience'],
      linkedIn: json['linkedIn'],
      website: json['website'],
      photo: json['photo'],
      featured: json['featured'] ?? false,
      totalCourses: json['totalCourses'] ?? 0,
    );
  }
}
