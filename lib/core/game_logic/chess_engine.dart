// lib/core/game_logic/chess_engine.dart
import 'package:equatable/equatable.dart';

enum PieceColor { white, black }
enum PieceType { pawn, rook, knight, bishop, queen, king }

class ChessPiece extends Equatable {
  final PieceType type;
  final PieceColor color;

  const ChessPiece(this.type, this.color);

  @override
  List<Object> get props => [type, color];

  @override
  String toString() => '${color.name[0].toUpperCase()}${type.name[0].toUpperCase()}';

  // FEN notation representation
  String get fenChar {
    final char = switch (type) {
      PieceType.pawn => 'p',
      PieceType.rook => 'r',
      PieceType.knight => 'n',
      PieceType.bishop => 'b',
      PieceType.queen => 'q',
      PieceType.king => 'k',
    };
    return color == PieceColor.white ? char.toUpperCase() : char;
  }

  // Create piece from FEN character
  static ChessPiece? fromFen(String fenChar) {
    if (fenChar.isEmpty) return null;
    
    final color = fenChar == fenChar.toUpperCase() ? PieceColor.white : PieceColor.black;
    final type = switch (fenChar.toLowerCase()) {
      'p' => PieceType.pawn,
      'r' => PieceType.rook,
      'n' => PieceType.knight,
      'b' => PieceType.bishop,
      'q' => PieceType.queen,
      'k' => PieceType.king,
      _ => null,
    };
    
    return type != null ? ChessPiece(type, color) : null;
  }
}

class ChessSquare extends Equatable {
  final int file; // 0-7 (a-h)
  final int rank; // 0-7 (1-8)

  const ChessSquare(this.file, this.rank);

  bool get isValid => file >= 0 && file <= 7 && rank >= 0 && rank <= 7;

  String get algebraic => '${String.fromCharCode(97 + file)}${rank + 1}';

  static ChessSquare? fromAlgebraic(String notation) {
    if (notation.length != 2) return null;
    
    final file = notation.codeUnitAt(0) - 97; // 'a' = 97
    final rank = int.tryParse(notation[1]) ?? 0;
    
    final square = ChessSquare(file, rank - 1);
    return square.isValid ? square : null;
  }

  @override
  List<Object> get props => [file, rank];

  @override
  String toString() => algebraic;
}

class ChessMove extends Equatable {
  final ChessSquare from;
  final ChessSquare to;
  final ChessPiece? promotion; // For pawn promotion
  final bool isCapture;
  final bool isCheck;
  final bool isCheckmate;

  const ChessMove({
    required this.from,
    required this.to,
    this.promotion,
    this.isCapture = false,
    this.isCheck = false,
    this.isCheckmate = false,
  });

  @override
  List<Object?> get props => [from, to, promotion, isCapture, isCheck, isCheckmate];

  @override
  String toString() => '${from.algebraic}${to.algebraic}';

  // Create move from algebraic notation like "e2e4"
  static ChessMove? fromAlgebraic(String notation) {
    if (notation.length < 4) return null;
    
    final from = ChessSquare.fromAlgebraic(notation.substring(0, 2));
    final to = ChessSquare.fromAlgebraic(notation.substring(2, 4));
    
    if (from == null || to == null) return null;
    
    // Handle promotion (e.g., "e7e8q")
    ChessPiece? promotion;
    if (notation.length == 5) {
      final promoChar = notation[4].toLowerCase();
      promotion = ChessPiece.fromFen(promoChar);
    }
    
    return ChessMove(from: from, to: to, promotion: promotion);
  }
}

class ChessBoard {
  // 8x8 board: [file][rank] or [a-h][1-8]
  final List<List<ChessPiece?>> _board;
  final PieceColor activeColor;
  final bool whiteCanCastleKingside;
  final bool whiteCanCastleQueenside;
  final bool blackCanCastleKingside;
  final bool blackCanCastleQueenside;
  final ChessSquare? enPassantTarget;
  final int halfmoveClock;
  final int fullmoveNumber;

  ChessBoard._({
    required List<List<ChessPiece?>> board,
    required this.activeColor,
    required this.whiteCanCastleKingside,
    required this.whiteCanCastleQueenside,
    required this.blackCanCastleKingside,
    required this.blackCanCastleQueenside,
    required this.enPassantTarget,
    required this.halfmoveClock,
    required this.fullmoveNumber,
  }) : _board = board;

