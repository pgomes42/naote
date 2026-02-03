import 'package:flutter/material.dart';
import '../models/board_geometry.dart';
import '../models/board_cell.dart';

/// Widget que percorre todas as casas dos braços (A, B, C, D)
/// em forma de ciclo, excluindo as casas centrais (L e R)
class ArmsCycleWidget extends StatefulWidget {
  const ArmsCycleWidget({
    super.key,
    required this.boardGeometry,
    this.onCellSelected,
    this.highlightedCellId,
  });

  /// Geometria do tabuleiro
  final BoardGeometry boardGeometry;

  /// Callback quando uma célula é selecionada
  final Function(BoardCell)? onCellSelected;

  /// ID da célula atualmente destacada
  final String? highlightedCellId;

  @override
  State<ArmsCycleWidget> createState() => _ArmsCycleWidgetState();
}

class _ArmsCycleWidgetState extends State<ArmsCycleWidget>
    with SingleTickerProviderStateMixin {
  late List<BoardCell> _armsCells;
  int _currentCellIndex = 0;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _initializeArmsCells();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(ArmsCycleWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.boardGeometry != widget.boardGeometry) {
      _initializeArmsCells();
    }
  }

  /// Inicializa a lista de células dos braços (excluindo centro e laterais)
  void _initializeArmsCells() {
    final allCells = widget.boardGeometry.buildCells();
    _armsCells = allCells.where((cell) {
      // Excluir célula do centro
      if (cell.isCenter) return false;
      // Excluir células centrais (C), manter apenas laterais (L e R)
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

      // Extrair número da célula (ex: 'A1L' -> 1)
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

  /// Avança para a próxima célula no ciclo
  void _nextCell() {
    setState(() {
      _currentCellIndex = (_currentCellIndex + 1) % _armsCells.length;
    });
    _animationController.forward(from: 0.0);
    widget.onCellSelected?.call(_armsCells[_currentCellIndex]);
  }

  /// Volta para a célula anterior no ciclo
  void _previousCell() {
    setState(() {
      _currentCellIndex =
          (_currentCellIndex - 1 + _armsCells.length) % _armsCells.length;
    });
    _animationController.forward(from: 0.0);
    widget.onCellSelected?.call(_armsCells[_currentCellIndex]);
  }

  /// Move para uma célula específica
  void goToCell(String cellId) {
    final index = _armsCells.indexWhere((cell) => cell.id == cellId);
    if (index != -1) {
      setState(() {
        _currentCellIndex = index;
      });
      _animationController.forward(from: 0.0);
      widget.onCellSelected?.call(_armsCells[_currentCellIndex]);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_armsCells.isEmpty) {
      return const Center(
        child: Text('Nenhuma célula dos braços encontrada'),
      );
    }

    final currentCell = _armsCells[_currentCellIndex];

    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Informação da célula atual
          ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(
              CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
            ),
            child: Card(
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Célula: ${currentCell.id}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Braço: ${currentCell.arm} | Posição: ${_currentCellIndex + 1}/${_armsCells.length}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Botões de navegação
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _nextCell,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Próxima'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Lista de células do ciclo
          _buildCellsList(),
        ],
      ),
    );
  }

  /// Constrói uma lista visual de todas as células dos braços
  Widget _buildCellsList() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(_armsCells.length, (index) {
        final cell = _armsCells[index];
        final isSelected = index == _currentCellIndex;
        final isHighlighted = cell.id == widget.highlightedCellId;

        return GestureDetector(
          onTap: () {
            setState(() {
              _currentCellIndex = index;
            });
            _animationController.forward(from: 0.0);
            widget.onCellSelected?.call(cell);
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.green
                  : isHighlighted
                      ? Colors.orange
                      : Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? Colors.green[900]! : Colors.grey,
                width: isSelected ? 3 : 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              cell.id,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : Colors.black,
                fontSize: isSelected ? 14 : 12,
              ),
            ),
          ),
        );
      }),
    );
  }
}
