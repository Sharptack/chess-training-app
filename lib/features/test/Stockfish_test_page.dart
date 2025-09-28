// lib/features/test/stockfish_test_page.dart
import 'package:flutter/material.dart';
import '../../core/game_logic/stockfish_bot.dart';
import '../../core/game_logic/chess_board_state.dart';

class StockfishTestPage extends StatefulWidget {
  const StockfishTestPage({super.key});
  
  @override
  State<StockfishTestPage> createState() => _StockfishTestPageState();
}

class _StockfishTestPageState extends State<StockfishTestPage> {
  late StockfishBot bot;
  late ChessBoardState boardState;
  String status = 'Initializing...';
  
  @override
  void initState() {
    super.initState();
    bot = StockfishBot(difficulty: 3);
    boardState = ChessBoardState();
    _testBot();
  }
  
  Future<void> _testBot() async {
    setState(() => status = 'Getting move from Stockfish...');
    
    final move = await bot.getNextMove(boardState);
    
    setState(() {
      status = move != null 
        ? 'Stockfish suggested: $move'
        : 'No move received';
    });
  }
  
  @override
  void dispose() {
    bot.dispose();
    boardState.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stockfish Test')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(status, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _testBot,
              child: const Text('Test Again'),
            ),
          ],
        ),
      ),
    );
  }
}