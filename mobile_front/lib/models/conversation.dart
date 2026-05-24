class Conversation {
  final String otherUserId;
  final String otherUsername;
  final String? otherUserPhoto;
  final String lastMessage;
  final bool lastMessageWasMine;
  final DateTime lastMessageAt;
  final int unreadCount;

  Conversation({
    required this.otherUserId,
    required this.otherUsername,
    this.otherUserPhoto,
    required this.lastMessage,
    required this.lastMessageWasMine,
    required this.lastMessageAt,
    required this.unreadCount,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      otherUserId: json['otherUserId']?.toString() ?? '',
      otherUsername: json['otherUsername']?.toString() ?? '',
      otherUserPhoto: json['otherUserPhoto']?.toString(),
      lastMessage: json['lastMessage']?.toString() ?? '',
      lastMessageWasMine: json['lastMessageWasMine'] ?? false,
      lastMessageAt: json['lastMessageAt'] != null 
          ? DateTime.parse(json['lastMessageAt'].toString()) 
          : DateTime.now(),
      unreadCount: json['unreadCount'] is int ? json['unreadCount'] : (json['unreadCount'] ?? 0),
    );
  }
}