  // Get piece at square
  ChessPiece? pieceAt(ChessSquare square) {
    if (!square.isValid) return null;
    return _board[square.file][square.rank];
  }

  // Check if square is occupied
  bool isOccupied(ChessSquare square) => pieceAt(square) != null;

  // Check if square has piece of specific color
  bool hasColorAt(ChessSquare square, PieceColor color) {
    final piece = pieceAt(square);
    return piece?.color == color;
  }

  // Create initial chess position
  factory ChessBoard.initial() {
    final board = List.generate(8, (_) => List<ChessPiece?>.filled(8, null));
    
    // Set up initial position
    // Black pieces (rank 7 = 8th rank)
    board[0][7] = const ChessPiece(PieceType.rook, PieceColor.black);
    board[1][7] = const ChessPiece(PieceType.knight, PieceColor.black);
    board[2][7] = const ChessPiece(PieceType.bishop, PieceColor.black);
    board[3][7] = const ChessPiece(PieceType.queen, PieceColor.black);
    board[4][7] = const ChessPiece(PieceType.king, PieceColor.black);
    board[5][7] = const ChessPiece(PieceType.bishop, PieceColor.black);
    board[6][7] = const ChessPiece(PieceType.knight, PieceColor.black);
    board[7][7] = const ChessPiece(PieceType.rook, PieceColor.black);
    
    // Black pawns (rank 6 = 7th rank)
    for (int file = 0; file < 8; file++) {
      board[file][6] = const ChessPiece(PieceType.pawn, PieceColor.black);
    }
    
    // White pawns (rank 1 = 2nd rank)
    for (int file = 0; file < 8; file++) {
      board[file][1] = const ChessPiece(PieceType.pawn, PieceColor.white);
    }
    
    // White pieces (rank 0 = 1st rank)
    board[0][0] = const ChessPiece(PieceType.rook, PieceColor.white);
    board[1][0] = const ChessPiece(PieceType.knight, PieceColor.white);
    board[2][0] = const ChessPiece(PieceType.bishop, PieceColor.white);
    board[3][0] = const ChessPiece(PieceType.queen, PieceColor.white);
    board[4][0] = const ChessPiece(PieceType.king, PieceColor.white);
    board[5][0] = const ChessPiece(PieceType.bishop, PieceColor.white);
    board[6][0] = const ChessPiece(PieceType.knight, PieceColor.white);
    board[7][0] = const ChessPiece(PieceType.rook, PieceColor.white);
    
    return ChessBoard._(
      board: board,
      activeColor: PieceColor.white,
      whiteCanCastleKingside: true,
      whiteCanCastleQueenside: true,
      blackCanCastleKingside: true,
      blackCanCastleQueenside: true,
      enPassantTarget: null,
      halfmoveClock: 0,
      fullmoveNumber: 1,
    );
  }

  // Create board from FEN string
  factory ChessBoard.fromFen(String fen) {
    final parts = fen.split(' ');
    if (parts.length != 6) {
      throw ArgumentError('Invalid FEN string: must have 6 parts');
    }
    
    // Parse board position
    final board = List.generate(8, (_) => List<ChessPiece?>.filled(8, null));
    final ranks = parts[0].split('/');
    
    if (ranks.length != 8) {
      throw ArgumentError('Invalid FEN: must have 8 ranks');
    }
    
    for (int rank = 0; rank < 8; rank++) {
      final rankStr = ranks[7 - rank]; // FEN starts from rank 8
      int file = 0;
      
      for (int i = 0; i < rankStr.length; i++) {
        final char = rankStr[i];
        if (char.contains(RegExp(r'[1-8]'))) {
          // Empty squares
          file += int.parse(char);
        } else {
          // Piece
          board[file][rank] = ChessPiece.fromFen(char);
          file++;
        }
      }
    }
    
    // Parse active color
    final activeColor = parts[1] == 'w' ? PieceColor.white : PieceColor.black;
    
    // Parse castling rights
    final castling = parts[2];
    final whiteCanCastleKingside = castling.contains('K');
    final whiteCanCastleQueenside = castling.contains('Q');
    final blackCanCastleKingside = castling.contains('k');
    final blackCanCastleQueenside = castling.contains('q');
    
    // Parse en passant
    final enPassantTarget = parts[3] == '-' ? null : ChessSquare.fromAlgebraic(parts[3]);
    
    // Parse move counters
    final halfmoveClock = int.tryParse(parts[4]) ?? 0;
    final fullmoveNumber = int.tryParse(parts[5]) ?? 1;
    
    return ChessBoard._(
      board: board,
      activeColor: activeColor,
      whiteCanCastleKingside: whiteCanCastleKingside,
      whiteCanCastleQueenside: whiteCanCastleQueenside,
      blackCanCastleKingside: blackCanCastleKingside,
      blackCanCastleQueenside: blackCanCastleQueenside,
      enPassantTarget: enPassantTarget,
      halfmoveClock: halfmoveClock,
      fullmoveNumber: fullmoveNumber,
    );
  }

