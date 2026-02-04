import 'package:flutter/material.dart';
import '../models/player.dart';
import '../models/piece.dart';
import '../models/game_piece.dart';
import '../models/board_geometry.dart';
import '../models/dynamic_board_widget.dart';
import '../widgets/board_cell_widget.dart';
import '../widgets/dynamic_widget_token.dart';
import 'dart:math' as math;

/// Tela principal do jogo Não Te Errites
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

/// Estado da tela de jogo
class _GameScreenState extends State<GameScreen> {
  String? _selectedCell;
  Player _currentPlayer = Player.red;
  late GamePieceManager _gamePieceManager;
  final Map<String, String> _textByCell = {};
  final Map<String, double> _angleByCell = {};
  final Map<Player, List<DynamicBoardWidget>> _dynamicWidgets = {};
  final Map<Player, int> _selectedWidgetIndex = {}; // Índice do widget selecionado por jogador
  late List<String> _cellSequence; // Sequência de células em sentido anti-horário
  final TextEditingController _movementController = TextEditingController(); // Controller para entrada de movimento
  final Map<Player, bool> _isMoving = {}; // Rastreia se um widget está animando

  /// Define um texto customizado para uma célula específica
  void setText(String cellId, String text) {
    setState(() {
      _textByCell[cellId] = text;
    });
  }

  /// Remove o texto de uma célula específica
  void clearText(String cellId) {
    setState(() {
      _textByCell.remove(cellId);
    });
  }

  /// Define o ângulo (em graus) do texto de uma célula específica
  void setAngle(String cellId, double angleDegrees) {
    setState(() {
      _angleByCell[cellId] = angleDegrees;
    });
  }

  /// Remove o ângulo customizado da célula (volta ao padrão do widget)
  void clearAngle(String cellId) {
    setState(() {
      _angleByCell.remove(cellId);
    });
  }

  /// Configura textos nas células baseado em condições personalizadas
  void configureCellTexts() {
    
    for (var i = 1; i <= 10; i++) {
      if (i == 1) {
        setText('A${i}C', 'FICHA');
        setText('C${i}C', 'FICHA');

        setText('D${i}L', '${6 - i}');
        setText('D${i }R', '${6 - i}');
        setText('B${i}C', '${10 - i }');
        setText('D${i}C', '${10 - i}');
      } 
      else if( i < 10)
      {
        setText('A${i}C', '${i - 1}');
        setText('C${i}C', '${i - 1}');
        setText('B${i}C', '${10 -  i}');
        setText('D${i}C', '${10 - i}');
      
      }
      else if( i == 10) {
        
        setText('A${i}C', '${i - 1}');
        setText('C${i}C', '${i - 1}');
        setText('B${i}C', 'FICHA');
        setText('D${i}C', 'FICHA');
      }

      if(i < 5) {
        setText('A${i}L', '${i + 15}');
        setText('A${i}R', '${15 - i}');
        setText('C${i}L', '${15 - i}');
        setText('C${i}R', '${i + 15}');


        setText('B${i + 1}R', '${5 - i}');
        setText('B${i + 1}L', '${i + 5}');
        setText('D${i + 1}L', '${5 - i}');
        setText('D${i + 1}R', '${i + 5}');
      } else if (i == 5) {
        setText('A${i}L', 'F');
        setText('A${i}R', 'F');
        setText('C${i}L', 'F');
        setText('C${i}R', 'F');
        
        setText('B${i + 1}L', 'F');
        setText('B${i +1 }R', 'F');
        setText('D${i + 1}L', 'F');
        setText('D${i + 1}R', 'F');
      }
      else {
        setText('A${i}L', '${i - 5}');
        setText('A${i}R', '${15 - i}');
        setText('C${i}R', '${i - 5}');
        setText('C${i}L', '${15 - i}');

        setText('B${i + 1}L', '${i + 5}');
        setText('B${i + 1}R', '${25 - i}');
        setText('D${i + 1}R', '${i + 5}');
        setText('D${i + 1}L', '${25 - i}');
      }
      
    }
  }

  /// Acessa uma célula por ID e aplica texto baseado em uma condição
  void setTextByCondition(String cellId, bool Function(String) condition, String text) {
    if (condition(cellId)) {
      setText(cellId, text);
    }
  }

