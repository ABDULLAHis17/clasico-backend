import 'package:flutter/material.dart';
import '../models/friend.dart';
import '../screens/chat_screen.dart';
import '../utils/app_strings.dart';
import '../utils/app_themes.dart';

class FriendDetailScreen extends StatefulWidget {
  final Friend friend;

  const FriendDetailScreen({Key? key, required this.friend}) : super(key: key);

  @override
  State<FriendDetailScreen> createState() => _FriendDetailScreenState();
}

class _FriendDetailScreenState extends State<FriendDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late AnimationController _favoriteAnimationController;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _favoriteAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _favoriteAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: AppThemes.backgroundGradient(context),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: ScaleTransition(
            scale: Tween<double>(begin: 1.0, end: 0.9).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Curves.easeInOut,
              ),
            ),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_back, color: colorScheme.onSurface),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Profile Header with Scale Animation
                    ScaleTransition(
                      scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                        CurvedAnimation(
                          parent: _animationController,
                          curve: const Interval(
                            0.0,
                            0.5,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                      ),
                      child: ClipOval(
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                colorScheme.primary.withValues(alpha: 0.3),
                                colorScheme.secondary.withValues(alpha: 0.3),
                              ],
                            ),
                            border: Border.all(
                              color: colorScheme.primary,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.primary.withValues(alpha: 0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              widget.friend.profileImage,
                              style: const TextStyle(fontSize: 56),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Username
                    Text(
                      widget.friend.username,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 32),

                    // Favorite Team Section
                    _buildAnimatedInfoCard(
                      context: context,
                      delay: 0,
                      icon: Icons.shield,
                      iconColor: colorScheme.primary,
                      title: AppStrings.t(context, 'favorite_team'),
                      logo: widget.friend.favoriteTeamLogo,
                      value: widget.friend.favoriteTeam,
                      colorScheme: colorScheme,
                      isDark: isDark,
                    ),

                    const SizedBox(height: 16),

                    // Favorite Player Section
                    _buildAnimatedInfoCard(
                      context: context,
                      delay: 1,
                      icon: Icons.sports_soccer,
                      iconColor: colorScheme.secondary,
                      title: AppStrings.t(context, 'favorite_player'),
                      logo: widget.friend.favoritePlayerImage,
                      value: widget.friend.favoritePlayer,
                      colorScheme: colorScheme,
                      isDark: isDark,
                    ),

                    const SizedBox(height: 16),

                    // National Team Section
                    _buildAnimatedInfoCard(
                      context: context,
                      delay: 2,
                      icon: Icons.flag,
                      iconColor: colorScheme.tertiary,
                      title: AppStrings.t(context, 'national_team'),
                      logo: widget.friend.nationalTeamFlag,
                      value: widget.friend.nationalTeam,
                      colorScheme: colorScheme,
                      isDark: isDark,
                    ),

                    const SizedBox(height: 32),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatScreen(
                                    friendName: widget.friend.username,
                                    friendAvatar: widget.friend.profileImage,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.message),
                            label: Text(AppStrings.t(context, 'message')),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: isDark
                                  ? colorScheme.onPrimary
                                  : Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ScaleTransition(
                            scale: Tween<double>(begin: 1.0, end: 1.1).animate(
                              CurvedAnimation(
                                parent: _favoriteAnimationController,
                                curve: Curves.elasticOut,
                              ),
                            ),
                            child: OutlinedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _isFavorite = !_isFavorite;
                                });
                                _favoriteAnimationController.forward(from: 0.0);
                              },
                              icon: Icon(
                                _isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                              ),
                              label: Text(
                                AppStrings.t(context, 'add_to_favorites'),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _isFavorite
                                    ? Colors.red
                                    : colorScheme.primary,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                side: BorderSide(
                                  color: _isFavorite
                                      ? Colors.red
                                      : colorScheme.primary,
                                  width: 2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedInfoCard({
    required BuildContext context,
    required int delay,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String logo,
    required String value,
    required ColorScheme colorScheme,
    required bool isDark,
  }) {
    final delayedAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(
          delay * 0.1,
          0.6 + (delay * 0.1),
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    return FadeTransition(
      opacity: delayedAnimation,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0.2, 0.0), end: Offset.zero)
            .animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Interval(
                  delay * 0.1,
                  0.6 + (delay * 0.1),
                  curve: Curves.easeOutCubic,
                ),
              ),
            ),
        child: _buildInfoCard(
          context: context,
          icon: icon,
          iconColor: iconColor,
          title: title,
          logo: logo,
          value: value,
          colorScheme: colorScheme,
          isDark: isDark,
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String logo,
    required String value,
    required ColorScheme colorScheme,
    required bool isDark,
  }) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.surface,
                  colorScheme.surface.withValues(alpha: 0.95),
                ],
              )
            : null,
        color: isDark ? null : colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? iconColor.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),

          const SizedBox(width: 16),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.outline,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(logo, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        value,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
