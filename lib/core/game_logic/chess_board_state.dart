// lib/core/game_logic/chess_board_state.dart
import 'package:flutter/foundation.dart';
import 'package:chess/chess.dart' as chess_lib;

/// Represents a chess piece with its type and color (UI model only)
class ChessPiece {
  final String type; // 'p', 'r', 'n', 'b', 'q', 'k'
  final bool isWhite;
  
  const ChessPiece({
    required this.type,
    required this.isWhite,
  });
  
  /// Create from chess package piece
  factory ChessPiece.fromChessLibPiece(dynamic piece) {
    final pieceType = piece.type.toString().toLowerCase();
    final isWhite = piece.color == chess_lib.Color.WHITE;
    return ChessPiece(type: pieceType, isWhite: isWhite);
  }
  
  @override
  String toString() => isWhite ? type.toUpperCase() : type.toLowerCase();
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChessPiece && 
      runtimeType == other.runtimeType &&
      type == other.type &&
      isWhite == other.isWhite;

  @override
  int get hashCode => type.hashCode ^ isWhite.hashCode;
}

/// Chess board state using the chess package directly
class ChessBoardState extends ChangeNotifier {
  late chess_lib.Chess _chess;
  
  // UI State
  String? _selectedSquare;
  List<String> _highlightedSquares = [];
  String? _lastMoveFrom;
  String? _lastMoveTo;
  bool _isFlipped = false;
  
  ChessBoardState() {
    _chess = chess_lib.Chess();
  }
  
  // === DIRECT CHESS PACKAGE ACCESS ===
  
  /// Current FEN position
  String get fen => _chess.fen;
  
  /// Is it white's turn?
  bool get isWhiteTurn => _chess.turn == chess_lib.Color.WHITE;
  
  /// Is current player in check?
  bool get isInCheck => _chess.in_check;
  
  /// Is the game over?
  bool get isGameOver => _chess.game_over;
  
  /// Is it checkmate?
  bool get isCheckmate => _chess.in_checkmate;
  
  /// Is it stalemate?
  bool get isStalemate => _chess.in_stalemate;
  
  /// Is it a draw?
  bool get isDraw => _chess.in_draw;
  
  /// Move history in SAN notation
  List<String> get moveHistory {
    final history = _chess.getHistory();
    return List<String>.from(history);
  }
  
  /// Game in PGN format
  String get pgn => _chess.pgn();
  
  /// Get all legal moves
  List<String> getLegalMoves() {
    final moves = _chess.moves();
    return List<String>.from(moves);
  }
  
  /// Get legal moves from a specific square
  List<String> getLegalMovesFromSquare(String square) {
    final moves = _chess.moves({'square': square});
    return List<String>.from(moves);
  }
  
  // === UI STATE ===
  
  String? get selectedSquare => _selectedSquare;
  List<String> get highlightedSquares => List.unmodifiable(_highlightedSquares);
  bool get isFlipped => _isFlipped;
  
  String? get lastMoveFrom => _lastMoveFrom;
  String? get lastMoveTo => _lastMoveTo;
  
  // === BOARD QUERIES ===
  
  /// Get piece at a square, or null if empty
  ChessPiece? getPieceAt(String square) {
    final piece = _chess.get(square);
    return piece != null ? ChessPiece.fromChessLibPiece(piece) : null;
  }
  
  /// Get all pieces on the board as a map
  Map<String, ChessPiece> getAllPieces() {
    final pieces = <String, ChessPiece>{};
    
    for (int rank = 1; rank <= 8; rank++) {
      for (int file = 0; file < 8; file++) {
        final square = '${String.fromCharCode(97 + file)}$rank'; // a1, b1, etc.
        final piece = getPieceAt(square);
        if (piece != null) {
          pieces[square] = piece;
        }
      }
    }
    
    return pieces;
  }
  
  // === MOVE OPERATIONS ===
  
