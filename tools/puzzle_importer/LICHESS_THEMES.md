# Lichess Puzzle Themes Reference

Complete list of all themes available in the Lichess puzzle database.

## All Available Themes (62 total)

### Checkmate Patterns (13)
- `mate` - General checkmate
- `mateIn1` - Checkmate in one move
- `mateIn2` - Checkmate in two moves
- `mateIn3` - Checkmate in three moves
- `mateIn4` - Checkmate in four moves
- `mateIn5` - Checkmate in five moves
- `anastasiaMate` - Anastasia's mate pattern (knight and rook)
- `arabianMate` - Arabian mate (knight and rook corner mate)
- `backRankMate` - Back rank checkmate
- `bodenMate` - Boden's mate (crisscrossing bishops)
- `doubleBishopMate` - Two bishops deliver mate
- `dovetailMate` - Dovetail mate (queen delivers mate, king blocked by own pieces)
- `hookMate` - Hook mate (rook and knight)
- `killBoxMate` - Kill box mate pattern
- `smotheredMate` - Smothered mate (knight mates, king surrounded by own pieces)
- `vukovicMate` - Vukovic mate pattern

### Tactical Motifs (15)
- `fork` - Attacking two or more pieces simultaneously
- `pin` - Piece cannot move without exposing a more valuable piece
- `skewer` - Attacking a valuable piece forcing it to move and exposing another
- `discoveredAttack` - Moving a piece reveals attack from another piece
- `doubleCheck` - Two pieces giving check simultaneously
- `xRayAttack` - Attack through an opponent's piece
- `attraction` - Forcing an enemy piece to a bad square
- `deflection` - Forcing a piece away from defending another piece
- `clearance` - Clearing a square or line for another piece
- `interference` - Blocking a line of defense
- `intermezzo` - In-between move
- `sacrifice` - Giving up material for advantage
- `trappedPiece` - Piece has no good squares
- `zugzwang` - Any move worsens the position

### Piece-Specific (6)
- `advancedPawn` - Advanced pawn(s) are key to the tactic
- `promotion` - Promoting a pawn
- `underPromotion` - Promoting to something other than queen
- `enPassant` - En passant capture
- `castling` - Castling is the key move
- `quietMove` - Non-checking, non-capturing winning move

### Defenders & Defense (6)
- `capturingDefender` - Capturing the piece that defends something
- `defensiveMove` - Finding the best defensive move
- `hangingPiece` - Undefended piece
- `exposedKing` - King in danger
- `kingSafety` - King safety is the theme

### Endgame Types (6)
- `endgame` - General endgame position
- `pawnEndgame` - Pawn endgame
- `queenEndgame` - Queen endgame
- `rookEndgame` - Rook endgame
- `bishopEndgame` - Bishop endgame
- `knightEndgame` - Knight endgame
- `queenRookEndgame` - Queen and rook endgame

### Attack Targets (3)
- `attackingF2F7` - Attacking the f2/f7 weak squares
- `kingsideAttack` - Attack on the kingside
- `queensideAttack` - Attack on the queenside

### Game Phase (3)
- `opening` - Opening phase
- `middlegame` - Middle game
- `endgame` - Endgame phase

### Difficulty/Quality (6)
- `oneMove` - One-move puzzle
- `short` - Short puzzle (2-3 moves)
- `long` - Long puzzle (4-6 moves)
- `veryLong` - Very long puzzle (7+ moves)
- `master` - From master-level games
- `masterVsMaster` - From games between masters
- `superGM` - From super-GM games

### Result/Evaluation (3)
- `advantage` - Winning material/position
- `crushing` - Overwhelming advantage
- `equality` - Achieving equality

## Usage in import_puzzles.py

```python
"level_0001": {
    "title": "Your Level",
    "themes": ["mateIn1", "mate", "short"],  # Combine multiple themes
    "rating_range": [600, 800],
    "max_candidates": 50,
}
```

## Tips for Choosing Themes

### For Beginner Levels (600-800):
- `mateIn1`, `mateIn2` - Simple checkmates
- `hangingPiece` - Spotting undefended pieces
- `fork` - Basic knight/pawn forks
- `pin` - Simple pins
- `backRankMate` - Common checkmate pattern
- `attackingF2F7` - Early game weaknesses
- `promotion` - Pawn promotion tactics

### For Intermediate Levels (900-1200):
- `mateIn2`, `mateIn3` - Multi-move mates
- `discoveredAttack` - More complex tactics
- `skewer`, `deflection` - Advanced motifs
- `sacrifice` - Tactical sacrifices
- `trappedPiece` - Spotting trapped pieces
- `exposedKing` - King safety tactics

### For Advanced Levels (1300+):
- `mateIn4`, `mateIn5` - Complex checkmates
- `zugzwang` - Endgame technique
- `quietMove` - Subtle moves
- `underPromotion` - Tricky promotions
- `long`, `veryLong` - Multi-move combinations
- `master`, `superGM` - High-quality games

## Combining Themes

You can combine themes for more specific filtering:

```python
# Beginner mate patterns
"themes": ["mateIn1", "queenEndgame", "short"]

# Fork practice
"themes": ["fork", "knightEndgame", "advantage"]

# Back rank tactics
"themes": ["backRankMate", "rookEndgame", "mate"]

# Pawn endgames
"themes": ["pawnEndgame", "promotion", "advancedPawn"]
```

## Finding Good Puzzles

The script filters by:
1. **Themes** - Puzzles must match at least one theme
2. **Rating** - Puzzles within your rating range
3. **Popularity** - Sorts by popularity (quality indicator)

If you get:
- **Too few candidates**: Broaden themes or widen rating range
- **Too many candidates**: Make themes more specific
- **Wrong difficulty**: Adjust rating range

## Official Documentation

- [Lichess Database Documentation](https://database.lichess.org/#puzzles)
- [Lichess Puzzle Themes on GitHub](https://github.com/lichess-org/lila/blob/master/modules/puzzle/src/main/PuzzleTheme.scala)
