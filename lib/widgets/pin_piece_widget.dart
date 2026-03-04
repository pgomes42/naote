import 'package:flutter/material.dart';

/// Widget que representa uma peça como um alfinete flutuante com animação
class PinPieceWidget extends StatefulWidget {
  final Color color;
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final double size;

  const PinPieceWidget({
    super.key,
    required this.color,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.size = 18,
  });

  @override
  State<PinPieceWidget> createState() => _PinPieceWidgetState();
}

class _PinPieceWidgetState extends State<PinPieceWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    // Controlador para a animação de flutuar (sobe e desce)
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _floatController,
        builder: (context, child) {
          // Valor da oscilação vertical (sobe e desce suavemente)
          double floatValue = _floatController.value * 6.0;

          return SizedBox(
            width: widget.size * 1.5,
            height: widget.size * 2.5,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // 1. Sombra no chão (diminui quando a peça sobe)
                Positioned(
                  bottom: widget.size * 0.7,
                  child: Transform.scale(
                    scale: 1.0 - (_floatController.value * 0.25),
                    child: Container(
                      width: widget.size * 0.4,
                      height: 2.5,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 2. O Alfinete (Haste fixa no chão)
                Positioned(
                  bottom: widget.size * 0.8 + widget.size * 0.05,
                  child: Container(
                    width: 1.2,
                    height: widget.size * 0.8,
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(0.8),
                    ),
                  ),
                ),

                // 3. A Cabeça Flutuante (Esfera com gradiente)
                Positioned(
                  bottom: widget.size * 0.8 + floatValue,
                  child: Container(
                    width: widget.size * 0.7,
                    height: widget.size * 0.7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withOpacity(0.5),
                          widget.color,
                          widget.color.withOpacity(0.75),
                        ],
                        center: const Alignment(-0.35, -0.35),
                      ),
                      boxShadow: [
                        // Sombra de profundidade
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                          spreadRadius: 0.5,
                        ),
                        // Brilho quando selecionado
                        if (widget.isSelected)
                          BoxShadow(
                            color: Colors.white.withOpacity(0.6),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                      ],
                      border: Border.all(
                        color: widget.isSelected
                            ? Colors.white.withOpacity(0.8)
                            : Colors.black.withOpacity(0.3),
                        width: widget.isSelected ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        widget.label,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: widget.size * 0.4,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.4),
                              offset: const Offset(0.3, 0.3),
                              blurRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
