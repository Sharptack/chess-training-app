# Chess Notation Reference Guide

## Quick Reference for Chess Puzzle Development

This guide covers Forsyth-Edwards Notation (FEN) and Standard Algebraic Notation (SAN) for chess applications.

---

## Part 1: FEN (Forsyth-Edwards Notation)

### What is FEN?
FEN describes a complete chess position in a single ASCII string. It consists of 6 space-separated fields.

### FEN Structure
```
<Piece Placement> <Side to move> <Castling> <En passant> <Halfmove> <Fullmove>
```

**Example Starting Position:**
```
rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1
```

### Field 1: Piece Placement
- **Order:** Rank 8 → Rank 1 (top to bottom)
- **Within each rank:** File a → File h (left to right)
- **Separator:** `/` between ranks
- **Empty squares:** Use digits 1-8 to count consecutive empty squares
- **Pieces:**
  - Uppercase = White: `P N B R Q K`
  - Lowercase = Black: `p n b r q k`

**Examples:**
```
rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR  (starting position)
rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR  (after 1.e4)
rnbqkbnr/pp1ppppp/8/2p5/4P3/8/PPPP1PPP/RNBQKBNR  (after 1.e4 c5)
```

### Field 2: Side to Move
- `w` = White to move
- `b` = Black to move

### Field 3: Castling Rights
Shows which castling moves are still legal:
- `K` = White can castle kingside
- `Q` = White can castle queenside  
- `k` = Black can castle kingside
- `q` = Black can castle queenside
- `-` = No castling available
- Combine available rights: `KQkq`, `Kk`, `q`, etc.

**Important:** Rights are lost when king or rook moves, even if they move back!

### Field 4: En Passant Target Square
- Shows the square **behind** a pawn that just moved two squares
- Format: file + rank (e.g., `e3`, `d6`)
- Use `-` if no en passant is possible
- **Critical:** Set this after ANY double pawn push, even if capture isn't actually legal

**Examples:**
- After `e2-e4`, the en passant square is `e3` (not e4!)
- After `d7-d5`, the en passant square is `d6` (not d5!)

### Field 5: Halfmove Clock
- Number of halfmoves since last capture or pawn move
- Used for the 50-move draw rule
- Reset to `0` after captures or pawn moves
- Incremented otherwise
- Usually `0` in puzzles

### Field 6: Fullmove Number
- The move number of the game
- Starts at `1`
- Incremented after Black's move
- If it's Black to move on move 5, this is still `5`

### Common FEN Mistakes to Avoid
1. ❌ Wrong rank order (must be rank 8 first, not rank 1)
2. ❌ En passant square is the pawn's square (should be behind it)
3. ❌ Using `0` instead of `-` for missing fields
4. ❌ Forgetting slashes between ranks
5. ❌ Wrong number of squares per rank (must total 8)

### FEN Validation Checklist
- [ ] Exactly 8 ranks separated by 7 slashes
- [ ] Each rank totals to 8 squares (pieces + empty squares)
- [ ] Exactly one white king and one black king
- [ ] Side to move is `w` or `b`
- [ ] Castling is `-` or valid combination of `KQkq`
- [ ] En passant is `-` or valid square (rank 3 or 6 only)
- [ ] Halfmove and fullmove are non-negative integers

---

## Part 2: Move Notation - UCI and SAN

### UCI (Universal Chess Interface) Notation

**Required for this app:** All puzzle/game move data MUST use UCI notation.

**Why UCI?** Simpler, unambiguous, and consistent with our data sources.

#### Format
```
<from-square><to-square><promotion>
```

**Examples:**
```
e2e4        - Pawn from e2 to e4
g1f3        - Knight from g1 to f3
e7e8q       - Pawn promotes to queen (lowercase q)
e1g1        - Castling (king e1 to g1)
e5d6        - En passant capture
```

#### Advantages
- ✅ No ambiguity - always specifies exact squares
- ✅ Easy to parse programmatically
- ✅ Works for all moves including castling and promotions
- ✅ Used by Lichess puzzles and UCI chess engines

#### **CRITICAL: chess.js Library Quirk**
The chess.js `move()` function behaves differently for UCI:
```javascript
// ✅ WORKS: UCI as object
chess.move({from: 'e2', to: 'e4'})

// ❌ FAILS: UCI as string
chess.move('e2e4')

// ✅ WORKS: SAN as string
chess.move('e4')
```

