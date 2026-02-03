import 'package:flutter/material.dart';
import '../models/board_geometry.dart';
import '../models/board_cell.dart';

/// Widget que anima um objeto se movendo pelas casas dos braços
class MovingPieceAnimator extends StatefulWidget {
  const MovingPieceAnimator({
    super.key,
    required this.boardGeometry,
    this.speed = const Duration(milliseconds: 800),
    this.pieceColor = Colors.blue,
    this.pieceSize = 30,
  });

  /// Geometria do tabuleiro
  final BoardGeometry boardGeometry;

  /// Velocidade da animação entre casas
  final Duration speed;

  /// Cor da peça animada
  final Color pieceColor;

  /// Tamanho da peça animada
  final double pieceSize;

  @override
  State<MovingPieceAnimator> createState() => _MovingPieceAnimatorState();
}

class _MovingPieceAnimatorState extends State<MovingPieceAnimator>
    with TickerProviderStateMixin {
  late List<BoardCell> _armsCells;
  late AnimationController _movementController;
  late AnimationController _pulseController;
  int _currentCellIndex = 0;
  bool _isPlaying = true;

  @override
  void initState() {
    super.initState();
    _initializeArmsCells();
    _setupAnimations();
  }

  /// Inicializa a lista de células dos braços
  void _initializeArmsCells() {
    final allCells = widget.boardGeometry.buildCells();
    _armsCells = allCells.where((cell) {
      if (cell.isCenter) return false;
      // Incluir apenas células laterais (L e R), excluir centrais (C)
      return cell.id.endsWith('L') || cell.id.endsWith('R');
    }).toList();

    // Ordenar em ciclo: A1L, A1R, A2L, A2R, ..., D10L, D10R
    _armsCells.sort((a, b) {
      final armOrder = {'A': 0, 'B': 1, 'C': 2, 'D': 3};
      final armA = armOrder[a.arm] ?? 4;
      final armB = armOrder[b.arm] ?? 4;

      if (armA != armB) {
        return armA.compareTo(armB);
      }

      final numA = int.tryParse(a.id.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
      final numB = int.tryParse(b.id.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;

      if (numA != numB) {
        return numA.compareTo(numB);
      }

      // Se o número é igual, L vem antes de R
      final sideA = a.id.endsWith('L') ? 0 : 1;
      final sideB = b.id.endsWith('L') ? 0 : 1;
      return sideA.compareTo(sideB);
    });
  }

  /// Configura as animações
  void _setupAnimations() {
    _movementController = AnimationController(
      duration: widget.speed,
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat(reverse: true);

    _startMovement();
  }

  /// Inicia o movimento cíclico
  void _startMovement() {
    if (!_isPlaying || _armsCells.isEmpty) return;

    _movementController.forward().then((_) {
      if (_isPlaying) {
        setState(() {
          _currentCellIndex = (_currentCellIndex + 1) % _armsCells.length;
        });
        _movementController.reset();
        _startMovement();
      }
    });
  }

  /// Pausa/retoma a animação
  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _movementController.forward();
      } else {
        _movementController.stop();
      }
    });
  }

  /// Próxima célula
  void _nextCell() {
    setState(() {
      _currentCellIndex = (_currentCellIndex + 1) % _armsCells.length;
      _movementController.reset();
    });
    if (_isPlaying) {
      _startMovement();
    }
  }

  /// Célula anterior
  void _previousCell() {
    setState(() {
      _currentCellIndex =
          (_currentCellIndex - 1 + _armsCells.length) % _armsCells.length;
      _movementController.reset();
    });
    if (_isPlaying) {
      _startMovement();
    }
  }

  @override
  void dispose() {
    _movementController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_armsCells.isEmpty) {
      return const Center(
        child: Text('Nenhuma célula encontrada'),
      );
    }

    final currentCell = _armsCells[_currentCellIndex];
    final nextCellIndex = (_currentCellIndex + 1) % _armsCells.length;
    final nextCell = _armsCells[nextCellIndex];

    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Informação atual
          Card(
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'Célula Atual: ${currentCell.id}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Próxima: ${nextCell.id}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_currentCellIndex + 1}/${_armsCells.length}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Visualização da animação
          Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blue, width: 2),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[50],
            ),
            child: Stack(
              children: [
                // Célula atual (origem)
                Positioned(
                  left: 20,
                  top: 130,
                  child: Column(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          border: Border.all(color: Colors.green, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            currentCell.id,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('Atual', style: TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
                // Célula próxima (destino)
                Positioned(
                  right: 20,
                  top: 130,
                  child: Column(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          border: Border.all(color: Colors.orange, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            nextCell.id,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('Próxima', style: TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
                // Peça animada se movendo
                AnimatedBuilder(
                  animation: _movementController,
                  builder: (context, child) {
                    final progress = _movementController.value;
                    final left = 70 + (progress * 130);

                    return Positioned(
                      left: left,
                      top: 125,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.8, end: 1.2).animate(
                          CurvedAnimation(
                            parent: _pulseController,
                            curve: Curves.easeInOut,
                          ),
                        ),
                        child: Container(
                          width: widget.pieceSize,
                          height: widget.pieceSize,
                          decoration: BoxDecoration(
                            color: widget.pieceColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: widget.pieceColor.withOpacity(0.5),
                                blurRadius: 8,
                                spreadRadius: 2,
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
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Botões de controle
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _previousCell,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Anterior'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _togglePlayPause,
                icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                label: Text(_isPlaying ? 'Pausar' : 'Reproduzir'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _nextCell,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Próxima'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Legenda de velocidades
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSpeedButton(
                  'Lento',
                  const Duration(milliseconds: 1500),
                  Colors.red[300]!,
                ),
                _buildSpeedButton(
                  'Normal',
                  const Duration(milliseconds: 800),
                  Colors.blue[300]!,
                ),
                _buildSpeedButton(
                  'Rápido',
                  const Duration(milliseconds: 400),
                  Colors.green[300]!,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói botão de velocidade
  Widget _buildSpeedButton(String label, Duration duration, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _movementController.duration = duration;
            _movementController.reset();
            _currentCellIndex = 0;
            _isPlaying = true;
          });
          _startMovement();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
        ),
        child: Text(label),
      ),
    );
  }
}