  /// Select a square for move input (UI only - doesn't make moves)
  void selectSquare(String square) {
    final piece = getPieceAt(square);
    
    // If clicking on own piece, select it and show legal moves
    if (piece != null && piece.isWhite == isWhiteTurn) {
      _selectedSquare = square;
      _highlightedSquares = _getDestinationSquares(square);
      notifyListeners();
    }
    // If a piece is selected and clicking on a highlighted square, 
    // DON'T make the move here - let the widget handle it
    else if (_selectedSquare != null && _highlightedSquares.contains(square)) {
      // The widget will handle the actual move
      // Just keep the selection for now
    }
    // Otherwise, clear selection
    else {
      _clearSelection();
      notifyListeners();
    }
  }
  
  /// Make a move using from/to squares - SIMPLIFIED
  bool makeMove(String from, String to, {String? promotion}) {
    // Use chess package directly
    final moveMap = {
      'from': from,
      'to': to,
      if (promotion != null) 'promotion': promotion,
    };
    
    final success = _chess.move(moveMap);
    
    if (success) {
      _lastMoveFrom = from;
      _lastMoveTo = to;
      _clearSelection();
      notifyListeners();
    }
    
    return success;
  }

  /// Make a move using UCI notation (e.g., "e2e4")
  bool makeUciMove(String uciMove) {
    if (uciMove.length < 4) return false;
    
    final from = uciMove.substring(0, 2);
    final to = uciMove.substring(2, 4);
    final promotion = uciMove.length > 4 ? uciMove.substring(4, 5) : null;
    
    return makeMove(from, to, promotion: promotion);
  }
  
  /// Make a move using SAN notation
  bool makeSanMove(String san) {
    final success = _chess.move(san);
    
    if (success) {
      _clearSelection();
      notifyListeners();
    }
    
    return success;
  }
  
  /// Undo the last move
  bool undoMove() {
    final result = _chess.undo();
    final success = result != null;
    
    if (success) {
      _lastMoveFrom = null;
      _lastMoveTo = null;
      _clearSelection();
      notifyListeners();
    }
    
    return success;
  }
  
  // === POSITION OPERATIONS ===
  
  /// Load a position from FEN
  bool loadFen(String fen) {
    final success = _chess.load(fen);
    if (success) {
      _clearSelection();
      _lastMoveFrom = null;
      _lastMoveTo = null;
      notifyListeners();
    }
    return success;
  }
  
  /// Reset to starting position
  void reset() {
    _chess.reset();
    _clearSelection();
    _lastMoveFrom = null;
    _lastMoveTo = null;
    notifyListeners();
  }
  
  /// Flip the board orientation
  void flipBoard() {
    _isFlipped = !_isFlipped;
    notifyListeners();
  }
  
  // === HELPER METHODS ===
  
  void _clearSelection() {
    _selectedSquare = null;
    _highlightedSquares = [];
  }
  
  /// Get destination squares for legal moves from a square
  List<String> _getDestinationSquares(String from) {
    final legalMoves = getLegalMovesFromSquare(from);
    final destinations = <String>[];
    
    // Extract destination squares from SAN notation
    for (final move in legalMoves) {
      final destination = _extractDestinationFromSan(move);
      if (destination != null) {
        destinations.add(destination);
      }
    }
    
    return destinations;
  }
  
  /// Extract destination square from SAN notation
  String? _extractDestinationFromSan(String san) {
    // Remove annotations
    String cleanSan = san.replaceAll(RegExp(r'[+#x]'), '');
    
    // Handle castling
    if (cleanSan == 'O-O') {
      return isWhiteTurn ? 'g1' : 'g8';
    }
    if (cleanSan == 'O-O-O') {
      return isWhiteTurn ? 'c1' : 'c8';
    }
    
    // Look for destination square pattern
    final match = RegExp(r'([a-h][1-8])$').firstMatch(cleanSan);
    return match?.group(1);
  }
  
  /// Get ASCII representation for debugging
  String get ascii => _chess.ascii;
}