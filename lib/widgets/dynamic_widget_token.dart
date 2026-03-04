import 'package:flutter/material.dart';
import '../models/player.dart';
import 'pin_piece_widget.dart';

/// Widget visual do objeto dinâmico como um pin flutuante
class DynamicWidgetToken extends StatelessWidget {
  const DynamicWidgetToken({
    super.key,
    required this.owner,
    required this.size,
    required this.index,
    this.isSelected = false,
  });

  final Player owner;
  final double size;
  final int index; // 0 ou 1 para identificar qual peça
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return PinPieceWidget(
      color: PlayerHelper.getColor(owner),
      label: '${index + 1}',
      size: size,
      isSelected: isSelected,
    );
  }
}
