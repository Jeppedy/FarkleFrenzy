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
  bool hasOpenedScoring; // Has the player met the 500-pt opening requirement?

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

enum TurnActionType { addScore, bank, bust }

class TurnAction {
  final TurnActionType type;
  final int pointsBefore; // turn score before this action
  final ScoringCombo? combo; // which combo was added (null for bank/bust)
  final int playerIndexBefore; // which player was active
  final List<Player> playerStatesBefore; // snapshot of all player scores

  TurnAction({
    required this.type,
    required this.pointsBefore,
    this.combo,
    required this.playerIndexBefore,
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
  int currentPlayerIndex = 0;
  int currentTurnScore = 0;

  // Last round tracking
  int? lastRoundStartPlayerIndex; // the player who triggered the last round
  bool lastRoundInProgress = false;

  // Undo stack
  final List<TurnAction> _undoStack = [];

  // ---------------------------------------------------------------------------
  // Setup helpers
  // ---------------------------------------------------------------------------

  void initGame(List<String> playerNames, int targetScore) {
    players = playerNames
        .map((name) => Player(name: name.trim()))
        .toList();
    winningScore = targetScore;
    currentPlayerIndex = 0;
    currentTurnScore = 0;
    phase = GamePhase.playing;
    lastRoundInProgress = false;
    lastRoundStartPlayerIndex = null;
    _undoStack.clear();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Accessors
  // ---------------------------------------------------------------------------

  Player get currentPlayer => players[currentPlayerIndex];

  bool get currentPlayerHasOpened => currentPlayer.hasOpenedScoring;

  /// Returns true if the current turn score meets the opening requirement
  /// (or the player has already opened).
  bool get meetsOpeningRequirement =>
      currentPlayer.hasOpenedScoring ||
      currentTurnScore >= openingScoreRequirement;

  String get phaseLabel {
    if (lastRoundInProgress) return 'LAST ROUND';
    return '';
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
  // Bank
  // ---------------------------------------------------------------------------

  void bank() {
    if (!meetsOpeningRequirement) return; // enforce opening rule

    _pushUndo(TurnActionType.bank);

    players[currentPlayerIndex] = currentPlayer.copyWith(
      totalScore: currentPlayer.totalScore + currentTurnScore,
      hasOpenedScoring: true,
    );

    _checkAndAdvance();
  }

  // ---------------------------------------------------------------------------
  // Bust
  // ---------------------------------------------------------------------------

  void bust() {
    _pushUndo(TurnActionType.bust);
    // Turn score is lost — do NOT add to player total
    _checkAndAdvance();
  }

  // ---------------------------------------------------------------------------
  // Internal: advance turn / handle last round logic
  // ---------------------------------------------------------------------------

  void _checkAndAdvance() {
    // Check if any player just crossed the winning threshold
    final justBanked = players[currentPlayerIndex];
    if (!lastRoundInProgress && justBanked.totalScore >= winningScore) {
      // Trigger last round — everyone else gets one more turn
      lastRoundInProgress = true;
      lastRoundStartPlayerIndex = currentPlayerIndex;
      phase = GamePhase.lastRound;
    }

    _advancePlayer();
  }

  void _advancePlayer() {
    currentTurnScore = 0;
    final nextIndex = (currentPlayerIndex + 1) % players.length;

    if (lastRoundInProgress) {
      // Last round ends when we cycle back to the player who triggered it
      if (nextIndex == lastRoundStartPlayerIndex) {
        currentPlayerIndex = nextIndex;
        phase = GamePhase.gameOver;
        notifyListeners();
        return;
      }
    }

    currentPlayerIndex = nextIndex;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Undo
  // ---------------------------------------------------------------------------

  bool get canUndo => _undoStack.isNotEmpty;

  void undo() {
    if (_undoStack.isEmpty) return;
    final action = _undoStack.removeLast();

    // Restore player states
    players = action.playerStatesBefore
        .map((p) => Player(
              name: p.name,
              totalScore: p.totalScore,
              hasOpenedScoring: p.hasOpenedScoring,
            ))
        .toList();

    // Restore turn score and player index
    currentTurnScore = action.pointsBefore;
    currentPlayerIndex = action.playerIndexBefore;

    // If undoing a bank/bust that triggered last round, roll back last round state
    if (action.type == TurnActionType.bank ||
        action.type == TurnActionType.bust) {
      // Re-evaluate last round state from restored scores
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
      playerIndexBefore: currentPlayerIndex,
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
  // Winner determination
  // ---------------------------------------------------------------------------

  Player get winner {
    return players.reduce(
        (a, b) => a.totalScore >= b.totalScore ? a : b);
  }

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
    currentPlayerIndex = 0;
    currentTurnScore = 0;
    phase = GamePhase.setup;
    lastRoundInProgress = false;
    lastRoundStartPlayerIndex = null;
    _undoStack.clear();
    notifyListeners();
  }
}
