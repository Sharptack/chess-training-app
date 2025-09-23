// lib/core/widgets/piece_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../game_logic/chess_board_state.dart';

/// Widget that renders a single chess piece using SVG assets
class PieceWidget extends StatelessWidget {
  final ChessPiece piece;
  final double size;
  final bool isDragging;
  
  const PieceWidget({
    super.key,
    required this.piece,
    this.size = 60.0,
    this.isDragging = false,
  });
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: _buildPieceImage(),
      ),
    );
  }
  
  /// Build SVG piece image with proper asset path
  Widget _buildPieceImage() {
    final color = piece.isWhite ? 'white' : 'black';
    final pieceType = _getPieceTypeName(piece.type);
    final assetPath = 'assets/images/pieces/piece_${color}_$pieceType.svg';
    
    return SvgPicture.asset(
      assetPath,
      width: size,
      height: size,
      colorFilter: isDragging 
        ? ColorFilter.mode(
            Colors.grey.withValues(alpha: 0.7), 
            BlendMode.srcATop,
          )
        : null,
      // Handle missing assets gracefully
      placeholderBuilder: (context) => _buildFallbackPiece(),
    );
  }
  
  /// Convert piece type letter to full name
  String _getPieceTypeName(String type) {
    switch (type) {
      case 'k': return 'king';
      case 'q': return 'queen';
      case 'r': return 'rook';
      case 'b': return 'bishop';
      case 'n': return 'knight';
      case 'p': return 'pawn';
      default: return 'pawn';
    }
  }
  
  /// Fallback for missing assets (using old Unicode approach)
  Widget _buildFallbackPiece() {
    return Text(
      _getPieceSymbol(piece),
      style: TextStyle(
        fontSize: size * 0.7,
        fontWeight: FontWeight.normal,
        color: _getPieceColor(piece, isDragging),
        shadows: isDragging 
          ? [
              Shadow(
                offset: const Offset(2, 2),
                blurRadius: 4,
                color: Colors.black.withValues(alpha: 0.3),
              ),
            ]
          : null,
      ),
      textAlign: TextAlign.center,
    );
  }
  
  /// Get the appropriate color for the piece (fallback only)
  Color _getPieceColor(ChessPiece piece, bool isDragging) {
    if (isDragging) {
      return Colors.grey.withValues(alpha: 0.7);
    }
    
    // For black pawns specifically, use black color to make the circle visible
    if (piece.type == 'p' && !piece.isWhite) {
      return Colors.black;
    }
    
    // For white pieces, use dark color with shadow for visibility
    if (piece.isWhite) {
      return Colors.black87;
    }
    
    // For other black pieces, use default black
    return Colors.black;
  }
  
  /// Get Unicode chess piece symbol (fallback only)
  String _getPieceSymbol(ChessPiece piece) {
    // Handle black pawn Unicode issue with fallback
    if (piece.type == 'p' && !piece.isWhite) {
      return '●';  // Solid black circle
    }
    
    // Standard Unicode symbols for other pieces
    const pieceSymbols = {
      // White pieces (outlined)
      ('k', true): '♔', // White King
      ('q', true): '♕', // White Queen  
      ('r', true): '♖', // White Rook
      ('b', true): '♗', // White Bishop
      ('n', true): '♘', // White Knight
      ('p', true): '♙', // White Pawn
      
      // Black pieces (filled)
      ('k', false): '♚', // Black King
      ('q', false): '♛', // Black Queen
      ('r', false): '♜', // Black Rook
      ('b', false): '♝', // Black Bishop
      ('n', false): '♞', // Black Knight
      ('p', false): '♟', // Black Pawn
    };
    
    final symbol = pieceSymbols[(piece.type, piece.isWhite)];
    return symbol ?? '?';
  }
}

/// Draggable wrapper for chess pieces
class DraggablePieceWidget extends StatelessWidget {
  final ChessPiece piece;
  final String square;
  final double size;
  final VoidCallback? onDragStarted;
  final VoidCallback? onDragEnd;
  final Function(String targetSquare)? onDragCompleted;
  
  const DraggablePieceWidget({
    super.key,
    required this.piece,
    required this.square,
    this.size = 60.0,
    this.onDragStarted,
    this.onDragEnd,
    this.onDragCompleted,
  });
  
  @override
  Widget build(BuildContext context) {
    return Draggable<String>(
      data: square,
      onDragStarted: onDragStarted,
      onDragEnd: (_) => onDragEnd?.call(),
      feedback: Material(
        color: Colors.transparent,
        child: PieceWidget(
          piece: piece,
          size: size * 1.2, // Slightly larger when dragging
          isDragging: true,
        ),
      ),
      childWhenDragging: SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Container(
            width: size * 0.3,
            height: size * 0.3,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
      child: PieceWidget(
        piece: piece,
        size: size,
      ),
    );
  }
}

/// Drop target for chess squares
class ChessSquareDropTarget extends StatelessWidget {
  final String square;
  final Widget child;
  final Function(String fromSquare, String toSquare)? onPieceDropped;
  final bool isHighlighted;
  
  const ChessSquareDropTarget({
    super.key,
    required this.square,
    required this.child,
    this.onPieceDropped,
    this.isHighlighted = false,
  });
  
  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      onAcceptWithDetails: (details) {
        onPieceDropped?.call(details.data, square);
      },
      builder: (context, candidateData, rejectedData) {
        final isReceivingDrop = candidateData.isNotEmpty;
        
        return Container(
          decoration: BoxDecoration(
            border: isReceivingDrop
              ? Border.all(color: Colors.blue, width: 3)
              : isHighlighted
                ? Border.all(color: Colors.green, width: 2)
                : null,
            borderRadius: BorderRadius.circular(4),
          ),
          child: child,
        );
      },
    );
  }
}