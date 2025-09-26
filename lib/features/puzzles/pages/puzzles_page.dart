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
  
  // Multi-move puzzle tracking
  int _currentStepIndex = 0;
  bool _isComputerMoving = false;
  
  // Track completed puzzles in this session
  Set<String> _completedPuzzleIds = {};

  @override
  void initState() {
    super.initState();
    _boardState = ChessBoardState();
  }

  void _onPuzzleSetLoaded(PuzzleSet puzzleSet) async {
    // print('DEBUG: PuzzlesPage received puzzle set with ${puzzleSet.puzzleCount} puzzles');
    setState(() {
      _puzzleSet = puzzleSet;
      _currentPuzzleIndex = 0;
    });
    
    // Load completed puzzles from progress storage
    await _loadCompletedPuzzles();
    
    // Find first incomplete puzzle or start from beginning
    _findNextIncompletePuzzle();
    _loadCurrentPuzzle();
  }
  
  Future<void> _loadCompletedPuzzles() async {
    _completedPuzzleIds.clear();
    if (_puzzleSet != null) {
      for (final puzzle in _puzzleSet!.puzzles) {
        final progressKey = '${widget.levelId}_${puzzle.id}';
        final progressAsync = await ref.read(puzzleProgressProvider(progressKey).future);
        // Fix: Use the correct property name from Progress model
        // Progress likely has 'completed' or 'completedAt' instead of 'isCompleted'
        if (progressAsync.completed) {  // Changed from isCompleted to completed
          _completedPuzzleIds.add(puzzle.id);
        }
      }
    }
    // print('DEBUG: Loaded ${_completedPuzzleIds.length} completed puzzles');
  }
  
  void _findNextIncompletePuzzle() {
    if (_puzzleSet == null) return;
    
    for (int i = 0; i < _puzzleSet!.puzzleCount; i++) {
      final puzzle = _puzzleSet!.getPuzzleAt(i);
      if (puzzle != null && !_completedPuzzleIds.contains(puzzle.id)) {
        _currentPuzzleIndex = i;
        // print('DEBUG: Starting at puzzle index $i (first incomplete)');
        return;
      }
    }
    
    // All puzzles completed, start at last puzzle
    _currentPuzzleIndex = _puzzleSet!.puzzleCount - 1;
  }

  void _loadCurrentPuzzle() {
    // print('DEBUG: Loading puzzle at index $_currentPuzzleIndex');
    if (_puzzleSet != null && _currentPuzzleIndex < _puzzleSet!.puzzleCount) {
      final puzzle = _puzzleSet!.getPuzzleAt(_currentPuzzleIndex);
      if (puzzle != null) {
        // print('DEBUG: Loading puzzle: ${puzzle.title}');
        setState(() {
          _currentPuzzle = puzzle;
          _puzzleSolved = _completedPuzzleIds.contains(puzzle.id);
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
      
      // Reset multi-move tracking
      _currentStepIndex = 0;
      _isComputerMoving = false;
      
      setState(() {});
    } catch (e) {
      print('DEBUG: Error loading puzzle position: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading puzzle position: $e')),
      );
    }
  }

  void _onMoveMade(String move) {
    print('DEBUG PuzzlesPage: Move received: "$move"');
    print('DEBUG PuzzlesPage: Current puzzle: ${_currentPuzzle?.id}');
    print('DEBUG PuzzlesPage: Is multi-move? ${_currentPuzzle?.isMultiMove}');
    print('DEBUG PuzzlesPage: Solution sequence: ${_currentPuzzle?.solutionSequence}');
    print('DEBUG PuzzlesPage: Current step: $_currentStepIndex');
    
    if (_puzzleSolved || _showingFeedback || _isComputerMoving) {
      print('DEBUG PuzzlesPage: Ignoring move - puzzle solved/feedback/computer moving');
      return;
    }

    if (_currentPuzzle != null) {
      bool isCorrect = false;
      
      // Check if this is a multi-move puzzle
      if (_currentPuzzle!.isMultiMove) {
        // Debug the expected move at this step
        if (_currentPuzzle!.solutionSequence != null && 
            _currentStepIndex < _currentPuzzle!.solutionSequence!.length) {
          final expectedStep = _currentPuzzle!.solutionSequence![_currentStepIndex];
          print('DEBUG PuzzlesPage: Expected move at step $_currentStepIndex: ${expectedStep.move}');
          print('DEBUG PuzzlesPage: Is user move? ${expectedStep.isUserMove}');
        }
        
        isCorrect = _currentPuzzle!.isCorrectMoveAtStep(move, _currentStepIndex);
        print('DEBUG PuzzlesPage: Multi-move puzzle - move correct at step $_currentStepIndex? $isCorrect');
        
        if (isCorrect) {
          _currentStepIndex++;
          
          // Check if there's a computer response needed
          final computerMove = _currentPuzzle!.getComputerResponseAtStep(_currentStepIndex - 1);
          if (computerMove != null) {
            print('DEBUG PuzzlesPage: Computer needs to respond with: $computerMove');
            _makeComputerMove(computerMove);
            return; // Don't complete puzzle yet
          }
          
          // Check if puzzle is complete
          // We've made all the user moves if we've gone through the entire sequence
          final totalMoves = _currentPuzzle!.solutionSequence!.length;
          final puzzleComplete = _currentStepIndex >= totalMoves || _boardState.isCheckmate;
          
          print('DEBUG PuzzlesPage: Step $_currentStepIndex of $totalMoves, checkmate: ${_boardState.isCheckmate}');
          
          if (puzzleComplete) {
            print('DEBUG PuzzlesPage: Multi-move puzzle complete!');
            _handleCorrectMove();
          } else {
            // Show temporary success feedback but continue puzzle
            _showTemporaryFeedback('Good move! Continue...', true);
          }
        } else {
          _handleIncorrectMove();
        }
      } else {
        // Single-move puzzle
        isCorrect = _currentPuzzle!.isSolutionMove(move);
        print('DEBUG PuzzlesPage: Single-move puzzle - is solution? $isCorrect');
        
        if (isCorrect) {
          _handleCorrectMove();
        } else {
          // Check if checkmate achieved anyway
          if (_boardState.isCheckmate) {
            print('DEBUG PuzzlesPage: Checkmate detected! Accepting as correct');
            _handleCorrectMove();
          } else {
            _handleIncorrectMove();
          }
        }
      }
    } else {
      print('DEBUG PuzzlesPage: ERROR - No current puzzle!');
    }
    
    setState(() {});
  }
  
  Future<void> _makeComputerMove(String move) async {
    setState(() {
      _isComputerMoving = true;
    });
    
    // Delay to make it feel like computer is thinking
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Make the computer's move
    final success = _boardState.makeSanMove(move);
    
    if (success) {
      print('DEBUG PuzzlesPage: Computer moved: $move');
      _currentStepIndex++;
    } else {
      print('DEBUG PuzzlesPage: ERROR - Computer move failed: $move');
    }
    
    setState(() {
      _isComputerMoving = false;
    });
  }

  void _handleCorrectMove() {
    setState(() {
      _puzzleSolved = true;
      _isSuccess = true;
      _feedbackMessage = _currentPuzzle?.successMessage ?? 'Correct!';
      _showingFeedback = true;
      
      // Add to completed set
      if (_currentPuzzle != null) {
        _completedPuzzleIds.add(_currentPuzzle!.id);
      }
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
      // Add to completed set first
      _completedPuzzleIds.add(_currentPuzzle!.id);
      
      // Mark this specific puzzle as completed
      markPuzzleCompleted(ref, widget.levelId, _currentPuzzle!.id);
      
      // Check if ALL puzzles in the level are now completed
      // Count actual completed puzzles, not just current index
      final totalCompleted = _completedPuzzleIds.length;
      final totalPuzzles = _puzzleSet?.puzzleCount ?? 0;
      
      print('DEBUG: Completed $totalCompleted of $totalPuzzles puzzles');
      
      if (totalCompleted >= totalPuzzles && totalPuzzles > 0) {
        // All puzzles in this level completed
        print('DEBUG: Marking level ${widget.levelId} puzzles as complete');
        markLevelPuzzlesCompleted(ref, widget.levelId);
      }
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
        _currentStepIndex = 0;
        _isComputerMoving = false;
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