// lib/core/widgets/chess_board_widget.dart
import 'package:flutter/material.dart';
import '../game_logic/chess_board_state.dart';
import '../game_logic/chess_notation.dart';
import 'piece_widget.dart';

/// Simplified chess board widget using chess package directly
class ChessBoardWidget extends StatefulWidget {
  final ChessBoardState boardState;
  final double size;
  final bool showCoordinates;
  final Color lightSquareColor;
  final Color darkSquareColor;
  final Color highlightColor;
  final Color lastMoveColor;
  final Function(String move)? onMoveMade;
  final VoidCallback? onIllegalMove;
  final bool Function(String move)? validateMove; // NEW: Check if move is allowed before making it
  final bool showGameStatus; // Whether to show check/checkmate/stalemate overlays

  const ChessBoardWidget({
    super.key,
    required this.boardState,
    this.size = 400.0,
    this.showCoordinates = true,
    this.lightSquareColor = const Color(0xFFF0D9B5),
    this.darkSquareColor = const Color(0xFFB58863),
    this.highlightColor = const Color(0xFF646F40),
    this.lastMoveColor = const Color(0xFFCDD26A),
    this.onMoveMade,
    this.onIllegalMove,
    this.validateMove,
    this.showGameStatus = false, // Default to false - don't show check/checkmate overlays
  });
  
  @override
  State<ChessBoardWidget> createState() => _ChessBoardWidgetState();
}

class _ChessBoardWidgetState extends State<ChessBoardWidget> {
  @override
  void initState() {
    super.initState();
    widget.boardState.addListener(_onBoardStateChanged);
  }
  
  @override
  void dispose() {
    widget.boardState.removeListener(_onBoardStateChanged);
    super.dispose();
  }
  
  void _onBoardStateChanged() {
    setState(() {});
  }
  
