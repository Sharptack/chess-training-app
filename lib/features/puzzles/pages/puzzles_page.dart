//lib/features/puzzles/pages/puzzles_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/chess_board_widget.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/game_logic/chess_board_state.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/constants.dart';
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
        // Use the same key format as markPuzzleCompleted: 'puzzle_levelId_puzzleId'
        final progressKey = 'puzzle_${widget.levelId}_${puzzle.id}';
        final progressAsync = await ref.read(puzzleProgressProvider(progressKey).future);
        if (progressAsync.completed) {
          _completedPuzzleIds.add(puzzle.id);
        }
      }
    }
    print('DEBUG: Loaded ${_completedPuzzleIds.length} completed puzzles from storage');
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
          _puzzleSolved = false; // Always allow the puzzle to be played, even if completed before
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

      // Check if there's an initial computer move to make
      if (puzzle.solutionSequence != null &&
          puzzle.solutionSequence!.isNotEmpty &&
          !puzzle.solutionSequence!.first.isUserMove) {
        // Make the opponent's first move automatically
        Future.delayed(Duration(milliseconds: 500), () {
          final firstMove = puzzle.solutionSequence!.first.move;
          print('DEBUG: Making initial opponent move: $firstMove');
          _makeComputerMove(firstMove);
        });
      }
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
      print('DEBUG PuzzlesPage: Ignoring move - _puzzleSolved=$_puzzleSolved, _showingFeedback=$_showingFeedback, _isComputerMoving=$_isComputerMoving');
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
    await Future.delayed(Duration(milliseconds: GameConstants.computerMoveDelayMs));

    // Make the computer's move - puzzle data uses UCI format (our standard)
    // Try UCI first, then SAN as fallback for legacy compatibility
    bool success = _boardState.makeUciMove(move);
    if (!success) {
      success = _boardState.makeSanMove(move);
    }

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
    final padding = ResponsiveUtils.getHorizontalPadding(context);
    final spacing = ResponsiveUtils.getSpacing(context, mobile: 6, tablet: 8, desktop: 10);

    return Container(
      padding: EdgeInsets.all(padding),
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
          SizedBox(height: spacing),
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

    final horizontalPadding = ResponsiveUtils.getHorizontalPadding(context);
    final verticalPadding = ResponsiveUtils.getVerticalPadding(context) * 0.5;
    final spacing = ResponsiveUtils.getSpacing(context, mobile: 4, tablet: 6, desktop: 8);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
      child: Column(
        children: [
          Text(
            _currentPuzzle!.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: spacing),
          Text(
            _currentPuzzle!.subtitle,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: spacing * 1.5),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _currentPuzzle!.isWhiteToMove ? Icons.radio_button_unchecked : Icons.circle,
                color: _currentPuzzle!.isWhiteToMove ? Colors.white : Colors.black,
                size: ResponsiveUtils.getIconSize(context, mobile: 14, tablet: 16, desktop: 18),
              ),
              SizedBox(width: spacing),
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
    final padding = ResponsiveUtils.getHorizontalPadding(context);
    final iconSize = ResponsiveUtils.getIconSize(context, mobile: 18, tablet: 20, desktop: 22);

    return Container(
      padding: EdgeInsets.all(padding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            onPressed: _resetPuzzle,
            icon: Icon(Icons.refresh, size: iconSize),
            label: const Text('Reset'),
          ),
          if (_currentPuzzle?.hints.isNotEmpty == true)
            ElevatedButton.icon(
              onPressed: _showHint,
              icon: Icon(Icons.lightbulb_outline, size: iconSize),
              label: const Text('Hint'),
            ),
          if (_puzzleSolved)
            ElevatedButton.icon(
              onPressed: _advanceToNextPuzzle,
              icon: Icon(Icons.arrow_forward, size: iconSize),
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

              // Use responsive values for estimates
              final progressBarHeight = ResponsiveUtils.getValue(
                context,
                mobile: 70.0,
                tablet: 75.0,
                desktop: 80.0,
              );

              final headerHeight = ResponsiveUtils.getValue(
                context,
                mobile: 90.0,
                tablet: 95.0,
                desktop: 100.0,
              );

              final buttonHeight = ResponsiveUtils.getValue(
                context,
                mobile: 70.0,
                tablet: 75.0,
                desktop: 80.0,
              );

              final padding = ResponsiveUtils.getHorizontalPadding(context) * 2;

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
                        height: boardSize + ResponsiveUtils.getHorizontalPadding(context) * 2,
                        padding: EdgeInsets.all(ResponsiveUtils.getHorizontalPadding(context)),
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