// lib/core/game_logic/chess_notation.dart

/// Utilities for chess notation conversion and coordinate handling
class ChessNotation {
  /// Convert file index (0-7) to file letter (a-h)
  static String fileIndexToLetter(int fileIndex) {
    if (fileIndex < 0 || fileIndex > 7) {
      throw ArgumentError('File index must be 0-7, got $fileIndex');
    }
    return String.fromCharCode(97 + fileIndex); // 97 = 'a'
  }
  
  /// Convert file letter (a-h) to file index (0-7)
  static int fileLetterToIndex(String fileLetter) {
    if (fileLetter.length != 1 || fileLetter.codeUnitAt(0) < 97 || fileLetter.codeUnitAt(0) > 104) {
      throw ArgumentError('File letter must be a-h, got $fileLetter');
    }
    return fileLetter.codeUnitAt(0) - 97;
  }
  
  /// Convert rank number (1-8) to rank index (0-7)
  static int rankNumberToIndex(int rankNumber) {
    if (rankNumber < 1 || rankNumber > 8) {
      throw ArgumentError('Rank number must be 1-8, got $rankNumber');
    }
    return rankNumber - 1;
  }
  
  /// Convert rank index (0-7) to rank number (1-8)
  static int rankIndexToNumber(int rankIndex) {
    if (rankIndex < 0 || rankIndex > 7) {
      throw ArgumentError('Rank index must be 0-7, got $rankIndex');
    }
    return rankIndex + 1;
  }
  
  /// Convert square name (e.g., 'e4') to file/rank indices
  static (int file, int rank) squareToIndices(String square) {
    if (square.length != 2) {
      throw ArgumentError('Square must be 2 characters, got $square');
    }
    
    final file = fileLetterToIndex(square[0]);
    final rank = rankNumberToIndex(int.parse(square[1]));
    
    return (file, rank);
  }
  
  /// Convert file/rank indices to square name (e.g., 'e4')
  static String indicesToSquare(int file, int rank) {
    final fileLetter = fileIndexToLetter(file);
    final rankNumber = rankIndexToNumber(rank);
    return '$fileLetter$rankNumber';
  }
  
  /// Get all square names in order (a1, b1, ..., h8)
  static List<String> getAllSquares() {
    final squares = <String>[];
    for (int rank = 1; rank <= 8; rank++) {
      for (int file = 0; file < 8; file++) {
        squares.add('${fileIndexToLetter(file)}$rank');
      }
    }
    return squares;
  }
  
  /// Get all squares for a specific rank (1-8)
  static List<String> getSquaresForRank(int rank) {
    final squares = <String>[];
    for (int file = 0; file < 8; file++) {
      squares.add('${fileIndexToLetter(file)}$rank');
    }
    return squares;
  }
  
  /// Get all squares for a specific file ('a'-'h')
  static List<String> getSquaresForFile(String file) {
    final squares = <String>[];
    for (int rank = 1; rank <= 8; rank++) {
      squares.add('$file$rank');
    }
    return squares;
  }
  
  /// Check if a square name is valid
  static bool isValidSquare(String square) {
    if (square.length != 2) return false;
    
    final file = square[0];
    final rank = square[1];
    
    return file.codeUnitAt(0) >= 97 && file.codeUnitAt(0) <= 104 && // a-h
           rank.codeUnitAt(0) >= 49 && rank.codeUnitAt(0) <= 56;    // 1-8
  }
  
  /// Get the color of a square ('light' or 'dark')
  static String getSquareColor(String square) {
    final (file, rank) = squareToIndices(square);
    return (file + rank) % 2 == 0 ? 'dark' : 'light';
  }
  
  /// Check if a square is a light square
  static bool isLightSquare(String square) {
    return getSquareColor(square) == 'light';
  }
  
  /// Check if a square is a dark square
  static bool isDarkSquare(String square) {
    return getSquareColor(square) == 'dark';
  }
  
  /// Get the distance between two squares
  static int getSquareDistance(String square1, String square2) {
    final (file1, rank1) = squareToIndices(square1);
    final (file2, rank2) = squareToIndices(square2);
    
    return (file1 - file2).abs() + (rank1 - rank2).abs();
  }
  
  /// Parse a simple FEN string to get piece placement only
  static Map<String, String> parseFenPosition(String fen) {
    final parts = fen.split(' ');
    if (parts.isEmpty) {
      throw ArgumentError('Invalid FEN: $fen');
    }
    
    final piecePlacement = parts[0];
    final pieces = <String, String>{};
    
    int file = 0;
    int rank = 8; // Start from rank 8, work down
    
    for (int i = 0; i < piecePlacement.length; i++) {
      final char = piecePlacement[i];
      
      if (char == '/') {
        // Move to next rank
        rank--;
        file = 0;
      } else if (char.codeUnitAt(0) >= 49 && char.codeUnitAt(0) <= 56) {
        // Number indicating empty squares
        final emptySquares = int.parse(char);
        file += emptySquares;
      } else {
        // Piece character
        final square = indicesToSquare(file, rank - 1);
        pieces[square] = char;
        file++;
      }
    }
    
    return pieces;
  }
  
  /// Get starting position FEN
  static const String startingFen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
  
  /// Common test positions
  static const Map<String, String> testPositions = {
    'starting': startingFen,
    'sicilian': 'rnbqkbnr/pp1ppppp/8/2p5/4P3/8/PPPP1PPP/RNBQKBNR w KQkq c6 0 2',
    'scholars_mate': 'rnb1kbnr/pppp1ppp/8/4p3/2B1P3/8/PPPP1PPP/RNBQK1NR w KQkq - 2 3',
    'endgame_kq_k': '8/8/8/8/8/8/4K3/4Q2k w - - 0 1',
    'promotion': '8/P7/8/8/8/8/8/K6k w - - 0 1',
  };
}