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
  /// Casas iniciais: A (Vermelho): A5L, B (Azul): B6R, C (Verde): C5R, D (Amarelo): D6L
  void _initializePieces() {
    for (final player in Player.values) {
      final homeCell = PlayerHelper.getStartingCell(player);
      piecesByPlayer[player] = List.generate(
        piecesPerPlayer,
        (index) => Piece(
          player: player,
          id: '${PlayerHelper.getLabel(player)}${index + 1}',
          currentCell: null,
          homeCell: homeCell,
        ),
      );
    }
  }

  /// Retorna a célula inicial de um jogador
  String getStartingCell(Player player) {
    return PlayerHelper.getStartingCell(player);
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

  /// Remove todas as peças do tabuleiro (sem voltar para a casa inicial)
  void removeAllPiecesFromBoard() {
    for (final pieces in piecesByPlayer.values) {
      for (final piece in pieces) {
        piece.currentCell = null;
      }
    }
  }

  /// Adiciona uma peça do jogador na célula especificada
  /// Retorna true se conseguiu adicionar, false se não há peças disponíveis
  bool addPieceToCell(Player player, String cellId) {
    final pieces = getPieces(player);
    // Procura a primeira peça que não está no tabuleiro
    final availablePiece = pieces.firstWhere(
      (piece) => piece.currentCell == null,
      orElse: () => pieces.first,
    );
    
    if (availablePiece.currentCell == null) {
      availablePiece.moveTo(cellId);
      return true;
    }
    return false;
  }
}
