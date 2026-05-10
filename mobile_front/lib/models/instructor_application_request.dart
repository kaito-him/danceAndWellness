class InstructorApplicationRequest {
  final String username;
  final String email;
  final String password;
  final String yearsOfExperience;
  final String specialization;
  final String studioName;
  final String bio;
  final String linkedIn;
  final String website;

  InstructorApplicationRequest({
    required this.username,
    required this.email,
    required this.password,
    required this.yearsOfExperience,
    required this.specialization,
    required this.studioName,
    required this.bio,
    required this.linkedIn,
    required this.website,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'password': password,
      'yearsOfExperience': yearsOfExperience,
      'specialization': specialization,
      'studioName': studioName,
      'bio': bio,
      'linkedIn': linkedIn,
      'website': website,
    };
  }
}
