import 'player.dart';

/// Representa uma peça de jogo de um determinado jogador
class Piece {
  const Piece({required this.player});
  
  /// O jogador dono desta peça
  final Player player;
  
  /// Cria uma cópia da peça com opcionalmente um novo jogador
  Piece copyWith({Player? player}) {
    return Piece(
      player: player ?? this.player,
    );
  }
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Piece &&
          runtimeType == other.runtimeType &&
          player == other.player;

  @override
  int get hashCode => player.hashCode;
  
  @override
  String toString() => 'Piece(player: $player)';
}
