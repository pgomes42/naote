import 'package:flutter/material.dart';
import 'screens/game_screen.dart';

/// Ponto de entrada da aplicação Não Te Errites
void main() {
  runApp(const NaoTeErritesApp());
}

/// Widget raiz da aplicação
class NaoTeErritesApp extends StatelessWidget {
  const NaoTeErritesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Não Te Errites',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const GameScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
