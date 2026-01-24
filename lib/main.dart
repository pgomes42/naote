import 'package:flutter/material.dart';

void main() {
  runApp(const NaoTeErritesApp());
}

class NaoTeErritesApp extends StatelessWidget {
  const NaoTeErritesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Não Te Errites',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const GameScreen(),
    );
  }
}

enum Player { red, blue, green, yellow }

Color playerColor(Player player) {
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

String playerLabel(Player player) {
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

class Piece {
  const Piece({required this.player});
  final Player player;
}

class BoardCell {
  const BoardCell({
    required this.id,
    required this.rect,
    required this.isVertical,
    required this.isRed,
  });

  final String id;
  final Rect rect;
  final bool isVertical;
  final bool isRed;
}

class BoardGeometry {
  static const int cellsPerArm = 10;
  static const int subCellsPerCell = 3;

  BoardGeometry(Size size)
      : size = Size.square(size.shortestSide),
        scale = size.shortestSide / 320,
        squareSize = (size.shortestSide / 320) * 65, // reduz centro/faixas centrais pela metade (~35mm úteis)
        sideWidth = 15 * (size.shortestSide / 320), // laterais 15mm base
        step = 15 * (size.shortestSide / 320), // altura = largura das laterais (grids quadradas)
        center = Offset(size.shortestSide / 2, size.shortestSide / 2);

  final Size size;
  final double scale;
  final double squareSize;
  final double step;
  final double sideWidth;
  final Offset center;

  Rect get centerRect {
    final centerSize = (squareSize - 2 * sideWidth) * 0.9; // reduz 5% de cada lado (10% total)
    return Rect.fromCenter(
      center: center,
      width: centerSize,
      height: centerSize,
    );
  }

  List<BoardCell> buildCells() {
    final cells = <BoardCell>[];

    // Center
    cells.add(BoardCell(id: 'CENTER', rect: centerRect, isVertical: true, isRed: false));

    // Top A: 9 células no braço externo + A1 na borda superior do centro
    final inset = 10 * scale;
    final centerRect_Calc = centerRect;
    final topOrigin = Offset(center.dx - squareSize / 2, centerRect_Calc.top - step * (cellsPerArm - 1)); // braços conectam direto ao centro (topo)
    // A10 a A2: braço externo (9 células)
    for (int i = 0; i < cellsPerArm - 1; i++) {
      final labelIdx = cellsPerArm - i; // A10 no topo, A2 próximo ao centro
      final cellY = topOrigin.dy + step * i;
      final centerWidth = (squareSize - 2 * sideWidth) * 0.9; // reduz 5% de cada lado

      cells.add(BoardCell(
        id: 'A0$labelIdx',
        rect: Rect.fromLTWH(topOrigin.dx, cellY, sideWidth, step),
        isVertical: true,
        isRed: labelIdx % 5 == 0 && labelIdx != 5,
      ));
      cells.add(BoardCell(
        id: 'A2$labelIdx',
        rect: Rect.fromLTWH(topOrigin.dx + sideWidth, cellY, centerWidth, step),
        isVertical: true,
        isRed: false,
      ));
      cells.add(BoardCell(
        id: 'A1$labelIdx',
        rect: Rect.fromLTWH(topOrigin.dx + sideWidth + centerWidth, cellY, sideWidth, step),
        isVertical: true,
        isRed: labelIdx % 5 == 0 && labelIdx != 5,
      ));
    }
    // Braços começam direto no centerRect sem células de borda

    // Bottom B: B1 na borda inferior do centro (10mm) + 9 células no braço externo
    final b1Y = centerRect_Calc.bottom;
    final bottomOrigin = Offset(center.dx - squareSize / 2, b1Y); // começa exatamente onde centerRect termina embaixo
    final centerWidthB = (squareSize - 2 * sideWidth) * 0.9; // reduz 5% de cada lado
    // B2 a B10: braço externo (9 células)
    for (int i = 0; i < cellsPerArm - 1; i++) {
      final labelIdx = i + 2;
      final cellY = bottomOrigin.dy + step * i;
      cells.add(BoardCell(
        id: 'B0$labelIdx',
        rect: Rect.fromLTWH(bottomOrigin.dx, cellY, sideWidth, step),
        isVertical: true,
        isRed: labelIdx % 5 == 0 && labelIdx != 5,
      ));
      cells.add(BoardCell(
        id: 'B2$labelIdx',
        rect: Rect.fromLTWH(bottomOrigin.dx + sideWidth, cellY, centerWidthB, step),
        isVertical: true,
        isRed: false,
      ));
      cells.add(BoardCell(
        id: 'B1$labelIdx',
        rect: Rect.fromLTWH(bottomOrigin.dx + sideWidth + centerWidthB, cellY, sideWidth, step),
        isVertical: true,
        isRed: labelIdx % 5 == 0 && labelIdx != 5,
      ));
    }

    // Left C: 9 células no braço externo + C1 na borda esquerda do centro
    final centerHeight = (squareSize - 2 * sideWidth) * 0.9; // reduz 5% de cada lado
    final c1X = centerRect_Calc.left;
    final leftOrigin = Offset(c1X - step * (cellsPerArm - 1), center.dy - squareSize / 2); // braços conectam direto ao centro (esquerda)
    for (int i = 0; i < cellsPerArm - 1; i++) {
      final labelIdx = cellsPerArm - i; // C10 no extremo, C2 próximo ao centro
      final cellX = leftOrigin.dx + step * i;
      cells.add(BoardCell(
        id: 'C0$labelIdx',
        rect: Rect.fromLTWH(cellX, leftOrigin.dy, step, sideWidth),
        isVertical: false,
        isRed: labelIdx % 5 == 0 && labelIdx != 5,
      ));
      cells.add(BoardCell(
        id: 'C2$labelIdx',
        rect: Rect.fromLTWH(cellX, leftOrigin.dy + sideWidth, step, centerHeight),
        isVertical: false,
        isRed: false,
      ));
      cells.add(BoardCell(
        id: 'C1$labelIdx',
        rect: Rect.fromLTWH(cellX, leftOrigin.dy + sideWidth + centerHeight, step, sideWidth),
        isVertical: false,
        isRed: labelIdx % 5 == 0 && labelIdx != 5,
      ));
    }

    // Right D: braço começa exatamente na borda direita do centro e segue para a direita
    final d1X = centerRect_Calc.right;
    final rightOrigin = Offset(d1X, center.dy - squareSize / 2);
    // D2 a D10: braço externo (9 células)
    for (int i = 0; i < cellsPerArm - 1; i++) {
      final labelIdx = i + 2;
      final cellX = rightOrigin.dx + step * i;
      cells.add(BoardCell(
        id: 'D0$labelIdx',
        rect: Rect.fromLTWH(cellX, rightOrigin.dy, step, sideWidth),
        isVertical: false,
        isRed: labelIdx % 5 == 0 && labelIdx != 5,
      ));
      cells.add(BoardCell(
        id: 'D2$labelIdx',
        rect: Rect.fromLTWH(cellX, rightOrigin.dy + sideWidth, step, centerHeight),
        isVertical: false,
        isRed: false,
      ));
      cells.add(BoardCell(
        id: 'D1$labelIdx',
        rect: Rect.fromLTWH(cellX, rightOrigin.dy + sideWidth + centerHeight, step, sideWidth),
        isVertical: false,
        isRed: labelIdx % 5 == 0 && labelIdx != 5,
      ));
    }

    return cells;
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  String? _selectedCell;
  Player _currentPlayer = Player.red;
  final Map<String, List<Piece>> _piecesByCell = {};

  void _addPiece(String cellId) {
    setState(() {
      _selectedCell = cellId;
      final pieces = _piecesByCell.putIfAbsent(cellId, () => []);
      pieces.add(Piece(player: _currentPlayer));
    });
  }

  void _removePiece(String cellId) {
    final pieces = _piecesByCell[cellId];
    if (pieces == null || pieces.isEmpty) return;
    setState(() {
      _selectedCell = cellId;
      pieces.removeLast();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[700],
        title: const Text('Não Te Errites', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final boardSize = constraints.biggest.shortestSide.clamp(300.0, 800.0);
          final geometry = BoardGeometry(Size.square(boardSize));
          final cells = geometry.buildCells();

          return Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820, maxHeight: 820),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: geometry.size.width,
                        height: geometry.size.height,
                        child: Stack(
                          children: [
                            // Fundo
                            Positioned.fill(
                              child: Container(color: Colors.white),
                            ),
                            // Células como componentes
                            ...cells.map(
                              (cell) => Positioned(
                                left: cell.rect.left,
                                top: cell.rect.top,
                                width: cell.rect.width,
                                height: cell.rect.height,
                                child: BoardCellWidget(
                                  cell: cell,
                                  pieces: _piecesByCell[cell.id] ?? const [],
                                  selected: _selectedCell == cell.id,
                                  onTap: () => _addPiece(cell.id),
                                  onLongPress: () => _removePiece(cell.id),
                                  scale: geometry.scale,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text('Toque para adicionar peça do jogador ativo. Segure para remover a última peça.'),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class BoardCellWidget extends StatelessWidget {
  const BoardCellWidget({
    super.key,
    required this.cell,
    required this.pieces,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
    required this.scale,
  });

  final BoardCell cell;
  final List<Piece> pieces;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final padding = 2 * scale.clamp(1.0, 4.0);
    final tokenSize = 14 * scale.clamp(1.0, 2.2);

    final baseColor = cell.isRed
        ? Colors.red
        : Colors.transparent;
    final selectionColor = selected ? (Color.lerp(Colors.transparent, Colors.blue, 0.12) ?? Colors.transparent) : null;
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
              // Cell ID label
              Positioned(
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
              ),
              // Pieces
              Align(
                alignment: Alignment.center,
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 4,
                  runSpacing: 4,
                  children: pieces
                      .map((p) => _PieceToken(
                            player: p.player,
                            size: tokenSize,
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PieceToken extends StatelessWidget {
  const _PieceToken({required this.player, required this.size});

  final Player player;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: playerColor(player),
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
    );
  }
}
