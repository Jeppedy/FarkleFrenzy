import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'models/game_model.dart';
import 'screens/setup_screen.dart';
import 'screens/game_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const FarkleFrenzyApp());
}

class FarkleFrenzyApp extends StatelessWidget {
  const FarkleFrenzyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GameModel(),
      child: MaterialApp(
        title: 'Farkle Frenzy',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const _AppRoot(),
      ),
    );
  }
}

class _AppRoot extends StatelessWidget {
  const _AppRoot();

  @override
  Widget build(BuildContext context) {
    return Consumer<GameModel>(
      builder: (context, game, _) {
        if (game.phase == GamePhase.setup) {
          return const SetupScreen();
        }
        return const GameScreen();
      },
    );
  }
}
