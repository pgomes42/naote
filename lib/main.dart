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
        squareSize = (size.shortestSide / 320) * 100,
        step = ((size.shortestSide / 320) * 100) / 9, // 9 células nos braços externos
        sideWidth = 30 * (size.shortestSide / 320), // laterais 30mm
        center = Offset(size.shortestSide / 2, size.shortestSide / 2);

  final Size size;
  final double scale;
  final double squareSize;
  final double step;
  final double sideWidth;
  final Offset center;

  Rect get centerRect {
    final inset = 10 * scale; // 10mm de cada lado
    return Rect.fromCenter(
      center: center,
      width: squareSize - 2 * inset,
      height: squareSize - 2 * inset,
    );
  }

  List<BoardCell> buildCells() {
    final cells = <BoardCell>[];

    // Center
    cells.add(BoardCell(id: 'CENTER', rect: centerRect, isVertical: true, isRed: false));

    // Top A: 9 células no braço externo + A1 na borda superior do centro
    final topOrigin = Offset(center.dx - squareSize / 2, center.dy - squareSize / 2 - squareSize);
    final inset = 10 * scale;
    // A10 a A2: braço externo (9 células)
    for (int i = 0; i < cellsPerArm - 1; i++) {
      final labelIdx = cellsPerArm - i; // A10 no topo, A2 próximo ao centro
      final cellY = topOrigin.dy + step * i;
      final centerWidth = squareSize - 2 * sideWidth;

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
    // A1: borda superior do centro (10mm)
    final a1Y = center.dy - squareSize / 2;
    final centerWidth = squareSize - 2 * sideWidth;
    cells.add(BoardCell(
      id: 'A01',
      rect: Rect.fromLTWH(topOrigin.dx, a1Y, sideWidth, inset),
      isVertical: true,
      isRed: false,
    ));
    cells.add(BoardCell(
      id: 'A21',
      rect: Rect.fromLTWH(topOrigin.dx + sideWidth, a1Y, centerWidth, inset),
      isVertical: true,
      isRed: false,
    ));
    cells.add(BoardCell(
      id: 'A11',
      rect: Rect.fromLTWH(topOrigin.dx + sideWidth + centerWidth, a1Y, sideWidth, inset),
      isVertical: true,
      isRed: false,
    ));

    // Bottom B: B1 na borda inferior do centro (10mm) + 9 células no braço externo
    final bottomOrigin = Offset(center.dx - squareSize / 2, center.dy + squareSize / 2);
    final b1Y = center.dy + squareSize / 2 - inset;
    final centerWidthB = squareSize - 2 * sideWidth;
    cells.add(BoardCell(
      id: 'B01',
      rect: Rect.fromLTWH(bottomOrigin.dx, b1Y, sideWidth, inset),
      isVertical: true,
      isRed: false,
    ));
    cells.add(BoardCell(
      id: 'B21',
      rect: Rect.fromLTWH(bottomOrigin.dx + sideWidth, b1Y, centerWidthB, inset),
      isVertical: true,
      isRed: false,
    ));
    cells.add(BoardCell(
      id: 'B11',
      rect: Rect.fromLTWH(bottomOrigin.dx + sideWidth + centerWidthB, b1Y, sideWidth, inset),
      isVertical: true,
      isRed: false,
    ));
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
    final leftOrigin = Offset(center.dx - squareSize / 2 - squareSize, center.dy - squareSize / 2);
    final centerHeight = squareSize - 2 * sideWidth;
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
    // C1: borda esquerda do centro (10mm)
    final c1X = center.dx - squareSize / 2;
    cells.add(BoardCell(
      id: 'C01',
      rect: Rect.fromLTWH(c1X, leftOrigin.dy, inset, sideWidth),
      isVertical: false,
      isRed: false,
    ));
    cells.add(BoardCell(
      id: 'C21',
      rect: Rect.fromLTWH(c1X, leftOrigin.dy + sideWidth, inset, centerHeight),
      isVertical: false,
      isRed: false,
    ));
    cells.add(BoardCell(
      id: 'C11',
      rect: Rect.fromLTWH(c1X, leftOrigin.dy + sideWidth + centerHeight, inset, sideWidth),
      isVertical: false,
      isRed: false,
    ));

    // Right D: D1 na borda direita do centro (10mm) + 9 células no braço externo
    final rightOrigin = Offset(center.dx + squareSize / 2, center.dy - squareSize / 2);
    final d1X = center.dx + squareSize / 2 - inset;
    cells.add(BoardCell(
      id: 'D01',
      rect: Rect.fromLTWH(d1X, rightOrigin.dy, inset, sideWidth),
      isVertical: false,
      isRed: false,
    ));
    cells.add(BoardCell(
      id: 'D21',
      rect: Rect.fromLTWH(d1X, rightOrigin.dy + sideWidth, inset, centerHeight),
      isVertical: false,
      isRed: false,
    ));
    cells.add(BoardCell(
      id: 'D11',
      rect: Rect.fromLTWH(d1X, rightOrigin.dy + sideWidth + centerHeight, inset, sideWidth),
      isVertical: false,
      isRed: false,
    ));
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
                      _PlayerSelector(
                        current: _currentPlayer,
                        onChanged: (p) => setState(() => _currentPlayer = p),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: geometry.size.width,
                        height: geometry.size.height,
                        child: Stack(
                          children: [
                            // Fundo
                            Positioned.fill(
                              child: Container(color: Colors.white),
                            ),
                            // Linhas internas cruzando o centro (10mm de cada lado)
                            ..._buildCenterLines(geometry),
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

  List<Widget> _buildCenterLines(BoardGeometry geo) {
    final inset = 10 * geo.scale;
    final linePaint = BorderSide(color: Colors.black, width: 0.5);

    return [
      // Vertical esquerdo
      Positioned(
        left: geo.center.dx - geo.squareSize / 2 + inset - linePaint.width / 2,
        top: geo.center.dy - geo.squareSize / 2 - geo.squareSize,
        width: linePaint.width,
        height: geo.squareSize * 3,
        child: Container(color: linePaint.color),
      ),
      // Vertical direito
      Positioned(
        left: geo.center.dx + geo.squareSize / 2 - inset - linePaint.width / 2,
        top: geo.center.dy - geo.squareSize / 2 - geo.squareSize,
        width: linePaint.width,
        height: geo.squareSize * 3,
        child: Container(color: linePaint.color),
      ),
      // Horizontal superior
      Positioned(
        left: geo.center.dx - geo.squareSize / 2 - geo.squareSize,
        top: geo.center.dy - geo.squareSize / 2 + inset - linePaint.width / 2,
        width: geo.squareSize * 3,
        height: linePaint.width,
        child: Container(color: linePaint.color),
      ),
      // Horizontal inferior
      Positioned(
        left: geo.center.dx - geo.squareSize / 2 - geo.squareSize,
        top: geo.center.dy + geo.squareSize / 2 - inset - linePaint.width / 2,
        width: geo.squareSize * 3,
        height: linePaint.width,
        child: Container(color: linePaint.color),
      ),
    ];
  }
}

class _PlayerSelector extends StatelessWidget {
  const _PlayerSelector({required this.current, required this.onChanged});

  final Player current;
  final ValueChanged<Player> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: Player.values
          .map(
            (p) => ChoiceChip(
              label: Text('Jogador ${playerLabel(p)}'),
              selected: current == p,
              selectedColor: Color.lerp(Colors.transparent, playerColor(p), 0.2),
              labelStyle: TextStyle(
                color: current == p
                    ? Color.lerp(playerColor(p), Colors.black, 0.25)
                    : Colors.black,
                fontWeight: FontWeight.w600,
              ),
              avatar: CircleAvatar(
                backgroundColor: playerColor(p),
                radius: 10,
              ),
              onSelected: (_) => onChanged(p),
            ),
          )
          .toList(),
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
