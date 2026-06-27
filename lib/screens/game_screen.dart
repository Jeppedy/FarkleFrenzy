import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_model.dart';
import '../theme/app_theme.dart';
import 'game_over_screen.dart';

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

// ---------------------------------------------------------------------------
// Main Game Screen — tabbed: Scoring | Leaderboard
// ---------------------------------------------------------------------------

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _confirmNewGame(BuildContext context, GameModel game) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        title: const Text('New Game?'),
        content: const Text('This will end the current game and return to setup.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              game.resetGame();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('New Game'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameModel>(
      builder: (context, game, _) {
        if (game.phase == GamePhase.gameOver) {
          return const GameOverScreen();
        }

        final playerColor =
            _playerColors[game.currentPlayerIndex % _playerColors.length];

        return Scaffold(
          backgroundColor: AppTheme.darkBg,
          appBar: AppBar(
            title: const Text('🎲 FARKLE FRENZY'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'New Game',
                onPressed: () => _confirmNewGame(context, game),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.accentGold,
              indicatorWeight: 3,
              labelColor: AppTheme.accentGold,
              unselectedLabelColor: Colors.white54,
              tabs: const [
                Tab(icon: Icon(Icons.casino, size: 18), text: 'Scoring'),
                Tab(icon: Icon(Icons.leaderboard, size: 18), text: 'Leaderboard'),
              ],
            ),
          ),
          body: SafeArea(
            child: TabBarView(
              controller: _tabController,
              children: [
                // ── Tab 1: Active Scoring ──
                _ScoringTab(game: game, playerColor: playerColor),
                // ── Tab 2: Leaderboard ──
                _LeaderboardTab(game: game),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 1: Scoring
// ---------------------------------------------------------------------------

class _ScoringTab extends StatelessWidget {
  final GameModel game;
  final Color playerColor;

  const _ScoringTab({required this.game, required this.playerColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Last Round banner
        if (game.lastRoundInProgress)
          Container(
            width: double.infinity,
            color: AppTheme.accentRed,
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: const Text(
              '🔔  LAST ROUND — Push Your Luck!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
          ),

        // Compact player header
        _PlayerHeader(
          game: game,
          playerColor: playerColor,
        ),

        // Scoring buttons — compact grid, no section headers
        Expanded(
          child: _CompactScoringGrid(game: game),
        ),

        // Bank / Undo / Bust bar
        _ActionBar(game: game, playerColor: playerColor),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Compact player header
// ---------------------------------------------------------------------------

class _PlayerHeader extends StatelessWidget {
  final GameModel game;
  final Color playerColor;

  const _PlayerHeader({required this.game, required this.playerColor});

  @override
  Widget build(BuildContext context) {
    final player = game.currentPlayer;
    final turnScore = game.currentTurnScore;
    final meetsOpening = game.meetsOpeningRequirement;
    final hasOpened = game.currentPlayerHasOpened;

    return Container(
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: playerColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: playerColor, width: 1.5),
      ),
      child: Row(
        children: [
          // Player name + total
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: playerColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Text(
                      'Total: ${player.totalScore}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                    if (player.totalScore >= game.winningScore)
                      const Text('  👑',
                          style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),

          // Opening requirement chip — only while not yet opened
          if (!hasOpened)
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: meetsOpening
                    ? Colors.green.withValues(alpha: 0.25)
                    : Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: meetsOpening ? Colors.greenAccent : Colors.orange,
                ),
              ),
              child: Text(
                meetsOpening ? '✓ Can bank' : 'Need 500',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: meetsOpening ? Colors.greenAccent : Colors.orange,
                ),
              ),
            ),

          // Turn score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'TURN',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.white38,
                  letterSpacing: 2,
                ),
              ),
              Text(
                '$turnScore',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: turnScore > 0 ? AppTheme.accentGold : Colors.white24,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Compact scoring grid — all buttons, no section headers, color-grouped
// ---------------------------------------------------------------------------

class _CompactScoringGrid extends StatelessWidget {
  final GameModel game;
  const _CompactScoringGrid({required this.game});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Singles row ──────────────────────────────────────────────────
          _groupDivider('Singles', AppTheme.singlesColor),
          _buttonRow([
            _comboBtn('Single 1', allCombos[0], AppTheme.singlesColor),
            _comboBtn('Single 5', allCombos[1], AppTheme.singlesColor),
          ]),

          // ── Three of a Kind ──────────────────────────────────────────────
          _groupDivider('Three of a Kind', AppTheme.threeColor),
          _buttonRow([
            _comboBtn('Three Ones',   allCombos[2], AppTheme.threeColor),
            _comboBtn('Three Twos',   allCombos[3], AppTheme.threeColor),
            _comboBtn('Three Threes', allCombos[4], AppTheme.threeColor),
          ]),
          _buttonRow([
            _comboBtn('Three Fours', allCombos[5], AppTheme.threeColor),
            _comboBtn('Three Fives', allCombos[6], AppTheme.threeColor),
            _comboBtn('Three Sixes', allCombos[7], AppTheme.threeColor),
          ]),

          // ── Multiples ────────────────────────────────────────────────────
          _groupDivider('4 / 5 / 6 of a Kind', AppTheme.fourColor),
          _buttonRow([
            _comboBtn('Four of a Kind', allCombos[8],  AppTheme.fourColor),
            _comboBtn('Five of a Kind', allCombos[9],  AppTheme.fourColor),
            _comboBtn('Six of a Kind',  allCombos[10], AppTheme.fourColor),
          ]),

          // ── Special ──────────────────────────────────────────────────────
          _groupDivider('Special', AppTheme.specialColor),
          _buttonRow([
            _comboBtn('Small\nStraight',  allCombos[11], AppTheme.specialColor),
            _comboBtn('Large\nStraight',  allCombos[12], AppTheme.specialColor),
            _comboBtn('Three\nPairs',     allCombos[13], AppTheme.specialColor),
          ]),
          _buttonRow([
            _comboBtn('Farkle\nFull House', allCombos[14], AppTheme.specialColor),
            _comboBtn('Two\nTriplets',      allCombos[15], AppTheme.specialColor),
          ]),

          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _groupDivider(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 3),
      child: Row(
        children: [
          Container(width: 3, height: 13, color: color,
              margin: const EdgeInsets.only(right: 6)),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(child: Divider(color: color.withValues(alpha: 0.3), height: 1)),
        ],
      ),
    );
  }

  Widget _buttonRow(List<Widget> buttons) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: buttons
            .expand((b) => [Expanded(child: b), const SizedBox(width: 5)])
            .toList()
          ..removeLast(),
      ),
    );
  }

  Widget _comboBtn(String label, ScoringCombo combo, Color color) {
    return _ComboButton(
      label: label,
      combo: combo,
      color: color,
      onTap: () => game.addCombo(combo),
    );
  }
}

// ---------------------------------------------------------------------------
// Individual combo button — label only, no point value
// ---------------------------------------------------------------------------

class _ComboButton extends StatelessWidget {
  final String label;
  final ScoringCombo combo;
  final Color color;
  final VoidCallback onTap;

  const _ComboButton({
    required this.label,
    required this.combo,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        splashColor: color.withValues(alpha: 0.4),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.6)),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Action bar: Bust | Undo | Bank
// ---------------------------------------------------------------------------

class _ActionBar extends StatelessWidget {
  final GameModel game;
  final Color playerColor;

  const _ActionBar({required this.game, required this.playerColor});

  @override
  Widget build(BuildContext context) {
    final canBank = game.meetsOpeningRequirement && game.currentTurnScore > 0;
    final bustLabel = game.currentTurnScore > 0
        ? 'Lose ${game.currentTurnScore}'
        : 'Pass';

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceDark,
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // BUST
          Expanded(
            flex: 5,
            child: _ActionButton(
              label: 'BUST',
              sublabel: bustLabel,
              color: AppTheme.accentRed,
              icon: Icons.close_rounded,
              onPressed: () => _handleBust(context),
            ),
          ),
          const SizedBox(width: 8),

          // UNDO — narrower
          Expanded(
            flex: 3,
            child: _ActionButton(
              label: 'UNDO',
              sublabel: '',
              color: game.canUndo
                  ? const Color(0xFF455A64)
                  : const Color(0xFF263238),
              icon: Icons.undo_rounded,
              onPressed: game.canUndo ? game.undo : null,
              dimmed: !game.canUndo,
            ),
          ),
          const SizedBox(width: 8),

          // BANK
          Expanded(
            flex: 5,
            child: _ActionButton(
              label: 'BANK',
              sublabel: canBank ? '+${game.currentTurnScore}' : '—',
              color: canBank ? AppTheme.feltGreen : const Color(0xFF1B3320),
              icon: Icons.savings_rounded,
              onPressed: canBank ? game.bank : null,
              dimmed: !canBank,
            ),
          ),
        ],
      ),
    );
  }

  void _handleBust(BuildContext context) {
    if (game.currentTurnScore > 0) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          title: const Text('💥 Bust?'),
          content: Text(
              'Lose ${game.currentTurnScore} pts and pass to the next player?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                game.bust();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentRed,
                foregroundColor: Colors.white,
              ),
              child: const Text('Bust!'),
            ),
          ],
        ),
      );
    } else {
      game.bust();
    }
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final String sublabel;
  final Color color;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool dimmed;

  const _ActionButton({
    required this.label,
    required this.sublabel,
    required this.color,
    required this.icon,
    this.onPressed,
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: dimmed ? Colors.white30 : Colors.white,
        disabledBackgroundColor: color,
        disabledForegroundColor: Colors.white30,
        elevation: dimmed ? 0 : 3,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          if (sublabel.isNotEmpty)
            Text(
              sublabel,
              style: TextStyle(
                fontSize: 11,
                color: dimmed ? Colors.white24 : Colors.white70,
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 2: Leaderboard
// ---------------------------------------------------------------------------

class _LeaderboardTab extends StatelessWidget {
  final GameModel game;
  const _LeaderboardTab({required this.game});

  @override
  Widget build(BuildContext context) {
    final sorted = game.sortedPlayers;

    return Column(
      children: [
        if (game.lastRoundInProgress)
          Container(
            width: double.infinity,
            color: AppTheme.accentRed,
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: const Text(
              '🔔  LAST ROUND — Push Your Luck!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),

        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Row(
            children: [
              Text(
                'Standings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accentGold,
                ),
              ),
              const Spacer(),
              Text(
                'Target: ${game.winningScore}',
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white38,
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: sorted.length,
            itemBuilder: (context, rank) {
              final p = sorted[rank];
              final originalIdx =
                  game.players.indexWhere((pl) => pl.name == p.name);
              final pColor =
                  _playerColors[originalIdx % _playerColors.length];
              final isCurrent = p.name == game.currentPlayer.name;
              final isOver = p.totalScore >= game.winningScore;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: isCurrent
                      ? pColor.withValues(alpha: 0.18)
                      : AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isCurrent ? pColor : Colors.white12,
                    width: isCurrent ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Rank
                    SizedBox(
                      width: 32,
                      child: Text(
                        rank == 0
                            ? '🥇'
                            : rank == 1
                                ? '🥈'
                                : rank == 2
                                    ? '🥉'
                                    : ' ${rank + 1}.',
                        style: const TextStyle(fontSize: 20),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Color dot
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: pColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Name
                    Expanded(
                      child: Text(
                        p.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isCurrent
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Active turn indicator
                    if (isCurrent)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: pColor.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: pColor),
                        ),
                        child: Text(
                          'ACTIVE',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: pColor,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    // Score
                    Text(
                      '${p.totalScore}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isOver ? AppTheme.accentGold : Colors.white,
                      ),
                    ),
                    if (isOver)
                      const Text(' 👑', style: TextStyle(fontSize: 14)),
                  ],
                ),
              );
            },
          ),
        ),

        // Current player's turn score — quick ref at bottom
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          color: AppTheme.surfaceDark,
          child: Text(
            '${game.currentPlayer.name}\'s turn — ${game.currentTurnScore} pts accumulated',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Colors.white54),
          ),
        ),
      ],
    );
  }
}
