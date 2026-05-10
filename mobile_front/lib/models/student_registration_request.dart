class StudentRegistrationRequest {
  final String username;
  final String email;
  final String password;
  final List<String> categoryIds;
  final String skillLevel;

  StudentRegistrationRequest({
    required this.username,
    required this.email,
    required this.password,
    required this.categoryIds,
    required this.skillLevel,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'password': password,
      'categoryIds': categoryIds,
      'skillLevel': skillLevel,
    };
  }
}