  // Convert to FEN string
  String toFen() {
    final buffer = StringBuffer();
    
    // Board position
    for (int rank = 7; rank >= 0; rank--) {
      int emptyCount = 0;
      
      for (int file = 0; file < 8; file++) {
        final piece = _board[file][rank];
        if (piece == null) {
          emptyCount++;
        } else {
          if (emptyCount > 0) {
            buffer.write(emptyCount);
            emptyCount = 0;
          }
          buffer.write(piece.fenChar);
        }
      }
      
      if (emptyCount > 0) {
        buffer.write(emptyCount);
      }
      
      if (rank > 0) buffer.write('/');
    }
    
    buffer.write(' ');
    
    // Active color
    buffer.write(activeColor == PieceColor.white ? 'w' : 'b');
    buffer.write(' ');
    
    // Castling rights
    final castling = StringBuffer();
    if (whiteCanCastleKingside) castling.write('K');
    if (whiteCanCastleQueenside) castling.write('Q');
    if (blackCanCastleKingside) castling.write('k');
    if (blackCanCastleQueenside) castling.write('q');
    buffer.write(castling.isEmpty ? '-' : castling.toString());
    buffer.write(' ');
    
    // En passant
    buffer.write(enPassantTarget?.algebraic ?? '-');
    buffer.write(' ');
    
    // Move counters
    buffer.write('$halfmoveClock $fullmoveNumber');
    
    return buffer.toString();
  }

  // Apply a move and return a new board state
  ChessBoard makeMove(ChessMove move) {
    // Create a copy of the current board
    final newBoard = List.generate(8, (file) => 
      List.generate(8, (rank) => _board[file][rank])
    );
    
    // Get the piece being moved
    final piece = newBoard[move.from.file][move.from.rank];
    if (piece == null) {
      throw ArgumentError('No piece at ${move.from.algebraic}');
    }
    
    // Move the piece
    newBoard[move.to.file][move.to.rank] = piece;
    newBoard[move.from.file][move.from.rank] = null;
    
    // Handle pawn promotion
    if (move.promotion != null) {
      newBoard[move.to.file][move.to.rank] = move.promotion;
    }
    
    // Switch active color
    final newActiveColor = activeColor == PieceColor.white 
        ? PieceColor.black 
        : PieceColor.white;
    
    // Update move counters
    final newHalfmoveClock = (piece.type == PieceType.pawn || 
                             pieceAt(move.to) != null) ? 0 : halfmoveClock + 1;
    final newFullmoveNumber = activeColor == PieceColor.black 
        ? fullmoveNumber + 1 
        : fullmoveNumber;
    
    // For now, keep castling rights and en passant simple
    // These can be enhanced later for full chess rules
    
    return ChessBoard._(
      board: newBoard,
      activeColor: newActiveColor,
      whiteCanCastleKingside: whiteCanCastleKingside,
      whiteCanCastleQueenside: whiteCanCastleQueenside,
      blackCanCastleKingside: blackCanCastleKingside,
      blackCanCastleQueenside: blackCanCastleQueenside,
      enPassantTarget: null, // Simplified for now
      halfmoveClock: newHalfmoveClock,
      fullmoveNumber: newFullmoveNumber,
    );
  }

  @override
  String toString() => toFen();
}