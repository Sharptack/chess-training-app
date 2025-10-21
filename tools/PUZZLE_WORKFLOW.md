# Puzzle Creation Workflow

Complete guide for creating puzzles for your chess training app.

---

## 🎯 Two Main Workflows

### Workflow A: Import from Lichess Database
**Best for:** Finding high-quality tactical puzzles by theme and rating

### Workflow B: Create Custom Puzzles
**Best for:** Building specific positions or unique puzzles from scratch

---

## 📋 Workflow A: Import from Lichess

### Step 1: Generate Candidates (Interactive)

Run the interactive importer:

```bash
cd tools/puzzle_importer
python3 import_puzzles_interactive.py
```

You'll be prompted for:
- **Output filename**: e.g., `forks_beginner` or `checkmate_advanced`
- **Themes**: Space-separated (e.g., `fork pin mateIn1`)
- **Rating range**: Min and max (e.g., 600-800 for beginners)
- **Max candidates**: How many puzzles to generate (default: 50)
- **Match mode**: ANY (at least one theme) or ALL (all themes required)

**Example Session:**
```
📁 Output filename: checkmate_beginner
🎨 Themes: mateIn1 mateIn2 mate
⭐ Min rating: 600
⭐ Max rating: 900
📊 Max puzzles: 50
🔍 Match mode: 1 (ANY)
```

**Output:** `output/checkmate_beginner_candidates.json`

### Step 2: Review and Select

Open the review UI:

```bash
cd tools/puzzle_reviewer
open review_ui_with_editor.html
```

**In the browser:**
1. Click "Choose File" → Load your candidates JSON from `puzzle_importer/output/`
2. Review each puzzle:
   - Visual chessboard shows the position
   - Click "View on Lichess" to play through the solution
   - Click "Edit Puzzle" to modify FEN, moves, or hint
3. Click "Select" on your best 10-30 puzzles (green border)
4. Click "Export Selected Puzzles"
5. Save to Downloads as `selected_puzzles.json`

### Step 3: Convert to App Format

Run the converter:

```bash
cd tools/puzzle_reviewer
python3 convert_puzzles.py
```

**Interactive prompts:**
- Input file: `~/Downloads/selected_puzzles.json`
- Level ID: `0011`
- Title: `Checkmate Basics`
- Description: `Learn basic checkmate patterns`
- Output file: `puzzle_set_0011.json` (or press Enter for default)

**Output:** `puzzle_set_0011.json` in the correct app format!

**Command-line mode (skip prompts):**
```bash
python3 convert_puzzles.py \
  ~/Downloads/selected_puzzles.json \
  0011 \
  "Checkmate Basics" \
  "Learn basic checkmate patterns" \
  puzzle_set_0011.json
```

### Step 4: Move to Assets

```bash
mv puzzle_set_0011.json ../../assets/data/puzzles/
```

**Done!** Test in the app.

---

## 🎨 Workflow B: Create Custom Puzzles

### Step 1: Open Puzzle Creator

```bash
cd tools/puzzle_reviewer
open puzzle_creator.html
```

### Step 2: Create Puzzles

**Three ways to create:**

#### Option 1: Build from Scratch
1. Click "Clear Board" or "Starting Position"
2. Select a piece from the piece selector
3. Click squares on the board to place pieces
4. Set "Turn to Move" (White/Black)
5. Fill in:
   - Puzzle ID: `puzzle_custom_001`
   - Solution Moves: `e2e4 e7e5 g1f3` (space-separated UCI)
   - Hint: `Develop your knight!`
   - Rating: `800`
   - Themes: `opening development`
6. Click "💾 Save Puzzle"

#### Option 2: Import and Edit
1. Switch to **Import** tab
2. Load candidates from Lichess importer
3. Click a puzzle from the list to load it
4. Edit on the board (drag pieces, click to add/remove)
5. Update moves/hints as needed
6. Click "💾 Save Puzzle"

#### Option 3: Load from FEN
1. Click "Load from FEN"
2. Paste a FEN position (from Lichess, chess.com, etc.)
3. Add moves and hint
4. Click "💾 Save Puzzle"

### Step 3: Export Puzzles

Switch to **My Puzzles** tab, then choose:

#### Simple Export (Recommended)
1. Click "📥 Export Simple Format"
2. Save as `my_custom_puzzles.json`
3. Run `convert_puzzles.py` (see Workflow A, Step 3)

#### Direct App Format Export
1. Click "📥 Export App Format"
2. Enter Level ID, Title, Description
3. Save as `puzzle_set_XXXX.json`
4. Move directly to `assets/data/puzzles/`

---

## 🔄 Hybrid Workflow: Mix Both

Combine Lichess imports with custom puzzles:

```bash
# 1. Import 30 puzzles from Lichess
python3 import_puzzles_interactive.py
# Output: checkmate_candidates.json

# 2. Open puzzle creator
open puzzle_creator.html

# 3. Import tab → Load checkmate_candidates.json
# Now all 30 puzzles are in your library

# 4. Create 5 custom puzzles
# Build them from scratch and save to library

# 5. Edit some imported puzzles
# Click puzzle → Edit on board → Save

# 6. Export all 35 puzzles
# Click "Export App Format"
```

---

## 📊 Quick Reference

