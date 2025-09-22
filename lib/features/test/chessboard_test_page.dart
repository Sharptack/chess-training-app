// lib/features/test/chessboard_test_page.dart
import 'package:flutter/material.dart';
import '../../core/widgets/chess_board_widget.dart';
import '../../core/game_logic/chess_board_state.dart';
import '../../core/game_logic/chess_notation.dart';

class ChessboardTestPage extends StatefulWidget {
  const ChessboardTestPage({super.key});

  @override
  State<ChessboardTestPage> createState() => _ChessboardTestPageState();
}

class _ChessboardTestPageState extends State<ChessboardTestPage> {
  late ChessBoardState _boardState;
  String _status = 'White to move';
  String _lastMove = 'No moves yet';

  @override
  void initState() {
    super.initState();
    _boardState = ChessBoardState();
    _boardState.addListener(_updateStatus);
  }

  @override
  void dispose() {
    _boardState.removeListener(_updateStatus);
    _boardState.dispose();
    super.dispose();
  }

  void _updateStatus() {
    setState(() {
      if (_boardState.isCheckmate) {
        _status = '${_boardState.isWhiteTurn ? "Black" : "White"} wins by checkmate!';
      } else if (_boardState.isStalemate) {
        _status = 'Draw by stalemate';
      } else if (_boardState.isGameOver) {
        _status = 'Game over';
      } else if (_boardState.isInCheck) {
        _status = '${_boardState.isWhiteTurn ? "White" : "Black"} to move (in check!)';
      } else {
        _status = '${_boardState.isWhiteTurn ? "White" : "Black"} to move';
      }

      final moveHistory = _boardState.moveHistory;
      if (moveHistory.isNotEmpty) {
        _lastMove = moveHistory.last;
      }
    });
  }

  void _onMoveMade(String move) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Move played: $move'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _onIllegalMove() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Illegal move!'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final boardSize = (screenWidth * 0.9).clamp(300.0, 500.0);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chessboard Test'),
        actions: [
          IconButton(
            onPressed: () => _showPositionMenu(),
            icon: const Icon(Icons.menu),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Status information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status: $_status',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Last move: $_lastMove'),
                    Text('Move count: ${_boardState.moveHistory.length}'),
                    if (_boardState.isInCheck)
                      const Text(
                        'CHECK!',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Chess board - explicitly sized container
            Center(
              child: Container(
                width: boardSize,
                height: boardSize,
                child: ChessBoardWidget(
                  boardState: _boardState,
                  size: boardSize,
                  onMoveMade: _onMoveMade,
                  onIllegalMove: _onIllegalMove,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Control buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () => _boardState.reset(),
                  child: const Text('Reset'),
                ),
                ElevatedButton(
                  onPressed: _boardState.moveHistory.isNotEmpty 
                    ? () => _boardState.undoMove()
                    : null,
                  child: const Text('Undo'),
                ),
                ElevatedButton(
                  onPressed: () => _boardState.flipBoard(),
                  child: const Text('Flip Board'),
                ),
                ElevatedButton(
                  onPressed: () => _showMoveHistory(),
                  child: const Text('Move History'),
                ),
                ElevatedButton(
                  onPressed: () => _showDebugInfo(),
                  child: const Text('Debug Info'),
                ),
                ElevatedButton(
                  onPressed: () => _debugPosition(),
                  child: const Text('Debug Position'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  void _debugPosition() {
    // Debug helper to check piece positions
    final pieces = _boardState.getAllPieces();
    final debugInfo = StringBuffer();
    debugInfo.writeln('Current pieces on board:');
    
    for (int rank = 8; rank >= 1; rank--) {
      for (int file = 0; file < 8; file++) {
        final square = ChessNotation.indicesToSquare(file, rank - 1);
        final piece = pieces[square];
        if (piece != null) {
          debugInfo.writeln('$square: ${piece.isWhite ? "White" : "Black"} ${piece.type}');
        }
      }
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Position Debug'),
        content: SingleChildScrollView(
          child: Text(debugInfo.toString()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPositionMenu() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Load Position'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Starting Position'),
              onTap: () {
                _boardState.reset();
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Sicilian Defense'),
              onTap: () {
                _boardState.loadFen(ChessNotation.testPositions['sicilian']!);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Scholar\'s Mate Setup'),
              onTap: () {
                _boardState.loadFen(ChessNotation.testPositions['scholars_mate']!);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('King & Queen vs King'),
              onTap: () {
                _boardState.loadFen(ChessNotation.testPositions['endgame_kq_k']!);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Pawn Promotion'),
              onTap: () {
                _boardState.loadFen(ChessNotation.testPositions['promotion']!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showMoveHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Move History'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: _boardState.moveHistory.isEmpty
            ? const Center(child: Text('No moves played yet'))
            : ListView.builder(
                itemCount: (_boardState.moveHistory.length / 2).ceil(),
                itemBuilder: (context, index) {
                  final moveNumber = index + 1;
                  final whiteMove = _boardState.moveHistory[index * 2];
                  final blackMove = index * 2 + 1 < _boardState.moveHistory.length
                    ? _boardState.moveHistory[index * 2 + 1]
                    : null;
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 30,
                          child: Text('$moveNumber.'),
                        ),
                        Expanded(child: Text(whiteMove)),
                        Expanded(child: Text(blackMove ?? '')),
                      ],
                    ),
                  );
                },
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDebugInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Debug Information'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('FEN: ${_boardState.fen}'),
              const SizedBox(height: 8),
              Text('Turn: ${_boardState.isWhiteTurn ? "White" : "Black"}'),
              Text('In Check: ${_boardState.isInCheck}'),
              Text('Checkmate: ${_boardState.isCheckmate}'),
              Text('Stalemate: ${_boardState.isStalemate}'),
              Text('Game Over: ${_boardState.isGameOver}'),
              const SizedBox(height: 8),
              if (_boardState.selectedSquare != null)
                Text('Selected: ${_boardState.selectedSquare}'),
              if (_boardState.highlightedSquares.isNotEmpty)
                Text('Highlighted: ${_boardState.highlightedSquares.join(", ")}'),
              const SizedBox(height: 8),
              const Text('ASCII Board:'),
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.grey.shade100,
                child: Text(
                  _boardState.ascii,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}