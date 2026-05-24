import '../models/comment.dart';

class CommentsService {
  static final List<Comment> _comments = [
    Comment(
      id: '1',
      userId: 'user1',
      userName: 'أحمد محمد',
      userAvatar: '👨',
      content: 'مباراة رائعة جداً! راشفورد كان متألقاً اليوم 🔥',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      likes: 45,
      isLikedByUser: false,
      language: 'ar',
      replies: [
        Comment(
          id: '1-1',
          userId: 'user2',
          userName: 'فاطمة علي',
          userAvatar: '👩',
          content: 'أتفق معك تماماً! أداؤه كان استثنائي',
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          likes: 12,
          isLikedByUser: true,
          language: 'ar',
        ),
      ],
    ),
    Comment(
      id: '2',
      userId: 'user3',
      userName: 'محمود حسن',
      userAvatar: '👨',
      content: 'ليفربول كان يستحق الفوز بصراحة 💔',
      createdAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
      likes: 28,
      isLikedByUser: true,
      language: 'ar',
      replies: [],
    ),
    Comment(
      id: '3',
      userId: 'user4',
      userName: 'سارة خالد',
      userAvatar: '👩',
      content: 'ما أجمل هذه المباراة! كل اللاعبين كانوا رائعين',
      createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
      likes: 67,
      isLikedByUser: false,
      language: 'ar',
      replies: [
        Comment(
          id: '3-1',
          userId: 'user5',
          userName: 'علي محمود',
          userAvatar: '👨',
          content: 'نعم، كانت مباراة مثيرة جداً!',
          createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
          likes: 8,
          isLikedByUser: false,
          language: 'ar',
        ),
        Comment(
          id: '3-2',
          userId: 'user6',
          userName: 'نور أحمد',
          userAvatar: '👩',
          content: 'أتفق معك بنسبة 100%',
          createdAt: DateTime.now().subtract(const Duration(minutes: 20)),
          likes: 15,
          isLikedByUser: true,
          language: 'ar',
        ),
      ],
    ),
  ];

  static List<Comment> getComments() {
    return _comments;
  }

  static List<Comment> getCommentsByLanguage(String language) {
    return _comments.where((c) => c.language == language).toList();
  }

  static void updateCommentTranslation(String commentId, String translation) {
    final index = _comments.indexWhere((c) => c.id == commentId);
    if (index != -1) {
      final comment = _comments[index];
      _comments[index] = comment.copyWith(translatedContent: translation);
    }
  }

  static void updateReplyTranslation(String parentCommentId, String replyId, String translation) {
    final index = _comments.indexWhere((c) => c.id == parentCommentId);
    if (index != -1) {
      final comment = _comments[index];
      final replyIndex = comment.replies.indexWhere((r) => r.id == replyId);
      if (replyIndex != -1) {
        final reply = comment.replies[replyIndex];
        final updatedReply = reply.copyWith(translatedContent: translation);
        final updatedReplies = [...comment.replies];
        updatedReplies[replyIndex] = updatedReply;
        _comments[index] = comment.copyWith(replies: updatedReplies);
      }
    }
  }

  static void addComment(Comment comment) {
    _comments.insert(0, comment);
  }

  static void toggleLike(String commentId) {
    final index = _comments.indexWhere((c) => c.id == commentId);
    if (index != -1) {
      final comment = _comments[index];
      _comments[index] = comment.copyWith(
        likes: comment.isLikedByUser ? comment.likes - 1 : comment.likes + 1,
        isLikedByUser: !comment.isLikedByUser,
      );
    }
  }

  static void addReply(String parentCommentId, Comment reply) {
    final index = _comments.indexWhere((c) => c.id == parentCommentId);
    if (index != -1) {
      final comment = _comments[index];
      final updatedReplies = [...comment.replies, reply];
      _comments[index] = comment.copyWith(replies: updatedReplies);
    }
  }

  static void toggleReplyLike(String parentCommentId, String replyId) {
    final index = _comments.indexWhere((c) => c.id == parentCommentId);
    if (index != -1) {
      final comment = _comments[index];
      final replyIndex = comment.replies.indexWhere((r) => r.id == replyId);
      if (replyIndex != -1) {
        final reply = comment.replies[replyIndex];
        final updatedReply = reply.copyWith(
          likes: reply.isLikedByUser ? reply.likes - 1 : reply.likes + 1,
          isLikedByUser: !reply.isLikedByUser,
        );
        final updatedReplies = [...comment.replies];
        updatedReplies[replyIndex] = updatedReply;
        _comments[index] = comment.copyWith(replies: updatedReplies);
      }
    }
  }
}