**Our wrapper functions handle this:**
- `makeUciMove(string)` - Converts UCI strings to object format
- `makeSanMove(string)` - Passes strings directly to chess.js
- Data uses UCI strings, code converts before passing to chess.js

#### Promotion
- Append lowercase piece letter: `e7e8q`, `a7a8n`
- Letters: `q`, `r`, `b`, `n` (never `k` or `p`)

---

## Part 3: SAN (Standard Algebraic Notation)

### What is SAN?
SAN is the official FIDE notation for recording chess moves. It's compact and human-readable but requires disambiguation logic.

### Basic Move Format

#### Piece Moves (Non-Pawn)
```
<Piece><disambiguation><capture><destination><check/mate>
```

**Examples:**
- `Nf3` - Knight to f3
- `Bxc4` - Bishop captures on c4  
- `Qd2` - Queen to d2
- `Rh8+` - Rook to h8 with check

#### Pawn Moves
```
<file if capture><capture><destination><promotion><check/mate>
```

**Examples:**
- `e4` - Pawn to e4
- `exd5` - Pawn on e-file captures on d5
- `e8=Q` - Pawn promotes to Queen on e8
- `cxb3+` - Pawn on c-file captures on b3 with check

### Disambiguation Rules

When multiple pieces of the same type can move to the same square, add disambiguation:

**Priority order:**
1. **File only** (if files differ): `Nbd7`, `Rad1`
2. **Rank only** (if files same, ranks differ): `R1e2`, `N5f3`
3. **Full square** (if both file and rank same - rare): `Qg3e1`

**Examples:**
```
Position: Knights on b1 and g1, both can go to f3
Correct: Ngf3 (the knight from g-file)

Position: Rooks on a1 and a8, both can go to a4  
Correct: R1a4 (the rook from rank 1)

Position: Three queens (yes, really!) on d3, d5, g3, all can go to d4
Correct: Qd3d4 or Q3d4 or Qdxd4 (depends on position)
```

### Special Notations

#### Captures
- Use `x` before destination square
- Pawns must include origin file: `exd4` (not `xd4`)
- Pieces may include disambiguation: `Nxf7`, `Bxc3`

#### Castling
- **Kingside:** `O-O` (letter O, not zero)
- **Queenside:** `O-O-O`

#### Promotion
- Format: `<destination>=<piece>`
- Must use `=` sign in PGN standard
- Examples: `e8=Q`, `axb8=N+`, `c1=R#`
- Piece letters: `Q`, `R`, `B`, `N` (never `K` or `P`)

#### En Passant
- No special notation required
- Write as normal pawn capture: `exd6`
- Optional suffix `e.p.` allowed: `exd6 e.p.`

#### Check and Checkmate
- Check: `+` suffix (e.g., `Qh5+`)
- Checkmate: `#` suffix (e.g., `Qh7#`)
- Optional but recommended for clarity

### Converting Internal Moves to SAN

To generate SAN from internal move representation:

1. **Determine the piece type** at origin square
2. **Check for captures** (is destination square occupied?)
3. **Generate all legal moves** to the destination square by same piece type
4. **Apply disambiguation:**
   - If only one piece can move there → no disambiguation
   - If multiple pieces → add file/rank/square as needed
5. **Add special notation:** captures (`x`), promotion (`=Q`), check (`+`), mate (`#`)
6. **Handle castling separately:** Detect king moving 2 squares

### Parsing SAN Moves

To convert SAN string to internal move:

1. **Check for castling:** `O-O` or `O-O-O` → special handling
2. **Extract destination square** (last 2 chars before modifiers)
3. **Extract piece type** (first char if uppercase, else pawn)
4. **Extract disambiguation** (middle characters)
5. **Generate legal moves** for that piece type to destination
6. **Filter by disambiguation** (file/rank/square)
7. **Should have exactly one legal move** remaining

### SAN Validation & Common Mistakes

