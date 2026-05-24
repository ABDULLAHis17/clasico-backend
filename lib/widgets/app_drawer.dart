import 'package:flutter/material.dart';
import '../utils/app_strings.dart';
import '../utils/app_themes.dart';
import '../utils/app_images.dart';
import '../screens/news_screen.dart';
import '../screens/account/account_hub_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/friends_screen.dart';
import '../screens/games/games_screen.dart';
import '../screens/all_leagues_screen.dart';
import '../screens/login_screen.dart';

class AppDrawer extends StatelessWidget {
  final bool isGuest;

  const AppDrawer({Key? key, required this.isGuest}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    
    // حساب حجم اللوجو في Drawer بناءً على حجم الشاشة - حجم متوسط متناسق
    final drawerLogoSize = screenWidth < 600 ? 110.0 : 140.0;
    
    return Drawer(
      child: Column(
        children: [
            // Extraordinary Drawer Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 56, 24, 28),
              decoration: AppThemes.primaryGradient(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: drawerLogoSize,
                    height: drawerLogoSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.15),
                          Colors.white.withValues(alpha: 0.05),
                          Colors.transparent,
                        ],
                        stops: const [0.3, 0.7, 1.0],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Image.asset(
                        AppImages.logo,
                        width: drawerLogoSize * 0.85,
                        height: drawerLogoSize * 0.85,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isGuest ? AppStrings.t(context, 'drawer_guest') : AppStrings.t(context, 'drawer_welcome'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isGuest ? AppStrings.t(context, 'drawer_explore') : AppStrings.t(context, 'drawer_pro'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                children: [
                  // Games
                  _buildModernMenuItem(
                    context,
                    icon: Icons.sports_soccer_rounded,
                    title: AppStrings.t(context, 'drawer_games'),
                    subtitle: AppStrings.t(context, 'drawer_games_sub'),
                    color: const Color(0xFFEF4444),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const GamesScreen(),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // League Standings
                  _buildModernMenuItem(
                    context,
                    icon: Icons.emoji_events_rounded,
                    title: AppStrings.t(context, 'drawer_leagues'),
                    subtitle: AppStrings.t(context, 'drawer_leagues_sub'),
                    color: const Color(0xFF8B5CF6),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AllLeaguesScreen(),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // News
                  _buildModernMenuItem(
                    context,
                    icon: Icons.newspaper_rounded,
                    title: AppStrings.t(context, 'drawer_news'),
                    subtitle: AppStrings.t(context, 'drawer_news_sub'),
                    color: const Color(0xFF3B82F6),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NewsScreen(),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  Divider(color: colorScheme.outlineVariant),
                  const SizedBox(height: 8),
                  
                  // Friends
                  _buildModernMenuItem(
                    context,
                    icon: Icons.people_rounded,
                    title: AppStrings.t(context, 'drawer_friends'),
                    subtitle: AppStrings.t(context, 'drawer_friends_sub'),
                    color: const Color(0xFF10B981),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FriendsScreen(),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Profile
                  _buildModernMenuItem(
                    context,
                    icon: Icons.person_rounded,
                    title: AppStrings.t(context, 'drawer_profile'),
                    subtitle: AppStrings.t(context, 'drawer_profile_sub'),
                    color: const Color(0xFFF59E0B),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AccountHubScreen(),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Settings
                  _buildModernMenuItem(
                    context,
                    icon: Icons.settings_rounded,
                    title: AppStrings.t(context, 'drawer_settings'),
                    subtitle: AppStrings.t(context, 'drawer_settings_sub'),
                    color: const Color(0xFF6B7280),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            // Modern Footer
            if (isGuest)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.login_rounded, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          AppStrings.t(context, 'login'),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  // Modern colorful menu item for all buttons
  Widget _buildModernMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: AppThemes.accentGradient(context, color),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.pop(context);
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
