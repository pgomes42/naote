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

  /// Converte um número para numeração romana
  String toRoman(int num) {
    const List<int> values = [10, 9, 5, 4, 1];
    const List<String> numerals = ['X', 'IX', 'V', 'IV', 'I'];
    
    String result = '';
    int remaining = num;
    
    for (int i = 0; i < values.length; i++) {
      while (remaining >= values[i]) {
        result += numerals[i];
        remaining -= values[i];
      }
    }
    
    return result;
  }

  /// Configura textos nas células baseado em condições personalizadas
  void configureCellTexts() {
    
    for (var i = 1; i <= 10; i++) {
      if (i == 1) {
        setText('A${i}C', 'FICHA');
        setText('C${i}C', 'FICHA');

        setText('D${i}L', '${6 - i}');
        setText('D${i }R', '${6 - i}');
        setText('B${i}C', toRoman(10 - i));
        setText('D${i}C', toRoman(10 - i));
      } 
      else if( i < 10)
      {
        setText('A${i}C', toRoman(i - 1));
        setText('C${i}C', toRoman(i - 1));
        setText('B${i}C', toRoman(10 - i));
        setText('D${i}C', toRoman(10 - i));
      
      }
      else if( i == 10) {
        
        setText('A${i}C', toRoman(i - 1));
        setText('C${i}C', toRoman(i - 1));
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

  /// Retorna o valor exato de dados necessário para avançar de uma casa central
  /// Primeira casa: 10, Segunda: 8, Terceira: 6, Quarta: 4, Quinta: 2
  /// Retorna null se a peça chegou ao final
  int? _getRequiredDiceForCentralCell(String cellId) {
    final match = RegExp(r'([A-D])(\d+)C').firstMatch(cellId);
    if (match == null) return null;

    final arm = match.group(1)!;
    final number = int.parse(match.group(2)!);

    // Mapeia a posição de cada braço para a sequência: A1→1, A2→2...A10→10
    //                                                     B10→1, B9→2...B1→10
    //                                                     C1→1, C2→2...C10→10
    //                                                     D10→1, D9→2...D1→10
    int position;
    if (arm == 'A' || arm == 'C') {
      position = number;
    } else {
      // Para B e D que decrementam
      position = arm == 'B' ? (11 - number) : (11 - number);
    }

    // Sequência de valores requeridos: 10, 8, 6, 4, 2
    // Posição 1→10, Posição 2→8, Posição 3→6, Posição 4→4, Posição 5→2, Posição 6+→final
    if (position == 1) return 10;
    if (position == 2) return 8;
    if (position == 3) return 6;
    if (position == 4) return 4;
    if (position == 5) return 2;
    return null; // Já passou de posição 5, chegou ao final
  }

  /// Valida se um movimento para células centrais é permitido baseado no valor de dados
  bool _isValidCentralMove(String currentCell, int steps, Player player) {
    final playerArm = PlayerHelper.getArm(player);

    // Se não está numa casa central do seu braço, retorna true (movimento normal)
    if (!currentCell.startsWith(playerArm) || !currentCell.endsWith('C')) {
      return true;
    }

    // Se está numa casa central, valida o valor exato necessário
    final requiredDice = _getRequiredDiceForCentralCell(currentCell);
    
    // Se retornou null, já chegou ao final, não pode avançar
    if (requiredDice == null) {
      return false;
    }

    // Verifica se o número de passos coincide com o valor requerido
    return steps == requiredDice;
  }

  /// Calcula a próxima célula na sequência anti-horária
  String _getNextCell(String currentCell, Player player) {
    // Verifica se está na reta final (casas centrais do braço do jogador)
    final playerArm = PlayerHelper.getArm(player);
    
    // Se está em uma casa central do braço do jogador, segue a sequência central
    if (currentCell.startsWith(playerArm) && currentCell.endsWith('C')) {
      final match = RegExp(r'([A-D])(\d+)C').firstMatch(currentCell);
      if (match != null) {
        final arm = match.group(1)!;
        final number = int.parse(match.group(2)!);
        
        // Para braços A e C: incrementa normalmente (A1C→A2C...→A10C ou C1C→C2C...→C10C)
        if (arm == 'A' || arm == 'C') {
          if (number < 10) {
            return '$arm${number + 1}C';
          }
          return currentCell; // Chegou ao final
        }
        
        // Para braços B e D: decrementa (B10C→B9C→...→B1C ou D10C→D9C→...→D1C)
        if (arm == 'B' || arm == 'D') {
          if (number > 1) {
            return '$arm${number - 1}C';
          }
          return currentCell; // Chegou ao final (B1C ou D1C)
        }
      }
    }

    // Casas especiais que devem passar por C (central) - Ponto de entrada na reta final
    final specialCases = {
      'C1L': 'C1C',
      'C1C': 'C1R', // Verde não entra na reta aqui (apenas quando vier do percurso)
      'B10L': 'B10C',
      'B10C': 'B10R', // Azul não entra na reta aqui
      'D10R': 'D10C',
      'D10C': 'D10L', // Amarelo não entra na reta aqui
      'A1R': 'A1C',
      'A1C': 'A1L', // Vermelho não entra na reta aqui
    };

    // Verifica se o jogador está chegando na entrada do seu próprio braço
    // e deve entrar na reta final
    if (playerArm == 'A' && currentCell == 'A1R') {
      return 'A1C'; // Vermelho entra na reta final
    }
    if (playerArm == 'B' && currentCell == 'B10L') {
      return 'B10C'; // Azul entra na reta final  
    }
    if (playerArm == 'C' && currentCell == 'C1L') {
      return 'C1C'; // Verde entra na reta final
    }
    if (playerArm == 'D' && currentCell == 'D10R') {
      return 'D10C'; // Amarelo entra na reta final
    }

    // Se está em um caso especial mas não é entrada da reta final do jogador, usa tabela
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

    var currentCell = widgets[selectedIndex].cellId;

    // Valida movimento em casas centrais (dados requeridos)
    if (!_isValidCentralMove(currentCell, steps, _currentPlayer)) {
      // Movimento inválido - mostra mensagem de erro
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Valor de dados inválido! Para avançar de $currentCell, precisa de exatamente ${_getRequiredDiceForCentralCell(currentCell) ?? "completar"} ',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // Marca como animando
    setState(() {
      _isMoving[_currentPlayer] = true;
    });

    // Anima passo a passo
    for (int i = 0; i < steps; i++) {
      await Future.delayed(const Duration(milliseconds: 250));

      if (mounted) {
        final nextCell = _getNextCell(currentCell, _currentPlayer);
        
        // Se não mudou (chegou ao final), para a animação
        if (nextCell == currentCell) {
          break;
        }

        setState(() {
          currentCell = nextCell;
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
        // Se está numa casa central, não avança automaticamente - precisa de entrada de dados precisa
        final playerArm = PlayerHelper.getArm(_currentPlayer);
        if (cellId.startsWith(playerArm) && cellId.endsWith('C')) {
          final requiredDice = _getRequiredDiceForCentralCell(cellId);
          if (requiredDice != null) {
            // Mostra mensagem indicando valor necessário
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Peça em casa central! Precisa de exatamente $requiredDice no dado para avançar.',
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.blue,
                duration: const Duration(seconds: 2),
              ),
            );
            return; // Não avança
          }
        }
        
        final nextCell = _getNextCell(cellId, _currentPlayer);
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
    if (cellId == 'A1C') {
      return Image.asset(
        'assets/ficha.png',
        fit: BoxFit.cover,
      );
    }
    return null;
  }

  /// Constrói os widgets dinâmicos presentes em uma célula
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

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1220),
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
            ),
          ],
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
        clipBehavior: Clip.none,
        children: [
          // Fundo
          Positioned.fill(
            child: Container(color: Colors.white),
          ),
          // Células (sem peças dinâmicas dentro)
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
                // Sem widgets dinâmicos (serão renderizados globalmente)
                customWidget: _buildCellImage(cell.id),
                widgetAlignment: Alignment.center,
              ),
            ),
          ),
          // Peças dinâmicas flutuantes (sem clipping)
          ..._buildFloatingPieces(geometry),
        ],
      ),
    );
  }

  /// Constrói as peças flutuantes posicionadas no tabuleiro
  List<Widget> _buildFloatingPieces(BoardGeometry geometry) {
    final pieces = <Widget>[];
    final entries = <({Player player, int index, DynamicBoardWidget widget})>[];

    for (final player in Player.values) {
      final widgets = _dynamicWidgets[player] ?? [];
      for (int i = 0; i < widgets.length; i++) {
        entries.add((player: player, index: i, widget: widgets[i]));
      }
    }

    final entriesByCell = <String, List<({Player player, int index, DynamicBoardWidget widget})>>{};
    for (final entry in entries) {
      entriesByCell.putIfAbsent(entry.widget.cellId, () => []).add(entry);
    }

    for (final cellEntries in entriesByCell.values) {
      final cell = _findCellById(geometry, cellEntries.first.widget.cellId);
      if (cell == null) {
        continue;
      }

      final pieceSize = 14 * geometry.scale.clamp(1.0, 2.2);
      final pieceSizedBoxWidth = pieceSize * 1.5;
      final pieceSizedBoxHeight = pieceSize * 2.5;

      for (int slot = 0; slot < cellEntries.length; slot++) {
        final entry = cellEntries[slot];
        final offset = _offsetForCellSlot(slot, cellEntries.length, pieceSize);

        pieces.add(
          Positioned(
            left: cell.rect.center.dx - (pieceSizedBoxWidth / 2) + offset.dx,
            top: cell.rect.center.dy - (pieceSizedBoxHeight / 2) + offset.dy,
            child: GestureDetector(
              onTap: () {
                _selectDynamicWidget(entry.player, entry.index);
              },
              child: Tooltip(
                message: 'Peça ${entry.index + 1} - Clique para selecionar',
                child: DynamicWidgetToken(
                  owner: entry.player,
                  size: pieceSize,
                  index: entry.index,
                  isSelected: _currentPlayer == entry.player && _selectedWidgetIndex[entry.player] == entry.index,
                ),
              ),
            ),
          ),
        );
      }
    }

    return pieces;
  }

  Offset _offsetForCellSlot(int slot, int totalInCell, double pieceSize) {
    if (totalInCell <= 1) {
      return Offset.zero;
    }

    if (totalInCell == 2) {
      final x = slot == 0 ? -pieceSize * 0.32 : pieceSize * 0.32;
      return Offset(x, 0);
    }

    if (totalInCell == 3) {
      if (slot == 0) {
        return Offset(0, -pieceSize * 0.34);
      }

      if (slot == 1) {
        return Offset(-pieceSize * 0.38, pieceSize * 0.24);
      }

      return Offset(pieceSize * 0.38, pieceSize * 0.24);
    }

    final radius = pieceSize * 0.44;
    final angleStep = (2 * math.pi) / totalInCell;
    final angle = -math.pi / 2 + (slot * angleStep);

    return Offset(math.cos(angle) * radius, math.sin(angle) * radius);
  }

  /// Encontra uma célula pelo ID na lista de células do tabuleiro
  dynamic _findCellById(BoardGeometry geometry, String cellId) {
    final cells = geometry.buildCells();
    try {
      return cells.firstWhere((cell) => cell.id == cellId);
    } catch (e) {
      return null;
    }
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