❌ **Common Errors:**
1. `Pf3` - Don't use P for pawns (just `f3`)
2. `0-0` - Use letter O, not digit zero (`O-O`)
3. `e8Q` - Missing equals sign (should be `e8=Q`)
4. `Nd7` when ambiguous - Need `Nbd7` or `Nfd7`
5. `xf3` - Pawns need origin file (`exf3`)
6. `N3f3` - Wrong order (should be `N3` then destination: `Nf3` or with rank: `N3f3`)

✅ **Valid Examples:**
```
e4          - Pawn to e4
Nf3         - Knight to f3  
Bb5         - Bishop to b5
O-O         - Kingside castling
Qxd7+       - Queen captures on d7 with check
e8=Q#       - Pawn promotes to queen with checkmate
Nbd2        - Knight from b-file to d2 (disambiguation)
R1a3        - Rook from rank 1 to a3 (disambiguation)
exf6        - Pawn from e-file captures on f6
```

---

## Part 4: Chess Rules & Legal Move Generation

### Understanding Legal vs Pseudo-Legal Moves

**Pseudo-Legal Move:** A move that follows the piece's normal movement rules but might leave the king in check.

**Legal Move:** A pseudo-legal move that does NOT leave the king in check.

### Piece Movement Rules

#### Pawn Movement
- **Forward movement:** One square forward (two squares on first move)
- **Captures:** One square diagonally forward only
- **Cannot move backward** or capture straight ahead
- **En Passant:** Special capture when opponent pawn moves two squares and lands beside your pawn
  - Must be executed immediately after the double-step move
  - Capturing pawn moves diagonally to the square the enemy pawn passed over
  - The passed pawn is removed
- **Promotion:** When reaching the 8th rank (1st rank for Black)
  - Must promote to Queen, Rook, Bishop, or Knight
  - Cannot remain a pawn or become a King
  - Can have multiple queens on board

**FEN/SAN Notes:**
- Pawns have no piece letter in SAN (just write `e4` not `Pe4`)
- Pawn captures MUST include origin file: `exd5` (not `xd5`)
- Promotions use `=` in SAN: `e8=Q`, `axb8=N+`

#### Knight Movement
- Moves in "L" shape: 2 squares in one direction, then 1 square perpendicular
- **Only piece that can jump over other pieces**
- Can move forward, backward, or sideways
- 8 possible moves from center of board (fewer near edges)

**Example from d4:** c2, e2, f3, f5, e6, c6, b5, b3

#### Bishop Movement
- Moves diagonally any number of squares
- Cannot jump over pieces
- Each bishop is confined to one color (light or dark) entire game
- Two bishops per player (one light-square, one dark-square)

#### Rook Movement
- Moves horizontally or vertically any number of squares
- Cannot jump over pieces
- Participates in castling with the King

#### Queen Movement
- Combines Rook + Bishop movement
- Moves horizontally, vertically, or diagonally any number of squares
- Cannot jump over pieces
- Most powerful piece (worth ~9 points)

#### King Movement
- Moves one square in any direction (horizontal, vertical, diagonal)
- **Cannot move into check** (attacked square)
- **Cannot be captured** - game ends in checkmate instead
- Special move: Castling (see below)

### Special Moves

#### Castling
**Requirements:**
1. King and chosen rook have never moved
2. No pieces between king and rook
3. King is NOT in check
4. King does NOT move through check
5. King does NOT end in check

**How it works:**
- **Kingside (O-O):** King moves 2 squares toward h-rook, rook jumps to other side
- **Queenside (O-O-O):** King moves 2 squares toward a-rook, rook jumps to other side

**In FEN:** Castling rights are in field 3 (`KQkq`)
- Rights lost when king or rook moves (even if they move back!)

**In SAN:** 
- Use `O-O` (letter O, not zero 0) for kingside
- Use `O-O-O` for queenside

### Check, Checkmate, and Stalemate

#### Check
A king is in check when attacked by an opponent's piece.

**Three ways to escape check:**
1. **Move the king** to a non-attacked square
2. **Block the attack** (only works for sliding pieces: Bishop, Rook, Queen)
3. **Capture the attacking piece**

**Double Check:** King is attacked by two pieces simultaneously
- ONLY option is to move the king (cannot block two pieces or capture both)

**In SAN:** Add `+` suffix for check: `Qh5+`, `Nf3+`

#### Checkmate
King is in check AND has no legal moves to escape.

**In SAN:** Add `#` suffix for checkmate: `Qh7#`, `Rd8#`