  /// Aplica textos em múltiplas células que atendem uma condição
  void setTextForCells(bool Function(String) condition, String Function(String) textGenerator) {
    // Este método pode ser usado para configurar textos em batch
    // Exemplo: setTextForCells((id) => id.contains('C'), (id) => 'Central');
  }

  @override
  void initState() {
    super.initState();
    _gamePieceManager = GamePieceManager();
    configureCellTexts();
    
    // Calcula a sequência de células em sentido anti-horário
    final geometry = BoardGeometry(const Size(320, 320));
    _cellSequence = _buildCellSequence(geometry);
    
    // Inicializa 2 widgets dinâmicos por jogador nas mesmas células iniciais
    for (final player in Player.values) {
      final startingCell = PlayerHelper.getStartingCell(player);
      _dynamicWidgets[player] = [
        DynamicBoardWidget(cellId: startingCell, owner: player),
        DynamicBoardWidget(cellId: startingCell, owner: player),
      ];
      _selectedWidgetIndex[player] = 0; // Primeiro widget selecionado por padrão
    }
  }

  /// Constrói a sequência de células em sentido anti-horário
  List<String> _buildCellSequence(BoardGeometry geometry) {
    final allCells = geometry.buildCells();
    
    // Filtra apenas células L e R (sem as centrais)
    var armsCells = allCells.where((cell) {
      if (cell.isCenter) return false;
      return cell.id.endsWith('L') || cell.id.endsWith('R');
    }).toList();

    final center = geometry.center;

    double angleFor(dynamic cell) {
      final dx = cell.rect.center.dx - center.dx;
      final dy = cell.rect.center.dy - center.dy;
      var angle = math.atan2(-dy, dx);
      if (angle < 0) angle += math.pi * 2;
      return angle;
    }

    // Ordena por ângulo (anti-horário)
    armsCells.sort((a, b) {
      final angleA = angleFor(a);
      final angleB = angleFor(b);
      return angleA.compareTo(angleB);
    });

    // Começa em A1L
    final startIndex = armsCells.indexWhere((c) => c.id == 'A1L');
    if (startIndex > 0) {
      armsCells = [
        ...armsCells.sublist(startIndex),
        ...armsCells.sublist(0, startIndex),
      ];
    }

    var sequence = armsCells.map((c) => c.id as String).toList();

    // Insere as casas centrais nas posições especiais
    final specialCentrals = ['C1C', 'B10C', 'D10C', 'A1C'];
    for (final central in specialCentrals) {
      if (central == 'C1C') {
        final c1lIndex = sequence.indexOf('C1L');
        final c1rIndex = sequence.indexOf('C1R');
        if (c1lIndex != -1 && c1rIndex != -1) {
          sequence.insert(c1rIndex, central);
        }
      } else if (central == 'B10C') {
        final b10lIndex = sequence.indexOf('B10L');
        final b10rIndex = sequence.indexOf('B10R');
        if (b10lIndex != -1 && b10rIndex != -1) {
          sequence.insert(b10rIndex, central);
        }
      } else if (central == 'D10C') {
        final d10rIndex = sequence.indexOf('D10R');
        final d10lIndex = sequence.indexOf('D10L');
        if (d10rIndex != -1 && d10lIndex != -1) {
          sequence.insert(d10lIndex, central);
        }
      } else if (central == 'A1C') {
        final a1rIndex = sequence.indexOf('A1R');
        final a1lIndex = sequence.indexOf('A1L');
        if (a1rIndex != -1 && a1lIndex != -1) {
          sequence.insert(a1lIndex, central);
        }
      }
    }

    return sequence;
  }

  /// Calcula a próxima célula na sequência anti-horária
  String _getNextCell(String currentCell) {
    // Casas especiais que devem passar por C (central)
    const specialCases = {
      'C1L': 'C1C',
      'C1C': 'C1R',
      'B10L': 'B10C',
      'B10C': 'B10R',
      'D10R': 'D10C',
      'D10C': 'D10L',
      'A1R': 'A1C',
      'A1C': 'A1L',
    };

    // Se está em um caso especial, retorna o próximo conforme definido
    if (specialCases.containsKey(currentCell)) {
      return specialCases[currentCell]!;
    }

    // Caso contrário, segue a sequência normal
    final currentIndex = _cellSequence.indexOf(currentCell);
    if (currentIndex == -1) {
      return _cellSequence.isNotEmpty ? _cellSequence.first : currentCell;
    }
    final nextIndex = (currentIndex + 1) % _cellSequence.length;
    return _cellSequence[nextIndex];
  }

