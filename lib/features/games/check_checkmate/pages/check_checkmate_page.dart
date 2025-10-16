// lib/features/games/check_checkmate/pages/check_checkmate_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/chess_board_widget.dart';
import '../../../../core/game_logic/chess_board_state.dart';
import '../../../../state/providers.dart';
import '../models/check_checkmate_position.dart';

class CheckCheckmatePage extends ConsumerStatefulWidget {
  final String gameId;
  final String levelId;
  final List<int> positionIds;
  final int completionsRequired;

  const CheckCheckmatePage({
    Key? key,
    required this.gameId,
    required this.levelId,
    required this.positionIds,
    required this.completionsRequired,
  }) : super(key: key);

  @override
  ConsumerState<CheckCheckmatePage> createState() => _CheckCheckmatePageState();
}

class _CheckCheckmatePageState extends ConsumerState<CheckCheckmatePage> {
  late ChessBoardState _boardState;
  List<CheckCheckmatePosition> _positions = [];
  int _currentPositionIndex = 0;
  bool _showingFeedback = false;
  bool _isCorrect = false;
  int _correctAnswers = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _boardState = ChessBoardState();
    _loadPositions();
  }

  Future<void> _loadPositions() async {
    try {
      final String response = await rootBundle.loadString(
        'assets/data/games/check_checkmate_positions.json',
      );
      final data = json.decode(response) as Map<String, dynamic>;
      final allPositions = (data['positions'] as List<dynamic>)
          .map((e) => CheckCheckmatePosition.fromJson(e as Map<String, dynamic>))
          .toList();

      // Filter positions based on positionIds
      final selectedPositions = allPositions
          .where((pos) => widget.positionIds.contains(pos.id))
          .toList();

      // Sort by the order in positionIds
      selectedPositions.sort((a, b) {
        final indexA = widget.positionIds.indexOf(a.id);
        final indexB = widget.positionIds.indexOf(b.id);
        return indexA.compareTo(indexB);
      });

      setState(() {
        _positions = selectedPositions;
        _isLoading = false;
      });

      if (_positions.isNotEmpty) {
        _loadPosition(_positions[0]);
      }
    } catch (e) {
      print('Error loading check/checkmate positions: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading positions: $e')),
        );
      }
    }
  }

  void _loadPosition(CheckCheckmatePosition position) {
    try {
      final success = _boardState.loadFen(position.fen);
      if (!success) {
        throw Exception('Invalid FEN: ${position.fen}');
      }
      setState(() {});
    } catch (e) {
      print('Error loading position: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading position: $e')),
      );
    }
  }

  void _handleAnswer(String answer) {
    if (_showingFeedback) return;

    final currentPosition = _positions[_currentPositionIndex];
    final correct = currentPosition.isCorrectAnswer(answer);

    setState(() {
      _showingFeedback = true;
      _isCorrect = correct;
      if (correct) {
        _correctAnswers++;
      }
    });

    // Show feedback briefly, then move to next position
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;

      if (_currentPositionIndex < _positions.length - 1) {
        // Move to next position
        setState(() {
          _currentPositionIndex++;
          _showingFeedback = false;
          _loadPosition(_positions[_currentPositionIndex]);
        });
      } else {
        // All positions completed
        _handleCompletion();
      }
    });
  }

  Future<void> _handleCompletion() async {
    // Calculate score
    final score = (_correctAnswers / _positions.length * 100).round();

    // Update progress
    try {
      final progressRepo = ref.read(progressRepositoryProvider);
      await progressRepo.recordGameCompletion(
        widget.gameId,
        widget.completionsRequired,
      );

      // Invalidate providers to refresh the UI
      ref.invalidate(gameProgressProvider(widget.gameId));
      ref.invalidate(playProgressProvider(widget.levelId)); // For level page
    } catch (e) {
      print('Error updating progress: $e');
    }

    // Show completion dialog
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Game Complete!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('You got $_correctAnswers out of ${_positions.length} correct!'),
            const SizedBox(height: 8),
            Text('Score: $score%', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Return to game selector
            },
            child: const Text('Done'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              _resetGame();
            },
            child: const Text('Play Again'),
          ),
        ],
      ),
    );
  }

  void _resetGame() {
    setState(() {
      _currentPositionIndex = 0;
      _correctAnswers = 0;
      _showingFeedback = false;
      if (_positions.isNotEmpty) {
        _loadPosition(_positions[0]);
      }
    });
  }

  @override
  void dispose() {
    _boardState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Check vs Checkmate'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_positions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Check vs Checkmate'),
        ),
        body: const Center(
          child: Text('No positions available'),
        ),
      );
    }

    final progress = (_currentPositionIndex + 1) / _positions.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Check vs Checkmate'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),

            // Position counter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Position ${_currentPositionIndex + 1} of ${_positions.length}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Score: $_correctAnswers/${_currentPositionIndex + (_showingFeedback ? 1 : 0)}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Chess board
            Expanded(
              child: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final maxSize = constraints.maxWidth < constraints.maxHeight
                        ? constraints.maxWidth * 0.9
                        : constraints.maxHeight * 0.7;
                    return ChessBoardWidget(
                      boardState: _boardState,
                      size: maxSize,
                      showCoordinates: true,
                      // Disable moves - this is view-only
                      onMoveMade: null,
                    );
                  },
                ),
              ),
            ),

            // Feedback message
            if (_showingFeedback)
              Container(
                padding: const EdgeInsets.all(16),
                color: _isCorrect ? Colors.green[100] : Colors.red[100],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isCorrect ? Icons.check_circle : Icons.cancel,
                      color: _isCorrect ? Colors.green : Colors.red,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _isCorrect ? 'Correct!' : 'Incorrect',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _isCorrect ? Colors.green[900] : Colors.red[900],
                      ),
                    ),
                  ],
                ),
              ),

            // Answer buttons
            if (!_showingFeedback)
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _handleAnswer('check'),
                        icon: const Icon(Icons.check, size: 28),
                        label: const Text(
                          'Check',
                          style: TextStyle(fontSize: 20),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _handleAnswer('checkmate'),
                        icon: const Text('#', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                        label: const Text(
                          'Checkmate',
                          style: TextStyle(fontSize: 20),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
