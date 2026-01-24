import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/providers/lives_provider.dart';

class LivesIndicator extends StatelessWidget {
  final bool showTimer;
  final double iconSize;

  const LivesIndicator({
    super.key,
    this.showTimer = true,
    this.iconSize = 20,
  });

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
                final haLife = index < livesProvider.currentLives;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Icon(
                    haLife ? Icons.favorite : Icons.favorite_border,
                    color: haLife ? Colors.red : Colors.grey.shade400,
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