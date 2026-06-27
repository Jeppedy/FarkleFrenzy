import 'package:flutter/foundation.dart';

// ---------------------------------------------------------------------------
// Scoring combination definitions
// ---------------------------------------------------------------------------

class ScoringCombo {
  final String label;
  final int points;
  final String category;

  const ScoringCombo({
    required this.label,
    required this.points,
    required this.category,
  });
}

// All valid scoring combinations
const List<ScoringCombo> allCombos = [
  // Singles
  ScoringCombo(label: '1', points: 100, category: 'singles'),
  ScoringCombo(label: '5', points: 50, category: 'singles'),

  // Three of a kind
  ScoringCombo(label: 'Three Ones', points: 300, category: 'three'),
  ScoringCombo(label: 'Three Twos', points: 200, category: 'three'),
  ScoringCombo(label: 'Three Threes', points: 300, category: 'three'),
  ScoringCombo(label: 'Three Fours', points: 400, category: 'three'),
  ScoringCombo(label: 'Three Fives', points: 500, category: 'three'),
  ScoringCombo(label: 'Three Sixes', points: 600, category: 'three'),

  // Four / Five / Six of a kind — flat values regardless of die number
  ScoringCombo(label: 'Four of a Kind', points: 1000, category: 'multiples'),
  ScoringCombo(label: 'Five of a Kind', points: 2000, category: 'multiples'),
  ScoringCombo(label: 'Six of a Kind', points: 3000, category: 'multiples'),

  // Special combos
  ScoringCombo(label: 'Small Straight\n1-2-3-4-5', points: 500, category: 'special'),
  ScoringCombo(label: 'Large Straight\n1-2-3-4-5-6', points: 1500, category: 'special'),
  ScoringCombo(label: 'Three Pairs', points: 1500, category: 'special'),
  ScoringCombo(label: 'Farkle Full House', points: 1500, category: 'special'),
  ScoringCombo(label: 'Two Triplets', points: 2500, category: 'special'),
];

// ---------------------------------------------------------------------------
// Player model
// ---------------------------------------------------------------------------

class Player {
  final String name;
  int totalScore;
  bool hasOpenedScoring;

  Player({
    required this.name,
    this.totalScore = 0,
    this.hasOpenedScoring = false,
  });

  Player copyWith({
    String? name,
    int? totalScore,
    bool? hasOpenedScoring,
  }) {
    return Player(
      name: name ?? this.name,
      totalScore: totalScore ?? this.totalScore,
      hasOpenedScoring: hasOpenedScoring ?? this.hasOpenedScoring,
    );
  }
}

// ---------------------------------------------------------------------------
// Turn action — used for undo history
// ---------------------------------------------------------------------------

enum TurnActionType { addScore, bank, bust, pass }

class TurnAction {
  final TurnActionType type;
  final int pointsBefore;
  final ScoringCombo? combo;
  final int rotationOwnerIndexBefore;  // whose turn it is in sequence
  final int activeScorerIndexBefore;   // who is actually holding the dice
  final List<Player> playerStatesBefore;

  TurnAction({
    required this.type,
    required this.pointsBefore,
    this.combo,
    required this.rotationOwnerIndexBefore,
    required this.activeScorerIndexBefore,
    required this.playerStatesBefore,
  });
}

// ---------------------------------------------------------------------------
// Game phase
// ---------------------------------------------------------------------------

enum GamePhase { setup, playing, lastRound, gameOver }

// ---------------------------------------------------------------------------
// Main game state (ChangeNotifier for Provider)
// ---------------------------------------------------------------------------

class GameModel extends ChangeNotifier {
  // Setup
  List<Player> players = [];
  int winningScore = 10000;
  int openingScoreRequirement = 500;

  // Runtime state
  GamePhase phase = GamePhase.setup;

  /// The player whose position it is in the rotation sequence.
  /// After bank/bust, play advances to the player after this one.
  int rotationOwnerIndex = 0;

  /// The player currently holding the dice and scoring.
  /// May differ from rotationOwnerIndex when a pass has occurred.
  int activeScorerIndex = 0;

  int currentTurnScore = 0;

  // Last round tracking
  int? lastRoundStartPlayerIndex;
  bool lastRoundInProgress = false;

  // Undo stack
  final List<TurnAction> _undoStack = [];

  // ---------------------------------------------------------------------------
  // Convenience getters
  // ---------------------------------------------------------------------------

  /// The player whose turn it is in the rotation (may have passed the dice).
  Player get rotationOwner => players[rotationOwnerIndex];

  /// The player currently scoring (may be different after a pass).
  Player get activeScorer => players[activeScorerIndex];

  /// True when dice have been passed to someone other than the rotation owner.
  bool get isPassed => activeScorerIndex != rotationOwnerIndex;

  bool get activeScorerHasOpened => activeScorer.hasOpenedScoring;

  bool get meetsOpeningRequirement =>
      activeScorer.hasOpenedScoring ||
      currentTurnScore >= openingScoreRequirement;

  // Legacy accessor — used by UI that just wants "current player"
  Player get currentPlayer => activeScorer;
  int get currentPlayerIndex => activeScorerIndex;
  bool get currentPlayerHasOpened => activeScorerHasOpened;

  // ---------------------------------------------------------------------------
  // Setup
  // ---------------------------------------------------------------------------

