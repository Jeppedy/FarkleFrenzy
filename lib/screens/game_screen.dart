import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_model.dart';
import '../theme/app_theme.dart';
import 'game_over_screen.dart';

const List<Color> _playerColors = [
  Color(0xFFE53935), // red
  Color(0xFF1E88E5), // blue
  Color(0xFF43A047), // green
  Color(0xFFFB8C00), // orange
  Color(0xFF8E24AA), // purple
  Color(0xFF00ACC1), // cyan
  Color(0xFFFFB300), // amber
  Color(0xFF6D4C41), // brown
  Color(0xFFEC407A), // pink
];

Color _colorFor(int index) => _playerColors[index % _playerColors.length];

// ---------------------------------------------------------------------------
// Main Game Screen
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

        return Scaffold(
          backgroundColor: AppTheme.darkBg,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'New Game',
              onPressed: () => _confirmNewGame(context, game),
            ),
            title: const Text('🎲 FARKLE FRENZY',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.undo_rounded,
                  color: game.canUndo ? AppTheme.accentGold : Colors.white24,
                ),
                tooltip: 'Undo',
                onPressed: game.canUndo ? game.undo : null,
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
                _ScoringTab(game: game),
                _LeaderboardTab(
                  game: game,
                  onPassTo: (idx) {
                    game.passTurnTo(idx);
                    // Switch back to scoring tab after pass
                    _tabController.animateTo(0);
                  },
                ),
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
  const _ScoringTab({required this.game});

  @override
  Widget build(BuildContext context) {
    final scorerColor = _colorFor(game.activeScorerIndex);

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

        // Player header
        _PlayerHeader(game: game, scorerColor: scorerColor),

        // Scoring buttons
        Expanded(child: _CompactScoringGrid(game: game)),

        // Bank / Undo / Bust
        _ActionBar(game: game),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Player header — shows active scorer + rotation owner when passed
// ---------------------------------------------------------------------------

class _PlayerHeader extends StatelessWidget {
  final GameModel game;
  final Color scorerColor;

  const _PlayerHeader({required this.game, required this.scorerColor});

  @override
  Widget build(BuildContext context) {
    final scorer = game.activeScorer;
    final turnScore = game.currentTurnScore;
    final meetsOpening = game.meetsOpeningRequirement;
    final hasOpened = game.activeScorerHasOpened;
    final isPassed = game.isPassed;
    final ownerColor = _colorFor(game.rotationOwnerIndex);

    // Leader status — only meaningful when at least one player has scored
    final allZero = game.players.every((p) => p.totalScore == 0);
    final otherBest = game.players
        .where((p) => p.name != scorer.name)
        .fold<int>(0, (best, p) => p.totalScore > best ? p.totalScore : best);
    final myScore = scorer.totalScore;
    final leaderDiff = myScore - otherBest;

    return Container(
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: scorerColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scorerColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Leader status line — current standing + projected standing if banked
          if (!allZero) ...[
            Builder(
              builder: (_) {
                String phraseFor(int diff) {
                  if (diff > 0) return 'leader by $diff pts';
                  if (diff == 0) return 'tied for the lead';
                  return '${-diff} pts behind the leader';
                }

                Color colorFor(int diff) {
                  if (diff > 0) return AppTheme.accentGold;
                  if (diff == 0) return Colors.white54;
                  return Colors.redAccent;
                }

                final projectedDiff = (myScore + turnScore) - otherBest;

                return Row(
                  children: [
                    Text(
                      'Current: ${phraseFor(leaderDiff)}',
                      style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: colorFor(leaderDiff),
                      ),
                    ),
                    if (turnScore > 0) ...[
                      const Text('   →',
                          style: TextStyle(fontSize: 11, color: Colors.white38)),
                      Text(
                        '  If Banked: ${phraseFor(projectedDiff)}',
                        style: TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w600,
                          color: projectedDiff > leaderDiff
                              ? Colors.greenAccent
                              : colorFor(projectedDiff),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 4),
          ],

          Row(
            children: [
              // Active scorer name + total
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scorer.name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: scorerColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Text(
                          'Total: ${scorer.totalScore}',
                          style: const TextStyle(
                              fontSize: 13, color: Colors.white70),
                        ),
                        if (scorer.totalScore >= game.winningScore)
                          const Text('  👑',
                              style: TextStyle(fontSize: 12)),
                        if (turnScore > 0) ...[
                          const Text('   →',
                              style: TextStyle(fontSize: 12, color: Colors.white38)),
                          Text(
                            '  If Banked: ${scorer.totalScore + turnScore}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.greenAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Opening requirement chip
              if (!hasOpened)
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: meetsOpening
                        ? Colors.green.withValues(alpha: 0.25)
                        : Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color:
                          meetsOpening ? Colors.greenAccent : Colors.orange,
                    ),
                  ),
                  child: Text(
                    meetsOpening ? '✓ Can bank' : 'Need 500',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: meetsOpening
                          ? Colors.greenAccent
                          : Colors.orange,
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
                        fontSize: 9, color: Colors.white38, letterSpacing: 2),
                  ),
                  Text(
                    '$turnScore',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: turnScore > 0
                          ? AppTheme.accentGold
                          : Colors.white24,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Pass indicator — shown only when dice have been passed
          if (isPassed) ...[
            const SizedBox(height: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: ownerColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: ownerColor.withValues(alpha: 0.6)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.swap_horiz_rounded,
                      size: 14, color: ownerColor),
                  const SizedBox(width: 6),
                  Text(
                    '${game.rotationOwner.name}\'s turn — passed to ${scorer.name}',
                    style: TextStyle(
                      fontSize: 12,
                      color: ownerColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Compact scoring grid
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
          _groupDivider('Singles', AppTheme.singlesColor),
          _buttonRow([
            _comboBtn('Single 1', allCombos[0], AppTheme.singlesColor),
            _comboBtn('Single 5', allCombos[1], AppTheme.singlesColor),
          ]),

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

          _groupDivider('4 / 5 / 6 of a Kind', AppTheme.fourColor),
          _buttonRow([
            _comboBtn('Four of a Kind', allCombos[8],  AppTheme.fourColor),
            _comboBtn('Five of a Kind', allCombos[9],  AppTheme.fourColor),
            _comboBtn('Farkle! (All Six)', allCombos[10], AppTheme.fourColor),
          ]),

          _groupDivider('Special', AppTheme.specialColor),
          _buttonRow([
            _comboBtn('Small\nStraight',    allCombos[11], AppTheme.specialColor),
            _comboBtn('Large\nStraight',    allCombos[12], AppTheme.specialColor),
            _comboBtn('Three\nPairs',       allCombos[13], AppTheme.specialColor),
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
          Container(
              width: 3, height: 13, color: color,
              margin: const EdgeInsets.only(right: 6)),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5)),
          const SizedBox(width: 6),
          Expanded(
              child: Divider(
                  color: color.withValues(alpha: 0.3), height: 1)),
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
// Combo button — label only
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
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.6)),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
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
  const _ActionBar({required this.game});

  @override
  Widget build(BuildContext context) {
    final canBank = game.meetsOpeningRequirement && game.currentTurnScore > 0;
    final bustLabel =
        game.currentTurnScore > 0 ? 'Lose ${game.currentTurnScore}' : '';

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceDark,
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
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
          Expanded(
            flex: 5,
            child: _ActionButton(
              label: 'BANK',
              sublabel: canBank ? '+${game.currentTurnScore}' : '',
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
    game.bust();
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
        padding: const EdgeInsets.symmetric(vertical: 24),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 26),
              const SizedBox(width: 5),
              Text(label,
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2)),
            ],
          ),
          // Fixed-height slot keeps both buttons identical regardless of sublabel
          SizedBox(
            height: 22,
            child: sublabel.isNotEmpty
                ? Text(sublabel,
                    style: TextStyle(
                        fontSize: 16,
                        color: dimmed ? Colors.white24 : Colors.white70))
                : null,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 2: Leaderboard — tap a player to pass them the dice
// ---------------------------------------------------------------------------

class _LeaderboardTab extends StatelessWidget {
  final GameModel game;
  final void Function(int playerIndex) onPassTo;

  const _LeaderboardTab({
    required this.game,
    required this.onPassTo,
  });

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
                  fontSize: 12),
            ),
          ),

        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
          child: Row(
            children: [
              Text('Standings',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentGold)),
              const Spacer(),
              Text('Target: ${game.winningScore}',
                  style: const TextStyle(fontSize: 13, color: Colors.white38)),
            ],
          ),
        ),

        // Pass hint
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            'Tap a player to pass them the dice',
            style: TextStyle(
                fontSize: 11,
                color: Colors.white38,
                fontStyle: FontStyle.italic),
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
              final pColor = _colorFor(originalIdx);

              final isActiveScorer = originalIdx == game.activeScorerIndex;
              final isRotationOwner = originalIdx == game.rotationOwnerIndex;
              final isOver = p.totalScore >= game.winningScore;

              // Can't pass to yourself (the current active scorer)
              final canPassTo = !isActiveScorer;

              return GestureDetector(
                onTap: canPassTo ? () => onPassTo(originalIdx) : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: isActiveScorer
                        ? pColor.withValues(alpha: 0.22)
                        : canPassTo
                            ? AppTheme.surfaceCard
                            : AppTheme.surfaceCard.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isActiveScorer
                          ? pColor
                          : canPassTo
                              ? Colors.white24
                              : Colors.white12,
                      width: isActiveScorer ? 2 : 1,
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
                      const SizedBox(width: 8),
                      // Color dot
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                            color: pColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 10),
                      // Name
                      Expanded(
                        child: Text(
                          p.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isActiveScorer
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: canPassTo
                                ? Colors.white
                                : Colors.white38,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Status badges
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isActiveScorer)
                            _badge('SCORING', pColor),
                          if (isRotationOwner && !isActiveScorer)
                            _badge("TURN OWNER",
                                _colorFor(game.rotationOwnerIndex)),
                          if (!isActiveScorer && canPassTo)
                            Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: Icon(Icons.swap_horiz_rounded,
                                  size: 16, color: Colors.white24),
                            ),
                        ],
                      ),
                      const SizedBox(width: 6),

                      // Score
                      Text(
                        '${p.totalScore}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isOver
                              ? AppTheme.accentGold
                              : Colors.white,
                        ),
                      ),
                      if (isOver)
                        const Text(' 👑',
                            style: TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Footer: current turn info
        Container(
          width: double.infinity,
          padding:
              const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          color: AppTheme.surfaceDark,
          child: Text(
            game.isPassed
                ? '${game.rotationOwner.name}\'s turn  •  ${game.activeScorer.name} is scoring  •  ${game.currentTurnScore} pts built'
                : '${game.activeScorer.name}\'s turn  •  ${game.currentTurnScore} pts built',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.white54),
          ),
        ),
      ],
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: color,
            letterSpacing: 0.8),
      ),
    );
  }
}
