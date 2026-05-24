import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateBar extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;

  const DateBar({
    Key? key,
    required this.selectedDate,
    required this.onDateSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Generate fixed 5 days
    final days = List.generate(5, (index) {
      return DateTime.now().add(Duration(days: index - 2));
    });

    return Container(
      height: 100,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  colorScheme.primary,
                  colorScheme.primary.withValues(alpha: 0.85),
                  colorScheme.secondary.withValues(alpha: 0.7),
                ]
              : [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.9)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: days.map((date) {
            final isSelected = _isSameDay(date, selectedDate);
            final isToday = _isSameDay(date, DateTime.now());

            return Expanded(
              child: GestureDetector(
                onTap: () => onDateSelected(date),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark ? colorScheme.surface : Colors.white)
                        : (isDark
                              ? colorScheme.surface.withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.15)),
                    borderRadius: BorderRadius.circular(16),
                    border: isToday && !isSelected
                        ? Border.all(
                            color: isDark ? colorScheme.surface : Colors.white,
                            width: 2.5,
                          )
                        : (isSelected && isDark
                              ? Border.all(
                                  color: colorScheme.primary.withValues(alpha: 0.3),
                                  width: 1,
                                )
                              : null),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color:
                                  (isDark ? colorScheme.primary : Colors.black)
                                      .withValues(alpha: 0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('EEE').format(date).toUpperCase(),
                        style: TextStyle(
                          color: isSelected
                              ? (isDark
                                    ? colorScheme.primary
                                    : colorScheme.primary)
                              : (isDark
                                    ? colorScheme.onPrimary
                                    : Colors.white.withValues(alpha: 0.9)),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        DateFormat('dd').format(date),
                        style: TextStyle(
                          color: isSelected
                              ? (isDark
                                    ? colorScheme.primary
                                    : colorScheme.primary)
                              : (isDark ? colorScheme.onPrimary : Colors.white),
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM').format(date).toUpperCase(),
                        style: TextStyle(
                          color: isSelected
                              ? (isDark
                                    ? colorScheme.primary.withValues(alpha: 0.8)
                                    : colorScheme.primary.withValues(
                                        alpha: 0.7,
                                      ))
                              : (isDark
                                    ? colorScheme.onPrimary.withValues(
                                        alpha: 0.8,
                                      )
                                    : Colors.white.withValues(alpha: 0.8)),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}