  /// Move o widget selecionado N casas na sequência anti-horária com animação
  void _moveSelectedWidgetNCells(int steps) async {
    final widgets = _dynamicWidgets[_currentPlayer] ?? [];
    final selectedIndex = _selectedWidgetIndex[_currentPlayer] ?? 0;

    if (selectedIndex >= widgets.length || steps <= 0) return;

    // Marca como animando
    setState(() {
      _isMoving[_currentPlayer] = true;
    });

    var currentCell = widgets[selectedIndex].cellId;
    var currentIndex = _cellSequence.indexOf(currentCell);

    if (currentIndex == -1) {
      currentIndex = 0;
      currentCell = _cellSequence.isNotEmpty ? _cellSequence.first : currentCell;
    }

    // Anima passo a passo
    for (int i = 0; i < steps; i++) {
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        setState(() {
          currentIndex = (currentIndex + 1) % _cellSequence.length;
          final nextCell = _cellSequence[currentIndex];

          widgets[selectedIndex] = DynamicBoardWidget(
            cellId: nextCell,
            owner: _currentPlayer,
          );
        });
      }
    }

    // Marca como não animando e reseta para o primeiro widget
    if (mounted) {
      setState(() {
        _isMoving[_currentPlayer] = false;
        _movementController.clear();
        _selectedWidgetIndex[_currentPlayer] = 0; // Volta para primeira peça
      });
    }
  }

  /// Seleciona uma célula e move o widget selecionado se estiver nela
  void _selectCell(String cellId) {
    setState(() {
      _selectedCell = cellId;

      final widgets = _dynamicWidgets[_currentPlayer] ?? [];
      final selectedIndex = _selectedWidgetIndex[_currentPlayer] ?? 0;
      if (selectedIndex < widgets.length && widgets[selectedIndex].cellId == cellId) {
        final nextCell = _getNextCell(cellId);
        widgets[selectedIndex] = DynamicBoardWidget(
          cellId: nextCell,
          owner: _currentPlayer,
        );
      }
    });
  }

  /// Move o widget dinâmico selecionado do jogador atual para uma célula
  void _moveWidgetToCell(String cellId) {
    setState(() {
      final widgets = _dynamicWidgets[_currentPlayer] ?? [];
      final selectedIndex = _selectedWidgetIndex[_currentPlayer] ?? 0;
      
      if (selectedIndex < widgets.length) {
        widgets[selectedIndex] = DynamicBoardWidget(
          cellId: cellId,
          owner: _currentPlayer,
        );
      }
    });
  }

  /// Seleciona um widget dinâmico para ser movido (sem mudar o jogador em foco)
  void _selectDynamicWidget(Player player, int index) {
    setState(() {
      _selectedWidgetIndex[player] = index;
    });
  }

  /// Move uma peça de um jogador para a célula especificada
  void _movePiece(String cellId) {
    setState(() {
      final piecesInCell = _gamePieceManager.getPiecesInCell(cellId);
      if (piecesInCell.isNotEmpty) {
        _gamePieceManager.resetPiece(piecesInCell.last);
      } else {
        // Move o widget dinâmico para esta célula
        _moveWidgetToCell(cellId);
      }
    });
  }

  /// Muda o jogador atual
  void _changePlayer(Player player) {
    setState(() {
      _currentPlayer = player;
    });
  }

  /// Limpa todas as peças do tabuleiro
  void _clearBoard() {
    setState(() {
      _gamePieceManager.removeAllPiecesFromBoard();
      _angleByCell.clear();
      _selectedCell = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  /// Constrói uma imagem/widget customizado para uma célula específica
  /// Retorna null se não houver imagem para aquela célula
  Widget? _buildCellImage(String cellId) {
    return null;
  }

  /// Constrói os widgets dinâmicos presentes em uma célula
  Widget? _buildDynamicWidgetsForCell(String cellId, double width, double height) {
    final widgetsInCell = <(DynamicBoardWidget, Player, int)>[];
    for (final player in Player.values) {
      final widgets = _dynamicWidgets[player] ?? [];
      for (int i = 0; i < widgets.length; i++) {
        if (widgets[i].cellId == cellId) {
          widgetsInCell.add((widgets[i], player, i));
        }
      }
    }

    if (widgetsInCell.isEmpty) return null;

    final size = (width * 0.65).clamp(12.0, height * 0.65);
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 4,
        runSpacing: 4,
        children: widgetsInCell
            .map(
              (item) => GestureDetector(
                onTap: () {
                  print('Clique em peça ${item.$3} do player ${item.$2}');
                  _selectDynamicWidget(item.$2, item.$3);
                },
                child: Tooltip(
                  message: 'Peça ${item.$3 + 1} - Clique para selecionar',
                  child: DynamicWidgetToken(
                    owner: item.$1.owner,
                    size: size,
                    index: item.$3,
                    isSelected: _currentPlayer == item.$2 && _selectedWidgetIndex[item.$2] == item.$3,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }


  /// Constrói a barra de aplicação
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.blue[700],
      title: const Text(
        'Não Te Errites',
        style: TextStyle(color: Colors.white),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: _clearBoard,
          tooltip: 'Limpar tabuleiro',
        ),
      ],
    );
  }

  /// Constrói o corpo principal da tela
  Widget _buildBody() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boardSize = constraints.biggest.shortestSide.clamp(300.0, 1200.0);
        final geometry = BoardGeometry(Size.square(boardSize));
        final cells = geometry.buildCells();

        return Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1220, maxHeight: 1220),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildPlayerSelector(),
                    const SizedBox(height: 12),
                    if (_selectedCell != null) _buildSelectedCellInfo(),
                    _buildBoard(geometry, cells),
                    const SizedBox(height: 12),
                    _buildInstructions(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Constrói o seletor de jogador
  Widget _buildPlayerSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[400]!),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Jogador atual: ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 8),
              ...Player.values.map((player) => _buildPlayerButton(player)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Mover widget:', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(width: 8),
              SizedBox(
                width: 80,
                child: TextField(
                  controller: _movementController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Casas',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  final steps = int.tryParse(_movementController.text);
                  if (steps != null && steps > 0 && (_isMoving[_currentPlayer] ?? false) == false) {
                    _moveSelectedWidgetNCells(steps);
                  }
                },
                child: const Text('Mover'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Constrói um botão para selecionar um jogador
  Widget _buildPlayerButton(Player player) {
    final isSelected = _currentPlayer == player;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: () => _changePlayer(player),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: PlayerHelper.getColor(player),
            shape: BoxShape.circle,
            border: isSelected
                ? Border.all(color: Colors.black, width: 3)
                : Border.all(color: Colors.grey, width: 1),
            boxShadow: isSelected
                ? [const BoxShadow(color: Colors.black26, blurRadius: 4, spreadRadius: 1)]
                : null,
          ),
          child: Center(
            child: Text(
              PlayerHelper.getLabel(player),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Constrói a informação da célula selecionada
  Widget _buildSelectedCellInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.blue[100],
        border: Border.all(color: Colors.blue, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Célula 1: $_selectedCell',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue[900],
        ),
      ),
    );
  }

  /// Constrói o tabuleiro de jogo
  Widget _buildBoard(BoardGeometry geometry, List cells) {
    return SizedBox(
      width: geometry.size.width,
      height: geometry.size.height,
      child: Stack(
        children: [
          // Fundo
          Positioned.fill(
            child: Container(color: Colors.white),
          ),
          // Células
          ...cells.map(
            (cell) => Positioned(
              left: cell.rect.left,
              top: cell.rect.top,
              width: cell.rect.width,
              height: cell.rect.height,
              child: BoardCellWidget(
                cell: cell,
                pieces: _gamePieceManager.getPiecesInCell(cell.id),
                selected: _selectedCell == cell.id,
                onTap: () => _selectCell(cell.id),
                onLongPress: () {},
                scale: geometry.scale,
                customText: _textByCell[cell.id],
                textAngleDegrees: _angleByCell[cell.id] ?? BoardCellWidget.defaultTextAngleDegrees,
                // Widgets dinâmicos que se movem entre células
                customWidget: _buildDynamicWidgetsForCell(
                      cell.id,
                      cell.rect.width,
                      cell.rect.height,
                    ) ??
                    _buildCellImage(cell.id),
                widgetAlignment: Alignment.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói as instruções de uso
  Widget _buildInstructions() {
    return Text(
      'Toque para selecionar célula. Pressione e segure em célula vazia para mover o widget dinâmico.',
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey[700],
      ),
      textAlign: TextAlign.center,
    );
  }
}


