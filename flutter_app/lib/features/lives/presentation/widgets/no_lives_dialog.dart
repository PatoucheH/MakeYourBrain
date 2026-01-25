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
    
    Navigator.pop(context);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(l10n.loadingAdd),
              ],
            ),
          ),
        ),
      ),
    );
    
    await Future.delayed(const Duration(seconds: 3));
    
    if (mounted) {
      Navigator.of(context).pop();
    }
    
    await livesProvider.addLivesFromAd();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.winLifes),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
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
          title: Column(
            children: [
              Image.asset(
                'assets/branding/mascot/brainly_encourage.png',
                height: 100,
              ),
              const SizedBox(height: 12),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.heart_broken, color: Colors.red, size: 32),
                  const SizedBox(width: 12),
                  Text(l10n.noLife),
                ],
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.needLifes,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              
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
                      style: const TextStyle(fontSize: 14),
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
              
              Text(
                l10n.orWatchAdd,
                textAlign: TextAlign.center,
                style: const TextStyle(
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