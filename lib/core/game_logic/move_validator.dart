// lib/core/game_logic/move_validator.dart
import 'chess_engine.dart';

class MoveValidator {
  const MoveValidator();

  /// Check if a move is legal in the given position
  bool isValidMove(ChessBoard board, ChessMove move) {
    // Basic validation
    if (!_isBasicValidMove(board, move)) return false;
    
    // Check piece-specific move patterns
    if (!_isPieceMovementValid(board, move)) return false;
    
    // Check if move would leave king in check (we'll implement this later)
    // if (_wouldLeaveKingInCheck(board, move)) return false;
    
    return true;
  }

  /// Generate all legal moves for the current position
  List<ChessMove> generateLegalMoves(ChessBoard board) {
    final moves = <ChessMove>[];
    
    for (int file = 0; file < 8; file++) {
      for (int rank = 0; rank < 8; rank++) {
        final square = ChessSquare(file, rank);
        final piece = board.pieceAt(square);
        
        if (piece != null && piece.color == board.activeColor) {
          moves.addAll(_generateMovesForPiece(board, square, piece));
        }
      }
    }
    
    return moves.where((move) => isValidMove(board, move)).toList();
  }

  /// Basic move validation (piece exists, not capturing own piece, etc.)
  bool _isBasicValidMove(ChessBoard board, ChessMove move) {
    final piece = board.pieceAt(move.from);
    if (piece == null) return false;
    
    // Must be the right color's turn
    if (piece.color != board.activeColor) return false;
    
    // Can't capture your own piece
    final targetPiece = board.pieceAt(move.to);
    if (targetPiece?.color == piece.color) return false;
    
    return true;
  }

  /// Check if the piece movement pattern is valid
  bool _isPieceMovementValid(ChessBoard board, ChessMove move) {
    final piece = board.pieceAt(move.from)!;
    
    return switch (piece.type) {
      PieceType.pawn => _isValidPawnMove(board, move, piece),
      PieceType.rook => _isValidRookMove(board, move),
      PieceType.knight => _isValidKnightMove(move),
      PieceType.bishop => _isValidBishopMove(board, move),
      PieceType.queen => _isValidQueenMove(board, move),
      PieceType.king => _isValidKingMove(move),
    };
  }

  bool _isValidPawnMove(ChessBoard board, ChessMove move, ChessPiece pawn) {
    final from = move.from;
    final to = move.to;
    final direction = pawn.color == PieceColor.white ? 1 : -1;
    final startRank = pawn.color == PieceColor.white ? 1 : 6;
    
    final fileDiff = to.file - from.file;
    final rankDiff = to.rank - from.rank;
    
    // Forward move
    if (fileDiff == 0) {
      // One square forward
      if (rankDiff == direction) {
        return !board.isOccupied(to);
      }
      // Two squares forward from starting position
      if (rankDiff == 2 * direction && from.rank == startRank) {
        return !board.isOccupied(to) && !board.isOccupied(ChessSquare(from.file, from.rank + direction));
      }
      return false;
    }
    
    // Diagonal capture
    if (fileDiff.abs() == 1 && rankDiff == direction) {
      return board.isOccupied(to) || to == board.enPassantTarget;
    }
    
    return false;
  }

  bool _isValidRookMove(ChessBoard board, ChessMove move) {
    final from = move.from;
    final to = move.to;
    
    // Must move in straight line (horizontal or vertical)
    if (from.file != to.file && from.rank != to.rank) return false;
    
    // Check path is clear
    return _isPathClear(board, from, to);
  }

  bool _isValidKnightMove(ChessMove move) {
    final fileDiff = (move.to.file - move.from.file).abs();
    final rankDiff = (move.to.rank - move.from.rank).abs();
    
    // Knight moves in L-shape: 2+1 or 1+2
    return (fileDiff == 2 && rankDiff == 1) || (fileDiff == 1 && rankDiff == 2);
  }

  bool _isValidBishopMove(ChessBoard board, ChessMove move) {
    final from = move.from;
    final to = move.to;
    final fileDiff = (to.file - from.file).abs();
    final rankDiff = (to.rank - from.rank).abs();
    
    // Must move diagonally
    if (fileDiff != rankDiff) return false;
    
    // Check path is clear
    return _isPathClear(board, from, to);
  }

  bool _isValidQueenMove(ChessBoard board, ChessMove move) {
    // Queen moves like rook + bishop
    return _isValidRookMove(board, move) || _isValidBishopMove(board, move);
  }

  bool _isValidKingMove(ChessMove move) {
    final fileDiff = (move.to.file - move.from.file).abs();
    final rankDiff = (move.to.rank - move.from.rank).abs();
    
    // King moves one square in any direction
    return fileDiff <= 1 && rankDiff <= 1 && (fileDiff != 0 || rankDiff != 0);
  }

  /// Check if path between two squares is clear (excluding endpoints)
  bool _isPathClear(ChessBoard board, ChessSquare from, ChessSquare to) {
    final fileDiff = to.file - from.file;
    final rankDiff = to.rank - from.rank;
    
    final fileStep = fileDiff == 0 ? 0 : (fileDiff > 0 ? 1 : -1);
    final rankStep = rankDiff == 0 ? 0 : (rankDiff > 0 ? 1 : -1);
    
    int currentFile = from.file + fileStep;
    int currentRank = from.rank + rankStep;
    
    while (currentFile != to.file || currentRank != to.rank) {
      if (board.isOccupied(ChessSquare(currentFile, currentRank))) {
        return false;
      }
      currentFile += fileStep;
      currentRank += rankStep;
    }
    
    return true;
  }

