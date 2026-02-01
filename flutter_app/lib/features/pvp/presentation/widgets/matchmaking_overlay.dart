import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/providers/pvp_provider.dart';
import '../pages/pvp_game_page.dart';

class MatchmakingOverlay extends StatefulWidget {
  const MatchmakingOverlay({super.key});

  @override
  State<MatchmakingOverlay> createState() => _MatchmakingOverlayState();
}

class _MatchmakingOverlayState extends State<MatchmakingOverlay> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pvpProvider = context.read<PvPProvider>();
      pvpProvider.addListener(_onProviderChanged);
    });
  }

  @override
  void dispose() {
    try {
      context.read<PvPProvider>().removeListener(_onProviderChanged);
    } catch (_) {}
    super.dispose();
  }

  void _onProviderChanged() {
    if (!mounted) return;
    final pvpProvider = context.read<PvPProvider>();
    if (pvpProvider.isReadyToPlay && pvpProvider.currentMatch != null) {
      pvpProvider.clearReadyToPlay();
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PvPGamePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();

    return Consumer<PvPProvider>(
      builder: (context, pvpProvider, child) {
        final isInQueue = pvpProvider.isInQueue;
        final matchFound = pvpProvider.matchFound;
        final searchDuration = pvpProvider.searchDuration;
        final countdown = pvpProvider.matchFoundCountdown;

        if (!isInQueue && !matchFound) {
          return const SizedBox.shrink();
        }

        return Positioned(
          top: 60,
          right: 16,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: matchFound
                ? _buildMatchFoundPopup(l10n, countdown)
                : _buildSearchingPopup(l10n, searchDuration, pvpProvider),
          ),
        );
      },
    );
  }

  Widget _buildSearchingPopup(AppLocalizations l10n, int searchDuration, PvPProvider pvpProvider) {
    final minutes = searchDuration ~/ 60;
    final seconds = searchDuration % 60;
    final timeStr = minutes > 0
        ? '${minutes}m ${seconds.toString().padLeft(2, '0')}s'
        : '${seconds}s';

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.brainPurple.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.brainPurple,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.searchingOpponent,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.brainPurple,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => pvpProvider.leaveMatchmaking(),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  backgroundColor: AppColors.error.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.close, color: AppColors.error, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      l10n.cancel,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchFoundPopup(AppLocalizations l10n, int countdown) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF059669)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.matchFound,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.matchStartingIn(countdown),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: countdown / 5,
                minHeight: 6,
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
