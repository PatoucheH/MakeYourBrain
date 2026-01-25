import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/providers/lives_provider.dart';
import '../../../../l10n/app_localizations.dart';

class NoLivesDialog extends StatefulWidget {
  final VoidCallback? onClose;

  const NoLivesDialog({super.key, this.onClose});

  @override
  State<NoLivesDialog> createState() => _NoLivesDialogState();
}

class _NoLivesDialogState extends State<NoLivesDialog> {
  Future<void> _watchAd(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final livesProvider = context.read<LivesProvider>();
    
    // Fermer le dialog actuel
    Navigator.pop(context);
    
    // Afficher un loading pendant la "pub"
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
    
    // Simuler la durée de la pub (3 secondes)
    await Future.delayed(const Duration(seconds: 3));
    
    // Fermer le loading
    if (mounted) {
      Navigator.of(context).pop();
    }
    
    // Ajouter les vies
    await livesProvider.addLivesFromAd();
    
    // Afficher un message de succès
    if (mounted) {
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
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.heart_broken, color: Colors.red, size: 32),
              SizedBox(width: 12),
              Text(l10n.noLife),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.needLifes,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              
              // Timer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200, width: 2),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.access_time, color: Colors.blue, size: 40),
                    const SizedBox(height: 8),
                    Text(
                      l10n.nextLife,
                      style: TextStyle(fontSize: 14),
                    ),
                    Text(
                      livesProvider.getTimeUntilNextLife(),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              
              // Message pub
              Text(
                l10n.orWatchAdd,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onClose?.call();
              },
              child: Text(l10n.close),
            ),
            ElevatedButton.icon(
              onPressed: () => _watchAd(context),
              icon: const Icon(Icons.play_circle_outline),
              label: Text(l10n.watchAdd),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        );
      },
    );
  }
}