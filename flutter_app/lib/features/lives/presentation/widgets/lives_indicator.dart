import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/providers/lives_provider.dart';
import '../../../../l10n/app_localizations.dart';
import 'no_lives_dialog.dart';

class LivesIndicator extends StatelessWidget {
  final bool showTimer;
  final double iconSize;
  final bool showAddButton;

  const LivesIndicator({
    super.key,
    this.showTimer = true,
    this.iconSize = 20,
    this.showAddButton = true,
  });

  void _showAdDialog(BuildContext context) {
    final livesProvider = context.read<LivesProvider>();
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.favorite, color: Colors.red, size: 32),
            SizedBox(width: 12),
            Text(l10n.getMoreLifes),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${l10n.currentLife}: ${livesProvider.currentLives}/${livesProvider.maxLives}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.watchAdd,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            if (livesProvider.currentLives < livesProvider.maxLives) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.access_time, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${l10n.nextLife} ${livesProvider.getTimeUntilNextLife()}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await _watchAd(context);
            },
            icon: const Icon(Icons.play_circle_outline),
            label: Text(l10n.watchAdd),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _watchAd(BuildContext context) async {
    final livesProvider = context.read<LivesProvider>();
    final l10n = AppLocalizations.of(context)!;
    
    // Afficher loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(l10n.loadingAdd),
              ],
            ),
          ),
        ),
      ),
    );
    
    // Simuler la pub (3 secondes)
    await Future.delayed(const Duration(seconds: 3));
    
    // Fermer le loading
    if (context.mounted) {
      Navigator.of(context).pop();
    }
    
    // Ajouter les vies
    await livesProvider.addLivesFromAd();
    
    // Message de succès
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.winLifes),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Icon(
                    hasLife ? Icons.favorite : Icons.favorite_border,
                    color: hasLife ? Colors.red : Colors.grey.shade400,
                    size: iconSize,
                  ),
                );
              }),
            ),
            
            const SizedBox(width: 8),
            
            // Count
            Text(
              '${livesProvider.currentLives}/${livesProvider.maxLives}',
              style: TextStyle(
                fontSize: iconSize * 0.8,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            // Add button
            if (showAddButton) ...[
              const SizedBox(width: 4),
              InkWell(
                onTap: () => _showAdDialog(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Icon(
                    Icons.add,
                    size: iconSize * 0.9,
                    color: Colors.green.shade700,
                  ),
                ),
              ),
            ],
            
            // Timer
            if (showTimer && livesProvider.currentLives < livesProvider.maxLives) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: iconSize * 0.8,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      livesProvider.getTimeUntilNextLife(),
                      style: TextStyle(
                        fontSize: iconSize * 0.7,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
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