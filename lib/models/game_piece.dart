import 'piece.dart';
import 'player.dart';

/// Gerencia todas as peças do jogo para cada jogador
class GamePieceManager {
  /// Mapa de peças por jogador
  final Map<Player, List<Piece>> piecesByPlayer = {};
  
  /// Número de peças por jogador
  static const int piecesPerPlayer = 4;

  GamePieceManager() {
    _initializePieces();
  }

  /// Inicializa todas as peças na posição inicial de cada jogador
  void _initializePieces() {
    final homeCells = {
      Player.red: 'A1R',
      Player.blue: 'B1R',
      Player.green: 'C1R',
      Player.yellow: 'D1R',
    };

    for (final player in Player.values) {
      final homeCell = homeCells[player]!;
      piecesByPlayer[player] = List.generate(
        piecesPerPlayer,
        (index) => Piece(
          player: player,
          id: '${PlayerHelper.getLabel(player)}${index + 1}',
          currentCell: homeCell,
          homeCell: homeCell,
        ),
      );
    }
  }

  /// Obtém todas as peças de um jogador
  List<Piece> getPieces(Player player) {
    return piecesByPlayer[player] ?? [];
  }

  /// Obtém todas as peças no tabuleiro
  List<Piece> getAllPieces() {
    return piecesByPlayer.values.expand((pieces) => pieces).toList();
  }

  /// Obtém as peças em uma célula específica
  List<Piece> getPiecesInCell(String cellId) {
    return getAllPieces().where((piece) => piece.currentCell == cellId).toList();
  }

  /// Move uma peça para uma nova célula
  void movePiece(Piece piece, String cellId) {
    piece.moveTo(cellId);
  }

  /// Move uma peça para sua casa inicial
  void resetPiece(Piece piece) {
    piece.moveToHome();
  }

  /// Move todas as peças de um jogador para suas casas iniciais
  void resetPlayerPieces(Player player) {
    final pieces = getPieces(player);
    for (final piece in pieces) {
      piece.moveToHome();
    }
  }

  /// Limpa todas as peças do tabuleiro
  void clearAllPieces() {
    _initializePieces();
  }
}