  void initGame(List<String> playerNames, int targetScore) {
    players = playerNames.map((name) => Player(name: name.trim())).toList();
    winningScore = targetScore;
    rotationOwnerIndex = 0;
    activeScorerIndex = 0;
    currentTurnScore = 0;
    phase = GamePhase.playing;
    lastRoundInProgress = false;
    lastRoundStartPlayerIndex = null;
    _undoStack.clear();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Pass turn to another player
  // ---------------------------------------------------------------------------

  /// Pass the active scoring role to [targetIndex].
  /// Blocked if targetIndex == activeScorerIndex (can't pass to yourself).
  /// rotationOwnerIndex never changes during a pass chain.
  void passTurnTo(int targetIndex) {
    assert(targetIndex != activeScorerIndex, 'Cannot pass to yourself');
    if (targetIndex == activeScorerIndex) return;

    _pushUndo(TurnActionType.pass);
    activeScorerIndex = targetIndex;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Scoring action
  // ---------------------------------------------------------------------------

  void addCombo(ScoringCombo combo) {
    _pushUndo(TurnActionType.addScore, combo: combo);
    currentTurnScore += combo.points;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Bank — credits the ACTIVE SCORER, then advances from ROTATION OWNER
  // ---------------------------------------------------------------------------

  void bank() {
    if (!meetsOpeningRequirement) return;

    _pushUndo(TurnActionType.bank);

    // Credit goes to whoever is holding the dice
    players[activeScorerIndex] = activeScorer.copyWith(
      totalScore: activeScorer.totalScore + currentTurnScore,
      hasOpenedScoring: true,
    );

    _checkAndAdvance();
  }

  // ---------------------------------------------------------------------------
  // Bust — no credit, advance from rotation owner
  // ---------------------------------------------------------------------------

  void bust() {
    _pushUndo(TurnActionType.bust);
    _checkAndAdvance();
  }

  // ---------------------------------------------------------------------------
  // Internal: check last-round trigger, then advance rotation
  // ---------------------------------------------------------------------------

  void _checkAndAdvance() {
    // Check if the bank just pushed anyone over the winning score
    final anyOver = players.any((p) => p.totalScore >= winningScore);
    if (!lastRoundInProgress && anyOver) {
      lastRoundInProgress = true;
      // The rotation owner is the one whose "turn slot" triggered the last round
      lastRoundStartPlayerIndex = rotationOwnerIndex;
      phase = GamePhase.lastRound;
    }

    _advanceRotation();
  }

  void _advanceRotation() {
    currentTurnScore = 0;
    final nextIndex = (rotationOwnerIndex + 1) % players.length;

    if (lastRoundInProgress) {
      if (nextIndex == lastRoundStartPlayerIndex) {
        // Full circle completed — game over
        rotationOwnerIndex = nextIndex;
        activeScorerIndex = nextIndex;
        phase = GamePhase.gameOver;
        notifyListeners();
        return;
      }
    }

    rotationOwnerIndex = nextIndex;
    activeScorerIndex = nextIndex; // reset pass — new turn owner holds their own dice
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Undo
  // ---------------------------------------------------------------------------

  bool get canUndo => _undoStack.isNotEmpty;

  void undo() {
    if (_undoStack.isEmpty) return;
    final action = _undoStack.removeLast();

    // Restore player scores
    players = action.playerStatesBefore
        .map((p) => Player(
              name: p.name,
              totalScore: p.totalScore,
              hasOpenedScoring: p.hasOpenedScoring,
            ))
        .toList();

    currentTurnScore = action.pointsBefore;
    rotationOwnerIndex = action.rotationOwnerIndexBefore;
    activeScorerIndex = action.activeScorerIndexBefore;

    // Roll back last-round state if needed
    if (action.type == TurnActionType.bank ||
        action.type == TurnActionType.bust) {
      final anyOver = players.any((p) => p.totalScore >= winningScore);
      if (!anyOver) {
        lastRoundInProgress = false;
        lastRoundStartPlayerIndex = null;
        phase = GamePhase.playing;
      }
    }

    if (phase == GamePhase.gameOver) {
      phase = lastRoundInProgress ? GamePhase.lastRound : GamePhase.playing;
    }

    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Internal: snapshot for undo
  // ---------------------------------------------------------------------------

  void _pushUndo(TurnActionType type, {ScoringCombo? combo}) {
    _undoStack.add(TurnAction(
      type: type,
      pointsBefore: currentTurnScore,
      combo: combo,
      rotationOwnerIndexBefore: rotationOwnerIndex,
      activeScorerIndexBefore: activeScorerIndex,
      playerStatesBefore: players
          .map((p) => Player(
                name: p.name,
                totalScore: p.totalScore,
                hasOpenedScoring: p.hasOpenedScoring,
              ))
          .toList(),
    ));
  }

  // ---------------------------------------------------------------------------
  // Winner / standings
  // ---------------------------------------------------------------------------

  Player get winner =>
      players.reduce((a, b) => a.totalScore >= b.totalScore ? a : b);

  List<Player> get sortedPlayers {
    final sorted = List<Player>.from(players);
    sorted.sort((a, b) => b.totalScore.compareTo(a.totalScore));
    return sorted;
  }

  // ---------------------------------------------------------------------------
  // Reset
  // ---------------------------------------------------------------------------

  void resetGame() {
    players = [];
    rotationOwnerIndex = 0;
    activeScorerIndex = 0;
    currentTurnScore = 0;
    phase = GamePhase.setup;
    lastRoundInProgress = false;
    lastRoundStartPlayerIndex = null;
    _undoStack.clear();
    notifyListeners();
  }
}