  @override
  Widget build(BuildContext context) {
    // Show checkmate/stalemate/draw status (only if enabled)
    Widget? statusOverlay;
    if (widget.showGameStatus) {
      if (widget.boardState.isCheckmate) {
        statusOverlay = _buildStatusOverlay('Checkmate!', Colors.red);
      } else if (widget.boardState.isStalemate) {
        statusOverlay = _buildStatusOverlay('Stalemate!', Colors.orange);
      } else if (widget.boardState.isDraw) {
        statusOverlay = _buildStatusOverlay('Draw!', Colors.blue);
      } else if (widget.boardState.isInCheck) {
        statusOverlay = _buildStatusOverlay('Check!', Colors.amber);
      }
    }
    
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.brown, width: 2),
            ),
            child: AspectRatio(
              aspectRatio: 1.0,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 0,
                  mainAxisSpacing: 0,
                ),
                itemCount: 64,
                itemBuilder: (context, index) {
                  final file = index % 8;
                  final displayRank = index ~/ 8;
                  final chessRank = 7 - displayRank;
                  
                  final square = ChessNotation.indicesToSquare(file, chessRank);
                  final squareSize = widget.size / 8;
                  
                  return _buildSquare(square, squareSize, file, chessRank);
                },
              ),
            ),
          ),
          if (statusOverlay != null) statusOverlay,
        ],
      ),
    );
  }
  
  Widget _buildStatusOverlay(String text, Color color) {
    return Positioned(
      top: widget.size / 2 - 30,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildSquare(String square, double size, int file, int chessRank) {
    final piece = widget.boardState.getPieceAt(square);
    
    // Fixed: Correct chess board coloring (h1 should be light)
    final isLightSquare = (file + chessRank) % 2 == 1;
    
    final isSelected = widget.boardState.selectedSquare == square;
    final isHighlighted = widget.boardState.highlightedSquares.contains(square);
    final isLastMoveSquare = widget.boardState.lastMoveFrom == square || 
                             widget.boardState.lastMoveTo == square;
    
    Color squareColor;
    if (isSelected) {
      squareColor = widget.highlightColor;
    } else if (isLastMoveSquare) {
      squareColor = widget.lastMoveColor;
    } else if (isLightSquare) {
      squareColor = widget.lightSquareColor;
    } else {
      squareColor = widget.darkSquareColor;
    }
    
    return ChessSquareDropTarget(
      square: square,
      isHighlighted: isHighlighted,
      onPieceDropped: _onPieceDropped,
      child: GestureDetector(
        onTap: () => _onSquareTapped(square),
        child: Container(
          width: size,
          height: size,
          color: squareColor,
          child: Stack(
            children: [
              // Highlight dot for legal moves
              if (isHighlighted && piece == null)
                Center(
                  child: Container(
                    width: size * 0.3,
                    height: size * 0.3,
                    decoration: BoxDecoration(
                      color: widget.highlightColor.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              
              // Highlight border for captures
              if (isHighlighted && piece != null)
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: widget.highlightColor,
                      width: 3,
                    ),
                  ),
                ),
              
              // Chess piece
              if (piece != null)
                Center(
                  child: _buildPiece(piece, square, size),
                ),
              
              // Coordinate labels
              if (widget.showCoordinates)
                _buildCoordinates(square, size, file, chessRank),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildPiece(ChessPiece piece, String square, double size) {
    // Only allow dragging if onMoveMade callback is provided
    final canDrag = widget.onMoveMade != null &&
                   piece.isWhite == widget.boardState.isWhiteTurn &&
                   !widget.boardState.isGameOver;

    if (canDrag) {
      return DraggablePieceWidget(
        piece: piece,
        square: square,
        size: size * 0.8,
        onDragStarted: () => _onDragStarted(square),
        onDragEnd: _onDragEnd,
      );
    } else {
      return PieceWidget(
        piece: piece,
        size: size * 0.8,
      );
    }
  }
  
  Widget _buildCoordinates(String square, double size, int file, int chessRank) {
    return Positioned.fill(
      child: Stack(
        children: [
          if (chessRank == 0)
            Positioned(
              bottom: 2,
              right: 2,
              child: Text(
                ChessNotation.fileIndexToLetter(file),
                style: TextStyle(
                  fontSize: size * 0.15,
                  fontWeight: FontWeight.bold,
                  color: (file + chessRank) % 2 == 1
                    ? widget.darkSquareColor 
                    : widget.lightSquareColor,
                ),
              ),
            ),
          
          if (file == 0)
            Positioned(
              top: 2,
              left: 2,
              child: Text(
                '${chessRank + 1}',
                style: TextStyle(
                  fontSize: size * 0.15,
                  fontWeight: FontWeight.bold,
                  color: (file + chessRank) % 2 == 1
                    ? widget.darkSquareColor 
                    : widget.lightSquareColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  void _onSquareTapped(String square) {
  // Don't allow interaction if onMoveMade is not provided (view-only mode)
  if (widget.onMoveMade == null) return;

  final currentSelected = widget.boardState.selectedSquare;
  final highlightedSquares = widget.boardState.highlightedSquares;

  // If we have a piece selected and click on a highlighted square, make the move
  if (currentSelected != null && highlightedSquares.contains(square)) {
    // Make the move through our widget method to trigger callback
    _attemptMove(currentSelected, square);
  } else {
    // Otherwise, just select the square
    widget.boardState.selectSquare(square);
  }
}
  
  void _onDragStarted(String square) {
    widget.boardState.selectSquare(square);
  }
  
  void _onDragEnd() {
    // Nothing needed
  }
  
  void _onPieceDropped(String fromSquare, String toSquare) {
    // Don't allow interaction if onMoveMade is not provided (view-only mode)
    if (widget.onMoveMade == null) return;

    if (fromSquare == toSquare) return;

    final piece = widget.boardState.getPieceAt(fromSquare);

    // Check for pawn promotion
    final isPromotion = piece?.type == 'p' &&
                       ((piece?.isWhite == true && toSquare[1] == '8') ||
                        (piece?.isWhite == false && toSquare[1] == '1'));

    if (isPromotion) {
      _showPromotionDialog(fromSquare, toSquare);
    } else {
      _attemptMove(fromSquare, toSquare);
    }
  }
  
  void _attemptMove(String from, String to, {String? promotion}) {
  // Build UCI notation
  final uciMove = promotion != null ? '$from$to$promotion' : '$from$to';

  // First, try to make the move to validate it
  final tempSuccess = widget.boardState.makeMove(from, to, promotion: promotion);

  if (!tempSuccess) {
    widget.onIllegalMove?.call();
    return;
  }

  // Get the SAN notation for validation (if needed)
  final sanNotation = widget.boardState.moveHistory.isNotEmpty
      ? widget.boardState.moveHistory.last
      : uciMove;

  // Undo the move so we can validate it first
  widget.boardState.undoMove();

  // Validate the move if validator is provided (uses SAN for compatibility)
  if (widget.validateMove != null) {
    final isAllowed = widget.validateMove!(sanNotation);
    if (!isAllowed) {
      // Move is not allowed by game rules (e.g., restriction)
      widget.onIllegalMove?.call();
      return;
    }
  }

  // Now make the move for real
  final success = widget.boardState.makeMove(from, to, promotion: promotion);

  if (success) {
    // Call the callback with UCI notation (our standard format)
    widget.onMoveMade?.call(uciMove);
  } else {
    widget.onIllegalMove?.call();
  }
}
  
  void _showPromotionDialog(String from, String to) {
    showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Promote Pawn'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choose a piece to promote to:'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPromotionOption('q', 'Queen'),
                _buildPromotionOption('r', 'Rook'),
                _buildPromotionOption('b', 'Bishop'),
                _buildPromotionOption('n', 'Knight'),
              ],
            ),
          ],
        ),
      ),
    ).then((promotion) {
      if (promotion != null) {
        _attemptMove(from, to, promotion: promotion);
      }
    });
  }
  
  Widget _buildPromotionOption(String pieceType, String name) {
    final piece = ChessPiece(
      type: pieceType,
      isWhite: widget.boardState.isWhiteTurn,
    );
    
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(pieceType),
      child: Column(
        children: [
          PieceWidget(piece: piece, size: 40),
          Text(name, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}