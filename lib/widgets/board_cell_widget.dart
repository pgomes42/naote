import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/board_cell.dart';
import '../models/piece.dart';
import 'piece_token.dart';

/// Widget que representa visualmente uma célula do tabuleiro
class BoardCellWidget extends StatelessWidget {
  /// Define se os IDs das células devem ser exibidos (útil para desenvolvimento)
  static const bool showCellIds = false;
  /// Ângulo padrão do texto em graus (0 = horizontal)
  static const double defaultTextAngleDegrees = 0;
  
  const BoardCellWidget({
    super.key,
    required this.cell,
    required this.pieces,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
    required this.scale,
    this.customText,
    this.textAngleDegrees = defaultTextAngleDegrees,
    this.customWidget,
    this.widgetAlignment = Alignment.topCenter,
  });

  /// A célula do tabuleiro a ser renderizada
  final BoardCell cell;
  
  /// Lista de peças presentes nesta célula
  final List<Piece> pieces;
  
  /// Indica se esta célula está selecionada
  final bool selected;
  
  /// Callback para quando a célula é tocada
  final VoidCallback onTap;
  
  /// Callback para quando a célula é pressionada longamente
  final VoidCallback onLongPress;
  
  /// Fator de escala para ajuste responsivo
  final double scale;
  
  /// Texto customizado opcional para exibir na célula
  final String? customText;
  
  /// Ângulo do texto em graus (permite girar o texto)
  final double textAngleDegrees;
  
  /// Widget customizado para exibir na célula (pode ser imagem, ícone, animação, etc)
  final Widget? customWidget;
  
  /// Alinhamento do widget customizado (padrão: topo centralizado)
  final Alignment widgetAlignment;

  @override
  Widget build(BuildContext context) {
    final padding = 2 * scale.clamp(1.0, 4.0);
    final tokenSize = 20 * scale.clamp(1.0, 2.2);

    final baseColor = cell.isRed ? Colors.red : Colors.transparent;
    final selectionColor = selected
        ? (Color.lerp(Colors.transparent, Colors.blue, 0.12) ?? Colors.transparent)
        : null;
    final bgColor = selectionColor ?? baseColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        splashColor: Colors.transparent,
        hoverColor: Color.lerp(Colors.transparent, Colors.blue, 0.05),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.all(color: Colors.black, width: 0.5),
          ),
          child: Stack(
            children: [
              if (showCellIds) _buildCellIdLabel(),
              if (customWidget != null) _buildCustomWidget(),
              if (customText != null) _buildCustomText(),
              if (pieces.isNotEmpty) _buildPieces(tokenSize),
            ],
          ),
        ),
      ),
    );
  }

  /// Constrói o label com o ID da célula
  Widget _buildCellIdLabel() {
    return Positioned(
      top: 2,
      left: 2,
      child: Text(
        cell.id,
        style: TextStyle(
          fontSize: (6 * scale).clamp(4.0, 10.0),
          color: Colors.black54,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// Constrói o widget customizado
  Widget _buildCustomWidget() {
    return Align(
      alignment: widgetAlignment,
      child: customWidget!,
    );
  }

  /// Constrói o texto customizado centralizado
  Widget _buildCustomText() {
    return Center(
      child: Transform.rotate(
        angle: textAngleDegrees * math.pi / 180,
        child: Text(
          customText!,
          style: TextStyle(
            fontSize: (10 * scale).clamp(8.0, 16.0),
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  /// Constrói as peças na parte inferior da célula
  Widget _buildPieces(double tokenSize) {
    return Align(
      alignment: Alignment.center,
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 4,
        runSpacing: 4,
        children: pieces
            .map((p) => PieceToken(
                  player: p.player,
                  size: tokenSize,
                ))
            .toList(),
      ),
    );
  }
}
