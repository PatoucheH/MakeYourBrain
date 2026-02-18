import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/providers/lives_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/services/ad_service.dart';

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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.brainPurpleLight.withValues(alpha:0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.favorite,
                          color: livesProvider.currentLives <= 2 ? AppColors.error : Colors.red,
                          size: 48,
                        ),
                        Text(
                          '${livesProvider.currentLives}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '/${livesProvider.maxLives}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.brainPurple,
                      ),
                    ),
                  ],
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

              // Buttons - Stacked vertically
              SizedBox(
                width: double.infinity,
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
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    l10n.cancel,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
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

  Future<void> _watchAd(BuildContext context) async {
    final livesProvider = context.read<LivesProvider>();
    final l10n = AppLocalizations.of(context)!;
    final adService = AdService();

    if (!adService.isAdReady) {
      adService.loadRewardedAd();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.loadingAdd),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    final rewarded = await adService.showRewardedAd();

    if (rewarded) {
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
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LivesProvider>(
      builder: (context, livesProvider, child) {
        final isLow = livesProvider.currentLives <= 2;

        return MouseRegion(
          cursor: showAddButton ? SystemMouseCursors.click : SystemMouseCursors.basic,
          child: GestureDetector(
            onTap: showAddButton ? () => _showAdDialog(context) : null,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Heart with number inside
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.favorite,
                      color: isLow ? AppColors.error : Colors.red,
                      size: iconSize * 1.6,
                    ),
                    Text(
                      '${livesProvider.currentLives}',
                      style: TextStyle(
                        fontSize: iconSize * 0.6,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                Text(
                  '/${livesProvider.maxLives}',
                  style: TextStyle(
                    fontSize: iconSize * 0.75,
                    fontWeight: FontWeight.bold,
                    color: isLow ? AppColors.error : AppColors.textSecondary,
                  ),
                ),

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
            ),
          ),
        );
      },
    );
  }
}
