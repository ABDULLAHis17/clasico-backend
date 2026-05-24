import 'package:flutter/material.dart';
import '../models/comment.dart';
import '../services/comments_service.dart';
import '../services/translation_service.dart';
import '../services/comment_moderation_service.dart';
import '../services/user_ban_service.dart';
import '../utils/app_strings.dart';

class CommentsScreen extends StatefulWidget {
  final String matchId;

  const CommentsScreen({Key? key, required this.matchId}) : super(key: key);

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  late TextEditingController _commentController;
  String? _replyingToId;
  bool _showAllComments = false;
  Map<String, bool> _isTranslating = {};
  Map<String, bool> _showOriginal = {};
  
  static const List<String> popularEmojis = [
    '😂', '❤️', '😍', '🔥', '👏',
    '😢', '😡', '🤔', '👍', '👎',
    '🎉', '⚽', '🏆', '💪', '🙌',
    '😎', '🤩', '😤', '🎯', '✨',
  ];

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _addComment() async {
    if (_commentController.text.isEmpty) return;

    final userId = 'current_user';
    
    // التحقق من حظر المستخدم
    if (UserBanService.isUserBanned(userId)) {
      final banInfo = UserBanService.getBanInfo(userId);
      _showBanDialog(banInfo);
      return;
    }

    // التحقق من محتوى التعليق
    final isInappropriate = await CommentModerationService.isInappropriateComment(
      _commentController.text,
    );

    if (isInappropriate) {
      final reason = await CommentModerationService.getModerationReason(
        _commentController.text,
      );
      
      // حظر المستخدم لمدة 24 ساعة
      UserBanService.banUserFor24Hours(userId, reason);
      
      _showInappropriateCommentDialog(reason);
      _commentController.clear();
      return;
    }

    final locale = Localizations.localeOf(context).languageCode;
    final newComment = Comment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      userName: AppStrings.t(context, 'you'),
      userAvatar: '😊',
      content: _commentController.text,
      createdAt: DateTime.now(),
      likes: 0,
      isLikedByUser: false,
      language: locale,
    );

    if (_replyingToId != null) {
      CommentsService.addReply(_replyingToId!, newComment);
    } else {
      CommentsService.addComment(newComment);
    }

