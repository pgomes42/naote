import 'player.dart';

/// Representa uma peça de jogo de um determinado jogador
class Piece {
  Piece({
    required this.player,
    required this.id,
    this.currentCell,
    this.homeCell,
  });
  
  /// O jogador dono desta peça
  final Player player;
  
  /// Identificador único da peça (ex: R1, B2, G3, Y4)
  final String id;
  
  /// A célula onde a peça está atualmente
  String? currentCell;
  
  /// A casa inicial (home) desta peça
  final String? homeCell;
  
  /// Cria uma cópia da peça com opcionalmente novos valores
  Piece copyWith({
    Player? player,
    String? id,
    String? currentCell,
    String? homeCell,
  }) {
    return Piece(
      player: player ?? this.player,
      id: id ?? this.id,
      currentCell: currentCell ?? this.currentCell,
      homeCell: homeCell ?? this.homeCell,
    );
  }
  
  /// Move a peça para uma nova célula
  void moveTo(String cellId) {
    currentCell = cellId;
  }
  
  /// Move a peça para sua casa inicial
  void moveToHome() {
    if (homeCell != null) {
      currentCell = homeCell;
    }
  }
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Piece &&
          runtimeType == other.runtimeType &&
          player == other.player &&
          id == other.id;

  @override
  int get hashCode => Object.hash(player, id);
  
  @override
  String toString() => 'Piece(id: $id, player: $player, currentCell: $currentCell)';
}
