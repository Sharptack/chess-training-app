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
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Container(
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
    final canDrag = piece.isWhite == widget.boardState.isWhiteTurn &&
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
    widget.boardState.selectSquare(square);
  }
  
  void _onDragStarted(String square) {
    widget.boardState.selectSquare(square);
  }
  
  void _onDragEnd() {
    // Nothing needed
  }
  
  void _onPieceDropped(String fromSquare, String toSquare) {
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
    final moveCountBefore = widget.boardState.moveHistory.length;
    
    // Direct call to chess package via simplified state
    final success = widget.boardState.makeMove(from, to, promotion: promotion);
    
    if (success) {
      final lastMove = widget.boardState.moveHistory.isNotEmpty 
          ? widget.boardState.moveHistory.last 
          : '$from-$to';
      widget.onMoveMade?.call(lastMove);
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