    setState(() {
      _replyingToId = null;
      _commentController.clear();
    });
  }

  Future<void> _translateComment(
    String commentId,
    String content,
    String fromLang, {
    String? parentCommentId,
  }) async {
    final locale = Localizations.localeOf(context).languageCode;
    if (fromLang == locale) return;

    setState(() {
      _isTranslating[commentId] = true;
    });

    try {
      final translation = await TranslationService.translateText(
        content,
        fromLang,
        locale,
      );
      if (translation.startsWith('Error:')) {
        throw Exception(translation);
      }
      if (parentCommentId != null) {
        CommentsService.updateReplyTranslation(parentCommentId, commentId, translation);
      } else {
        CommentsService.updateCommentTranslation(commentId, translation);
      }
      setState(() {
        _isTranslating[commentId] = false;
      });
    } catch (e) {
      setState(() {
        _isTranslating[commentId] = false;
      });
    }
  }

  String _formatTime(DateTime dateTime, BuildContext context) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return AppStrings.t(context, 'now');
    } else if (difference.inMinutes < 60) {
      return '${AppStrings.t(context, 'ago')} ${difference.inMinutes} ${AppStrings.t(context, 'minutes_ago')}';
    } else if (difference.inHours < 24) {
      return '${AppStrings.t(context, 'ago')} ${difference.inHours} ${AppStrings.t(context, 'hours_ago')}';
    } else {
      return '${AppStrings.t(context, 'ago')} ${difference.inDays} ${AppStrings.t(context, 'days_ago')}';
    }
  }

  void _showInappropriateCommentDialog(String reason) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B6B), Color(0xFFEE5A6F)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6B6B).withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                AppStrings.t(context, 'inappropriate_comment'),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),

              // Message
              Text(
                AppStrings.t(context, 'comment_violates_guidelines'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),

              // Ban Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_rounded, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            AppStrings.t(context, 'user_banned_24h'),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${AppStrings.t(context, 'ban_reason')} $reason',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Close Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    AppStrings.t(context, 'close'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBanDialog(BannedUser? banInfo) {
    if (banInfo == null) return;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B6B), Color(0xFFEE5A6F)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6B6B).withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.block_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                AppStrings.t(context, 'cannot_comment_while_banned'),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Ban Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${AppStrings.t(context, 'ban_reason')} ${banInfo.reason}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.schedule_rounded, color: Colors.red, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${AppStrings.t(context, 'remaining_ban_time')} ${banInfo.remainingHours} ${AppStrings.t(context, 'hours')}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Close Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    AppStrings.t(context, 'close'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEmojiPicker(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Text(
              AppStrings.t(context, 'choose_reaction'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 24),

            // Emoji Grid
            GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
              ),
              itemCount: popularEmojis.length,
              itemBuilder: (context, index) {
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        final currentText = _commentController.text;
                        _commentController.text = currentText + popularEmojis[index];
                      });
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF334155)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.primary.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          popularEmojis[index],
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : colorScheme.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppStrings.t(context, 'comments'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _showAllComments = !_showAllComments;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _showAllComments ? Icons.visibility : Icons.visibility_off,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _showAllComments 
                            ? AppStrings.t(context, 'show_all_comments')
                            : AppStrings.t(context, 'show_language_comments'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Comments List
          Expanded(
            child: Builder(
              builder: (context) {
                final locale = Localizations.localeOf(context).languageCode;
                final allComments = CommentsService.getComments();
                final comments = _showAllComments
                    ? allComments
                    : allComments.where((c) => c.language == locale).toList();
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    return _buildCommentCard(
                      context,
                      comments[index],
                      colorScheme,
                      isDark,
                    );
                  },
                );
              },
            ),
          ),

          // Reply Indicator
          if (_replyingToId != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: colorScheme.primary.withValues(alpha: 0.1),
              child: Row(
                children: [
                  Icon(Icons.reply, color: colorScheme.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppStrings.t(context, 'reply_to_comment'),
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: colorScheme.primary, size: 18),
                    onPressed: () {
                      setState(() {
                        _replyingToId = null;
                      });
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

          // Comment Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // User Avatar with Emoji Picker
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showEmojiPicker(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [colorScheme.primary, colorScheme.secondary],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text('😊', style: TextStyle(fontSize: 20)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Input Field
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF334155) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: _commentController,
                      maxLines: null,
                      minLines: 1,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: AppStrings.t(context, 'add_comment'),
                        hintStyle: TextStyle(
                          color: isDark ? Colors.white54 : Colors.grey,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Send Button
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [colorScheme.primary, colorScheme.secondary],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _addComment,
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentCard(
    BuildContext context,
    Comment comment,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Comment Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Info
                Row(
                  children: [
                    // Avatar
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [colorScheme.primary, colorScheme.secondary],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          comment.userAvatar,
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Name and Time
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            comment.userName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          Text(
                            _formatTime(comment.createdAt, context),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white54 : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Comment Content
                Text(
                  _showOriginal[comment.id] == true
                      ? comment.content
                      : (comment.translatedContent ?? comment.content),
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white.withValues(alpha: 0.87) : Colors.black.withValues(alpha: 0.87),
                    height: 1.5,
                  ),
                ),
                if (comment.translatedContent != null && _showOriginal[comment.id] != true)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '(ترجمة)',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.primary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Comment Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Like Button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          CommentsService.toggleLike(comment.id);
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              comment.isLikedByUser
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: comment.isLikedByUser
                                  ? Colors.red
                                  : (isDark ? Colors.white54 : Colors.grey),
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              comment.likes.toString(),
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white54 : Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Translate Button with Icon Only
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isTranslating[comment.id] == true
                          ? null
                          : () {
                              if (_showOriginal[comment.id] == true) {
                                setState(() {
                                  _showOriginal[comment.id] = false;
                                });
                              } else if (comment.translatedContent != null) {
                                setState(() {
                                  _showOriginal[comment.id] = true;
                                });
                              } else {
                                _translateComment(
                                  comment.id,
                                  comment.content,
                                  comment.language,
                                );
                              }
                            },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                        child: Tooltip(
                          message: comment.translatedContent != null && _showOriginal[comment.id] != true
                              ? AppStrings.t(context, 'show_original_text')
                              : AppStrings.t(context, 'translate'),
                          child: _isTranslating[comment.id] == true
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(
                                      isDark ? Colors.white54 : Colors.grey,
                                    ),
                                  ),
                                )
                              : Icon(
                                  comment.translatedContent != null && _showOriginal[comment.id] != true
                                      ? Icons.language
                                      : Icons.translate,
                                  color: isDark ? Colors.white54 : Colors.grey,
                                  size: 18,
                                ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Divider
                  Container(
                    width: 1,
                    height: 20,
                    color: isDark ? Colors.white10 : Colors.grey.shade300,
                  ),

                  const SizedBox(width: 12),

                  // Reply Button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _replyingToId = comment.id;
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.reply,
                              color: isDark ? Colors.white54 : Colors.grey,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              AppStrings.t(context, 'reply'),
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white54 : Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Replies
          if (comment.replies.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF334155).withValues(alpha: 0.5)
                    : Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      '${comment.replies.length} ${AppStrings.t(context, 'replies')}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  ...comment.replies.map((reply) {
                    return _buildReplyCard(
                      context,
                      comment.id,
                      reply,
                      colorScheme,
                      isDark,
                    );
                  }).toList(),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReplyCard(
    BuildContext context,
    String parentCommentId,
    Comment reply,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reply Header
          Row(
            children: [
              // Avatar
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colorScheme.primary, colorScheme.secondary],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    reply.userAvatar,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Name and Time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reply.userName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      _formatTime(reply.createdAt, context),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white54 : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Reply Content
          Text(
            _showOriginal[reply.id] == true
                ? reply.content
                : (reply.translatedContent ?? reply.content),
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white.withValues(alpha: 0.87) : Colors.black.withValues(alpha: 0.87),
              height: 1.4,
            ),
          ),
          if (reply.translatedContent != null && _showOriginal[reply.id] != true)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '(ترجمة)',
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.primary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          const SizedBox(height: 8),

          // Reply Actions
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Like Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        CommentsService.toggleReplyLike(parentCommentId, reply.id);
                      });
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            reply.isLikedByUser
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: reply.isLikedByUser
                                ? Colors.red
                                : (isDark ? Colors.white54 : Colors.grey),
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            reply.likes.toString(),
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white54 : Colors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Translate Button with Icon Only
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isTranslating[reply.id] == true
                        ? null
                        : () {
                            if (_showOriginal[reply.id] == true) {
                              setState(() {
                                _showOriginal[reply.id] = false;
                              });
                            } else if (reply.translatedContent != null) {
                              setState(() {
                                _showOriginal[reply.id] = true;
                              });
                            } else {
                              _translateComment(
                                reply.id,
                                reply.content,
                                reply.language,
                                parentCommentId: parentCommentId,
                              );
                            }
                          },
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      child: Tooltip(
                        message: reply.translatedContent != null && _showOriginal[reply.id] != true
                            ? AppStrings.t(context, 'show_original_text')
                            : AppStrings.t(context, 'translate'),
                        child: _isTranslating[reply.id] == true
                            ? SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  valueColor: AlwaysStoppedAnimation(
                                    isDark ? Colors.white54 : Colors.grey,
                                  ),
                                ),
                              )
                            : Icon(
                                reply.translatedContent != null && _showOriginal[reply.id] != true
                                    ? Icons.language
                                    : Icons.translate,
                                color: isDark ? Colors.white54 : Colors.grey,
                                size: 14,
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
