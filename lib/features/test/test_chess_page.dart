// lib/features/test/test_chess_page.dart
import 'package:flutter/material.dart';
import '../../core/game_logic/chess_engine.dart';
import '../../core/widgets/chess_board_widget.dart';

class TestChessPage extends StatefulWidget {
  const TestChessPage({super.key});

  @override
  State<TestChessPage> createState() => _TestChessPageState();
}

class _TestChessPageState extends State<TestChessPage> {
  late ChessBoard _board;
  List<String> _moveHistory = [];

  @override
  void initState() {
    super.initState();
    _board = ChessBoard.initial();
  }

  void _onMovePlayed(ChessMove move) {
    try {
      setState(() {
        _board = _board.makeMove(move);
        _moveHistory.add('${move.from.algebraic}${move.to.algebraic}');
      });
      print('Move executed: $move');
      print('New board state: ${_board.toFen()}');
    } catch (e) {
      print('Error executing move $move: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chess Test')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ChessBoardWidget(
              board: _board,
              onMovePlayed: _onMovePlayed,
            ),
            const SizedBox(height: 16),
            Text('Current turn: ${_board.activeColor.name}'),
            Text('Moves: ${_moveHistory.join(', ')}'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _board = ChessBoard.initial();
                  _moveHistory.clear();
                });
              },
              child: const Text('Reset Board'),
            ),
          ],
        ),
      ),
    );
  }
}