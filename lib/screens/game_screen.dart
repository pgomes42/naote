import 'package:flutter/material.dart';
import '../models/player.dart';
import '../models/piece.dart';
import '../models/board_geometry.dart';
import '../widgets/board_cell_widget.dart';

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
  final Map<String, List<Piece>> _piecesByCell = {};
  final Map<String, String> _textByCell = {};
  final Map<String, double> _angleByCell = {};

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
        setAngle('C${i}C', -90);

        setText('D${i}L', '${6 - i}');
        setText('D${i }R', '${6 - i}');
        setText('B${i}C', '${10 - i }');
        setText('D${i}C', '${10 - i}');
      } 
      else if( i < 10)
      {
        setText('A${i}C', '${i - 1}');
        setText('C${i}C', '${i - 1}');
        setAngle('C${i}C', -90);
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
        
        setAngle('C${i}R', 90);
        setAngle('C${i}L', -90);
        setAngle('B${i}L', -180);


        setText('B${i + 1}R', '${5 - i}');
        setText('B${i + 1}L', '${i + 5}');
        setText('D${i + 1}L', '${5 - i}');
        setText('D${i + 1}R', '${i + 5}');
      } else if (i == 5) {
        setText('A${i}L', 'F');
        setText('A${i}R', 'F');
        setText('C${i}L', 'F');
        setText('C${i}R', 'F');
    setAngle('B${i}L', -180);

        setAngle('C${i}R', 90);
        setAngle('C${i}L', -90);
        
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

        setAngle('C${i}R', 90);
        setAngle('C${i}L', -90);


        setAngle('B${i}L', -180);

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
    // Chame configureCellTexts() aqui para configurar os textos no início
    configureCellTexts();
  }

  /// Adiciona uma peça do jogador atual na célula especificada
  void _addPiece(String cellId) {
    setState(() {
      _selectedCell = cellId;
      final pieces = _piecesByCell.putIfAbsent(cellId, () => []);
      pieces.add(Piece(player: _currentPlayer));
    });
  }

  /// Remove a última peça da célula especificada
  void _removePiece(String cellId) {
    final pieces = _piecesByCell[cellId];
    if (pieces == null || pieces.isEmpty) return;
    setState(() {
      _selectedCell = cellId;
      pieces.removeLast();
      if (pieces.isEmpty) {
        _piecesByCell.remove(cellId);
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
      _piecesByCell.clear();
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
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[400]!),
      ),
      child: Row(
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
        'Célula: $_selectedCell',
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
                pieces: _piecesByCell[cell.id] ?? const [],
                selected: _selectedCell == cell.id,
                onTap: () => _addPiece(cell.id),
                onLongPress: () => _removePiece(cell.id),
                scale: geometry.scale,
                customText: _textByCell[cell.id],
                textAngleDegrees: _angleByCell[cell.id] ?? BoardCellWidget.defaultTextAngleDegrees,
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
      'Toque para adicionar peça do jogador ativo. Segure para remover a última peça.',
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey[700],
      ),
      textAlign: TextAlign.center,
    );
  }
}
