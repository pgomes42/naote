import 'package:flutter/material.dart';
import '../models/player.dart';

/// Widget que representa visualmente uma peça de jogo
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
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: PlayerHelper.getColor(player),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.black,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          PlayerHelper.getLabel(player),
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.6,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
