// lib/features/test/chess_package_test.dart
import 'package:flutter/material.dart';
import 'package:chess/chess.dart' as chess_lib;

class ChessPackageTestPage extends StatefulWidget {
  const ChessPackageTestPage({super.key});

  @override
  State<ChessPackageTestPage> createState() => _ChessPackageTestPageState();
}

class _ChessPackageTestPageState extends State<ChessPackageTestPage> {
  late chess_lib.Chess _chess;
  String _output = '';

  @override
  void initState() {
    super.initState();
    _chess = chess_lib.Chess();
    _runTests();
  }

  void _runTests() {
    final buffer = StringBuffer();
    
    // Test 1: Initial position
    buffer.writeln('=== CHESS PACKAGE TESTS ===\n');
    buffer.writeln('1. Initial Position:');
    buffer.writeln('FEN: ${_chess.fen}');
    buffer.writeln('Turn: ${_chess.turn == chess_lib.Color.WHITE ? "White" : "Black"}');
    buffer.writeln('In Check: ${_chess.in_check}');
    buffer.writeln('Game Over: ${_chess.game_over}');
    buffer.writeln();

    // Test 2: Legal moves
    buffer.writeln('2. Legal Moves for White:');
    final moves = _chess.moves();
    buffer.writeln('Total moves: ${moves.length}');
    buffer.writeln('First 10 moves: ${moves.take(10).join(", ")}');
    buffer.writeln();

    // Test 3: Make a move
    buffer.writeln('3. Making move e4 (SAN notation):');
    final moveResult = _chess.move('e4');
    if (moveResult) {
      buffer.writeln('Move successful!');
      buffer.writeln('New FEN: ${_chess.fen}');
      buffer.writeln('Turn: ${_chess.turn == chess_lib.Color.WHITE ? "White" : "Black"}');
    } else {
      buffer.writeln('Move failed! Trying alternative format...');
      // Try map format
      final altResult = _chess.move({'from': 'e2', 'to': 'e4'});
      if (altResult) {
        buffer.writeln('Alternative format worked!');
        buffer.writeln('New FEN: ${_chess.fen}');
      } else {
        buffer.writeln('Both formats failed - investigating available moves:');
        final availableMoves = _chess.moves();
        buffer.writeln('Available moves: ${availableMoves.take(5).join(", ")}...');
      }
    }
    buffer.writeln();

    // Test 4: Black response
    buffer.writeln('4. Black response e5:');
    final blackMove = _chess.move('e5');
    if (blackMove) {
      buffer.writeln('Move successful!');
      buffer.writeln('New FEN: ${_chess.fen}');
    } else {
      buffer.writeln('Move failed! Available black moves: ${_chess.moves().take(3).join(", ")}...');
    }
    buffer.writeln();

    // Test 5: Check detection test
    buffer.writeln('5. Testing Check Detection with Scholar\'s Mate setup:');
    _chess.reset();
    // Set up Scholar's mate - Nf6 doesn't defend f7, so Qxf7# should work
    final scholarMoves = ['e4', 'e5', 'Bc4', 'Nc6', 'Qh5', 'Nf6', 'Qxf7#'];
    buffer.writeln('Playing moves: ${scholarMoves.join(" ")} (Scholar\'s mate - requires # for checkmate)');
    
    for (int i = 0; i < scholarMoves.length; i++) {
      final success = _chess.move(scholarMoves[i]);
      if (success) {
        buffer.writeln('Move ${i + 1}: ${scholarMoves[i]} ✓');
        buffer.writeln('   Position: ${_chess.fen}');
        if (i == scholarMoves.length - 1) {
          buffer.writeln('Final position - Black in check: ${_chess.in_check}');
          buffer.writeln('Game over (checkmate): ${_chess.game_over}');
        }
      } else {
        buffer.writeln('Move ${i + 1}: ${scholarMoves[i]} ✗ (failed)');
        buffer.writeln('   Current position: ${_chess.fen}');
        buffer.writeln('   Available moves: ${_chess.moves().take(10).join(", ")}');
        
        // Try alternative notation for the failing move
        if (scholarMoves[i] == 'Qxf7#') {
          buffer.writeln('   Trying without checkmate symbol: Qxf7...');
          final altSuccess = _chess.move('Qxf7');
          buffer.writeln('   Qxf7 result: ${altSuccess ? "✓ Success!" : "✗ Also failed"}');
        }
        break;
      }
    }
    buffer.writeln();

    // Test 6: Castling test
    buffer.writeln('6. Testing Castling Setup:');
    _chess.reset();
    // Set up position for castling (clear path between king and rook)
    const castlingSetup = ['e4', 'e5', 'Nf3', 'Nc6', 'Bc4', 'Bc5'];
    buffer.writeln('Setting up for castling: ${castlingSetup.join(" ")}');
    
    for (final move in castlingSetup) {
      _chess.move(move);
    }
    
    buffer.writeln('Current position: ${_chess.fen}');
    final allMoves = _chess.moves();
    final castlingMoves = allMoves.where((move) => move.contains('O')).toList();
    buffer.writeln('Available castling moves: ${castlingMoves.isNotEmpty ? castlingMoves.join(", ") : "None (need to clear more pieces)"}');
    
    // Try short castling for white
    if (castlingMoves.contains('O-O')) {
      final castleResult = _chess.move('O-O');
      buffer.writeln('White castling O-O: ${castleResult ? "Success!" : "Failed"}');
    } else {
      buffer.writeln('Castling not available yet (pieces still in the way)');
    }
    buffer.writeln();

    // Test 7: Move history
    buffer.writeln('7. Move History:');
    final history = _chess.getHistory();
    buffer.writeln('Game history: ${history.join(" ")}');
    buffer.writeln();

    // Test 8: PGN generation
    buffer.writeln('8. PGN Generation:');
    final pgn = _chess.pgn();
    buffer.writeln('PGN: $pgn');
    buffer.writeln();

    // Test 9: Undo move
    buffer.writeln('9. Undo Move Test:');
    final historyBefore = _chess.getHistory().length;
    buffer.writeln('Moves before undo: $historyBefore');
    
    final undoResult = _chess.undo();
    if (undoResult != null) {
      buffer.writeln('Undo successful!');
      buffer.writeln('Moves after undo: ${_chess.getHistory().length}');
    } else {
      buffer.writeln('Undo failed (no moves to undo)');
    }
    buffer.writeln();

    setState(() {
      _output = buffer.toString();
    });
  }

