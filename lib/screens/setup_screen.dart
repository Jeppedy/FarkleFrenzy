import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/game_model.dart';
import '../theme/app_theme.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  int? _playerCount;
  final _countController = TextEditingController();
  final _targetController = TextEditingController(text: '10000');
  final List<TextEditingController> _nameControllers = [];
  final _formKey = GlobalKey<FormState>();
  bool _showNames = false;

  @override
  void dispose() {
    _countController.dispose();
    _targetController.dispose();
    for (final c in _nameControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _setPlayerCount(int count) {
    setState(() {
      _playerCount = count;
      _nameControllers.clear();
      for (int i = 0; i < count; i++) {
        _nameControllers.add(TextEditingController(text: 'Player ${i + 1}'));
      }
      _showNames = true;
    });
  }

  void _startGame() {
    if (!_formKey.currentState!.validate()) return;
    final names = _nameControllers.map((c) => c.text.trim()).toList();
    final target = int.tryParse(_targetController.text) ?? 10000;
    context.read<GameModel>().initGame(names, target);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎲 FARKLE FRENZY'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo/Header area
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      Text(
                        '🎲',
                        style: TextStyle(fontSize: 64),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'FARKLE FRENZY',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentGold,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Score Tracker',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white54,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),

                // Winning score
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.emoji_events, color: AppTheme.accentGold),
                            const SizedBox(width: 8),
                            Text(
                              'Winning Score',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.accentGold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _targetController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: const InputDecoration(
                            labelText: 'Target Score',
                            hintText: '10000',
                          ),
                          validator: (v) {
                            final n = int.tryParse(v ?? '');
                            if (n == null || n < 1000) {
                              return 'Enter a valid score (minimum 1000)';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Player count selector
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.people, color: AppTheme.accentGold),
                            const SizedBox(width: 8),
                            Text(
                              'Number of Players',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.accentGold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: List.generate(7, (i) {
                            final count = i + 2; // 2–8 players
                            final selected = _playerCount == count;
                            return GestureDetector(
                              onTap: () => _setPlayerCount(count),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: selected
                                      ? AppTheme.accentGold
                                      : AppTheme.surfaceCard,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: selected
                                        ? AppTheme.accentGold
                                        : Colors.white24,
                                    width: selected ? 2 : 1,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    '$count',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: selected
                                          ? Colors.black
                                          : Colors.white70,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ),

                // Player name inputs
                if (_showNames) ...[
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.badge, color: AppTheme.accentGold),
                              const SizedBox(width: 8),
                              Text(
                                'Player Names',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.accentGold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...List.generate(_nameControllers.length, (i) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: TextFormField(
                                controller: _nameControllers[i],
                                textCapitalization: TextCapitalization.words,
                                decoration: InputDecoration(
                                  labelText: 'Player ${i + 1}',
                                  prefixIcon: CircleAvatar(
                                    radius: 14,
                                    backgroundColor: _playerColors[i % _playerColors.length],
                                    child: Text(
                                      '${i + 1}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Enter a player name';
                                  }
                                  return null;
                                },
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Start button
                if (_showNames)
                  ElevatedButton.icon(
                    onPressed: _startGame,
                    icon: const Icon(Icons.play_arrow, size: 28),
                    label: const Text(
                      'START GAME',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentGold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                // Rules reminder
                Card(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '📋 House Rules',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.accentGold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _ruleText('Opening: Must score 500+ pts to get on the board'),
                        _ruleText('Last Round: Once a player exceeds the target,\n  all others get one final turn'),
                        _ruleText('Winner: Highest score after last round wins'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _ruleText(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Text(
        '• $text',
        style: const TextStyle(fontSize: 12, color: Colors.white70),
      ),
    );
  }
}

const List<Color> _playerColors = [
  Color(0xFFE53935), // Red
  Color(0xFF1E88E5), // Blue
  Color(0xFF43A047), // Green
  Color(0xFFFB8C00), // Orange
  Color(0xFF8E24AA), // Purple
  Color(0xFF00ACC1), // Cyan
  Color(0xFFFFB300), // Amber
  Color(0xFF6D4C41), // Brown
];