  /// Generate all possible moves for a piece at a given square
  List<ChessMove> _generateMovesForPiece(ChessBoard board, ChessSquare square, ChessPiece piece) {
    return switch (piece.type) {
      PieceType.pawn => _generatePawnMoves(board, square, piece),
      PieceType.rook => _generateRookMoves(board, square),
      PieceType.knight => _generateKnightMoves(square),
      PieceType.bishop => _generateBishopMoves(board, square),
      PieceType.queen => _generateQueenMoves(board, square),
      PieceType.king => _generateKingMoves(square),
    };
  }

  List<ChessMove> _generatePawnMoves(ChessBoard board, ChessSquare square, ChessPiece pawn) {
    final moves = <ChessMove>[];
    final direction = pawn.color == PieceColor.white ? 1 : -1;
    final startRank = pawn.color == PieceColor.white ? 1 : 6;
    
    // Forward moves
    final oneForward = ChessSquare(square.file, square.rank + direction);
    if (oneForward.isValid && !board.isOccupied(oneForward)) {
      moves.add(ChessMove(from: square, to: oneForward));
      
      // Two squares forward from starting position
      if (square.rank == startRank) {
        final twoForward = ChessSquare(square.file, square.rank + 2 * direction);
        if (twoForward.isValid && !board.isOccupied(twoForward)) {
          moves.add(ChessMove(from: square, to: twoForward));
        }
      }
    }
    
    // Diagonal captures
    for (final fileOffset in [-1, 1]) {
      final captureSquare = ChessSquare(square.file + fileOffset, square.rank + direction);
      if (captureSquare.isValid) {
        if (board.hasColorAt(captureSquare, pawn.color == PieceColor.white ? PieceColor.black : PieceColor.white) ||
            captureSquare == board.enPassantTarget) {
          moves.add(ChessMove(from: square, to: captureSquare, isCapture: true));
        }
      }
    }
    
    return moves;
  }

  List<ChessMove> _generateRookMoves(ChessBoard board, ChessSquare square) {
    final moves = <ChessMove>[];
    
    // Generate moves in all four directions
    final directions = [
      (0, 1),   // Up
      (0, -1),  // Down
      (1, 0),   // Right
      (-1, 0),  // Left
    ];
    
    for (final (fileDir, rankDir) in directions) {
      for (int i = 1; i < 8; i++) {
        final newSquare = ChessSquare(square.file + i * fileDir, square.rank + i * rankDir);
        if (!newSquare.isValid) break;
        
        final targetPiece = board.pieceAt(newSquare);
        if (targetPiece == null) {
          moves.add(ChessMove(from: square, to: newSquare));
        } else {
          if (targetPiece.color != board.activeColor) {
            moves.add(ChessMove(from: square, to: newSquare, isCapture: true));
          }
          break; // Can't move past any piece
        }
      }
    }
    
    return moves;
  }

  List<ChessMove> _generateKnightMoves(ChessSquare square) {
    final moves = <ChessMove>[];
    
    final knightMoves = [
      (2, 1), (2, -1), (-2, 1), (-2, -1),
      (1, 2), (1, -2), (-1, 2), (-1, -2),
    ];
    
    for (final (fileOffset, rankOffset) in knightMoves) {
      final newSquare = ChessSquare(square.file + fileOffset, square.rank + rankOffset);
      if (newSquare.isValid) {
        moves.add(ChessMove(from: square, to: newSquare));
      }
    }
    
    return moves;
  }

  List<ChessMove> _generateBishopMoves(ChessBoard board, ChessSquare square) {
    final moves = <ChessMove>[];
    
    // Generate moves in all four diagonal directions
    final directions = [
      (1, 1),   // Up-right
      (1, -1),  // Down-right
      (-1, 1),  // Up-left
      (-1, -1), // Down-left
    ];
    
    for (final (fileDir, rankDir) in directions) {
      for (int i = 1; i < 8; i++) {
        final newSquare = ChessSquare(square.file + i * fileDir, square.rank + i * rankDir);
        if (!newSquare.isValid) break;
        
        final targetPiece = board.pieceAt(newSquare);
        if (targetPiece == null) {
          moves.add(ChessMove(from: square, to: newSquare));
        } else {
          if (targetPiece.color != board.activeColor) {
            moves.add(ChessMove(from: square, to: newSquare, isCapture: true));
          }
          break; // Can't move past any piece
        }
      }
    }
    
    return moves;
  }

  List<ChessMove> _generateQueenMoves(ChessBoard board, ChessSquare square) {
    // Queen moves like rook + bishop
    return [
      ..._generateRookMoves(board, square),
      ..._generateBishopMoves(board, square),
    ];
  }

  List<ChessMove> _generateKingMoves(ChessSquare square) {
    final moves = <ChessMove>[];
    
    for (int fileOffset = -1; fileOffset <= 1; fileOffset++) {
      for (int rankOffset = -1; rankOffset <= 1; rankOffset++) {
        if (fileOffset == 0 && rankOffset == 0) continue; // Can't stay on same square
        
        final newSquare = ChessSquare(square.file + fileOffset, square.rank + rankOffset);
        if (newSquare.isValid) {
          moves.add(ChessMove(from: square, to: newSquare));
        }
      }
    }
    
    return moves;
  }
}