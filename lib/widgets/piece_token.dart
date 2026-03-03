import 'package:flutter/material.dart';
import '../models/player.dart';

/// Widget que representa visualmente uma peça de jogo como um pin de localização
class PieceToken extends StatelessWidget {
  const PieceToken({
    super.key,
    required this.player,
    required this.size,
  });

  /// O jogador dono desta peça
  final Player player;
  
  /// Tamanho do token (diâmetro do círculo superior do pin)
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = PlayerHelper.getColor(player);
    
    return CustomPaint(
      painter: _PinPainter(
        color: color,
        label: PlayerHelper.getLabel(player),
        size: size,
      ),
      size: Size(size, size * 1.3),
    );
  }
}

/// Painter customizado para desenhar o pin
class _PinPainter extends CustomPainter {
  _PinPainter({
    required this.color,
    required this.label,
    required this.size,
  });

  final Color color;
  final String label;
  final double size;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final circleRadius = size * 0.35;
    final centerX = canvasSize.width / 2;
    final centerY = circleRadius;

    // Desenhar sombra
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    
    canvas.drawCircle(
      Offset(centerX, centerY + 2),
      circleRadius,
      shadowPaint,
    );

    // Desenhar círculo principal
    final circlePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      Offset(centerX, centerY),
      circleRadius,
      circlePaint,
    );

    // Desenhar border do círculo
    final borderPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    
    canvas.drawCircle(
      Offset(centerX, centerY),
      circleRadius,
      borderPaint,
    );

    // Desenhar ponta do pin (triângulo)
    final pointPath = Path();
    pointPath.moveTo(centerX - circleRadius * 0.3, centerY + circleRadius * 0.5);
    pointPath.lineTo(centerX + circleRadius * 0.3, centerY + circleRadius * 0.5);
    pointPath.lineTo(centerX, centerY + circleRadius * 1.2);
    pointPath.close();

    final pointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    canvas.drawPath(pointPath, pointPaint);

    // Desenhar texto
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: Colors.white,
          fontSize: circleRadius * 0.8,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        centerX - textPainter.width / 2,
        centerY - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(_PinPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.label != label ||
        oldDelegate.size != size;
  }
}
