import 'package:flutter/material.dart';
import '../../utils/app_strings.dart';
import '../../utils/app_themes.dart';
import '../../services/question_manager.dart';
import '../../models/ai_question.dart';

/// نسخة محدثة من لعبة النادي المشترك تستخدم Gemini AI
class CommonClubAIScreen extends StatefulWidget {
  final bool isOnlineMode;

  const CommonClubAIScreen({Key? key, this.isOnlineMode = false}) : super(key: key);

  @override
  State<CommonClubAIScreen> createState() => _CommonClubAIScreenState();
}

class _CommonClubAIScreenState extends State<CommonClubAIScreen> with TickerProviderStateMixin {
  final QuestionManager _questionManager = QuestionManager();
  
  int currentQuestionIndex = 0;
  int score = 0;
  bool isAnswered = false;
  String? selectedClub;
  List<String> shuffledClubs = [];
  
  AIQuestion? currentQuestion;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadQuestion();
  }

  Future<void> _loadQuestion() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      // إعادة تعيين الحالة عند تحميل سؤال جديد
      isAnswered = false;
      selectedClub = null;
    });

    try {
      String difficulty = _getDifficulty();
      
      final question = await _questionManager.getQuestion(
        difficulty: difficulty,
        category: 'common_club',
      );
      
      if (question != null) {
        // إنشاء نسخة جديدة وخلطها مرة واحدة فقط
        final newShuffledClubs = List<String>.from(question.options);
        newShuffledClubs.shuffle();
        
        setState(() {
          currentQuestion = question;
          shuffledClubs = newShuffledClubs;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'No questions available';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading question';
        isLoading = false;
      });
    }
  }

  String _getDifficulty() {
    if (currentQuestionIndex < 3) return 'easy';
    if (currentQuestionIndex < 8) return 'medium';
    return 'hard';
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _selectClub(String club) {
    if (isAnswered || currentQuestion == null) return;
    
    final isCorrect = club.trim().toLowerCase() == currentQuestion!.correctAnswer.trim().toLowerCase();
    
    setState(() {
      selectedClub = club;
      isAnswered = true;
      
      if (isCorrect) {
        score++;
      }
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      
      if (currentQuestionIndex < 9) {
        setState(() {
          currentQuestionIndex++;
        });
        _loadQuestion(); // سيعيد تعيين isAnswered و selectedClub داخلياً
      } else {
        _showGameOver();
      }
    });
  }

  void _showGameOver() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.emoji_events, color: colorScheme.primary, size: 32),
            const SizedBox(width: 12),
            Text(
              AppStrings.t(context, 'game_over'),
              style: TextStyle(color: colorScheme.onSurface),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${AppStrings.t(context, 'your_score')}: $score/10',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: score / 10,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text(AppStrings.t(context, 'back_to_home')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                currentQuestionIndex = 0;
                score = 0;
                isAnswered = false;
                selectedClub = null;
              });
              _loadQuestion();
            },
            child: Text(AppStrings.t(context, 'play_again')),
          ),
        ],
      ),
    );
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
          leading: IconButton(
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
          title: Row(
            children: [
              Text(
                AppStrings.t(context, 'common_club'),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple, width: 1),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 14, color: Colors.purple),
                    SizedBox(width: 4),
                    Text(
                      'AI',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorScheme.primary, colorScheme.secondary],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.stars, color: Colors.white, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    '$score',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildProgressIndicator(colorScheme),
                const SizedBox(height: 24),
                Expanded(
                  child: isLoading
                      ? _buildLoading()
                      : errorMessage != null
                          ? _buildError()
                          : currentQuestion != null
                              ? _buildQuestionContent(theme, colorScheme, isDark)
                              : _buildError(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(AppStrings.t(context, 'loading_question')),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(errorMessage ?? 'An error occurred'),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadQuestion,
            child: Text(AppStrings.t(context, 'continue')),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionContent(ThemeData theme, ColorScheme colorScheme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildQuestionCard(context, theme, colorScheme, currentQuestion!),
        const SizedBox(height: 32),
        Expanded(
          child: _buildClubsGrid(currentQuestion!, colorScheme, isDark),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator(ColorScheme colorScheme) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${AppStrings.t(context, 'question')} ${currentQuestionIndex + 1}/10',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: (currentQuestionIndex + 1) / 10,
            minHeight: 8,
            backgroundColor: colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard(BuildContext context, ThemeData theme, ColorScheme colorScheme, AIQuestion question) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withValues(alpha: 0.1),
            colorScheme.secondary.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.auto_awesome,
            size: 48,
            color: Colors.purple,
          ),
          const SizedBox(height: 16),
          Text(
            question.questionText,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClubsGrid(AIQuestion question, ColorScheme colorScheme, bool isDark) {
    // حماية من rebuild مع قائمة فارغة
    if (shuffledClubs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(), // منع Scroll لتجنب rebuild
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: shuffledClubs.length,
      itemBuilder: (context, index) {
        final club = shuffledClubs[index];
        final isCorrect = club.trim().toLowerCase() == question.correctAnswer.trim().toLowerCase();
        final isSelected = selectedClub == club;
        final showResult = isAnswered && isSelected;
        // إظهار الإجابة الصحيحة فقط عندما يختار المستخدم إجابة خاطئة
        final isWrongAnswer = selectedClub != null && selectedClub!.trim().toLowerCase() != question.correctAnswer.trim().toLowerCase();
        final showCorrectAnswer = isAnswered && !isSelected && isCorrect && isWrongAnswer;
        
        Color cardColor;
        if (showResult) {
          cardColor = isCorrect ? Colors.green : Colors.red;
        } else if (showCorrectAnswer) {
          cardColor = Colors.green;
        } else {
          cardColor = colorScheme.surface;
        }
        
        Widget child = InkWell(
          onTap: () => _selectClub(club),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              color: (showResult || showCorrectAnswer)
                  ? cardColor.withValues(alpha: 0.9)
                  : (isDark ? colorScheme.surface : Colors.white),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: (showResult || showCorrectAnswer)
                      ? cardColor
                      : colorScheme.outline.withValues(alpha: 0.3),
                width: (showResult || showCorrectAnswer) ? 3 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: (showResult || showCorrectAnswer)
                      ? cardColor.withValues(alpha: 0.4)
                      : Colors.black.withValues(alpha: 0.08),
                  blurRadius: (showResult || showCorrectAnswer) ? 20 : 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: (showResult || showCorrectAnswer)
                        ? Colors.white.withValues(alpha: 0.2)
                        : colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    (showResult || showCorrectAnswer)
                        ? (isCorrect ? Icons.check_circle : Icons.cancel)
                        : Icons.shield,
                    size: 40,
                    color: (showResult || showCorrectAnswer)
                        ? Colors.white
                        : colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    club,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: (showResult || showCorrectAnswer)
                          ? Colors.white
                          : colorScheme.onSurface,
                    ),
                  ),
                ),
                if (showCorrectAnswer) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star, size: 16, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          AppStrings.t(context, 'correct_answer'),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
        
        return child;
      },
    );
  }
}
