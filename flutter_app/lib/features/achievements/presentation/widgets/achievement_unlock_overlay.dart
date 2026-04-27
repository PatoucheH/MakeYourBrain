import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/achievement_model.dart';
import '../../data/repositories/achievement_repository.dart';

class AchievementUnlockOverlay extends StatefulWidget {
  final AchievementModel achievement;
  final String language;

  const AchievementUnlockOverlay({
    super.key,
    required this.achievement,
    required this.language,
  });

  static Future<void> show(
    BuildContext context,
    AchievementModel achievement,
    String language,
  ) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: Duration.zero,
      pageBuilder: (ctx, _, __) => AchievementUnlockOverlay(
        achievement: achievement,
        language: language,
      ),
    );
  }

  static Future<void> checkAndShow(
    BuildContext context,
    String userId,
    String language,
  ) async {
    List<AchievementModel> newOnes;
    try {
      newOnes = await AchievementRepository().checkAchievements(userId);
    } catch (e, st) {
      debugPrint('[Achievements] checkAndShow error: $e\n$st');
      return;
    }
    if (!context.mounted) return;
    for (final achievement in newOnes) {
      if (!context.mounted) break;
      await show(context, achievement, language);
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  @override
  State<AchievementUnlockOverlay> createState() =>
      _AchievementUnlockOverlayState();
}

class _AchievementUnlockOverlayState extends State<AchievementUnlockOverlay>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _glowController;
  late AudioPlayer _audioPlayer;

  late Animation<double> _backdropFade;
  late Animation<double> _cardScale;
  late Animation<double> _cardFade;
  late Animation<double> _starburstProgress;
  late Animation<double> _contentFade;
  late Animation<double> _glowPulse;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _backdropFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.25),
    );
    _cardFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.1, 0.4),
    );
    _cardScale = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.1, 0.6, curve: Curves.elasticOut),
    );
    _starburstProgress = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.2, 0.85, curve: Curves.easeOut),
    );
    _contentFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.55, 1.0),
    );
    _glowPulse = Tween<double>(begin: 0.7, end: 1.0).animate(_glowController);

    _entranceController.forward();
    _playSound();
  }

  Future<void> _playSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/badge-unlock.wav'));
    } catch (_) {}
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _glowController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBuilder(
        animation: _entranceController,
        builder: (context, _) {
          return Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    color: Colors.black
                        .withValues(alpha: 0.72 * _backdropFade.value),
                  ),
                ),
              ),
              Center(
                child: FadeTransition(
                  opacity: _cardFade,
                  child: ScaleTransition(
                    scale: _cardScale,
                    child: _buildCard(l10n),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCard(AppLocalizations l10n) {
    final name = widget.achievement.nameFor(widget.language);
    final description = widget.achievement.descriptionFor(widget.language);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: AppColors.cardColorOf(context),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.35),
            blurRadius: 32,
            spreadRadius: 4,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header with starburst ─────────────────────────────────
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A0640), Color(0xFF6A1B9A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    l10n.badgeUnlocked.toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Starburst + badge icon
                  AnimatedBuilder(
                    animation: _glowController,
                    builder: (context, _) {
                      return SizedBox(
                        width: 170,
                        height: 170,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Starburst rays
                            AnimatedBuilder(
                              animation: _starburstProgress,
                              builder: (_, __) => CustomPaint(
                                size: const Size(170, 170),
                                painter:
                                    _StarburstPainter(_starburstProgress.value),
                              ),
                            ),
                            // Glow ring
                            Container(
                              width: 95 * _glowPulse.value,
                              height: 95 * _glowPulse.value,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    const Color(0xFFFFD700).withValues(
                                        alpha: 0.18 * _glowPulse.value),
                                    Colors.transparent,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFFD700).withValues(
                                        alpha: 0.45 * _glowPulse.value),
                                    blurRadius: 24,
                                    spreadRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                            // Badge emoji
                            Text(
                              widget.achievement.icon,
                              style: const TextStyle(fontSize: 62),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // ── Body ─────────────────────────────────────────────────
            FadeTransition(
              opacity: _contentFade,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 28),
                child: Column(
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryOf(context),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondaryOf(context),
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brainPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          l10n.continueButton,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
}

class _StarburstPainter extends CustomPainter {
  final double progress;

  const _StarburstPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    for (int i = 0; i < 8; i++) {
      final angle = (i * pi / 4) - pi / 2;
      final isLong = i.isEven;
      final rayLength =
          (isLong ? maxRadius * 0.88 : maxRadius * 0.56) * progress;
      final halfWidth = isLong ? 9.0 : 4.5;
      final perpAngle = angle + pi / 2;

      final tipX = center.dx + cos(angle) * rayLength;
      final tipY = center.dy + sin(angle) * rayLength;

      final path = Path()
        ..moveTo(
          center.dx + cos(perpAngle) * halfWidth,
          center.dy + sin(perpAngle) * halfWidth,
        )
        ..lineTo(tipX, tipY)
        ..lineTo(
          center.dx - cos(perpAngle) * halfWidth,
          center.dy - sin(perpAngle) * halfWidth,
        )
        ..close();

      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFFFFD700)
              .withValues(alpha: (isLong ? 0.88 : 0.55) * progress)
          ..style = PaintingStyle.fill,
      );

      if (isLong) {
        canvas.drawCircle(
          Offset(tipX, tipY),
          4.0 * progress,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.9 * progress),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_StarburstPainter old) => old.progress != progress;
}