### Common Themes
```
Checkmates:  mate, mateIn1, mateIn2, mateIn3, backRankMate, smotheredMate
Tactics:     fork, pin, skewer, discoveredAttack, doubleCheck, sacrifice
Defense:     defensiveMove, escapingCheck, kingSafety
Endgames:    queenEndgame, rookEndgame, bishopEndgame, knightEndgame, pawnEndgame
Special:     promotion, castling, enPassant, hangingPiece
```

See full list: https://database.lichess.org/#puzzles

### Rating Ranges
```
600-800:    Absolute beginners (basic checkmates, hanging pieces)
800-1000:   Beginners (simple tactics, 1-2 move combos)
1000-1200:  Intermediate (forks, pins, basic endgames)
1200-1500:  Advanced intermediate (multi-move tactics)
1500-1800:  Advanced (complex combinations, sacrifices)
1800+:      Expert (deep calculation, positional puzzles)
```

### UCI Notation Format
All moves use UCI (Universal Chess Interface) notation:

```
Format: <from><to><promotion>

Examples:
  e2e4      - Pawn from e2 to e4
  g1f3      - Knight from g1 to f3
  e1g1      - Castling kingside (king moves)
  e7e8q     - Pawn promotion to queen
  d6h2      - Bishop captures on h2
```

**Important:**
- Use UCI in JSON files (storage format)
- App converts to SAN for display (Nf3, Qxf7#)
- See [docs/chess_reference.md](../docs/chess_reference.md) for details

---

## 🐛 Troubleshooting

### "No puzzles found" in Lichess importer
- **Solution:** Broaden themes or rating range, or use ANY match mode

### "Invalid FEN" error in converter
- **Solution:** Check FEN format - must have 6 space-separated parts:
  ```
  rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1
  ```

### Puzzle doesn't work in app
- **Check:** Move notation is UCI (e2e4), not SAN (e4)
- **Check:** FEN has correct turn indicator (w or b)
- **Check:** solutionSequence alternates user/opponent moves correctly

### Export button doesn't work in HTML tools
- **Solution:** Check browser console (F12) for errors
- **Solution:** Make sure you saved at least one puzzle first

---

## 📁 File Structure

```
tools/
├── puzzle_importer/
│   ├── import_puzzles_interactive.py  ← New interactive importer
│   ├── import_puzzles.py              ← Old level-based importer
│   ├── output/                        ← Generated candidates
│   │   └── checkmate_beginner_candidates.json
│   └── lichess_db_puzzle.csv          ← Database (download separately)
│
├── puzzle_reviewer/
│   ├── convert_puzzles.py             ← New converter script
│   ├── puzzle_creator.html            ← Updated with app format export
│   ├── review_ui_with_editor.html     ← Review and edit
│   └── review_ui.html                 ← Basic review (deprecated)
│
└── PUZZLE_WORKFLOW.md                 ← This file

assets/data/puzzles/
└── puzzle_set_0001.json               ← Final puzzle sets for app
```

---

## 🚀 Quick Start Examples

### Example 1: Beginner Checkmates
```bash
# Generate candidates
cd tools/puzzle_importer
python3 import_puzzles_interactive.py
# Input: checkmate_beginner, mateIn1 mateIn2, 600-800, 50

# Review and select
cd ../puzzle_reviewer
open review_ui_with_editor.html
# Load output/checkmate_beginner_candidates.json
# Select 15 best puzzles, export

# Convert
python3 convert_puzzles.py
# Input: ~/Downloads/selected_puzzles.json, 0001, "Checkmate Basics", "..."

# Deploy
mv puzzle_set_0001.json ../../assets/data/puzzles/
```

### Example 2: Mixed Custom Puzzles
```bash
# Open creator
cd tools/puzzle_reviewer
open puzzle_creator.html

# Create 15 puzzles manually
# Export App Format → Level 0020
# Save as puzzle_set_0020.json

# Deploy
mv ~/Downloads/puzzle_set_0020.json ../../assets/data/puzzles/
```

### Example 3: Hybrid (10 Lichess + 5 Custom)
```bash
# Import 30 Lichess candidates
cd tools/puzzle_importer
python3 import_puzzles_interactive.py

# Open creator and import
cd ../puzzle_reviewer
open puzzle_creator.html
# Import tab → Load candidates
# Select 10 best from Lichess
# Create 5 custom puzzles
# Export App Format (15 total)
```

---

## 💡 Tips

1. **Start with Lichess:** Faster to find quality puzzles than creating from scratch
2. **Review thoroughly:** Bad puzzles hurt learning - quality over quantity
3. **Use themes wisely:** Specific themes = fewer but better matches
4. **Edit freely:** The review UI lets you fix FEN or moves without starting over
5. **Test in app:** Always play through puzzles in the actual app before finalizing
6. **Batch similar puzzles:** Group by theme/difficulty for consistent levels
7. **Save your library:** Puzzle creator uses browser storage - export to JSON to back up

---

## 🔗 Related Documentation

- [Chess Notation Reference](../docs/chess_reference.md) - UCI vs SAN explained
- [Architecture Guide](../docs/ARCHITECTURE.md) - How puzzles work in the app
- [Lichess Database](https://database.lichess.org/#puzzles) - Theme documentation

---

**Questions?** Check the troubleshooting section or review the example workflows above.
