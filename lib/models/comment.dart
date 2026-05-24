class Comment {
  final String id;
  final String userId;
  final String userName;
  final String userAvatar;
  final String content;
  final DateTime createdAt;
  final int likes;
  final bool isLikedByUser;
  final List<Comment> replies;
  final String language; // ar, en, tr
  final String? translatedContent; // النص المترجم

  Comment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.content,
    required this.createdAt,
    this.likes = 0,
    this.isLikedByUser = false,
    this.replies = const [],
    this.language = 'ar',
    this.translatedContent,
  });

  // Copy with method for updating
  Comment copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userAvatar,
    String? content,
    DateTime? createdAt,
    int? likes,
    bool? isLikedByUser,
    List<Comment>? replies,
    String? language,
    String? translatedContent,
  }) {
    return Comment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      likes: likes ?? this.likes,
      isLikedByUser: isLikedByUser ?? this.isLikedByUser,
      replies: replies ?? this.replies,
      language: language ?? this.language,
      translatedContent: translatedContent ?? this.translatedContent,
    );
  }
}
