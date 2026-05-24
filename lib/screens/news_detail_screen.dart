import 'package:flutter/material.dart';
import '../models/news.dart';
import '../utils/app_colors.dart';
import '../utils/app_strings.dart';
import '../services/translation_service.dart';
import '../widgets/smart_logo.dart';
import 'package:intl/intl.dart';

class NewsDetailScreen extends StatefulWidget {
  final News news;

  const NewsDetailScreen({Key? key, required this.news}) : super(key: key);

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  bool _isTranslating = false;
  String? _translatedTitle;
  String? _translatedContent;
  String? _translatedSummary;
  String _currentLanguage = 'ar'; // Original is Arabic
  final List<Map<String, String>> _languages = [
    {'code': 'ar', 'label': 'العربية', 'flag': '🇸🇦'},
    {'code': 'en', 'label': 'English', 'flag': '🇬🇧'},
    {'code': 'tr', 'label': 'Türkçe', 'flag': '🇹🇷'},
  ];

  Future<void> _translateTo(String langCode) async {
    if (langCode == 'ar') {
      // Reset to original
      setState(() {
        _translatedTitle = null;
        _translatedContent = null;
        _translatedSummary = null;
        _currentLanguage = 'ar';
      });
      return;
    }

    setState(() => _isTranslating = true);

    try {
      final results = await Future.wait([
        TranslationService.translateText(widget.news.title, 'ar', langCode),
        TranslationService.translateText(widget.news.fullArticle, 'ar', langCode),
      ]);

      if (mounted) {
        setState(() {
          _translatedTitle = results[0];
          _translatedContent = results[1];
          _currentLanguage = langCode;
          _isTranslating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isTranslating = false);
        final errorMessage = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(errorMessage)),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  String get _displayTitle => _translatedTitle ?? widget.news.title;
  String get _displayContent => _translatedContent ?? widget.news.fullArticle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              // AI Translation Button
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.deepPurple.withValues(alpha: 0.8),
                      Colors.blue.withValues(alpha: 0.8),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurple.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: _isTranslating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.translate, color: Colors.white),
                  onPressed: _isTranslating ? null : () => _showTranslateSheet(context),
                  tooltip: AppStrings.t(context, 'ai_translation'),
                ),
              ),
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.share, color: Colors.white),
                  onPressed: () {},
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                          ? [const Color(0xFF3B82F6), const Color(0xFF2563EB)]
                          : [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
                      ),
                    ),
                    child: Center(
                      child: SmartLogo(
                        logo: widget.news.imageUrl,
                        size: 120,
                        isBackground: true,
                      ),
                    ),
                  ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                  // League badge
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF10B981) : colorScheme.primary,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          SmartLogo(logo: widget.news.imageUrl, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            widget.news.leagueName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Translation indicator
                    if (_currentLanguage != 'ar') ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.deepPurple.withValues(alpha: isDark ? 0.3 : 0.1),
                              Colors.blue.withValues(alpha: isDark ? 0.2 : 0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.deepPurple.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.auto_awesome, size: 16, color: Colors.deepPurple),
                            const SizedBox(width: 8),
                            Text(
                              '${AppStrings.t(context, 'translated_by_ai_to')} ${_languages.firstWhere((l) => l['code'] == _currentLanguage)['label']}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.deepPurple.shade200 : Colors.deepPurple,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => _translateTo('ar'),
                              child: Text(
                                AppStrings.t(context, 'return_to_original'),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.deepPurple.shade300,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Title
                    Text(
                      _displayTitle,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : colorScheme.onSurface,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Author and Date
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: isDark ? const Color(0xFF3B82F6) : colorScheme.primary,
                          child: Text(
                            widget.news.author.isNotEmpty ? widget.news.author[0].toUpperCase() : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.news.author,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat('MMM dd, yyyy • HH:mm').format(widget.news.publishedDate),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.white.withValues(alpha: 0.5) : colorScheme.onSurface.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Tags
                    if (widget.news.tags.isNotEmpty) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.news.tags.map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDark 
                                ? const Color(0xFF3B82F6).withValues(alpha: 0.2)
                                : colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isDark 
                                  ? const Color(0xFF3B82F6).withValues(alpha: 0.5)
                                  : colorScheme.primary.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? const Color(0xFF60A5FA) : colorScheme.primary,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Divider
                    Divider(color: isDark ? const Color(0xFF475569) : colorScheme.outline),
                    const SizedBox(height: 24),

                    // Full Article
                    Text(
                      _displayContent,
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.white.withValues(alpha: 0.9) : colorScheme.onSurface,
                        height: 1.8,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // AI Translate CTA
                    if (_currentLanguage == 'ar')
                      GestureDetector(
                        onTap: _isTranslating ? null : () => _showTranslateSheet(context),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.deepPurple.withValues(alpha: isDark ? 0.3 : 0.1),
                                Colors.blue.withValues(alpha: isDark ? 0.2 : 0.08),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.deepPurple.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Colors.deepPurple, Colors.blue],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppStrings.t(context, 'ai_translation'),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      AppStrings.t(context, 'translate_news_desc'),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? Colors.white60 : Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: isDark ? Colors.deepPurple.shade200 : Colors.deepPurple,
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Related News Section
                    Text(
                      _currentLanguage == 'ar' 
                        ? '${AppStrings.t(context, 'more_from')} ${widget.news.leagueName}'
                        : 'More from ${widget.news.leagueName}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark 
                          ? const Color(0xFF334155)
                          : colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.article_outlined,
                            color: isDark 
                              ? Colors.white.withValues(alpha: 0.5)
                              : colorScheme.onSurface.withValues(alpha: 0.5),
                            size: 32,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              AppStrings.t(context, 'more_news_soon'),
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark 
                                  ? Colors.white.withValues(alpha: 0.5)
                                  : colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTranslateSheet(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.deepPurple, Colors.blue],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'ترجمة بالذكاء الاصطناعي',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'اختر اللغة المطلوبة — مدعوم بتقنية Gemini AI',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white60 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),
            ..._languages.map((lang) {
              final isSelected = _currentLanguage == lang['code'];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    Navigator.pop(ctx);
                    _translateTo(lang['code']!);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.deepPurple.withValues(alpha: isDark ? 0.3 : 0.1)
                          : (isDark ? const Color(0xFF334155) : Colors.grey.shade50),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? Colors.deepPurple.withValues(alpha: 0.6)
                            : (isDark ? Colors.white10 : Colors.grey.shade200),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(lang['flag']!, style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 12),
                        Text(
                          lang['label']!,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const Spacer(),
                        if (isSelected)
                          const Icon(Icons.check_circle, color: Colors.deepPurple, size: 22),
                        if (lang['code'] != 'ar' && !isSelected)
                          Icon(Icons.arrow_forward_ios, size: 16, color: isDark ? Colors.white30 : Colors.grey),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
