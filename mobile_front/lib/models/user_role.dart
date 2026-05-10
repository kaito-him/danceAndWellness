enum UserRole {
  student('STUDENT'),
  instructor('INSTRUCTOR'),
  admin('ADMIN');

  final String value;
  const UserRole(this.value);

  static UserRole fromString(String role) {
    switch (role.toUpperCase()) {
      case 'STUDENT':
        return UserRole.student;
      case 'INSTRUCTOR':
        return UserRole.instructor;
      case 'ADMIN':
        return UserRole.admin;
      default:
        throw Exception('Unknown role: $role');
    }
  }
}
