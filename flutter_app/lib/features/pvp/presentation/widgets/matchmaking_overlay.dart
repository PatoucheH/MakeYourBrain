import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../main.dart';
import '../../data/providers/pvp_provider.dart';
import '../pages/pvp_game_page.dart';

class MatchmakingOverlay extends StatefulWidget {
  const MatchmakingOverlay({super.key});

  @override
  State<MatchmakingOverlay> createState() => _MatchmakingOverlayState();
}

class _MatchmakingOverlayState extends State<MatchmakingOverlay> {
  bool _isMinimized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PvPProvider>().addListener(_onProviderChanged);
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
    final pvp = context.read<PvPProvider>();
    // Dé-minimiser pour toute nouvelle notification
    if ((pvp.matchFound || pvp.matchFoundWaiting || pvp.yourTurnNotification || pvp.matchCompletedNotification) && _isMinimized) {
      setState(() => _isMinimized = false);
    }
  }

  void _toggleMinimized() {
    setState(() => _isMinimized = !_isMinimized);
  }

  void _goToMatch() {
    final pvpProvider = context.read<PvPProvider>();
    pvpProvider.dismissNotification();
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => const PvPGamePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();

    return Consumer<PvPProvider>(
      builder: (context, pvp, child) {
        final isInQueue = pvp.isInQueue;
        final hasMatchFound = pvp.matchFound;
        final hasMatchFoundWaiting = pvp.matchFoundWaiting;
        final hasYourTurn = pvp.yourTurnNotification;
        final hasMatchCompleted = pvp.matchCompletedNotification;
        final hasAnyNotification = hasMatchFound || hasMatchFoundWaiting || hasYourTurn || hasMatchCompleted;

        if (!isInQueue && !hasAnyNotification) {
          return const SizedBox.shrink();
        }

        return Positioned(
          top: 60,
          right: 16,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _isMinimized
                ? _buildMinimizedPopup(l10n, pvp)
                : hasMatchFound
                    ? _buildMatchFoundCountdown(l10n, pvp)
                    : hasMatchFoundWaiting
                        ? _buildMatchFoundWaitingPopup(l10n, pvp)
                        : hasYourTurn
                            ? _buildYourTurnPopup(l10n, pvp)
                            : hasMatchCompleted
                                ? _buildMatchCompletedPopup(l10n, pvp)
                                : _buildSearchingPopup(l10n, pvp),
          ),
        );
      },
    );
  }

  // ===================== MINIMIZED =====================

  Widget _buildMinimizedPopup(AppLocalizations l10n, PvPProvider pvp) {
    final hasNotification = pvp.matchFound || pvp.matchFoundWaiting || pvp.yourTurnNotification || pvp.matchCompletedNotification;
    final isCompleted = pvp.matchCompletedNotification;

    Color bgColor;
    Color textColor;
    IconData icon;
    String label;

    if (isCompleted) {
      bgColor = pvp.matchCompletedDidWin == true
          ? const Color(0xFF10B981)
          : pvp.matchCompletedDidWin == false
              ? AppColors.error
              : Colors.orange;
      textColor = Colors.white;
      icon = Icons.emoji_events;
      label = pvp.matchCompletedDidWin == true
          ? l10n.victory
          : pvp.matchCompletedDidWin == false
              ? l10n.defeat
              : l10n.draw;
    } else if (hasNotification) {
      bgColor = const Color(0xFF10B981);
      textColor = Colors.white;
      icon = Icons.sports_esports;
      label = l10n.yourTurn;
    } else {
      bgColor = AppColors.white;
      textColor = AppColors.brainPurple;
      icon = Icons.search;
      label = _formatDuration(pvp.searchDuration);
    }

    return GestureDetector(
      onTap: _toggleMinimized,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(28),
            border: hasNotification
                ? null
                : Border.all(color: AppColors.brainPurple.withValues(alpha: 0.3), width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!hasNotification)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.brainPurple),
                  ),
                )
              else
                Icon(icon, color: textColor, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.expand_more,
                color: textColor,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    if (minutes > 0) {
      return '${minutes}m ${secs.toString().padLeft(2, '0')}s';
    }
    return '${secs}s';
  }

  // ===================== SEARCHING =====================

  Widget _buildSearchingPopup(AppLocalizations l10n, PvPProvider pvp) {
    final timeStr = _formatDuration(pvp.searchDuration);

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
            color: AppColors.brainPurple.withValues(alpha: 0.3),
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
                _buildMinimizeButton(AppColors.brainPurple),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => pvp.leaveMatchmaking(),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  backgroundColor: AppColors.error.withValues(alpha: 0.1),
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

  // ===================== TYPE 1: MATCH FOUND + COUNTDOWN =====================

  Widget _buildMatchFoundCountdown(AppLocalizations l10n, PvPProvider pvp) {
    final opponentName = pvp.opponentUsername ?? l10n.opponent;

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
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.sports_esports,
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
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.matchStartingIn(pvp.matchFoundCountdown),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Barre de progression
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pvp.matchFoundCountdown / 5,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'vs $opponentName',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== TYPE 1b: MATCH FOUND - WAITING =====================

  Widget _buildMatchFoundWaitingPopup(AppLocalizations l10n, PvPProvider pvp) {
    final opponentName = pvp.opponentUsername ?? l10n.opponent;

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
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
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.sports_esports,
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
                        '${l10n.matchFound} vs $opponentName',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.matchFoundWaiting,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => pvp.dismissNotification(),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===================== TYPE 2: YOUR TURN =====================

  Widget _buildYourTurnPopup(AppLocalizations l10n, PvPProvider pvp) {
    final opponentName = pvp.opponentUsername ?? l10n.opponent;
    final roundNumber = pvp.notificationRoundNumber ?? pvp.currentMatch?.currentRound ?? 1;

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
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
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.sports_esports,
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
                        l10n.roundAgainst(roundNumber, opponentName),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.yourTurn,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildMinimizeButton(Colors.white),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _goToMatch,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.play_arrow, color: Colors.white, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      l10n.goToMatch,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => pvp.dismissNotification(),
              child: Text(
                l10n.close,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== TYPE 3: MATCH COMPLETED =====================

  Widget _buildMatchCompletedPopup(AppLocalizations l10n, PvPProvider pvp) {
    final opponentName = pvp.opponentUsername ?? l10n.opponent;
    final didWin = pvp.matchCompletedDidWin;

    Color color1;
    Color color2;
    IconData icon;
    String resultText;

    if (didWin == true) {
      color1 = const Color(0xFF10B981);
      color2 = const Color(0xFF059669);
      icon = Icons.emoji_events;
      resultText = l10n.youWon;
    } else if (didWin == false) {
      color1 = const Color(0xFFEF4444);
      color2 = const Color(0xFFDC2626);
      icon = Icons.sentiment_dissatisfied;
      resultText = l10n.youLost;
    } else {
      color1 = const Color(0xFFF59E0B);
      color2 = const Color(0xFFD97706);
      icon = Icons.handshake;
      resultText = l10n.matchDrew;
    }

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color1, color2],
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
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
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
                        l10n.matchEndedAgainst(opponentName),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        resultText,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildMinimizeButton(Colors.white),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _goToMatch,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.visibility, color: Colors.white, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      l10n.seeResults,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => pvp.dismissNotification(),
              child: Text(
                l10n.close,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== HELPERS =====================

  Widget _buildMinimizeButton(Color color) {
    return GestureDetector(
      onTap: _toggleMinimized,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.expand_less,
          color: color,
          size: 20,
        ),
      ),
    );
  }
}