**Game ends immediately** - no further moves possible.

#### Stalemate
King is NOT in check BUT has no legal moves (and no other pieces can move either).

**Result:** Draw (game tied)

### Pins and Legal Move Generation

#### Absolute Pin
A piece that cannot move because doing so would expose its own king to check.

**Example:** White king on e1, White bishop on f2, Black rook on h4
- The bishop on f2 is absolutely pinned
- It can move along the pin ray (e1-f2-g3-h4) only
- Cannot move to other squares (would expose king)

#### En Passant Legality
Most complex legal move check!

**Special case:** After en passant capture, must check if removing BOTH pawns creates a discovered check horizontally.

**Example:** 
```
Position: White king on e5, White pawn on d5, Black pawn on e5, Black rook on a5
If Black plays d7-d5 (double step), White CANNOT play exd6 en passant
Why? Removing both pawns exposes White's king to the Black rook!
```

### Move Generation Strategy

Most chess engines use this approach:

1. **Generate pseudo-legal moves** (fast - just follow piece movement rules)
2. **Make the move on a temporary board**
3. **Check if own king is in check** after the move
4. **If in check, move is illegal** - discard it
5. **If not in check, move is legal** - keep it

**Optimization for being in check:**
- Generate only king moves, captures of checker, or blocking moves
- Skip all other pieces (they can't help)

### Determining Check Status

**Efficient method (from king's perspective):**
1. Generate attack patterns FROM the king square
2. Check if any opponent pieces of that type exist on those squares
3. Example: Generate bishop moves from king → check if enemy bishop or queen there

**Don't do this:** Generate all opponent moves and see if they attack king (too slow!)

### Common Legality Tests

```
Is king in check after this move?
1. Make the move on temp board
2. Find my king position
3. For each opponent piece type:
   - Generate attacks from king square as if king were that piece type
   - Check if opponent has that piece type on any attack square
4. If any match found → king in check → move illegal

Is move legal?
1. Is it pseudo-legal? (follows piece movement rules)
2. Does it leave king in check? (see above)
3. Special: If castling, does king pass through check?
4. Special: If en passant, does it expose king horizontally?
```

### Check/Checkmate Detection Example

```
After a move is made:
1. Is opponent king in check? (attacks opponent king square)
2. Generate all legal moves for opponent
3. If no legal moves:
   - If in check → Checkmate (you win!)
   - If not in check → Stalemate (draw)
4. If legal moves exist → game continues
```

---

## Part 5: Working with Chess Puzzles

### Puzzle FEN Best Practices

1. **Set correct side to move** - Usually the side that has the winning tactic
2. **Clear castling rights** - Set to `-` unless castling is part of the puzzle
3. **En passant** - Only set if it's relevant to the solution
4. **Halfmove clock** - Usually `0` for puzzles
5. **Move number** - Can be `1` for puzzles (doesn't matter)

### Puzzle Data Structure

This app uses two types of puzzles: **single-move** and **multi-move** puzzles.

#### Two Puzzle Formats

**Format 1: User Moves First (Simple Puzzles)**
- FEN shows the user's turn to move
- User makes the first (and possibly only) move
- Best for simple tactical puzzles

**Format 2: Opponent Moves First (After-Move Puzzles)**
- FEN shows the opponent's turn to move
- `solutionSequence` starts with opponent move (`isUserMove: false`)
- Opponent move plays automatically
- Then user responds with winning move
- Best for "find the best response" puzzles
- `toMove` field indicates which side the USER plays (not who moves first in FEN)

#### Single-Move Puzzles

For simple tactical puzzles where the user makes one winning move:

```json
{
  "id": "puzzle_001",
  "title": "Checkmate in 1",
  "subtitle": "Find the winning move for White",
  "fen": "6k1/5ppp/8/8/8/8/5PPP/4R1K1 w - - 0 1",
  "toMove": "white",
  "themes": ["checkmate"],
  "difficulty": 1,
  "solutionMoves": ["e1e8"],
  "hints": ["Look for back rank weakness"],
  "successMessage": "Excellent! Checkmate!",
  "failureMessage": "Not quite right. Try again!"
}
```

**Key Points:**
- `toMove` must match the side to move in the FEN (the `w` or `b` in field 2)
- `solutionMoves` contains the user's winning move(s) in UCI notation
- No `solutionSequence` field needed for single-move puzzles

#### Multi-Move Puzzles - Format 1 (User First)

For tactical sequences where the user initiates the combination:

```json
{
  "id": "puzzle_002",
  "title": "Mate in 2",
  "subtitle": "Find the brilliant combination for White",
  "fen": "r1b1kb1r/pppp1ppp/8/4n3/2B1P2q/2N5/PPPP1PPP/R1BQK2R w KQkq - 0 7",
  "toMove": "white",
  "themes": ["checkmate", "sacrifice"],
  "difficulty": 4,
  "solutionMoves": ["d1h5"],
  "solutionSequence": [
    {
      "move": "d1h5",
      "isUserMove": true,
      "comment": "Threatening mate on f7"
    },
    {
      "move": "e5c4",
      "isUserMove": false,
      "comment": "Black tries to defend"
    },
    {
      "move": "h5f7",
      "isUserMove": true,
      "comment": "Checkmate!"
    }
  ],
  "hints": ["Look for forcing moves"],
  "successMessage": "Brilliant! You found the sequence!",
  "failureMessage": "Look for moves that create multiple threats."
}
```

**Sequence Flow:**
1. Puzzle loads with FEN (white to move, user's turn)
2. User makes first move (`isUserMove: true`)
3. App automatically makes opponent response (`isUserMove: false`)
4. User makes next move (`isUserMove: true`)
5. Continue until sequence complete or checkmate

#### Multi-Move Puzzles - Format 2 (Opponent First)

For puzzles where user must find the best response to opponent's move:

```json
{
  "id": "puzzle_003",
  "title": "Tactical Puzzle",
  "subtitle": "Find the winning move for Black",
  "fen": "2kr2r1/ppb2ppp/3qbn2/2Np2B1/P7/2P2Q1P/1PB2PP1/R4RK1 w - - 5 18",
  "toMove": "black",
  "themes": ["tactics"],
  "difficulty": 2,
  "solutionMoves": ["d6h2"],
  "solutionSequence": [
    {
      "move": "c5e6",
      "isUserMove": false,
      "comment": "White plays Ne6"
    },
    {
      "move": "d6h2",
      "isUserMove": true,
      "comment": "Black delivers checkmate"
    }
  ],
  "hints": ["You can checkmate in this position!"],
  "successMessage": "Excellent! You found the winning move!",
  "failureMessage": "Not quite right. Try again!"
}
```

**Key Points:**
- FEN shows white to move (opponent's turn)
- `toMove: "black"` indicates USER plays black (not who moves first!)
- `solutionSequence` **starts with opponent's move** (`isUserMove: false`)
- Opponent move plays automatically after puzzle loads
- Then user responds with winning move

**Sequence Flow:**
1. Puzzle loads with FEN (opponent's turn)
2. App automatically makes opponent's move (`isUserMove: false`)
3. User makes winning response (`isUserMove: true`)
4. Puzzle complete

#### General Rules for All Puzzles

**Key Points:**
- `toMove` field indicates which side the USER plays
- `solutionMoves` contains only the user's moves in UCI notation
- `solutionSequence` (if present) contains the complete move sequence
- Opponent moves (`isUserMove: false`) are played automatically by the app
- Each move must be in UCI notation
- ChessBoardWidget sends moves in UCI format to match data

### Puzzle Solution Format

**For this app:** MUST use **UCI notation** in all JSON data files:

```json
"solutionMoves": ["e2e4", "g1f3"],
"solutionSequence": [
  {"move": "d8h4", "isUserMove": true, "comment": "Attack!"},
  {"move": "g2g3", "isUserMove": false, "comment": "Defending"},
  {"move": "h4e1", "isUserMove": true, "comment": "Checkmate"}
]
```

**For display/documentation only:** SAN notation with move numbers:
```
1. e4 Nf3 2. Qh4 g3 3. Qe1#
```

**Policy (see ARCHITECTURE.md):**
- ✅ **JSON files**: UCI only (e2e4, g1f3)
- ✅ **Code**: Accepts both (chess.js compatibility)
- ✅ **UI Display**: SAN (from getHistory())

**Why UCI for data storage:**
- Unambiguous - no need to determine piece type or disambiguate
- Consistent with Lichess puzzle database (our source)
- Stockfish outputs UCI natively
- Easier to generate programmatically
- The chess.js library's move() function accepts both formats

### Testing FEN Strings

Valid starting position:
```
rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1
```

Scholar's Mate position:
```
r1bqkb1r/pppp1Qpp/2n2n2/4p3/2B1P3/8/PPPP1PPP/RNB1K1NR b KQkq - 0 4
```

Smothered Mate puzzle (famous):
```
6k1/5ppp/8/8/8/8/5PPP/3R2K1 w - - 0 1
```

### Common Libraries

**Python:**
```python
import chess

# Parse FEN
board = chess.Board("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")

# Make move from SAN
move = board.parse_san("e4")
board.push(move)

# Convert move to SAN  
san_move = board.san(move)
```

**JavaScript:**
```javascript
const Chess = require('chess.js')

// Parse FEN
const chess = new Chess('rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1')

// Make move from SAN
chess.move('e4')

// Get legal moves in SAN
const moves = chess.moves() // Returns array like ['a3', 'a4', 'b3', ...]
```

---

## Quick Reference Tables

### Piece Letters & Values
| Piece  | English | FEN (White/Black) | SAN | Value | Movement |
|--------|---------|-------------------|-----|-------|----------|
| King   | King    | K / k             | K   | ∞     | 1 square any direction |
| Queen  | Queen   | Q / q             | Q   | 9     | Any direction, any distance |
| Rook   | Rook    | R / r             | R   | 5     | Horizontal/vertical, any distance |
| Bishop | Bishop  | B / b             | B   | 3     | Diagonal, any distance |
| Knight | Knight  | N / n             | N   | 3     | L-shape, can jump pieces |
| Pawn   | Pawn    | P / p             | -   | 1     | Forward 1 (or 2 first move), captures diagonal |

### Square Coordinates
Files: `a b c d e f g h` (left to right)  
Ranks: `1 2 3 4 5 6 7 8` (bottom to top for White)

```
8 [ ][ ][ ][ ][ ][ ][ ][ ]
7 [ ][ ][ ][ ][ ][ ][ ][ ]
6 [ ][ ][ ][ ][ ][ ][ ][ ]
5 [ ][ ][ ][ ][ ][ ][ ][ ]
4 [ ][ ][ ][ ][ ][ ][ ][ ]
3 [ ][ ][ ][ ][ ][ ][ ][ ]
2 [ ][ ][ ][ ][ ][ ][ ][ ]
1 [ ][ ][ ][ ][ ][ ][ ][ ]
   a  b  c  d  e  f  g  h
```

### En Passant Squares
- White pawn double push → en passant square on rank 3
- Black pawn double push → en passant square on rank 6

| Move   | En Passant Target |
|--------|-------------------|
| e2-e4  | e3                |
| d2-d4  | d3                |
| c7-c5  | c6                |
| f7-f5  | f6                |

---

## Debugging Checklist

When FEN/SAN isn't working:

### FEN Issues:
- [ ] Count total squares per rank (should be 8)
- [ ] Verify rank order (8→1, not 1→8)
- [ ] Check piece letters (uppercase=White, lowercase=Black)
- [ ] Confirm exactly 1 white king, 1 black king
- [ ] Verify en passant is rank 3 or 6 (if not `-`)
- [ ] Ensure castling rights match piece positions

### SAN Issues:
- [ ] Check disambiguation (file/rank/square)
- [ ] Verify capture notation (`x` present when capturing)
- [ ] Confirm promotion uses `=` sign
- [ ] Verify castling uses letter O (not zero)
- [ ] Check pawn captures include origin file
- [ ] Ensure move is legal from current position

---

## Additional Resources

- **Chess Programming Wiki (FEN):** https://www.chessprogramming.org/Forsyth-Edwards_Notation
- **Chess Programming Wiki (SAN):** https://www.chessprogramming.org/Algebraic_Chess_Notation  
- **PGN Specification:** http://www.saremba.de/chessgml/standards/pgn/pgn-complete.htm
- **FIDE Laws of Chess:** https://handbook.fide.com/chapter/E012023

---

*Reference compiled from Chess Programming Wiki and FIDE standards*
*Last updated for chess puzzle development applications*