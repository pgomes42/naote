import 'package:flutter/material.dart';
import '../models/player.dart';
import 'pin_piece_widget.dart';

/// Widget que representa visualmente uma peça de jogo como um pin flutuante
class PieceToken extends StatelessWidget {
  const PieceToken({
    super.key,
    required this.player,
    required this.size,
  });

  /// O jogador dono desta peça
  final Player player;
  
  /// Tamanho do token (diâmetro do círculo)
  final double size;

  @override
  Widget build(BuildContext context) {
    return PinPieceWidget(
      color: PlayerHelper.getColor(player),
      label: PlayerHelper.getLabel(player),
      size: size,
      isSelected: false,
    );
  }
}
