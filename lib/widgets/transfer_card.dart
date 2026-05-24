import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transfer.dart';
import '../screens/transfer_details_screen.dart';
import '../utils/page_transitions.dart';
import 'smart_logo.dart';

class TransferCard extends StatefulWidget {
  final Transfer transfer;

  const TransferCard({Key? key, required this.transfer}) : super(key: key);

  @override
  State<TransferCard> createState() => _TransferCardState();
}

class _TransferCardState extends State<TransferCard>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _arrowController;
  late Animation<double> _arrowAnimation;

  @override
  void initState() {
    super.initState();
    _arrowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _arrowAnimation = Tween<double>(begin: -5, end: 5).animate(
      CurvedAnimation(parent: _arrowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _arrowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedScale(
      scale: _isPressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeInOut,
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            gradient: isDark
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.surface,
                      colorScheme.surface.withValues(alpha: 0.95),
                      colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
                    ],
                  )
                : null,
            color: isDark ? null : colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: isDark
                ? Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                    width: 1,
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? colorScheme.primary.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            onTap: () {
              Navigator.push(
                context,
                FadePageRoute(
                  page: TransferDetailsScreen(transfer: widget.transfer),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Player Name & Nationality at Top
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Player Photo
                      ClipOval(
                        child: SmartLogo(
                          logo: widget.transfer.playerPhoto,
                          size: 32,
                          isBackground: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.transfer.nationalityFlag,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          widget.transfer.playerName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Position Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      widget.transfer.position,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Transfer Visualization: Old Club -> Arrow -> New Club
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Old Club
                      Expanded(
                        child: _buildClubSection(
                          context: context,
                          clubLogo: widget.transfer.oldClubLogo,
                          clubName: widget.transfer.oldClub,
                          colorScheme: colorScheme,
                          isDark: isDark,
                        ),
                      ),

                      // Animated Arrow
                      AnimatedBuilder(
                        animation: _arrowAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(_arrowAnimation.value, 0),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    colorScheme.primary,
                                    colorScheme.secondary,
                                  ],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: colorScheme.primary.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          );
                        },
                      ),

                      // New Club
                      Expanded(
                        child: _buildClubSection(
                          context: context,
                          clubLogo: widget.transfer.newClubLogo,
                          clubName: widget.transfer.newClub,
                          colorScheme: colorScheme,
                          isDark: isDark,
                          isNewClub: true,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Transfer Fee & Date
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.attach_money_rounded,
                            color: colorScheme.primary,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.transfer.transferFee,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        DateFormat(
                          'd MMM yyyy',
                        ).format(widget.transfer.transferDate),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.outline,
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
    );
  }

  Widget _buildClubSection({
    required BuildContext context,
    required String clubLogo,
    required String clubName,
    required ColorScheme colorScheme,
    required bool isDark,
    bool isNewClub = false,
  }) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isNewClub
                  ? [
                      colorScheme.primary.withValues(alpha: 0.2),
                      colorScheme.secondary.withValues(alpha: 0.2),
                    ]
                  : [colorScheme.surface, colorScheme.surfaceContainerHighest],
            ),
            shape: BoxShape.circle,
            border: Border.all(
              color: isNewClub
                  ? colorScheme.primary.withValues(alpha: 0.4)
                  : colorScheme.outlineVariant,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: isNewClub
                    ? colorScheme.primary.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: SmartLogo(logo: clubLogo, size: 36, isBackground: true),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          clubName,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isNewClub ? colorScheme.primary : colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
