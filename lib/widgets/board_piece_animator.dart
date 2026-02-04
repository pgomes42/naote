import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../models/board_geometry.dart';

/// Widget que anima uma peça sobre o tabuleiro, se posicionando nas casas reais
class BoardPieceAnimator extends StatefulWidget {
  const BoardPieceAnimator({
    super.key,
    required this.geometry,
    required this.cells,
    this.speed = const Duration(milliseconds: 800),
    this.pieceColor = Colors.blue,
    this.pieceSize = 30,
    this.onCellChanged,
  });

  final BoardGeometry geometry;
  final List cells;
  final Duration speed;
  final Color pieceColor;
  final double pieceSize;
  final Function(String)? onCellChanged;

  @override
  State<BoardPieceAnimator> createState() => _BoardPieceAnimatorState();
}

class _BoardPieceAnimatorState extends State<BoardPieceAnimator>
    with SingleTickerProviderStateMixin {
  late List<dynamic> _armsCells;
  late AnimationController _moveController;
  int _currentCellIndex = 0;
  bool _isPlaying = true;

  @override
  void initState() {
    super.initState();
    _initializeArmsCells();
    _setupAnimation();
  }

  void _initializeArmsCells() {
    _armsCells = [];

    for (var cell in widget.cells) {
      if (cell == null) continue;
      try {
        // Verificar se tem os atributos necessários
        final isCenter = cell.isCenter ?? false;
        final id = cell.id ?? '';

        if (!isCenter && (id.endsWith('L') || id.endsWith('R'))) {
          _armsCells.add(cell);
        }
      } catch (e) {
        continue;
      }
    }

    // Ordenar em sentido anti-horário usando a posição no tabuleiro
    try {
      final center = widget.geometry.center;

      double angleFor(dynamic cell) {
        final rect = cell?.rect;
        if (rect == null) return 0;
        final dx = rect.center.dx - center.dx;
        final dy = rect.center.dy - center.dy;
        var angle = math.atan2(-dy, dx);
        if (angle < 0) angle += math.pi * 2;
        return angle;
      }

      double distanceSqFor(dynamic cell) {
        final rect = cell?.rect;
        if (rect == null) return 0;
        final dx = rect.center.dx - center.dx;
        final dy = rect.center.dy - center.dy;
        return dx * dx + dy * dy;
      }

      _armsCells.sort((a, b) {
        final angleA = angleFor(a);
        final angleB = angleFor(b);

        if (angleA != angleB) {
          return angleA.compareTo(angleB);
        }

        final distA = distanceSqFor(a);
        final distB = distanceSqFor(b);
        return distB.compareTo(distA);
      });

      final startIndex = _armsCells.indexWhere((c) => (c?.id ?? '') == 'A1L');
      if (startIndex > 0) {
        _armsCells = [
          ..._armsCells.sublist(startIndex),
          ..._armsCells.sublist(0, startIndex),
        ];
      }
    } catch (e) {
      print('Erro ao ordenar células: $e');
    }
  }

  void _setupAnimation() {
    _moveController = AnimationController(
      duration: widget.speed,
      vsync: this,
    );
    _startMovement();
  }

  void _startMovement() {
    if (!_isPlaying || _armsCells.isEmpty) return;

    _moveController.forward().then((_) {
      if (_isPlaying && mounted) {
        setState(() {
          _currentCellIndex = (_currentCellIndex + 1) % _armsCells.length;
        });
        try {
          widget.onCellChanged?.call(_armsCells[_currentCellIndex].id);
        } catch (e) {
          print('Erro ao chamar callback: $e');
        }
        _moveController.reset();
        _startMovement();
      }
    });
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _moveController.forward();
      } else {
        _moveController.stop();
      }
    });
  }

  @override
  void dispose() {
    _moveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_armsCells.isEmpty) {
      return SizedBox.expand(
        child: Stack(
          children: const [
            Center(
              child: Text('Nenhuma célula para animar'),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        AnimatedBuilder(
          animation: _moveController,
          builder: (context, child) {
            final progress = _moveController.value;
            
            try {
              final currentCell = _armsCells[_currentCellIndex];
              final nextCellIndex = (_currentCellIndex + 1) % _armsCells.length;
              final nextCell = _armsCells[nextCellIndex];

              final currentRect = currentCell?.rect;
              final nextRect = nextCell?.rect;

              if (currentRect == null || nextRect == null) {
                return SizedBox.expand(
                  child: Center(
                    child: Text(
                        'Erro: Célula inválida (${_currentCellIndex})'),
                  ),
                );
              }

              final animLeft =
                  currentRect.left + (nextRect.left - currentRect.left) * progress;
              final animTop =
                  currentRect.top + (nextRect.top - currentRect.top) * progress;

              return Positioned(
                left: animLeft,
                top: animTop,
                width: currentRect.width,
                height: currentRect.height,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: widget.pieceSize,
                        height: widget.pieceSize,
                        decoration: BoxDecoration(
                          color: widget.pieceColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: widget.pieceColor.withOpacity(0.7),
                              blurRadius: 12,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.sports_esports,
                            color: Colors.white,
                            size: widget.pieceSize * 0.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          currentCell?.id ?? '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            } catch (e) {
              return SizedBox.expand(
                child: Center(
                  child: Text('Erro na animação: $e'),
                ),
              );
            }
          },
        ),
        // Botão de controle
        Positioned(
          bottom: 10,
          left: 10,
          child: ElevatedButton.icon(
            onPressed: _togglePlayPause,
            icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
            label: Text(_isPlaying ? 'Pausar' : 'Reproduzir'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

