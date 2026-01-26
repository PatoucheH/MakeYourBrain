import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/providers/lives_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';

class LivesIndicator extends StatelessWidget {
  final bool showTimer;
  final double iconSize;
  final bool showAddButton;

  const LivesIndicator({
    super.key,
    this.showTimer = false,
    this.iconSize = 18,
    this.showAddButton = true,
  });

  void _showAdDialog(BuildContext context) {
    final livesProvider = context.read<LivesProvider>();
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.favorite, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.getMoreLifes,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              // Current lives display
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.brainPurpleLight.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...List.generate(livesProvider.maxLives, (index) {
                      final hasLife = index < livesProvider.currentLives;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Icon(
                          hasLife ? Icons.favorite : Icons.favorite_border,
                          color: hasLife ? Colors.red : AppColors.textLight,
                          size: 24,
                        ),
                      );
                    }),
                    const SizedBox(width: 8),
                    Text(
                      '${livesProvider.currentLives}/${livesProvider.maxLives}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.brainPurple,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Text(
                l10n.watchAdd,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                ),
              ),

              if (livesProvider.currentLives < livesProvider.maxLives) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.infoLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time, color: AppColors.info, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '${l10n.nextLife} ${livesProvider.getTimeUntilNextLife()}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.info,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(
                          colors: [AppColors.success, Color(0xFF059669)],
                        ),
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _watchAd(context);
                        },
                        icon: const Icon(Icons.play_circle_outline, color: Colors.white),
                        label: Text(
                          l10n.watchAdd,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 12),
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
    );
  }

  Future<void> _watchAd(BuildContext context) async {
    final livesProvider = context.read<LivesProvider>();
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.brainPurple),
              const SizedBox(height: 20),
              Text(
                l10n.loadingAdd,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await Future.delayed(const Duration(seconds: 3));

    if (context.mounted) {
      Navigator.of(context).pop();
    }

    await livesProvider.addLivesFromAd();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.favorite, color: Colors.white),
              const SizedBox(width: 8),
              Text(l10n.winLifes),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LivesProvider>(
      builder: (context, livesProvider, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Hearts
            Row(
              children: List.generate(livesProvider.maxLives, (index) {
                final hasLife = index < livesProvider.currentLives;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: Icon(
                    hasLife ? Icons.favorite : Icons.favorite_border,
                    color: hasLife ? Colors.red : AppColors.textLight,
                    size: iconSize,
                  ),
                );
              }),
            ),

            // Add button
            if (showAddButton) ...[
              const SizedBox(width: 4),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => _showAdDialog(context),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.add,
                      size: iconSize * 0.8,
                      color: AppColors.success,
                    ),
                  ),
                ),
              ),
            ],

            // Timer
            if (showTimer && livesProvider.currentLives < livesProvider.maxLives) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.infoLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: iconSize * 0.7,
                      color: AppColors.info,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      livesProvider.getTimeUntilNextLife(),
                      style: TextStyle(
                        fontSize: iconSize * 0.65,
                        fontWeight: FontWeight.bold,
                        color: AppColors.info,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