  void _resetTest() {
    _chess.reset();
    _runTests();
  }

  void _testMoveFormats() {
    // Reset to starting position
    _chess.reset();
    
    // Test different move formats for the same move (e2-e4)
    final moveFormats = [
      'e4',           // SAN notation
      'e2e4',         // Long algebraic
      {'from': 'e2', 'to': 'e4'},  // Map format
    ];
    
    String results = '';
    for (int i = 0; i < moveFormats.length; i++) {
      _chess.reset(); // Reset for each test
      final format = moveFormats[i];
      final success = _chess.move(format);
      final formatName = i == 0 ? 'SAN (e4)' : 
                        i == 1 ? 'Long algebraic (e2e4)' : 
                                'Map format';
      results += '$formatName: ${success ? "✅" : "❌"}\n';
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(results.trim()),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _testIllegalMove() {
    // Reset to starting position for clean test
    _chess.reset();
    
    // Test various illegal move formats
    final illegalMoves = ['e8', 'e2e8', 'Ke8', 'Qh8'];
    
    String results = '';
    for (final move in illegalMoves) {
      final result = _chess.move(move);
      results += 'Move "$move": ${result ? "❌ Accepted" : "✅ Rejected"}\n';
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(results.trim()),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chess Package Test'),
        actions: [
          IconButton(
            onPressed: _resetTest,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    _output,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _resetTest,
                    child: const Text('Run Tests Again'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _testMoveFormats,
                    child: const Text('Test Move Formats'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _testIllegalMove,
                    child: const Text('Test Illegal Moves'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}