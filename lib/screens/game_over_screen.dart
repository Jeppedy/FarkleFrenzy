import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_model.dart';
import '../theme/app_theme.dart';

const List<Color> _playerColors = [
  Color(0xFFE53935),
  Color(0xFF1E88E5),
  Color(0xFF43A047),
  Color(0xFFFB8C00),
  Color(0xFF8E24AA),
  Color(0xFF00ACC1),
  Color(0xFFFFB300),
  Color(0xFF6D4C41),
];

class GameOverScreen extends StatelessWidget {
  const GameOverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameModel>();
    final sorted = game.sortedPlayers;
    final winner = sorted.first;

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text('🎲 FARKLE FRENZY'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Winner announcement
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4A3000), Color(0xFF7A5200)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.accentGold, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentGold.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      '👑',
                      style: TextStyle(fontSize: 56),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'WINNER!',
                      style: TextStyle(
                        fontSize: 14,
                        letterSpacing: 6,
                        color: AppTheme.accentGold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      winner.name,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${winner.totalScore} points',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentGold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Final standings
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Final Standings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.separated(
                        itemCount: sorted.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final p = sorted[i];
                          final originalIdx =
                              game.players.indexWhere((pl) => pl.name == p.name);
                          final pColor =
                              _playerColors[originalIdx % _playerColors.length];
                          final isWinner = i == 0;

                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isWinner
                                  ? AppTheme.accentGold.withValues(alpha: 0.15)
                                  : AppTheme.surfaceCard,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isWinner
                                    ? AppTheme.accentGold
                                    : Colors.white12,
                                width: isWinner ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Rank medal/number
                                SizedBox(
                                  width: 40,
                                  child: Text(
                                    i == 0
                                        ? '🥇'
                                        : i == 1
                                            ? '🥈'
                                            : i == 2
                                                ? '🥉'
                                                : '${i + 1}.',
                                    style: const TextStyle(fontSize: 22),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Player color indicator
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: pColor,
                                  child: Text(
                                    '${originalIdx + 1}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    p.name,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: isWinner
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${p.totalScore}',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: isWinner
                                            ? AppTheme.accentGold
                                            : Colors.white,
                                      ),
                                    ),
                                    if (p.totalScore >= game.winningScore)
                                      Text(
                                        'over ${game.winningScore}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.white38,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Play again buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Same players, new game
                        final names =
                            game.players.map((p) => p.name).toList();
                        final target = game.winningScore;
                        game.initGame(names, target);
                      },
                      icon: const Icon(Icons.replay),
                      label: const Text('Same Players'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.accentGold,
                        side: const BorderSide(color: AppTheme.accentGold),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => game.resetGame(),
                      icon: const Icon(Icons.people),
                      label: const Text('New Players'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.feltGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
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
}
