import 'package:flutter/material.dart';

/// Enumeração dos jogadores disponíveis no jogo
enum Player { red, blue, green, yellow }

/// Classe auxiliar para operações relacionadas aos jogadores
class PlayerHelper {
  /// Retorna a cor associada a um jogador
  static Color getColor(Player player) {
    switch (player) {
      case Player.red:
        return Colors.red;
      case Player.blue:
        return Colors.blue;
      case Player.green:
        return Colors.green;
      case Player.yellow:
        return Colors.amber;
    }
  }

  /// Retorna o rótulo/label de um jogador
  static String getLabel(Player player) {
    switch (player) {
      case Player.red:
        return 'R';
      case Player.blue:
        return 'B';
      case Player.green:
        return 'G';
      case Player.yellow:
        return 'Y';
    }
  }
  
  /// Retorna o nome completo do jogador
  static String getName(Player player) {
    switch (player) {
      case Player.red:
        return 'Vermelho';
      case Player.blue:
        return 'Azul';
      case Player.green:
        return 'Verde';
      case Player.yellow:
        return 'Amarelo';
    }
  }
}
