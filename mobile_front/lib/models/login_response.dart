class LoginResponse {
  final bool success;
  final String? role;
  final String? token;
  final String message;
  final String? userId;

  LoginResponse({
    required this.success,
    this.role,
    this.token,
    required this.message,
    this.userId,
  });

  factory LoginResponse.fromJson(dynamic json) {
    // Handle both Map (parsed JSON) and String (plain text body)
    if (json is Map) {
      return LoginResponse(
        success: json['success'] == true,
        role: json['role']?.toString(),
        token: json['token']?.toString(),
        message: json['message']?.toString() ?? '',
        userId: json['userId']?.toString(),
      );
    }
    // Plain-text body — treat as failure message
    return LoginResponse(
      success: false,
      message: json?.toString() ?? '',
    );
  }
}
