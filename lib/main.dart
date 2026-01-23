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

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  String? _selectedCell;
  final _paintKey = GlobalKey();

  void _handleTapDown(TapDownDetails details) {
    final renderBox = _paintKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final localPos = renderBox.globalToLocal(details.globalPosition);
    final size = renderBox.size;
    final hit = _hitTestCell(localPos, size);
    setState(() {
      _selectedCell = hit;
    });
  }

  String? _hitTestCell(Offset p, Size size) {
    final scale = size.width / 320;
    final squareSize = 100 * scale;
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    final centerRect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: squareSize,
      height: squareSize,
    );
    if (centerRect.contains(p)) return 'CENTER';

    final step = squareSize / 9;

    // Top (A)
    final topRect = Rect.fromLTWH(
      centerX - squareSize / 2,
      centerY - squareSize / 2 - squareSize,
      squareSize,
      squareSize,
    );
    if (topRect.contains(p)) {
      final idx = ((p.dy - topRect.top) / step).floor().clamp(0, 8);
      return 'A${idx + 1}';
    }

    // Bottom (B)
    final bottomRect = Rect.fromLTWH(
      centerX - squareSize / 2,
      centerY + squareSize / 2,
      squareSize,
      squareSize,
    );
    if (bottomRect.contains(p)) {
      final idx = ((p.dy - bottomRect.top) / step).floor().clamp(0, 8);
      return 'B${idx + 1}';
    }

    // Left (C)
    final leftRect = Rect.fromLTWH(
      centerX - squareSize / 2 - squareSize,
      centerY - squareSize / 2,
      squareSize,
      squareSize,
    );
    if (leftRect.contains(p)) {
      final idx = ((p.dx - leftRect.left) / step).floor().clamp(0, 8);
      return 'C${idx + 1}';
    }

    // Right (D)
    final rightRect = Rect.fromLTWH(
      centerX + squareSize / 2,
      centerY - squareSize / 2,
      squareSize,
      squareSize,
    );
    if (rightRect.contains(p)) {
      final idx = ((p.dx - rightRect.left) / step).floor().clamp(0, 8);
      return 'D${idx + 1}';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[700],
        title: const Text('Não Te Errites', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 800, maxHeight: 800),
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  color: Colors.white,
                  child: GestureDetector(
                    onTapDown: _handleTapDown,
                    child: CustomPaint(
                      key: _paintKey,
                      painter: GameBoardPainter(selectedCell: _selectedCell),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GameBoardPainter extends CustomPainter {
  final String? selectedCell;

  GameBoardPainter({this.selectedCell});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final bgPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Fundo branco
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Dimensões baseadas em 100mm por quadrado
    // Escala para caber no canvas
    final scale = size.width / 320; // 3 quadrados de largura + margens
    final squareSize = 100 * scale; // 100mm escalado
    final segmentSize = 10 * scale; // 10mm por segmento
    
    final centerX = size.width / 2;
    final centerY = size.height / 2;

      final centerRect = Rect.fromCenter(
        center: Offset(centerX, centerY),
        width: squareSize,
        height: squareSize,
      );

      final highlightPaint = Paint()
        ..color = Colors.blue.withOpacity(0.35)
        ..style = PaintingStyle.fill;

      // Desenhar quadrado central (com destaque opcional)
      if (selectedCell == 'CENTER') {
        canvas.drawRect(centerRect, highlightPaint);
      }
      canvas.drawRect(centerRect, paint);

    // Aba superior
    _drawFlap(
      canvas,
      paint,
      centerX - squareSize / 2,
      centerY - squareSize / 2 - squareSize,
      squareSize,
      squareSize,
      segmentSize,
      true, // vertical
      'A',
    );

    // Aba inferior
    _drawFlap(
      canvas,
      paint,
      centerX - squareSize / 2,
      centerY + squareSize / 2,
      squareSize,
      squareSize,
      segmentSize,
      true, // vertical
      'B',
    );

    // Aba esquerda
    _drawFlap(
      canvas,
      paint,
      centerX - squareSize / 2 - squareSize,
      centerY - squareSize / 2,
      squareSize,
      squareSize,
      segmentSize,
      false, // horizontal
      'C',
    );

    // Aba direita
    _drawFlap(
      canvas,
      paint,
      centerX + squareSize / 2,
      centerY - squareSize / 2,
      squareSize,
      squareSize,
      segmentSize,
      false, // horizontal
      'D',
    );

    // Linhas internas a 10mm das bordas laterais, cruzando o centro
    final inset = 10 * scale;

    // Linhas verticais (braços superior/inferior) cruzando todo o eixo Y
    final verticalLineStartY = centerY - squareSize / 2 - squareSize;
    final verticalLineEndY = centerY + squareSize / 2 + squareSize;
    canvas.drawLine(
      Offset(centerX - squareSize / 2 + inset, verticalLineStartY),
      Offset(centerX - squareSize / 2 + inset, verticalLineEndY),
      paint,
    );
    canvas.drawLine(
      Offset(centerX + squareSize / 2 - inset, verticalLineStartY),
      Offset(centerX + squareSize / 2 - inset, verticalLineEndY),
      paint,
    );

    // Linhas horizontais (braços esquerdo/direito) cruzando todo o eixo X
    final horizontalLineStartX = centerX - squareSize / 2 - squareSize;
    final horizontalLineEndX = centerX + squareSize / 2 + squareSize;
    canvas.drawLine(
      Offset(horizontalLineStartX, centerY - squareSize / 2 + inset),
      Offset(horizontalLineEndX, centerY - squareSize / 2 + inset),
      paint,
    );
    canvas.drawLine(
      Offset(horizontalLineStartX, centerY + squareSize / 2 - inset),
      Offset(horizontalLineEndX, centerY + squareSize / 2 - inset),
      paint,
    );
  }

  void _drawFlap(
    Canvas canvas,
    Paint paint,
    double x,
    double y,
    double width,
    double height,
    double segmentSize,
    bool isVertical,
    String label,
  ) {
    // Contorno do quadrado
    canvas.drawRect(Rect.fromLTWH(x, y, width, height), paint);

    // Pintar cada 5º quadrado de vermelho
    final red = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    final highlight = Paint()
      ..color = Colors.blue.withOpacity(0.35)
      ..style = PaintingStyle.fill;

    // Desenhar linhas paralelas criando 9 segmentos (8 linhas) distribuídas uniformemente
    if (isVertical) {
      // Linhas horizontais espaçadas uniformemente pelo comprimento do braço
      final step = height / 9;

      // Preencher células; a cada 5ª célula (1-indexed) fica vermelha
      for (int i = 0; i < 9; i++) {
        // Pinta cada 5ª célula, exceto a central (5ª permanece branca)
        if ((i + 1) % 5 == 0 && i != 4) {
          final rect = Rect.fromLTWH(x, y + step * i, width, step);
          canvas.drawRect(rect, red);
        }
        // Destaque se selecionada
        if (selectedCell == '$label${i + 1}') {
          final rect = Rect.fromLTWH(x, y + step * i, width, step);
          canvas.drawRect(rect, highlight);
        }
      }

      for (int i = 1; i < 9; i++) {
        final dy = y + step * i;
        canvas.drawLine(
          Offset(x, dy),
          Offset(x + width, dy),
          paint,
        );
      }
    } else {
      // Linhas verticais espaçadas uniformemente pelo comprimento do braço
      final step = width / 9;

      // Preencher células; a cada 5ª célula (1-indexed) fica vermelha
      for (int i = 0; i < 9; i++) {
        // Pinta cada 5ª célula, exceto a central (5ª permanece branca)
        if ((i + 1) % 5 == 0 && i != 4) {
          final rect = Rect.fromLTWH(x + step * i, y, step, height);
          canvas.drawRect(rect, red);
        }
        // Destaque se selecionada
        if (selectedCell == '$label${i + 1}') {
          final rect = Rect.fromLTWH(x + step * i, y, step, height);
          canvas.drawRect(rect, highlight);
        }
      }

      for (int i = 1; i < 9; i++) {
        final dx = x + step * i;
        canvas.drawLine(
          Offset(dx, y),
          Offset(dx, y + height),
          paint,
        );
      }
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is GameBoardPainter && oldDelegate.selectedCell != selectedCell;
  }
}
