import 'player.dart';

/// Representa um widget dinâmico no tabuleiro
class DynamicBoardWidget {
  const DynamicBoardWidget({
    required this.cellId,
    required this.owner,
  });

  /// ID da célula onde o widget está
  final String cellId;

  /// Dono do widget (Jogador A-D)
  final Player owner;

  DynamicBoardWidget copyWith({
    String? cellId,
    Player? owner,
  }) {
    return DynamicBoardWidget(
      cellId: cellId ?? this.cellId,
      owner: owner ?? this.owner,
    );
  }
}