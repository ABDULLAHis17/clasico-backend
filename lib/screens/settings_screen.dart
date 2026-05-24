import 'package:flutter/material.dart';
import '../utils/app_strings.dart';
import '../utils/app_themes.dart';
import '../services/settings_service.dart';
import '../services/api_service.dart';

/// Settings Screen - Material Design 3
/// Provides full control over app preferences with instant updates
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  final _settings = SettingsService();
  final _feedbackCtrl = TextEditingController();
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _showFeedback(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: _settings,
      builder: (context, _) {
        return Container(
          decoration: AppThemes.backgroundGradient(context),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(
                AppStrings.t(context, 'settings'),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            body: FadeTransition(
              opacity: _fadeAnim,
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                children: [
                  // Notifications Section
                  _buildSectionHeader(
                    context,
                    icon: Icons.notifications_rounded,
                    title: AppStrings.t(context, 'notifications'),
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                  _buildCard(
                    context,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.t(context, 'news_notifications'),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildRadioTile<bool>(
                          context,
                          value: true,
                          groupValue: _settings.newsAll,
                          title: AppStrings.t(context, 'receive_all_news'),
                          onChanged: (v) {
                            _settings.setNewsMode(all: true);
                            _showFeedback('News notifications updated');
                          },
                        ),
                        _buildRadioTile<bool>(
                          context,
                          value: false,
                          groupValue: _settings.newsAll,
                          title: AppStrings.t(context, 'only_favorites_news'),
                          subtitle: AppStrings.t(
                            context,
                            'only_favorites_news_sub',
                          ),
                          onChanged: (v) {
                            _settings.setNewsMode(all: false);
                            _showFeedback('News notifications updated');
                          },
                        ),
                        Divider(color: colorScheme.outlineVariant),
                        _buildSwitchTile(
                          context,
                          value: _settings.matchStartAlerts,
                          title: AppStrings.t(context, 'match_start'),
                          subtitle: AppStrings.t(context, 'match_start_sub'),
                          onChanged: (v) {
                            _settings.setMatchStartAlerts(v);
                            _showFeedback(
                              v
                                  ? 'Match start alerts enabled'
                                  : 'Match start alerts disabled',
                            );
                          },
                        ),
                        _buildSwitchTile(
                          context,
                          value: _settings.matchEndAlerts,
                          title: AppStrings.t(context, 'match_end'),
                          subtitle: AppStrings.t(context, 'match_end_sub'),
                          onChanged: (v) {
                            _settings.setMatchEndAlerts(v);
                            _showFeedback(
                              v
                                  ? 'Match end alerts enabled'
                                  : 'Match end alerts disabled',
                            );
                          },
                        ),
                        _buildSwitchTile(
                          context,
                          value: _settings.goalAlertsOnly,
                          title: AppStrings.t(context, 'goal_only'),
                          subtitle: AppStrings.t(context, 'goal_only_sub'),
                          onChanged: (v) {
                            _settings.setGoalAlertsOnly(v);
                            _showFeedback(
                              v
                                  ? 'Goal alerts enabled'
                                  : 'Goal alerts disabled',
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Language Section
                  _buildSectionHeader(
                    context,
                    icon: Icons.language_rounded,
                    title: AppStrings.t(context, 'language'),
                    color: colorScheme.secondary,
                  ),
                  const SizedBox(height: 8),
                  _buildCard(
                    context,
                    child: Column(
                      children: [
                        _buildRadioTile<String>(
                          context,
                          value: 'system',
                          groupValue: _settings.languageCode,
                          title: AppStrings.t(context, 'system_language'),
                          leading: const Icon(Icons.settings_suggest_rounded),
                          onChanged: (v) {
                            _settings.setLanguage(v!);
                            _showFeedback('Following system language');
                          },
                        ),
                        _buildRadioTile<String>(
                          context,
                          value: 'en',
                          groupValue: _settings.languageCode,
                          title: AppStrings.t(context, 'english'),
                          onChanged: (v) {
                            _settings.setLanguage(v!);
                            _showFeedback('Language changed to English');
                          },
                        ),
                        _buildRadioTile<String>(
                          context,
                          value: 'ar',
                          groupValue: _settings.languageCode,
                          title: AppStrings.t(context, 'arabic'),
                          onChanged: (v) {
                            _settings.setLanguage(v!);
                            _showFeedback('تم تغيير اللغة إلى العربية');
                          },
                        ),
                        _buildRadioTile<String>(
                          context,
                          value: 'tr',
                          groupValue: _settings.languageCode,
                          title: AppStrings.t(context, 'turkish'),
                          onChanged: (v) {
                            _settings.setLanguage(v!);
                            _showFeedback('Dil Türkçe olarak değiştirildi');
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Time Format Section
                  _buildSectionHeader(
                    context,
                    icon: Icons.access_time_filled_rounded,
                    title: AppStrings.t(context, 'time_format'),
                    color: colorScheme.tertiary,
                  ),
                  const SizedBox(height: 8),
                  _buildCard(
                    context,
                    child: Column(
                      children: [
                        _buildRadioTile<String>(
                          context,
                          value: '12h',
                          groupValue: _settings.timeFormat,
                          title: AppStrings.t(context, 'fmt_12'),
                          onChanged: (v) {
                            _settings.setTimeFormat(v!);
                            _showFeedback('Time format: 12-hour');
                          },
                        ),
                        _buildRadioTile<String>(
                          context,
                          value: '24h',
                          groupValue: _settings.timeFormat,
                          title: AppStrings.t(context, 'fmt_24'),
                          onChanged: (v) {
                            _settings.setTimeFormat(v!);
                            _showFeedback('Time format: 24-hour');
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Location Section
                  _buildSectionHeader(
                    context,
                    icon: Icons.place_rounded,
                    title: AppStrings.t(context, 'location'),
                    color: Colors.green,
                  ),
                  const SizedBox(height: 8),
                  _buildCard(
                    context,
                    child: _buildSwitchTile(
                      context,
                      value: _settings.locationBased,
                      title: AppStrings.t(context, 'location_title'),
                      subtitle: AppStrings.t(context, 'location_sub'),
                      onChanged: (v) {
                        _settings.setLocationBased(v);
                        _showFeedback(
                          v
                              ? 'Location-based notifications enabled'
                              : 'Location-based notifications disabled',
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Microphone Permission Section
                  _buildSectionHeader(
                    context,
                    icon: Icons.mic_rounded,
                    title: AppStrings.t(context, 'microphone_permission'),
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 8),
                  _buildCard(
                    context,
                    child: _buildSwitchTile(
                      context,
                      value: _settings.microphoneEnabled,
                      title: AppStrings.t(context, 'enable_microphone'),
                      subtitle: AppStrings.t(
                        context,
                        'microphone_permission_description',
                      ),
                      onChanged: (v) {
                        _settings.setMicrophoneEnabled(v);
                        _showFeedback(
                          v
                              ? AppStrings.t(context, 'microphone_enabled')
                              : AppStrings.t(context, 'microphone_disabled'),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Appearance Section
                  _buildSectionHeader(
                    context,
                    icon: Icons.brightness_6_rounded,
                    title: AppStrings.t(context, 'appearance'),
                    color: Colors.deepPurple,
                  ),
                  const SizedBox(height: 8),
                  _buildCard(
                    context,
                    child: Column(
                      children: [
                        _buildRadioTile<String>(
                          context,
                          value: 'system',
                          groupValue: _settings.theme,
                          title: AppStrings.t(context, 'system_theme'),
                          leading: const Icon(Icons.brightness_auto_rounded),
                          onChanged: (v) {
                            _settings.setTheme(v!);
                            _showFeedback('Following system theme');
                          },
                        ),
                        _buildRadioTile<String>(
                          context,
                          value: 'light',
                          groupValue: _settings.theme,
                          title: AppStrings.t(context, 'light_mode'),
                          leading: const Icon(Icons.light_mode_rounded),
                          onChanged: (v) {
                            _settings.setTheme(v!);
                            _showFeedback('Light mode enabled');
                          },
                        ),
                        _buildRadioTile<String>(
                          context,
                          value: 'dark',
                          groupValue: _settings.theme,
                          title: AppStrings.t(context, 'dark_mode'),
                          leading: const Icon(Icons.dark_mode_rounded),
                          onChanged: (v) {
                            _settings.setTheme(v!);
                            _showFeedback('Dark mode enabled');
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Share & Feedback Section
                  _buildSectionHeader(
                    context,
                    icon: Icons.share_rounded,
                    title: AppStrings.t(context, 'share_feedback'),
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 8),
                  _buildCard(
                    context,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FilledButton.icon(
                          onPressed: () => _showFeedback(
                            AppStrings.t(context, 'share_mock'),
                          ),
                          icon: const Icon(Icons.share_rounded),
                          label: Text(AppStrings.t(context, 'share_app')),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _feedbackCtrl,
                          minLines: 3,
                          maxLines: 5,
                          decoration: InputDecoration(
                            labelText: AppStrings.t(context, 'feedback_label'),
                            hintText: AppStrings.t(context, 'write_message_here'),
                            border: const OutlineInputBorder(),
                            filled: true,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.tonal(
                            onPressed: () async {
                              final text = _feedbackCtrl.text.trim();
                              if (text.isEmpty) {
                                _showFeedback(AppStrings.t(context, 'please_write_message'));
                                return;
                              }

                              // To prevent spamming clicks
                              FocusScope.of(context).unfocus();

                              _showFeedback(AppStrings.t(context, 'sending_message'));

                              final success = await ApiService().submitFeedback(
                                text,
                              );

                              if (success && mounted) {
                                _feedbackCtrl.clear();
                                _showFeedback(
                                  AppStrings.t(context, 'message_sent_successfully'),
                                );
                              } else if (mounted) {
                                _showFeedback(
                                  AppStrings.t(context, 'error_sending_message'),
                                );
                              }
                            },
                            child: Text(AppStrings.t(context, 'send')),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, {required Widget child}) {
    return Container(
      decoration: AppThemes.cardGradient(context),
      child: Padding(padding: const EdgeInsets.all(12), child: child),
    );
  }

  Widget _buildRadioTile<T>(
    BuildContext context, {
    required T value,
    required T groupValue,
    required String title,
    String? subtitle,
    Widget? leading,
    required ValueChanged<T?> onChanged,
  }) {
    return RadioListTile<T>(
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      title: Text(title),
      subtitle: subtitle != null
          ? Text(subtitle, style: Theme.of(context).textTheme.bodySmall)
          : null,
      secondary: leading,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required bool value,
    required String title,
    String? subtitle,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      title: Text(title),
      subtitle: subtitle != null
          ? Text(subtitle, style: Theme.of(context).textTheme.bodySmall)
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
