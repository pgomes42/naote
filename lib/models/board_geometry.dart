import 'package:flutter/material.dart';
import 'board_cell.dart';

/// Gerencia a geometria e layout do tabuleiro de jogo
class BoardGeometry {
  /// Número de células por braço do tabuleiro
  static const int cellsPerArm = 10;
  
  /// Número de sub-células por célula
  static const int subCellsPerCell = 3;

  BoardGeometry(Size size)
      : size = Size.square(size.shortestSide),
        scale = size.shortestSide / 320,
        squareSize = (size.shortestSide / 320) * 65,
        sideWidth = 13.5 * (size.shortestSide / 320),
        step = 13.5 * (size.shortestSide / 320),
        center = Offset(size.shortestSide / 2, size.shortestSide / 2);

  /// Tamanho total do tabuleiro
  final Size size;
  
  /// Fator de escala baseado no tamanho
  final double scale;
  
  /// Tamanho do quadrado central
  final double squareSize;
  
  /// Altura/largura de cada passo/célula
  final double step;
  
  /// Largura das células laterais
  final double sideWidth;
  
  /// Ponto central do tabuleiro
  final Offset center;

  /// Retorna o retângulo do centro do tabuleiro
  Rect get centerRect {
    final centerSize = (squareSize - 2 * sideWidth) * 0.72;
    return Rect.fromCenter(
      center: center,
      width: centerSize,
      height: centerSize,
    );
  }

  /// Constrói e retorna todas as células do tabuleiro
  List<BoardCell> buildCells() {
    final cells = <BoardCell>[];

    // Centro
    cells.add(BoardCell(
      id: 'CENTER',
      rect: centerRect,
      isVertical: true,
      isRed: false,
    ));

    // Adiciona células dos quatro braços
    cells.addAll(_buildTopArm());
    cells.addAll(_buildBottomArm());
    cells.addAll(_buildLeftArm());
    cells.addAll(_buildRightArm());

    return cells;
  }

  /// Constrói as células do braço superior (A)
  List<BoardCell> _buildTopArm() {
    final cells = <BoardCell>[];
    final centerRect_Calc = centerRect;
    final centerSizeVal = centerRect_Calc.width;
    final topOrigin = Offset(
      centerRect_Calc.left - sideWidth,
      centerRect_Calc.top - step * cellsPerArm,
    );

    for (int i = 0; i < cellsPerArm; i++) {
      final labelIdx = cellsPerArm + 1 - i;
      final cellY = topOrigin.dy + step * i;
      final globalNum = i + 1;

      if (labelIdx != 2) {
        cells.add(BoardCell(
          id: 'A${globalNum}L',
          rect: Rect.fromLTWH(topOrigin.dx, cellY, sideWidth, step),
          isVertical: true,
          isRed: labelIdx == 7,
        ));
      }
      cells.add(BoardCell(
        id: 'A${globalNum}C',
        rect: Rect.fromLTWH(topOrigin.dx + sideWidth, cellY, centerSizeVal, step),
        isVertical: true,
        isRed: false,
      ));
      if (labelIdx != 2) {
        cells.add(BoardCell(
          id: 'A${globalNum}R',
          rect: Rect.fromLTWH(topOrigin.dx + sideWidth + centerSizeVal, cellY, sideWidth, step),
          isVertical: true,
          isRed: labelIdx == 7,
        ));
      }
    }

    return cells;
  }

