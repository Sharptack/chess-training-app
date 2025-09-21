// lib/core/widgets/chess_board_widget.dart
import 'package:flutter/material.dart';
import '../game_logic/chess_engine.dart';
import '../game_logic/move_validator.dart';

class ChessBoardWidget extends StatefulWidget {
  final ChessBoard board;
  final Function(ChessMove)? onMovePlayed;
  final bool interactive;
  final bool showCoordinates;
  final bool flipped;

  const ChessBoardWidget({
    super.key,
    required this.board,
    this.onMovePlayed,
    this.interactive = true,
    this.showCoordinates = true,
    this.flipped = false,
  });

  @override
  State<ChessBoardWidget> createState() => _ChessBoardWidgetState();
}

class _ChessBoardWidgetState extends State<ChessBoardWidget> {
  ChessSquare? _selectedSquare;
  List<ChessMove> _possibleMoves = [];
  final _moveValidator = const MoveValidator();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400, maxHeight: 400),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showCoordinates) _buildCoordinateRow(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.showCoordinates) _buildRankLabels(),
              Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.brown.shade800, width: 2),
                ),
                child: _buildBoard(),
              ),
              if (widget.showCoordinates) _buildRankLabels(),
            ],
          ),
          if (widget.showCoordinates) _buildCoordinateRow(),
        ],
      ),
    );
  }

  Widget _buildBoard() {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 8,
        childAspectRatio: 1.0,
        crossAxisSpacing: 0,
        mainAxisSpacing: 0,
      ),
      itemCount: 64,
      itemBuilder: (context, index) {
        final file = index % 8;
        final rank = 7 - (index ~/ 8);
        
        // Don't apply flipping here - use the coordinates directly
        final square = ChessSquare(file, rank);
        
        return _buildSquare(square, file, rank);
      },
    );
  }

  Widget _buildSquare(ChessSquare square, int file, int rank) {
    final piece = widget.board.pieceAt(square);
    final isLight = (file + rank) % 2 == 0;
    final isSelected = _selectedSquare == square;
    final isPossibleMove = _possibleMoves.any((move) => move.to == square);
    
    Color squareColor;
    if (isSelected) {
      squareColor = Colors.yellow.shade300;
    } else if (isPossibleMove) {
      squareColor = Colors.green.shade200;
    } else {
      squareColor = isLight ? Colors.brown.shade200 : Colors.brown.shade600;
    }

    return GestureDetector(
      onTap: widget.interactive ? () => _onSquareTapped(square) : null,
      child: Container(
        color: squareColor,
        child: Stack(
          children: [
            if (piece != null)
              Center(
                child: PieceWidget(
                  piece: piece,
                  size: 32,
                ),
              ),
            if (isPossibleMove && piece == null)
              Center(
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.green.shade400,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            if (isPossibleMove && piece != null)
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.green.shade400, width: 3),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoordinateRow() {
    return SizedBox(
      height: 20,
      width: 320,
      child: Row(
        children: List.generate(8, (index) {
          final file = widget.flipped ? 7 - index : index;
          final letter = String.fromCharCode(97 + file); // a-h
          return SizedBox(
            width: 40,
            child: Center(
              child: Text(
                letter,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown.shade800,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildRankLabels() {
    return SizedBox(
      width: 20,
      height: 320,
      child: Column(
        children: List.generate(8, (index) {
          final rank = widget.flipped ? index + 1 : 8 - index;
          return SizedBox(
            height: 40,
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown.shade800,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  void _onSquareTapped(ChessSquare square) {
    if (_selectedSquare == null) {
      final piece = widget.board.pieceAt(square);
      if (piece?.color == widget.board.activeColor) {
        setState(() {
          _selectedSquare = square;
          _possibleMoves = _moveValidator
              .generateLegalMoves(widget.board)
              .where((move) => move.from == square)
              .toList();
        });
      }
    } else {
      final move = ChessMove(from: _selectedSquare!, to: square);
      
      if (_possibleMoves.any((m) => m.from == move.from && m.to == move.to)) {
        widget.onMovePlayed?.call(move);
      }
      
      setState(() {
        _selectedSquare = null;
        _possibleMoves = [];
      });
    }
  }
}

class PieceWidget extends StatelessWidget {
  final ChessPiece piece;
  final double size;

  const PieceWidget({
    super.key,
    required this.piece,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      _getPieceSymbol(),
      style: TextStyle(
        fontSize: size,
        fontWeight: FontWeight.bold,
        color: piece.color == PieceColor.black ? Colors.black87 : Colors.grey.shade100,
        shadows: piece.color == PieceColor.white 
          ? [
              const Shadow(color: Colors.black, offset: Offset(0.5, 0.5), blurRadius: 1),
              const Shadow(color: Colors.black54, offset: Offset(1, 1), blurRadius: 2),
            ]
          : [
              const Shadow(color: Colors.white24, offset: Offset(0.5, 0.5), blurRadius: 0.5),
            ],
      ),
    );
  }

  String _getPieceSymbol() {
    final symbols = {
      (PieceType.king, PieceColor.white): '♔',
      (PieceType.queen, PieceColor.white): '♕',
      (PieceType.rook, PieceColor.white): '♖',
      (PieceType.bishop, PieceColor.white): '♗',
      (PieceType.knight, PieceColor.white): '♘',
      (PieceType.pawn, PieceColor.white): '♙',
      (PieceType.king, PieceColor.black): '♚',
      (PieceType.queen, PieceColor.black): '♛',
      (PieceType.rook, PieceColor.black): '♜',
      (PieceType.bishop, PieceColor.black): '♝',
      (PieceType.knight, PieceColor.black): '♞',
      (PieceType.pawn, PieceColor.black): '●', // Solid circle works consistently
    };
    
    return symbols[(piece.type, piece.color)] ?? '?';
  }
}