import 'package:flutter/material.dart';
import '../models/player.dart';
import '../models/piece.dart';
import '../models/game_piece.dart';
import '../models/board_geometry.dart';
import '../models/dynamic_board_widget.dart';
import '../widgets/board_cell_widget.dart';
import '../widgets/dynamic_widget_token.dart';
import 'config_screen.dart';
import 'dart:math' as math;

/// Tela principal do jogo Não Te Errites
class GameScreen extends StatefulWidget {
  final List<Player> activePlayers;
  final int piecesPerPlayer;

  const GameScreen({
    super.key,
    this.activePlayers = const [Player.red, Player.blue],
    this.piecesPerPlayer = 2,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

/// Estado da tela de jogo
class _GameScreenState extends State<GameScreen> {
  String? _selectedCell;
  late Player _currentPlayer;
  late List<Player> _activePlayers;
  late GamePieceManager _gamePieceManager;
  final Map<String, String> _textByCell = {};
  final Map<String, double> _angleByCell = {};
  final Map<Player, List<DynamicBoardWidget>> _dynamicWidgets = {};
  final Map<Player, int> _selectedWidgetIndex = {}; // Índice do widget selecionado por jogador
  late List<String> _cellSequence; // Sequência de células em sentido anti-horário
  final Map<Player, bool> _isMoving = {}; // Rastreia se um widget está animando
  final math.Random _random = math.Random();
  int? _die1;
  int? _die2;
  int? _availableDie1;
  int? _availableDie2;
  bool _hasRolledThisTurn = false;
  bool _isRollingDice = false;
  bool _isGameOver = false;
  int _rollVisualTick = 0;
  String? _selectedDiceOption; // 'die1', 'die2', 'sum' ou null

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

  String _getOffBoardCellId(Player player) {
    return 'OUT_${PlayerHelper.getArm(player)}';
  }

  bool _isOffBoardCell(String cellId) {
    return cellId.startsWith('OUT_');
  }

  void _initializeDynamicWidgets() {
    for (final player in _activePlayers) {
      _dynamicWidgets[player] = List.generate(
        widget.piecesPerPlayer,
        (index) => DynamicBoardWidget(
          cellId: _getOffBoardCellId(player),
          owner: player,
        ),
      );
      _selectedWidgetIndex[player] = 0;
      _isMoving[player] = false;
    }
  }

  @override
  void initState() {
    super.initState();
    _activePlayers = widget.activePlayers;
    _currentPlayer = _activePlayers.first;
    _gamePieceManager = GamePieceManager();
    configureCellTexts();
    
    // Calcula a sequência de células em sentido anti-horário
    final geometry = BoardGeometry(const Size(320, 320));
    _cellSequence = _buildCellSequence(geometry);
    
    // Inicializa as peças por jogador conforme configurado.
    _initializeDynamicWidgets();
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

  /// Retorna os pontos restantes para concluir no braço do jogador.
  /// Exemplos:
  /// A1C/C1C/B10C/D10C -> 10
  /// A10C/C10C/B1C/D1C -> 1
  int? _getRemainingPointsForCentralCell(String cellId, Player player) {
    final match = RegExp(r'([A-D])(\d+)C').firstMatch(cellId);
    if (match == null) return null;

    final arm = match.group(1)!;
    final playerArm = PlayerHelper.getArm(player);
    if (arm != playerArm) return null;

    final number = int.parse(match.group(2)!);
    if (number < 1 || number > 10) return null;

    if (arm == 'A' || arm == 'C') {
      return 11 - number;
    }

    // B e D terminam em 1
    return number;
  }

  bool _isFinishedCell(String cellId) {
    return cellId == 'CENTER';
  }

  bool _isPieceInField(String cellId) {
    return !_isFinishedCell(cellId) && !_isOffBoardCell(cellId);
  }

  bool _isNumericCell(String cellId) {
    if (_isFinishedCell(cellId) || _isOffBoardCell(cellId)) {
      return false;
    }

    final label = _textByCell[cellId];
    return label != null && RegExp(r'^\d+$').hasMatch(label);
  }

  bool _canApplyBonusMoveToPiece(Player player, int pieceIndex, int bonusSteps) {
    final widgets = _dynamicWidgets[player] ?? [];
    if (pieceIndex < 0 || pieceIndex >= widgets.length || bonusSteps <= 0) {
      return false;
    }

    final currentCell = widgets[pieceIndex].cellId;
    if (_isFinishedCell(currentCell) || _isOffBoardCell(currentCell)) {
      return false;
    }

    return _isValidMove(currentCell, bonusSteps, player);
  }

  List<int> _getEligibleBonusPieceIndexes(Player player, int bonusSteps) {
    final widgets = _dynamicWidgets[player] ?? [];
    final eligible = <int>[];

    for (int index = 0; index < widgets.length; index++) {
      if (_canApplyBonusMoveToPiece(player, index, bonusSteps)) {
        eligible.add(index);
      }
    }

    return eligible;
  }

  Future<int?> _showCaptureBonusPieceChooser(Player player, int bonusSteps) async {
    final widgets = _dynamicWidgets[player] ?? [];
    final eligibleIndexes = _getEligibleBonusPieceIndexes(player, bonusSteps);
    if (widgets.isEmpty || eligibleIndexes.isEmpty || !mounted) {
      return null;
    }

    final selectedIndex = await showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            title: const Text('Escolha a peça do bônus'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Selecione qual peça vai mover $bonusSteps casas:'),
                const SizedBox(height: 12),
                ...List.generate(widgets.length, (index) {
                  final pieceCell = widgets[index].cellId;
                  final isFinished = _isFinishedCell(pieceCell);
                  final canUseBonus = eligibleIndexes.contains(index);

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: PlayerHelper.getColor(player),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text('Peça ${index + 1}'),
                    subtitle: Text(
                      isFinished
                          ? 'Já está no CENTER'
                          : canUseBonus
                              ? 'Pode mover $bonusSteps casas'
                              : 'Não pode mover $bonusSteps casas',
                    ),
                    enabled: canUseBonus,
                    onTap: canUseBonus
                        ? () {
                            Navigator.of(dialogContext).pop(index);
                          }
                        : null,
                  );
                }),
              ],
            ),
          ),
        );
      },
    );

    return selectedIndex;
  }

  Future<bool> _applyBonusMove(
    Player player,
    int bonusSteps, {
    required String noEligibleMessage,
  }) async {
    final eligibleIndexes = _getEligibleBonusPieceIndexes(player, bonusSteps);
    if (eligibleIndexes.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              noEligibleMessage,
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return false;
    }

    int? chosenPieceIndex;
    final onlyInFieldIndex = _getOnlyInFieldWidgetIndex(player);

    if (onlyInFieldIndex != -1 && _canApplyBonusMoveToPiece(player, onlyInFieldIndex, bonusSteps)) {
      chosenPieceIndex = onlyInFieldIndex;
    } else if (eligibleIndexes.length == 1) {
      chosenPieceIndex = eligibleIndexes.first;
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Clique na peça que deseja contar $bonusSteps valores.',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.blueGrey,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      chosenPieceIndex = await _showCaptureBonusPieceChooser(player, bonusSteps);
      if (!mounted) return false;
    }

    if (chosenPieceIndex != null && _canApplyBonusMoveToPiece(player, chosenPieceIndex, bonusSteps)) {
      final selectedIndex = chosenPieceIndex;
      setState(() {
        _selectedWidgetIndex[player] = selectedIndex;
      });
      await _moveWidgetByBonusPoints(player, selectedIndex, bonusSteps);
      return true;
    }

    return false;
  }

  Future<void> _handleCapturesAtCell(
    String cellId,
    Player attacker, {
    bool awardBonusMove = true,
  }) async {
    if (!_isNumericCell(cellId) || !mounted) {
      return;
    }

    final capturedEntries = <({Player player, int index})>[];

    for (final player in _activePlayers) {
      if (player == attacker) {
        continue;
      }

      final widgets = _dynamicWidgets[player] ?? [];
      for (int index = 0; index < widgets.length; index++) {
        if (widgets[index].cellId == cellId) {
          capturedEntries.add((player: player, index: index));
        }
      }
    }

    if (capturedEntries.isEmpty) {
      return;
    }

    setState(() {
      for (final entry in capturedEntries) {
        final widgets = _dynamicWidgets[entry.player] ?? [];
        if (entry.index < widgets.length) {
          widgets[entry.index] = DynamicBoardWidget(
            cellId: _getOffBoardCellId(entry.player),
            owner: entry.player,
          );
        }
        _selectedWidgetIndex[entry.player] = _getFirstSelectableWidgetIndex(entry.player);
      }
    });

    var bonusApplied = false;
    if (awardBonusMove) {
      bonusApplied = await _applyBonusMove(
        attacker,
        20,
        noEligibleMessage: 'Nenhuma peça pode mover 20 casas. Bônus cancelado.',
      );
      if (!mounted) return;
    }

    final capturedPlayers = capturedEntries
        .map((entry) => PlayerHelper.getName(entry.player))
        .toSet()
        .join(', ');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Peça capturada em $cellId. Jogadores atingidos: $capturedPlayers.',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _moveWidgetByBonusPoints(Player player, int pieceIndex, int bonusSteps) async {
    final widgets = _dynamicWidgets[player] ?? [];
    if (pieceIndex < 0 || pieceIndex >= widgets.length || bonusSteps <= 0) {
      return;
    }

    var currentCell = widgets[pieceIndex].cellId;
    if (_isFinishedCell(currentCell) || _isOffBoardCell(currentCell)) {
      return;
    }

    final wasMovingBefore = _isMoving[player] ?? false;
    if (!wasMovingBefore && mounted) {
      setState(() {
        _isMoving[player] = true;
      });
    }

    try {
      for (int i = 0; i < bonusSteps; i++) {
        await Future.delayed(const Duration(milliseconds: 250));
        if (!mounted) return;

        final nextCell = _getNextCell(currentCell, player);

        if (nextCell == currentCell) {
          setState(() {
            widgets[pieceIndex] = DynamicBoardWidget(
              cellId: 'CENTER',
              owner: player,
            );
            _selectedWidgetIndex[player] = _getFirstSelectableWidgetIndex(player);
          });
          return;
        }

        setState(() {
          currentCell = nextCell;
          widgets[pieceIndex] = DynamicBoardWidget(
            cellId: nextCell,
            owner: player,
          );
        });
      }
    } finally {
      if (!wasMovingBefore && mounted) {
        setState(() {
          _isMoving[player] = false;
        });
      }
    }
  }

  int _getFirstSelectableWidgetIndex(Player player) {
    final widgets = _dynamicWidgets[player] ?? [];
    final firstInField = widgets.indexWhere((widget) => _isPieceInField(widget.cellId));
    if (firstInField >= 0) {
      return firstInField;
    }

    final firstSelectable = widgets.indexWhere((widget) => !_isFinishedCell(widget.cellId));
    return firstSelectable >= 0 ? firstSelectable : 0;
  }

  int _getFirstOffBoardWidgetIndex(Player player) {
    final widgets = _dynamicWidgets[player] ?? [];
    return widgets.indexWhere((widget) => _isOffBoardCell(widget.cellId));
  }

  int _getOnlyInFieldWidgetIndex(Player player) {
    final widgets = _dynamicWidgets[player] ?? [];
    final inFieldIndexes = <int>[];

    for (int i = 0; i < widgets.length; i++) {
      if (_isPieceInField(widgets[i].cellId)) {
        inFieldIndexes.add(i);
      }
    }

    return inFieldIndexes.length == 1 ? inFieldIndexes.first : -1;
  }

  int _getOnlyMovableWidgetIndex(Player player) {
    final widgets = _dynamicWidgets[player] ?? [];
    final movableIndexes = <int>[];

    for (int i = 0; i < widgets.length; i++) {
      if (!_isFinishedCell(widgets[i].cellId)) {
        movableIndexes.add(i);
      }
    }

    return movableIndexes.length == 1 ? movableIndexes.first : -1;
  }

  bool _isInteractionLocked() {
    return _isGameOver || _isRollingDice || _isMoving.values.any((isMoving) => isMoving);
  }

  Player _getNextPlayer(Player player) {
    final currentIndex = _activePlayers.indexOf(player);
    final nextIndex = (currentIndex + 1) % _activePlayers.length;
    return _activePlayers[nextIndex];
  }

  Future<void> _rollDice() async {
    if (_isInteractionLocked() || _hasRolledThisTurn) {
      return;
    }

    setState(() {
      _isRollingDice = true;
      _die1 = _random.nextInt(6) + 1;
      _die2 = _random.nextInt(6) + 1;
    });

    for (int i = 0; i < 12; i++) {
      await Future.delayed(const Duration(milliseconds: 60));
      if (!mounted) return;

      setState(() {
        _die1 = _random.nextInt(6) + 1;
        _die2 = _random.nextInt(6) + 1;
        _rollVisualTick++;
      });
    }

    if (!mounted) return;

    setState(() {
      _die1 = _random.nextInt(6) + 1;
      _die2 = _random.nextInt(6) + 1;
      _availableDie1 = _die1;
      _availableDie2 = _die2;
      _hasRolledThisTurn = true;
      _isRollingDice = false;
      _rollVisualTick++;
    });

    await _autoDeployPiecesFromRolledSixes();
    if (!mounted) return;

    await _autoExecuteSingleLegalMove();
    if (!mounted) return;

    await _advanceTurnIfNoMoves();
  }

  void _resetDice({bool clearFaces = false}) {
    if (clearFaces) {
      _die1 = null;
      _die2 = null;
    }
    _availableDie1 = null;
    _availableDie2 = null;
    _hasRolledThisTurn = false;
    _isRollingDice = false;
    _rollVisualTick = 0;
    _selectedDiceOption = null;
  }

  bool _canMoveFromOutsideBoard(int steps, {required bool useDie1, required bool useDie2}) {
    return steps == 6 && (useDie1 ^ useDie2);
  }

  bool _canWidgetUseMove(
    DynamicBoardWidget widget,
    Player player,
    int steps, {
    required bool useDie1,
    required bool useDie2,
  }) {
    final currentCell = widget.cellId;

    if (_isFinishedCell(currentCell)) {
      return false;
    }

    if (_isOffBoardCell(currentCell)) {
      return _canMoveFromOutsideBoard(
        steps,
        useDie1: useDie1,
        useDie2: useDie2,
      );
    }

    return _isValidMove(currentCell, steps, player);
  }

  bool _hasAnyLegalMove(Player player) {
    return _getLegalMoves(player).isNotEmpty;
  }

  List<({
    int pieceIndex,
    int steps,
    bool useDie1,
    bool useDie2,
    String option,
  })> _getLegalMoves(Player player) {
    final widgets = _dynamicWidgets[player] ?? [];
    final moveOptions = <({int steps, bool useDie1, bool useDie2})>[];
    final legalMoves = <({
      int pieceIndex,
      int steps,
      bool useDie1,
      bool useDie2,
      String option,
    })>[];
    final seenKeys = <String>{};

    if (_availableDie1 != null) {
      moveOptions.add((steps: _availableDie1!, useDie1: true, useDie2: false));
    }

    if (_availableDie2 != null) {
      moveOptions.add((steps: _availableDie2!, useDie1: false, useDie2: true));
    }

    if (_availableDie1 != null && _availableDie2 != null) {
      moveOptions.add((
        steps: _availableDie1! + _availableDie2!,
        useDie1: true,
        useDie2: true,
      ));
    }

    for (int pieceIndex = 0; pieceIndex < widgets.length; pieceIndex++) {
      final widget = widgets[pieceIndex];
      for (final option in moveOptions) {
        if (_canWidgetUseMove(
          widget,
          player,
          option.steps,
          useDie1: option.useDie1,
          useDie2: option.useDie2,
        )) {
          final optionKey = option.useDie1 && option.useDie2
              ? 'sum_${option.steps}'
              : 'single_${option.steps}';
          final dedupeKey = '${pieceIndex}_$optionKey';

          if (seenKeys.add(dedupeKey)) {
            legalMoves.add((
              pieceIndex: pieceIndex,
              steps: option.steps,
              useDie1: option.useDie1,
              useDie2: option.useDie2,
              option: option.useDie1 && option.useDie2
                  ? 'sum'
                  : option.useDie1
                      ? 'die1'
                      : 'die2',
            ));
          }
        }
      }
    }

    return legalMoves;
  }

  int _compareLegalMovePriority(
    ({
      int pieceIndex,
      int steps,
      bool useDie1,
      bool useDie2,
      String option,
    }) a,
    ({
      int pieceIndex,
      int steps,
      bool useDie1,
      bool useDie2,
      String option,
    }) b,
  ) {
    final stepsCompare = b.steps.compareTo(a.steps);
    if (stepsCompare != 0) {
      return stepsCompare;
    }

    final aIsSum = a.useDie1 && a.useDie2;
    final bIsSum = b.useDie1 && b.useDie2;
    if (aIsSum != bIsSum) {
      return bIsSum ? 1 : -1;
    }

    if (a.useDie1 != b.useDie1) {
      return a.useDie1 ? -1 : 1;
    }

    return 0;
  }

  bool _isCentralCellForPlayer(String cellId, Player player) {
    final playerArm = PlayerHelper.getArm(player);
    return cellId.startsWith(playerArm) && cellId.endsWith('C');
  }

  Future<void> _advanceTurnIfNoMoves() async {
    if (!_hasRolledThisTurn || _hasAnyLegalMove(_currentPlayer)) {
      return;
    }

    final blockedPlayer = _currentPlayer;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Jogador ${PlayerHelper.getName(blockedPlayer)} sem jogadas válidas. Turno encerrado.',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.blueGrey,
          duration: const Duration(seconds: 2),
        ),
      );
    }

    if (!mounted) return;

    setState(() {
      _resetDice();
      _currentPlayer = _getNextPlayer(blockedPlayer);
      _selectedWidgetIndex[_currentPlayer] = _getFirstSelectableWidgetIndex(_currentPlayer);
    });
  }

  Future<void> _autoExecuteSingleLegalMove() async {
    if (!_hasRolledThisTurn || (_isMoving[_currentPlayer] ?? false) || _isRollingDice) {
      return;
    }

    final legalMoves = _getLegalMoves(_currentPlayer);
    if (legalMoves.isEmpty) {
      return;
    }

    final onlyInFieldIndex = _getOnlyInFieldWidgetIndex(_currentPlayer);
    final onlyMovableIndex = _getOnlyMovableWidgetIndex(_currentPlayer);

    ({
      int pieceIndex,
      int steps,
      bool useDie1,
      bool useDie2,
      String option,
    })? move;

    if (legalMoves.length == 1) {
      move = legalMoves.single;
    } else if (onlyInFieldIndex != -1) {
      final movesForOnlyInFieldPiece = legalMoves
          .where((legalMove) => legalMove.pieceIndex == onlyInFieldIndex)
          .toList()
        ..sort((a, b) {
          final stepsCompare = b.steps.compareTo(a.steps);
          if (stepsCompare != 0) {
            return stepsCompare;
          }

          final aIsSum = a.useDie1 && a.useDie2;
          final bIsSum = b.useDie1 && b.useDie2;
          if (aIsSum != bIsSum) {
            return bIsSum ? 1 : -1;
          }

          if (a.useDie1 != b.useDie1) {
            return a.useDie1 ? -1 : 1;
          }

          return 0;
        });

      if (movesForOnlyInFieldPiece.isNotEmpty) {
        move = movesForOnlyInFieldPiece.first;
      }
    } else if (onlyMovableIndex != -1) {
      final movesForOnlyPiece = legalMoves
          .where((legalMove) => legalMove.pieceIndex == onlyMovableIndex)
          .toList()
        ..sort((a, b) {
          final stepsCompare = b.steps.compareTo(a.steps);
          if (stepsCompare != 0) {
            return stepsCompare;
          }

          final aIsSum = a.useDie1 && a.useDie2;
          final bIsSum = b.useDie1 && b.useDie2;
          if (aIsSum != bIsSum) {
            return bIsSum ? 1 : -1;
          }

          if (a.useDie1 != b.useDie1) {
            return a.useDie1 ? -1 : 1;
          }

          return 0;
        });

      if (movesForOnlyPiece.isNotEmpty) {
        move = movesForOnlyPiece.first;
      }
    }

    if (move == null) {
      return;
    }

    final selectedMove = move;

    setState(() {
      _selectedWidgetIndex[_currentPlayer] = selectedMove.pieceIndex;
      _selectedDiceOption = selectedMove.option;
    });

    final moved = await _playDiceMove(
      selectedMove.steps,
      useDie1: selectedMove.useDie1,
      useDie2: selectedMove.useDie2,
    );

    if (!mounted || !moved) {
      return;
    }

    setState(() {
      _selectedDiceOption = null;
    });
  }

  Future<void> _autoDeployPiecesFromRolledSixes() async {
    if (!_hasRolledThisTurn) {
      return;
    }

    if (_availableDie1 == 6) {
      final offBoardIndex = _getFirstOffBoardWidgetIndex(_currentPlayer);
      if (offBoardIndex != -1) {
        setState(() {
          _selectedWidgetIndex[_currentPlayer] = offBoardIndex;
          _selectedDiceOption = null;
        });

        await _playDiceMove(6, useDie1: true, useDie2: false);
        if (!mounted) return;
      }
    }

    if (_availableDie2 == 6) {
      final offBoardIndex = _getFirstOffBoardWidgetIndex(_currentPlayer);
      if (offBoardIndex != -1) {
        setState(() {
          _selectedWidgetIndex[_currentPlayer] = offBoardIndex;
          _selectedDiceOption = null;
        });

        await _playDiceMove(6, useDie1: false, useDie2: true);
      }
    }
  }

  Future<bool> _playDiceMove(int steps, {required bool useDie1, required bool useDie2}) async {
    if (!_hasRolledThisTurn || (_isMoving[_currentPlayer] ?? false)) {
      return false;
    }

    final moved = await _moveSelectedWidgetNCells(
      steps,
      useDie1: useDie1,
      useDie2: useDie2,
    );
    if (!moved) {
      return false;
    }

    if (_isGameOver) {
      return true;
    }

    final rolledDouble = _die1 != null && _die1 == _die2;
    if (!mounted) return false;

    var shouldKeepTurn = false;
    setState(() {
      if (useDie1) {
        _availableDie1 = null;
      }
      if (useDie2) {
        _availableDie2 = null;
      }

      final hasRemainingDice = _availableDie1 != null || _availableDie2 != null;
      shouldKeepTurn = rolledDouble || hasRemainingDice;

      if (!hasRemainingDice) {
        _resetDice();
      }

      if (!shouldKeepTurn) {
        _currentPlayer = _getNextPlayer(_currentPlayer);
      }
      _selectedWidgetIndex[_currentPlayer] = _getFirstSelectableWidgetIndex(_currentPlayer);
    });

    if (rolledDouble && _availableDie1 == null && _availableDie2 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Dupla! Jogue novamente.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }

    await _autoExecuteSingleLegalMove();

    await _advanceTurnIfNoMoves();

    return true;
  }

  Future<void> _executeSelectedMove() async {
    if (_selectedDiceOption == null) return;

    bool useDie1 = false;
    bool useDie2 = false;
    int steps = 0;

    if (_selectedDiceOption == 'die1') {
      steps = _availableDie1 ?? 0;
      useDie1 = true;
    } else if (_selectedDiceOption == 'die2') {
      steps = _availableDie2 ?? 0;
      useDie2 = true;
    } else if (_selectedDiceOption == 'sum') {
      steps = (_availableDie1 ?? 0) + (_availableDie2 ?? 0);
      useDie1 = true;
      useDie2 = true;
    }

    final legalMoves = _getLegalMoves(_currentPlayer);
    final legalPieceIndexes = legalMoves.map((move) => move.pieceIndex).toSet();

    if (legalPieceIndexes.length == 1) {
      final forcedPieceIndex = legalPieceIndexes.first;
      final widgets = _dynamicWidgets[_currentPlayer] ?? [];

      if (forcedPieceIndex < widgets.length) {
        final forcedCell = widgets[forcedPieceIndex].cellId;
        if (_isCentralCellForPlayer(forcedCell, _currentPlayer)) {
          final forcedMoves = legalMoves
              .where((move) => move.pieceIndex == forcedPieceIndex)
              .toList()
            ..sort(_compareLegalMovePriority);

          if (forcedMoves.isNotEmpty) {
            final forcedMove = forcedMoves.first;
            steps = forcedMove.steps;
            useDie1 = forcedMove.useDie1;
            useDie2 = forcedMove.useDie2;

            if (mounted) {
              setState(() {
                _selectedWidgetIndex[_currentPlayer] = forcedPieceIndex;
                _selectedDiceOption = forcedMove.option;
              });
            }
          }
        }
      }
    }

    if (steps <= 0) return;

    final moved = await _playDiceMove(steps, useDie1: useDie1, useDie2: useDie2);
    if (!mounted) return;
    if (moved) {
      setState(() {
        _selectedDiceOption = null;
      });
    }
  }

  Future<void> _handleDiceSelection(String option) async {
    if (_isInteractionLocked()) {
      return;
    }

    if (!_hasRolledThisTurn) {
      await _rollDice();
      return;
    }

    final onlyInFieldIndex = _getOnlyInFieldWidgetIndex(_currentPlayer);

    setState(() {
      _selectedDiceOption = option;
      if (onlyInFieldIndex != -1) {
        _selectedWidgetIndex[_currentPlayer] = onlyInFieldIndex;
      }
    });

    if (onlyInFieldIndex != -1) {
      await _executeSelectedMove();
    }
  }

  Future<void> _showCompletionCelebration(Player player) async {
    if (!mounted) return;

    final overlayState = Overlay.of(context);
    if (overlayState == null) return;

    final playerColor = PlayerHelper.getColor(player);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) {
        return IgnorePointer(
          child: Positioned.fill(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(seconds: 1),
              curve: Curves.easeOut,
              builder: (context, value, _) {
                return CustomPaint(
                  painter: _BurstBalloonsPainter(
                    progress: value,
                    color: playerColor,
                  ),
                );
              },
            ),
          ),
        );
      },
    );

    overlayState.insert(entry);
    await Future.delayed(const Duration(seconds: 1));
    entry.remove();
  }

  bool _hasPlayerFinishedAllPieces(Player player) {
    final widgets = _dynamicWidgets[player] ?? [];
    if (widgets.isEmpty) {
      return false;
    }

    return widgets.every((widget) => _isFinishedCell(widget.cellId));
  }

  Future<void> _showWinnerDialog(Player winner) async {
    if (!mounted) {
      return;
    }

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Fim de jogo',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 450),
      pageBuilder: (context, animation, secondaryAnimation) {
        final winnerName = PlayerHelper.getName(winner);
        final winnerColor = PlayerHelper.getColor(winner);

        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 340,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: winnerColor, width: 3),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 14, offset: Offset(0, 6)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.emoji_events, size: 54, color: winnerColor),
                  const SizedBox(height: 12),
                  const Text(
                    'Fim de Jogo!',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$winnerName terminou todas as peças!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: winnerColor,
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const ConfigScreen(),
                          ),
                        );
                      },
                      child: const Text('Voltar à configuração'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.75, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  Future<void> _handleGameOver(Player winner) async {
    if (_isGameOver || !mounted) {
      return;
    }

    setState(() {
      _isGameOver = true;
      _resetDice();
    });

    await _showWinnerDialog(winner);
  }

  /// Retorna quantos movimentos ainda faltam para a peça chegar ao CENTER.
  int? _getRemainingMovesToFinish(String currentCell, Player player) {
    if (_isOffBoardCell(currentCell)) {
      return null;
    }

    // Peça já finalizada não pode mover
    if (_isFinishedCell(currentCell)) {
      return 0;
    }

    var probeCell = currentCell;
    var moves = 0;

    // Limite de segurança para evitar loops inesperados
    while (moves < 200) {
      final nextCell = _getNextCell(probeCell, player);

      // Ao parar na última casa do braço, falta exatamente 1 para entrar no CENTER
      if (nextCell == probeCell) {
        return moves + 1;
      }

      probeCell = nextCell;
      moves++;
    }

    return null;
  }

  /// Valida se um movimento é permitido baseado no total restante até o CENTER.
  bool _isValidMove(String currentCell, int steps, Player player) {
    final remainingMoves = _getRemainingMovesToFinish(currentCell, player);
    if (remainingMoves == null || remainingMoves == 0) {
      return false;
    }

    return steps <= remainingMoves;
  }

  /// Calcula a próxima célula na sequência anti-horária
  String _getNextCell(String currentCell, Player player) {
    if (_isFinishedCell(currentCell)) {
      return currentCell;
    }

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
  Future<bool> _moveSelectedWidgetNCells(
    int steps, {
    required bool useDie1,
    required bool useDie2,
  }) async {
    final movingPlayer = _currentPlayer;
    final widgets = _dynamicWidgets[movingPlayer] ?? [];
    final selectedIndex = _selectedWidgetIndex[movingPlayer] ?? 0;

    if (selectedIndex >= widgets.length || steps <= 0) return false;

    var currentCell = widgets[selectedIndex].cellId;

    if (_isOffBoardCell(currentCell)) {
      final canEnterBoard = _canMoveFromOutsideBoard(
        steps,
        useDie1: useDie1,
        useDie2: useDie2,
      );

      if (!canEnterBoard) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Peças fora da quadra só entram com um dado de valor 6.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.deepOrange,
            duration: Duration(seconds: 2),
          ),
        );
        return false;
      }

      final entryCell = PlayerHelper.getStartingCell(movingPlayer);
      setState(() {
        widgets[selectedIndex] = DynamicBoardWidget(
          cellId: entryCell,
          owner: movingPlayer,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Peça do jogador ${PlayerHelper.getName(movingPlayer)} entrou em jogo.',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      return true;
    }

    // Não permite mover peça já concluída
    if (_isFinishedCell(currentCell)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Esta peça já completou o ciclo.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return false;
    }

    // Valida movimento pelo total restante até o CENTER
    if (!_isValidMove(currentCell, steps, movingPlayer)) {
      return false;
    }

    final remaining = _getRemainingMovesToFinish(currentCell, movingPlayer);
    final completesCycle = remaining != null && steps == remaining;

    int stepsToAnimate = steps;
    if (completesCycle) {
      // O último movimento é a entrada no CENTER.
      stepsToAnimate = steps - 1;
    }

    // Marca como animando
    setState(() {
      _isMoving[movingPlayer] = true;
    });

    // Anima passo a passo
    for (int i = 0; i < stepsToAnimate; i++) {
      await Future.delayed(const Duration(milliseconds: 250));

      if (mounted) {
        final nextCell = _getNextCell(currentCell, movingPlayer);
        
        // Se não mudou (chegou ao final), para a animação
        if (nextCell == currentCell) {
          break;
        }

        setState(() {
          currentCell = nextCell;
          widgets[selectedIndex] = DynamicBoardWidget(
            cellId: nextCell,
            owner: movingPlayer,
          );
        });
      }
    }

    if (mounted && completesCycle) {
      setState(() {
        widgets[selectedIndex] = DynamicBoardWidget(
          cellId: 'CENTER',
          owner: movingPlayer,
        );
        _selectedWidgetIndex[movingPlayer] = _getFirstSelectableWidgetIndex(movingPlayer);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Peça do lado ${PlayerHelper.getArm(movingPlayer)} completou o ciclo e ficou no CENTER!',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      await _showCompletionCelebration(movingPlayer);

      if (_hasPlayerFinishedAllPieces(movingPlayer)) {
        await _handleGameOver(movingPlayer);
        if (!mounted) return false;
      }

      if (_isGameOver) {
        if (mounted) {
          setState(() {
            _isMoving[movingPlayer] = false;
          });
        }
        return true;
      }

      final completionBonusApplied = await _applyBonusMove(
        movingPlayer,
        10,
        noEligibleMessage: 'Nenhuma peça pode mover 10 casas. Bônus de término cancelado.',
      );
      if (!mounted) return false;
    }

    if (mounted && !completesCycle) {
      await _handleCapturesAtCell(
        currentCell,
        movingPlayer,
      );
    }

    // Marca como não animando e reseta para o primeiro widget
    if (mounted) {
      setState(() {
        _isMoving[movingPlayer] = false;
        _selectedWidgetIndex[movingPlayer] = _getFirstSelectableWidgetIndex(movingPlayer);
      });
    }

    return true;
  }

  /// Seleciona uma célula e move o widget selecionado se estiver nela
  void _selectCell(String cellId) {
    if (_isInteractionLocked()) {
      return;
    }

    setState(() {
      _selectedCell = cellId;

      final widgets = _dynamicWidgets[_currentPlayer] ?? [];
      final selectedIndex = _selectedWidgetIndex[_currentPlayer] ?? 0;
      if (selectedIndex < widgets.length && widgets[selectedIndex].cellId == cellId) {
        if (_isFinishedCell(cellId)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Esta peça já está no CENTER e não pode mover.',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }

        // Se está numa casa central, não avança automaticamente - precisa de entrada de dados precisa
        final playerArm = PlayerHelper.getArm(_currentPlayer);
        if (cellId.startsWith(playerArm) && cellId.endsWith('C')) {
          final remaining = _getRemainingMovesToFinish(cellId, _currentPlayer);
          if (remaining != null) {
            // Mostra mensagem com o total restante até o CENTER
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Peça em casa central! Restam até $remaining movimentos possíveis até o CENTER.',
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
    if (_isInteractionLocked()) {
      return;
    }

    if (player != _currentPlayer) {
      return;
    }

    final widgets = _dynamicWidgets[player] ?? [];
    if (index < widgets.length && _isFinishedCell(widgets[index].cellId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Peça concluída no CENTER não pode ser selecionada.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _selectedWidgetIndex[player] = index;
    });

    if (_selectedDiceOption != null) {
      _executeSelectedMove();
    }
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
      _selectedWidgetIndex[player] = _getFirstSelectableWidgetIndex(player);
      _resetDice();
    });
  }

  /// Limpa todas as peças do tabuleiro
  void _clearBoard() {
    setState(() {
      _gamePieceManager.removeAllPiecesFromBoard();
      _initializeDynamicWidgets();
      _angleByCell.clear();
      _selectedCell = null;
      _currentPlayer = _activePlayers.first;
      _isGameOver = false;
      _resetDice(clearFaces: true);
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
          onPressed: _isInteractionLocked() ? null : _clearBoard,
          tooltip: 'Limpar tabuleiro',
        ),
        IconButton(
          icon: const Icon(Icons.settings, color: Colors.white),
          onPressed: _isInteractionLocked()
              ? null
              : () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const ConfigScreen(),
                    ),
                  );
                },
          tooltip: 'Voltar à configuração',
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
            AbsorbPointer(
              absorbing: _isInteractionLocked(),
              child: Center(
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
                          _buildBoard(geometry, cells),
                        ],
                      ),
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
              ..._activePlayers.map((player) => _buildPlayerButton(player)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Dados:', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: ((_isMoving[_currentPlayer] ?? false) || _isRollingDice)
                    ? null
                    : () async {
                        if (!_hasRolledThisTurn) {
                          await _rollDice();
                        } else if (_availableDie1 != null) {
                          await _handleDiceSelection('die1');
                        }
                      },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _selectedDiceOption == 'die1' ? Colors.green : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: _buildDieFace(
                    _die1,
                    isAvailable: _availableDie1 != null || !_hasRolledThisTurn,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: ((_isMoving[_currentPlayer] ?? false) || _isRollingDice)
                    ? null
                    : () async {
                        if (!_hasRolledThisTurn) {
                          await _rollDice();
                        } else if (_availableDie2 != null) {
                          await _handleDiceSelection('die2');
                        }
                      },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _selectedDiceOption == 'die2' ? Colors.green : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: _buildDieFace(
                    _die2,
                    isAvailable: _availableDie2 != null || !_hasRolledThisTurn,
                  ),
                ),
              ),
            ],
          ),
          if (_hasRolledThisTurn && _die1 != null && _die2 != null) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 12,
              children: [
                // Opção Soma (se ambos dados disponíveis)
                if (_availableDie1 != null && _availableDie2 != null)
                  GestureDetector(
                    onTap: ((_isMoving[_currentPlayer] ?? false) || _isRollingDice)
                        ? null
                        : () async {
                            await _handleDiceSelection('sum');
                          },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _selectedDiceOption == 'sum'
                              ? Colors.green
                              : Colors.transparent,
                          width: 3,
                        ),
                        color: Colors.grey[100],
                      ),
                      child: Text(
                        'Soma: ${_availableDie1! + _availableDie2!}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDieFace(int? value, {required bool isAvailable}) {
    final faceValue = value ?? 1;
    final rotationAngle = _isRollingDice 
      ? (_rollVisualTick * (1 + (_random.nextDouble() - 0.5) * 0.5)) 
      : 0.0;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: _isRollingDice ? 1 : 0),
      duration: const Duration(milliseconds: 100),
      curve: Curves.linear,
      builder: (context, rollProgress, _) {
        final bounceScale = _isRollingDice 
          ? 1.0 + (math.sin(rollProgress * math.pi * 3) * 0.12).clamp(-0.12, 0.15)
          : 1.0;
        final bounceOffset = _isRollingDice 
          ? math.sin(rollProgress * math.pi * 2) * 8
          : 0.0;

        return Transform.translate(
          offset: Offset(0, bounceOffset),
          child: AnimatedRotation(
            turns: rotationAngle,
            duration: const Duration(milliseconds: 80),
            child: AnimatedScale(
              scale: bounceScale,
              duration: const Duration(milliseconds: 100),
              child: AnimatedOpacity(
                opacity: isAvailable ? 1 : 0.35,
                duration: const Duration(milliseconds: 200),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Face lateral direita (sombra 3D)
                    Transform.translate(
                      offset: const Offset(6, 4),
                      child: Container(
                        width: 14,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.grey[400]!.withValues(alpha: 0.4),
                              Colors.grey[600]!.withValues(alpha: 0.6),
                            ],
                          ),
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    // Face lateral superior (sombra 3D)
                    Transform.translate(
                      offset: const Offset(3, -6),
                      child: Container(
                        width: 56,
                        height: 14,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.grey[300]!.withValues(alpha: 0.5),
                              Colors.grey[500]!.withValues(alpha: 0.4),
                            ],
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    // Face frontal principal
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white,
                            Colors.grey[200]!,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.grey[400]!,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                            spreadRadius: 1,
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: _DicePips(value: faceValue),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Constrói um botão para selecionar um jogador
  Widget _buildPlayerButton(Player player) {
    final isSelected = _currentPlayer == player;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: null,
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

    for (final player in _activePlayers) {
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
      if (_isOffBoardCell(cellEntries.first.widget.cellId)) {
        pieces.addAll(_buildOffBoardPieces(geometry, cellEntries));
        continue;
      }

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
        final canSelect = !_isFinishedCell(entry.widget.cellId);

        pieces.add(
          Positioned(
            left: cell.rect.center.dx - (pieceSizedBoxWidth / 2) + offset.dx,
            top: cell.rect.center.dy - (pieceSizedBoxHeight / 2) + offset.dy,
            child: GestureDetector(
              onTap: canSelect
                  ? () {
                      _selectDynamicWidget(entry.player, entry.index);
                    }
                  : null,
              child: DynamicWidgetToken(
                owner: entry.player,
                size: pieceSize,
                index: entry.index,
                isSelected: canSelect && _currentPlayer == entry.player && _selectedWidgetIndex[entry.player] == entry.index,
              ),
            ),
          ),
        );
      }
    }

    return pieces;
  }

  List<Widget> _buildOffBoardPieces(
    BoardGeometry geometry,
    List<({Player player, int index, DynamicBoardWidget widget})> cellEntries,
  ) {
    final pieces = <Widget>[];
    final player = cellEntries.first.player;
    final pieceSize = 14 * geometry.scale.clamp(1.0, 2.2);
    final pieceSizedBoxWidth = pieceSize * 1.5;
    final pieceSizedBoxHeight = pieceSize * 2.5;
    final anchor = _getOffBoardAnchor(
      geometry,
      player,
      pieceSizedBoxWidth,
      pieceSizedBoxHeight,
    );

    for (int slot = 0; slot < cellEntries.length; slot++) {
      final entry = cellEntries[slot];
      final offset = _offsetForOffBoardSlot(player, slot, pieceSize);

      pieces.add(
        Positioned(
          left: anchor.dx + offset.dx,
          top: anchor.dy + offset.dy,
          child: GestureDetector(
            onTap: () {
              _selectDynamicWidget(entry.player, entry.index);
            },
            child: DynamicWidgetToken(
              owner: entry.player,
              size: pieceSize,
              index: entry.index,
              isSelected: _currentPlayer == entry.player && _selectedWidgetIndex[entry.player] == entry.index,
            ),
          ),
        ),
      );
    }

    return pieces;
  }

  Offset _getOffBoardAnchor(
    BoardGeometry geometry,
    Player player,
    double pieceWidth,
    double pieceHeight,
  ) {
    switch (player) {
      case Player.red:
        return Offset(geometry.size.width * 0.15, -(pieceHeight * 0.9));
        // Canto superior esquerdo
        return const Offset(15, 15);
      case Player.blue:
        return Offset(geometry.size.width + (pieceWidth * 0.1), geometry.size.height * 0.18);
        // Canto superior direito
        return Offset(geometry.size.width - (pieceWidth * 2) - 15, 15);
      case Player.green:
        return Offset(geometry.size.width * 0.72, geometry.size.height + (pieceHeight * 0.1));
        // Canto inferior direito
        return Offset(geometry.size.width - (pieceWidth * 2) - 15, geometry.size.height - (pieceHeight * 2) - 15);
      case Player.yellow:
        return Offset(-(pieceWidth * 1.1), geometry.size.height * 0.7);
        // Canto inferior esquerdo
        return Offset(15, geometry.size.height - (pieceHeight * 2) - 15);
    }
  }

  Offset _offsetForOffBoardSlot(Player player, int slot, double pieceSize) {
    final delta = pieceSize * 0.95;
    // Organiza as peças numa grelha 2x2
    final deltaX = pieceSize * 1.5; // Largura do PinPieceWidget
    final deltaY = pieceSize * 2.5; // Altura do PinPieceWidget

    switch (player) {
      case Player.red:
      case Player.green:
        return Offset(slot * delta, 0);
      case Player.blue:
      case Player.yellow:
        return Offset(0, slot * delta);
    }
    final col = slot % 2;
    final row = slot ~/ 2;

    return Offset(col * deltaX, row * deltaY);
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

}

class _BurstBalloonsPainter extends CustomPainter {
  _BurstBalloonsPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final fade = (1 - progress).clamp(0.0, 1.0);
    final corePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withValues(alpha: 0.95 * fade);

    final glowPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withValues(alpha: 0.35 * fade);

    final shortestSide = size.shortestSide;
    final origins = [
      Offset(size.width * 0.5, size.height * 0.5),
      Offset(size.width * 0.5, size.height * 0.35),
      Offset(size.width * 0.5, size.height * 0.65),
      Offset(size.width * 0.36, size.height * 0.58),
      Offset(size.width * 0.36, size.height * 0.42),
      Offset(size.width * 0.64, size.height * 0.42),
      Offset(size.width * 0.64, size.height * 0.58),
    ];

    const particles = 16;
    for (final origin in origins) {
      for (int index = 0; index < particles; index++) {
        final angle = (2 * math.pi * index) / particles;
        final distance = shortestSide * (0.04 + (0.20 * progress));
        final center = Offset(
          origin.dx + math.cos(angle) * distance,
          origin.dy + math.sin(angle) * distance,
        );
        final radius = (shortestSide * 0.013) * (1 - (progress * 0.6));
        canvas.drawCircle(center, radius * 1.8, glowPaint);
        canvas.drawCircle(center, radius, corePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BurstBalloonsPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class _DicePips extends StatelessWidget {
  const _DicePips({required this.value});

  final int value;

  static const _positions = {
    'tl': Alignment.topLeft,
    'tc': Alignment.topCenter,
    'tr': Alignment.topRight,
    'cl': Alignment.centerLeft,
    'cc': Alignment.center,
    'cr': Alignment.centerRight,
    'bl': Alignment.bottomLeft,
    'bc': Alignment.bottomCenter,
    'br': Alignment.bottomRight,
  };

  List<String> _pipKeysForValue(int v) {
    switch (v) {
      case 1:
        return ['cc'];
      case 2:
        return ['tl', 'br'];
      case 3:
        return ['tl', 'cc', 'br'];
      case 4:
        return ['tl', 'tr', 'bl', 'br'];
      case 5:
        return ['tl', 'tr', 'cc', 'bl', 'br'];
      case 6:
        return ['tl', 'tr', 'cl', 'cr', 'bl', 'br'];
      default:
        return ['cc'];
    }
  }

  Color _getPipColor() {
    if (value == 1 || value == 4) {
      return const Color(0xFFDD3333); // Vermelho
    } else {
      return const Color(0xFF3366DD); // Azul
    }
  }

  @override
  Widget build(BuildContext context) {
    final pips = _pipKeysForValue(value);
    final pipColor = _getPipColor();

    return Stack(
      children: [
        for (final key in pips)
          Align(
            alignment: _positions[key]!,
            child: Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(-0.4, -0.4),
                  radius: 0.9,
                  colors: [
                    pipColor.withValues(alpha: 0.9),
                    (pipColor.withValues(alpha: 0.6)).withRed((pipColor.red * 0.6).toInt()),
                  ],
                  stops: const [0.0, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: pipColor.withValues(alpha: 0.5),
                    blurRadius: 3,
                    offset: const Offset(1, 2),
                    spreadRadius: 0.5,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}


