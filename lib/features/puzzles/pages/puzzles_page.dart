//lib/features/puzzles/pages/puzzles_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/chess_board_widget.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/game_logic/chess_board_state.dart';
import '../../../data/models/puzzle.dart';
import '../../../data/models/puzzle_set.dart';
import '../../../state/providers.dart';

class PuzzlesPage extends ConsumerStatefulWidget {
  final String levelId;

  const PuzzlesPage({
    Key? key,
    required this.levelId,
  }) : super(key: key);

  @override
  ConsumerState<PuzzlesPage> createState() => _PuzzlesPageState();
}

class _PuzzlesPageState extends ConsumerState<PuzzlesPage> {
  late ChessBoardState _boardState;
  PuzzleSet? _puzzleSet;
  Puzzle? _currentPuzzle;
  int _currentPuzzleIndex = 0;
  bool _puzzleSolved = false;
  bool _showingFeedback = false;
  String _feedbackMessage = '';
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _boardState = ChessBoardState();
  }

  void _onPuzzleSetLoaded(PuzzleSet puzzleSet) {
    print('DEBUG: PuzzlesPage received puzzle set with ${puzzleSet.puzzleCount} puzzles');
    setState(() {
      _puzzleSet = puzzleSet;
      _currentPuzzleIndex = 0;
      _loadCurrentPuzzle();
    });
  }

  void _loadCurrentPuzzle() {
    print('DEBUG: Loading puzzle at index $_currentPuzzleIndex');
    if (_puzzleSet != null && _currentPuzzleIndex < _puzzleSet!.puzzleCount) {
      final puzzle = _puzzleSet!.getPuzzleAt(_currentPuzzleIndex);
      if (puzzle != null) {
        print('DEBUG: Loading puzzle: ${puzzle.title}');
        setState(() {
          _currentPuzzle = puzzle;
          _puzzleSolved = false;
          _showingFeedback = false;
          _loadPuzzlePosition(puzzle);
        });
      }
    }
  }

  void _loadPuzzlePosition(Puzzle puzzle) {
    try {
      print('DEBUG: Loading FEN: ${puzzle.fen}');
      final success = _boardState.loadFen(puzzle.fen);
      if (!success) {
        throw Exception('Invalid FEN: ${puzzle.fen}');
      }
      setState(() {});
    } catch (e) {
      print('DEBUG: Error loading puzzle position: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading puzzle position: $e')),
      );
    }
  }

  void _onMoveMade(String move) {
    print('DEBUG: Move made: $move');
    if (_puzzleSolved || _showingFeedback) return;

    // The move has already been made by ChessBoardWidget
    // Check if this move is the solution
    if (_currentPuzzle != null) {
      print('DEBUG: Checking if $move is solution: ${_currentPuzzle!.solutionMoves}');
      if (_currentPuzzle!.isSolutionMove(move)) {
        print('DEBUG: Correct move!');
        _handleCorrectMove();
      } else {
        print('DEBUG: Incorrect move');
        _handleIncorrectMove();
      }
    }
    
    setState(() {});
  }

  void _handleCorrectMove() {
    setState(() {
      _puzzleSolved = true;
      _isSuccess = true;
      _feedbackMessage = _currentPuzzle?.successMessage ?? 'Correct!';
      _showingFeedback = true;
    });

    // Mark puzzle as completed in progress tracking
    _markPuzzleCompleted();

    // Auto-advance to next puzzle after delay
    Future.delayed(const Duration(seconds: 2), () {
      _advanceToNextPuzzle();
    });
  }

  void _handleIncorrectMove() {
    // Undo the incorrect move using your actual method
    final undoSuccess = _boardState.undoMove();
    
    if (undoSuccess) {
      _showTemporaryFeedback(
        _currentPuzzle?.failureMessage ?? 'Not quite right. Try again!',
        false,
      );
    } else {
      // If undo failed, reload the position
      if (_currentPuzzle != null) {
        _loadPuzzlePosition(_currentPuzzle!);
      }
      _showTemporaryFeedback(
        'Let\'s try that again.',
        false,
      );
    }
  }

  void _showTemporaryFeedback(String message, bool isSuccess) {
    setState(() {
      _feedbackMessage = message;
      _isSuccess = isSuccess;
      _showingFeedback = true;
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _showingFeedback = false;
        });
      }
    });
  }

  void _markPuzzleCompleted() {
    if (_currentPuzzle != null) {
      // Use existing progress tracking pattern
      markPuzzleCompleted(ref, _currentPuzzle!.id);
    }
  }

  void _advanceToNextPuzzle() {
    if (_puzzleSet != null && _currentPuzzleIndex < _puzzleSet!.puzzleCount - 1) {
      setState(() {
        _currentPuzzleIndex++;
      });
      _loadCurrentPuzzle();
    } else {
      // All puzzles completed
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('All Puzzles Complete!'),
        content: const Text('Congratulations! You\'ve solved all the puzzles in this set.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Return to level page
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _resetPuzzle() {
    if (_currentPuzzle != null) {
      _loadPuzzlePosition(_currentPuzzle!);
      setState(() {
        _puzzleSolved = false;
        _showingFeedback = false;
      });
    }
  }

  void _showHint() {
    if (_currentPuzzle != null && _currentPuzzle!.hints.isNotEmpty) {
      final hint = _currentPuzzle!.hints.first;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hint: $hint'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Widget _buildProgressBar() {
    if (_puzzleSet == null) return const SizedBox.shrink();
    
    final progress = (_currentPuzzleIndex + 1) / _puzzleSet!.puzzleCount;
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Puzzle ${_currentPuzzleIndex + 1} of ${_puzzleSet!.puzzleCount}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                '${(progress * 100).toInt()}% Complete',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPuzzleHeader() {
    if (_currentPuzzle == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Text(
            _currentPuzzle!.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            _currentPuzzle!.subtitle,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _currentPuzzle!.isWhiteToMove ? Icons.radio_button_unchecked : Icons.circle,
                color: _currentPuzzle!.isWhiteToMove ? Colors.white : Colors.black,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                _currentPuzzle!.turnDisplay,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackOverlay() {
    if (!_showingFeedback) return const SizedBox.shrink();

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _isSuccess ? Colors.green : Colors.red,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
        ),
        child: Text(
          _feedbackMessage,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            onPressed: _resetPuzzle,
            icon: const Icon(Icons.refresh),
            label: const Text('Reset'),
          ),
          if (_currentPuzzle?.hints.isNotEmpty == true)
            ElevatedButton.icon(
              onPressed: _showHint,
              icon: const Icon(Icons.lightbulb_outline),
              label: const Text('Hint'),
            ),
          if (_puzzleSolved)
            ElevatedButton.icon(
              onPressed: _advanceToNextPuzzle,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Next'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('DEBUG: Loading puzzle set for levelId: ${widget.levelId}');
    final puzzleSetAsync = ref.watch(puzzleSetProvider(widget.levelId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Puzzles - Level ${widget.levelId}'),
        elevation: 0,
      ),
      body: AsyncValueView(
        asyncValue: puzzleSetAsync,
        data: (puzzleSet) {
          print('DEBUG: PuzzlesPage received puzzle set with ${puzzleSet.puzzleCount} puzzles');
          // Load puzzle set on first build
          if (_puzzleSet == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _onPuzzleSetLoaded(puzzleSet);
            });
          }

          // Use a different layout approach - SingleChildScrollView with intrinsic height
          return LayoutBuilder(
            builder: (context, constraints) {
              // Calculate sizes
              final screenHeight = constraints.maxHeight;
              final screenWidth = constraints.maxWidth;
              
              // Estimate space needed for other widgets
              const appBarHeight = kToolbarHeight;
              const progressBarHeight = 80.0; // Approximate
              const headerHeight = 100.0; // Approximate  
              const buttonHeight = 80.0; // Approximate
              const padding = 32.0;
              
              // Calculate available space for board
              final availableHeight = screenHeight - 
                progressBarHeight - headerHeight - buttonHeight - padding;
              final availableWidth = screenWidth - padding;
              
              // Board should be square and fit in available space
              final boardSize = availableHeight < availableWidth 
                ? availableHeight 
                : availableWidth;
              
              print('DEBUG: Screen dimensions: ${screenWidth}x${screenHeight}');
              print('DEBUG: Available space: ${availableWidth}x${availableHeight}');
              print('DEBUG: Board size: $boardSize');
              
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildProgressBar(),
                      _buildPuzzleHeader(),
                      // Fixed height container for the board
                      Container(
                        height: boardSize + 32, // Add padding
                        padding: const EdgeInsets.all(16),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Center(
                              child: ChessBoardWidget(
                                boardState: _boardState,
                                onMoveMade: _onMoveMade,
                                size: boardSize,
                              ),
                            ),
                            _buildFeedbackOverlay(),
                          ],
                        ),
                      ),
                      _buildActionButtons(),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}