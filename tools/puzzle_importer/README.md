# Puzzle Importer Tool

This tool imports puzzles from the Lichess puzzle database and filters them by level themes and rating.

## Available Tools

This package includes three tools for different workflows:

| Tool | Purpose | Best For |
|------|---------|----------|
| **import_puzzles.py** | Import from Lichess database | Finding high-quality puzzles by theme/rating |
| **review_ui_with_editor.html** | Review & edit candidates | Selecting best 15 from candidates, minor edits |
| **puzzle_creator.html** | Create custom puzzles | Building puzzles from scratch, major edits |

## Quick Start

```bash
cd tools/puzzle_importer

# 1. Install dependencies (first time only)
pip3 install -r requirements.txt

# 2. Generate puzzle candidates
python3 import_puzzles.py

# 3. Review and edit puzzles
./open_editor.sh

# OR: Create puzzles from scratch
open ../puzzle_reviewer/puzzle_creator.html
```

Then load a file from the `output/` directory and select your 15 best puzzles!

**💡 NEW: Puzzle Creator** - Build custom puzzles with drag-and-drop!

For detailed instructions, see [Usage](#usage) below.

---

## Setup

1. Install required Python packages:
```bash
pip3 install -r requirements.txt
# or
pip3 install pandas python-chess
```

2. Make sure `lichess_db_puzzle.csv` is in this directory

## Usage

### Step 1: Import Candidate Puzzles

Run the import script to generate candidate puzzles for each level:

```bash
cd tools/puzzle_importer
python3 import_puzzles.py
```

This will:
- Load the Lichess puzzle database (5.4M puzzles)
- Filter puzzles for each level based on:
  - **Rating range**: 600-800 (beginner level)
  - **Themes**: Level-specific tactical patterns
  - **Popularity**: High-quality puzzles ranked first
- Generate up to 50 candidates per level
- Save results to `output/level_XXXX_candidates.json`

### Step 2: Review and Select Puzzles

1. Open the review UI in your browser:
```bash
# Option 1: Quick script (shows helpful paths)
./open_review.sh

# Option 2: Direct open (basic review)
open ../puzzle_reviewer/review_ui.html

# Option 3: With editing features (RECOMMENDED)
open ../puzzle_reviewer/review_ui_with_editor.html
```

**✨ NEW: Editor Features**
- Visual chessboard showing puzzle position
- Edit FEN position, moves, or hint
- Changes tracked and included in export
- Can export all puzzles with edits

2. Click "Choose File" and navigate to the output directory:
   - The file picker opens in Downloads by default
   - Navigate to: `chess-training-app/tools/puzzle_importer/output/`
   - Select a candidate file (e.g., `level_0001_candidates.json`)

   **Tip**: The full path is `/Users/[YourName]/chess-training-app/tools/puzzle_importer/output/`

3. Review each puzzle:
   - Click "View on Lichess" to see the puzzle on Lichess (opens in new tab)
   - Study the FEN, solution, themes, and rating
   - Click "Select" to add to your final selection (card turns green)
4. Select 15 puzzles per level (counter shows in top-right)
5. Click "Export Selected Puzzles" to download the final JSON
   - File saves to your Downloads folder as `selected_puzzles.json`
6. Rename and move the exported file:
```bash
# Example: Move and rename for level 1
mv ~/Downloads/selected_puzzles.json ../../assets/data/puzzles/puzzles_level_0001.json
```

---

## Alternative: Create Custom Puzzles

Don't want to use Lichess puzzles? Create your own from scratch!

### Puzzle Creator Tool

Open the drag-and-drop puzzle creator:
```bash
./open_creator.sh
# or
open ../puzzle_reviewer/puzzle_creator.html
```

**Features:**
- 🎨 **Drag & Drop Editor** - Visual board setup with pieces
- 💾 **Auto-Save Library** - Puzzles saved in browser storage
- 📥 **Import & Edit** - Load Lichess candidates and modify them
- 🔄 **Full Control** - Edit position, moves, hints, everything
- 📦 **Batch Export** - Export all puzzles at once

**Three Ways to Use:**

1. **Create from Scratch**
   - Start with empty/starting position
   - Drag pieces to build your position
   - Add solution moves and hint
   - Save to library

2. **Edit Imported Puzzles**
   - Import Lichess candidates
   - Click puzzle to load on board
   - Modify position with drag & drop
   - Update moves/hints
   - Save changes

3. **Mixed Workflow**
   - Import some Lichess puzzles
   - Create some custom ones
   - Edit both types
   - Export all together

**Usage Example:**
```bash
# Create 5 custom puzzles
open puzzle_creator.html
# Build positions, save each one

# Import 10 Lichess puzzles and tweak them
# Import tab → Load file → Edit → Save

# Export all 15 puzzles
# Library tab → Export All → Save to assets/data/puzzles/
```

---

## Level Themes (Currently Configured)

### Campaign 1: Fundamentals 1

| Level | Title | Themes | Rating |
|-------|-------|--------|--------|
| 0001 | Check vs. Checkmate | mate, mateIn1, mateIn2 | 600-800 |
| 0002 | Pawn Promotion | promotion, advancedPawn, endgame | 600-800 |
| 0003 | Stopping Check 1 - Capture | capturingDefender, defensiveMove | 600-800 |
| 0004 | Stopping Check 2 - Block | intermezzo, defensiveMove | 600-800 |
| 0005 | Stopping Check 3 - Move | kingSafety, exposedKing | 600-800 |

### Campaign 2: Fundamentals 2

| Level | Title | Themes | Rating |
|-------|-------|--------|--------|
| 0006 | Checkmate in 1 with Queen | mateIn1, queenEndgame | 600-800 |
| 0007 | Bishop Practice | bishopEndgame, long | 600-800 |
| 0008 | Checkmate in 1 with Queen (Part 2) | mateIn1, queenEndgame | 600-800 |
| 0009 | Knight Practice | knightEndgame, fork | 600-800 |
| 0010 | Checkmate in 1 with Rook | mateIn1, rookEndgame, backRankMate | 600-800 |

## Customizing Levels

Edit `LEVEL_THEMES` in `import_puzzles.py`:

```python
"level_0001": {
    "title": "Your Level Title",
    "themes": ["theme1", "theme2", "theme3"],  # Lichess theme tags
    "rating_range": [600, 800],                # Min/max rating
    "max_candidates": 50,                       # How many candidates to generate
    "notes": "Description of what this level focuses on"
}
```

### Available Lichess Themes

Common themes you can use:
- **Checkmates**: `mate`, `mateIn1`, `mateIn2`, `backRankMate`, `smotheredMate`
- **Tactics**: `fork`, `pin`, `skewer`, `discoveredAttack`, `doubleCheck`
- **Piece-specific**: `queenEndgame`, `rookEndgame`, `bishopEndgame`, `knightEndgame`, `pawnEndgame`
- **Concepts**: `promotion`, `castling`, `enPassant`, `sacrifice`, `defensiveMove`
- **Positions**: `opening`, `middlegame`, `endgame`, `kingSafety`, `exposedKing`

See the [Lichess theme documentation](https://database.lichess.org/#puzzles) for a complete list.

## Output Format

Final puzzle JSON format:
```json
[
  {
    "id": "puzzle_00008",
    "fen": "r6k/pp2r2p/4Rp1Q/3p4/8/1N1P2R1/PqP2bPP/7K b - - 0 24",
    "moveSequence": ["f2g3", "e6e7", "b2b1", "b3c1", "b1c1", "h6c1"],
    "hint": "Checkmate in two moves!"
  }
]
```

## Tips

- **Too few candidates?** Broaden the theme list or increase rating range
- **Too many candidates?** Make themes more specific or narrow rating range
- **Wrong difficulty?** Adjust the rating_range (lower = easier)
- **Quality issues?** The script sorts by popularity, so top results should be good

## Next Steps

After selecting puzzles for levels 1-10, add more level definitions to `LEVEL_THEMES` and repeat the process!
