class Comment {
  final String commentId;
  final String courseId;
  final String authorId;
  final String authorUsername;
  final String? authorRole;
  final String? authorPhoto;
  final String content;
  final String? createdAt;
  final String? parentCommentId;
  final List<String> likedByUserIds;

  Comment({
    required this.commentId,
    required this.courseId,
    required this.authorId,
    required this.authorUsername,
    this.authorRole,
    this.authorPhoto,
    required this.content,
    this.createdAt,
    this.parentCommentId,
    this.likedByUserIds = const [],
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      commentId: json['commentId'] ?? '',
      courseId: json['courseId'] ?? '',
      authorId: json['authorId'] ?? '',
      authorUsername: json['authorUsername'] ?? 'Unknown',
      authorRole: json['authorRole'],
      authorPhoto: json['authorPhoto'],
      content: json['content'] ?? '',
      createdAt: json['createdAt']?.toString(),
      parentCommentId: json['parentCommentId'],
      likedByUserIds: json['likedByUserIds'] != null
          ? List<String>.from(json['likedByUserIds'])
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'commentId': commentId,
      'courseId': courseId,
      'authorId': authorId,
      'authorUsername': authorUsername,
      'authorRole': authorRole,
      'authorPhoto': authorPhoto,
      'content': content,
      'createdAt': createdAt,
      'parentCommentId': parentCommentId,
      'likedByUserIds': likedByUserIds,
    };
  }
}
