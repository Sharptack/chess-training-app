// lib/core/constants.dart

/// Application-wide constants
class AppConstants {
  AppConstants._();

  // ============================================================================
  // APP INFO
  // ============================================================================

  static const appName = 'Chess Trainer';

  // ============================================================================
  // NETWORK & TIMEOUTS
  // ============================================================================

  static const httpTimeoutMs = 15000;

  // ============================================================================
  // ROUTING
  // ============================================================================

  static const defaultCampaignId = 'beginner';
  static const defaultLevelId = '0001';
}

/// Game logic constants for chess, bots, and gameplay
class GameConstants {
  GameConstants._();

  // ============================================================================
  // CHESS PIECE VALUES (for bot move evaluation)
  // ============================================================================

  /// Value of a pawn in chess evaluation
  static const double pieceValuePawn = 1.0;

  /// Value of a knight in chess evaluation
  static const double pieceValueKnight = 3.0;

  /// Value of a bishop in chess evaluation
  static const double pieceValueBishop = 3.0;

  /// Value of a rook in chess evaluation
  static const double pieceValueRook = 5.0;

  /// Value of a queen in chess evaluation
  static const double pieceValueQueen = 9.0;

  /// Value of a king (effectively infinite, should never be captured)
  static const double pieceValueKing = 100.0;

  // ============================================================================
  // MOVE EVALUATION SCORES (for bot decision making)
  // ============================================================================

  /// Bonus score for making a capture move
  static const double captureBonus = 5.0;

  /// Bonus score for making a check move
  static const double checkBonus = 3.0;

  /// Bonus score for checkmate (game-winning move)
  static const double checkmateBonus = 1000.0;

  /// Bonus score for controlling center squares (d4, d5, e4, e5)
  static const double centerControlBonus = 1.0;

  /// Bonus score for controlling near-center squares
  static const double nearCenterControlBonus = 0.5;

  /// Bonus score for castling
  static const double castleBonus = 2.0;

  /// Maximum random variation added to move scores (prevents identical evaluations)
  static const double moveScoreRandomVariation = 0.1;

  // ============================================================================
  // BOT THINKING TIME (milliseconds)
  // ============================================================================

  /// Base thinking delay for all bots
  static const int botBaseThinkingTime = 500;

  /// Additional thinking time per difficulty level
  static const int botThinkingTimePerLevel = 300;

  /// Random variation in bot thinking time (±500ms)
  static const int botThinkingRandomVariation = 500;

  /// Move time for difficulty level 1 bots (50ms)
  static const int moveTimeDifficulty1 = 50;

  /// Move time for difficulty level 2 bots (100ms)
  static const int moveTimeDifficulty2 = 100;

  /// Move time for difficulty level 3 bots (300ms)
  static const int moveTimeDifficulty3 = 300;

  /// Move time for difficulty level 4 bots (500ms)
  static const int moveTimeDifficulty4 = 500;

  /// Move time for difficulty level 5 bots (1000ms)
  static const int moveTimeDifficulty5 = 1000;

  /// Default move time if difficulty is unknown
  static const int moveTimeDefault = 300;

  /// Timeout buffer added to Stockfish move requests (2 seconds)
  static const int stockfishMoveTimeoutBuffer = 2000;

  // ============================================================================
  // BOT BEHAVIOR PROBABILITIES
  // ============================================================================

  /// Probability of choosing a capture move (difficulty 2)
  static const double captureProbabilityLevel2 = 0.8;

  /// Probability of choosing a capture move (difficulty 3)
  static const double captureProbabilityLevel3 = 0.8;

  /// Probability of choosing a check move (difficulty 3)
  static const double checkProbabilityLevel3 = 0.6;

  /// Probability of making a random move instead of best (difficulty 4)
  static const double randomMoveProbabilityLevel4 = 0.3;

  /// Probability of making a random move instead of best (difficulty 5)
  static const double randomMoveProbabilityLevel5 = 0.1;

  // ============================================================================
  // STOCKFISH ENGINE SETTINGS
  // ============================================================================

  /// Stockfish initialization timeout (5 seconds)
  static const int stockfishInitTimeoutSeconds = 5;

  /// Delay after sending UCI command
  static const int stockfishUciDelayMs = 200;

  /// Delay after position commands
  static const int stockfishPositionDelayMs = 50;

  /// Delay after isready command
  static const int stockfishIsReadyDelayMs = 100;

  /// Minimum valid Stockfish skill level
  static const int stockfishMinSkillLevel = -20;

  /// Maximum valid Stockfish skill level
  static const int stockfishMaxSkillLevel = 20;

  /// Minimum UCI_Elo value that Stockfish accepts
  static const int stockfishMinUciElo = 1320;

  /// Default skill level for difficulty 1 (beginner)
  static const int stockfishSkillLevelDifficulty1 = -10;

  /// Default skill level for difficulty 2
  static const int stockfishSkillLevelDifficulty2 = -5;

  /// Default skill level for difficulty 3
  static const int stockfishSkillLevelDifficulty3 = 0;

  /// Default skill level for difficulty 4
  static const int stockfishSkillLevelDifficulty4 = 8;

  /// Default skill level for difficulty 5 (strong)
  static const int stockfishSkillLevelDifficulty5 = 15;

  /// ELO threshold for weak bot settings
  static const int weakBotEloThreshold = 600;

  // ============================================================================
  // VIDEO LESSON PROGRESS TRACKING
  // ============================================================================

  /// Seconds of video playback before marking as "started"
  static const int videoStartedThresholdSeconds = 2;

  /// Percentage of video watched before marking as "completed" (0.9 = 90%)
  static const double videoCompletionThresholdPercent = 0.9;

  // ============================================================================
  // GAME UI TIMINGS
  // ============================================================================

  /// Delay for computer move animation (feels more natural)
  static const int computerMoveDelayMs = 800;

  /// Stockfish ready check interval
  static const int stockfishReadyCheckIntervalMs = 100;
}