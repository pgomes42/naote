import 'package:flutter/material.dart';
import '../models/player.dart';

/// Widget visual do objeto dinâmico
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
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: PlayerHelper.getColor(owner),
        shape: BoxShape.circle,
        border: isSelected
            ? Border.all(
                color: Colors.white,
                width: 3,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: PlayerHelper.getColor(owner).withOpacity(0.6),
            blurRadius: 8,
            spreadRadius: isSelected ? 4 : 2,
          ),
        ],
      ),
      child: Center(
        child: Text(
          '${index + 1}',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: (size * 0.5).clamp(10.0, 20.0),
          ),
        ),
      ),
    );
  }
}