  /// Constrói as células do braço inferior (B)
  List<BoardCell> _buildBottomArm() {
    final cells = <BoardCell>[];
    final centerRect_Calc = centerRect;
    final centerSizeVal = centerRect_Calc.width;
    final bottomOrigin = Offset(centerRect_Calc.left - sideWidth, centerRect_Calc.bottom);

    for (int i = 0; i < cellsPerArm; i++) {
      final labelIdx = i + 2;
      final cellY = bottomOrigin.dy + step * i;
      final globalNum = i + 1;

      if (labelIdx != 2) {
        cells.add(BoardCell(
          id: 'B${globalNum}L',
          rect: Rect.fromLTWH(bottomOrigin.dx, cellY, sideWidth, step),
          isVertical: true,
          isRed: labelIdx == 7,
        ));
      }
      cells.add(BoardCell(
        id: 'B${globalNum}C',
        rect: Rect.fromLTWH(bottomOrigin.dx + sideWidth, cellY, centerSizeVal, step),
        isVertical: true,
        isRed: false,
      ));
      if (labelIdx != 2) {
        cells.add(BoardCell(
          id: 'B${globalNum}R',
          rect: Rect.fromLTWH(bottomOrigin.dx + sideWidth + centerSizeVal, cellY, sideWidth, step),
          isVertical: true,
          isRed: labelIdx == 7,
        ));
      }
    }

    return cells;
  }

  /// Constrói as células do braço esquerdo (C)
  List<BoardCell> _buildLeftArm() {
    final cells = <BoardCell>[];
    final centerRect_Calc = centerRect;
    final centerSizeVal = centerRect_Calc.width;
    final leftOrigin = Offset(
      centerRect_Calc.left - step * cellsPerArm,
      centerRect_Calc.top - sideWidth,
    );

    for (int i = 0; i < cellsPerArm; i++) {
      final labelIdx = cellsPerArm + 1 - i;
      final cellX = leftOrigin.dx + step * i;
      final globalNum = i + 1;

      cells.add(BoardCell(
        id: 'C${globalNum}L',
        rect: Rect.fromLTWH(cellX, leftOrigin.dy, step, sideWidth),
        isVertical: false,
        isRed: labelIdx == 7,
      ));
      cells.add(BoardCell(
        id: 'C${globalNum}C',
        rect: Rect.fromLTWH(cellX, leftOrigin.dy + sideWidth, step, centerSizeVal),
        isVertical: false,
        isRed: false,
      ));
      cells.add(BoardCell(
        id: 'C${globalNum}R',
        rect: Rect.fromLTWH(cellX, leftOrigin.dy + sideWidth + centerSizeVal, step, sideWidth),
        isVertical: false,
        isRed: labelIdx == 7,
      ));
    }

    return cells;
  }

  /// Constrói as células do braço direito (D)
  List<BoardCell> _buildRightArm() {
    final cells = <BoardCell>[];
    final centerRect_Calc = centerRect;
    final centerSizeVal = centerRect_Calc.width;
    final rightOrigin = Offset(centerRect_Calc.right, centerRect_Calc.top - sideWidth);

    for (int i = 0; i < cellsPerArm; i++) {
      final labelIdx = i + 2;
      final cellX = rightOrigin.dx + step * i;
      final globalNum = i + 1;

      cells.add(BoardCell(
        id: 'D${globalNum}L',
        rect: Rect.fromLTWH(cellX, rightOrigin.dy, step, sideWidth),
        isVertical: false,
        isRed: labelIdx == 7,
      ));
      cells.add(BoardCell(
        id: 'D${globalNum}C',
        rect: Rect.fromLTWH(cellX, rightOrigin.dy + sideWidth, step, centerSizeVal),
        isVertical: false,
        isRed: false,
      ));
      cells.add(BoardCell(
        id: 'D${globalNum}R',
        rect: Rect.fromLTWH(cellX, rightOrigin.dy + sideWidth + centerSizeVal, step, sideWidth),
        isVertical: false,
        isRed: labelIdx == 7,
      ));
    }

    return cells;
  }
  
  /// Calcula a posição central de uma célula
  Offset getCellCenter(BoardCell cell) {
    return cell.rect.center;
  }
  
  /// Verifica se um ponto está dentro de uma célula
  bool isPointInCell(BoardCell cell, Offset point) {
    return cell.rect.contains(point);
  }
}
