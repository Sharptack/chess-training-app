# Chess Training App - Development Tools

Tools for creating and managing puzzle content for your chess training app.

---

## 🚀 Quick Start

**Interactive launcher (recommended):**
```bash
cd tools
./create_puzzles.sh
```

This opens an interactive menu with all workflows!

**Or run directly:**
```bash
./create_puzzles.sh lichess   # Import from Lichess
./create_puzzles.sh custom    # Create custom puzzles
./create_puzzles.sh convert   # Convert to app format
./create_puzzles.sh docs      # View documentation
```

**First time setup:**
```bash
# Install Python dependencies
cd puzzle_importer
pip3 install -r requirements.txt

# Download Lichess database (optional, for imports)
# Get from: https://database.lichess.org/#puzzles
# Place: lichess_db_puzzle.csv in puzzle_importer/
```

---

## 📚 Documentation

- **[QUICK_START.md](QUICK_START.md)** - 2-minute quick start guide
- **[PUZZLE_WORKFLOW.md](PUZZLE_WORKFLOW.md)** - Complete step-by-step guide
- **[CHANGELOG.md](CHANGELOG.md)** - Version history and updates

---

## 🎯 Three Main Workflows

### 1️⃣ Lichess Import Workflow

**Best for:** Finding high-quality tactical puzzles by theme/rating

```bash
cd tools
./create_puzzles.sh lichess
```

**Steps:**
1. Interactive script asks for themes, rating range, etc.
2. Generates 50 candidates from Lichess database
3. Open review UI to select best puzzles
4. Convert to app format
5. Move to `assets/data/puzzles/`

**Time:** ~10 minutes for 15 puzzles

---

### 2️⃣ Custom Puzzle Workflow

**Best for:** Building specific positions from scratch

```bash
cd tools
./create_puzzles.sh custom
```

**Steps:**
1. Opens drag-and-drop puzzle creator in browser
2. Build positions with visual editor
3. Add solution moves and hints
4. Export directly in app format
5. Move to `assets/data/puzzles/`

**Time:** ~2-3 minutes per puzzle

---

### 3️⃣ Hybrid Workflow

**Best for:** Mix of Lichess puzzles + custom puzzles

```bash
# 1. Import Lichess candidates
./create_puzzles.sh lichess

# 2. Open creator and import candidates
./create_puzzles.sh custom
# In creator: Import tab → Load candidates
# Create additional custom puzzles
# Export all together

# 3. Convert if needed
./create_puzzles.sh convert
```

---

## 📁 Tool Structure

```
tools/
├── create_puzzles.sh              ← 🆕 Interactive launcher
├── PUZZLE_WORKFLOW.md             ← 🆕 Complete guide
│
├── puzzle_importer/
│   ├── import_puzzles_interactive.py  ← 🆕 Interactive Lichess import
│   ├── import_puzzles.py              ← Old level-based import
│   ├── output/                        ← Generated candidates
│   └── README.md
│
└── puzzle_reviewer/
    ├── convert_puzzles.py             ← 🆕 Format converter
    ├── puzzle_creator.html            ← 🆕 Updated with app export
    ├── review_ui_with_editor.html     ← Visual review & edit
    └── convert_puzzles.html           ← Deprecated
```

---

## 🔧 Setup (First Time Only)

### Install Python Dependencies

```bash
cd tools/puzzle_importer
pip3 install -r requirements.txt
```

### Download Lichess Database (Optional)

Only needed if using Lichess import workflow.

Download from: https://database.lichess.org/#puzzles

Place `lichess_db_puzzle.csv` in `tools/puzzle_importer/`

**Size:** ~1.5 GB (5.4 million puzzles)

---

## 💡 Which Workflow Should I Use?

| Use Case | Recommended Workflow |
|----------|---------------------|
| Need 15 beginner checkmate puzzles | Lichess Import (theme: mateIn1, rating: 600-800) |
| Want specific endgame positions | Custom Puzzle Creator |
| Need variety of tactics | Lichess Import (themes: fork pin skewer) |
| Testing a specific position | Custom Puzzle Creator |
| Building a full level (30 puzzles) | Hybrid (20 Lichess + 10 custom) |
| Need high-quality puzzles fast | Lichess Import |
| Want complete creative control | Custom Puzzle Creator |

---

## 🛠️ Setup & Configuration

### First Time Setup

1. **Install Python dependencies:**
```bash
cd puzzle_importer
pip3 install -r requirements.txt
# Installs: pandas, python-chess
```

2. **Download Lichess database (optional):**
   - Only needed if using Lichess import workflow
   - Download from: https://database.lichess.org/#puzzles
   - Size: ~1.5 GB (5.4 million puzzles)
   - Place as: `puzzle_importer/lichess_db_puzzle.csv`

### Customizing Batch Import (Advanced)

If using the legacy `import_puzzles.py` for batch processing, edit `LEVEL_THEMES`:

```python
"level_0001": {
    "title": "Your Level Title",
    "themes": ["mate", "mateIn1"],      # Lichess theme tags
    "rating_range": [600, 800],         # Min/max rating
    "max_candidates": 50,               # Candidates to generate
    "notes": "Description"
}
```

**Available Lichess Themes:**
- **Checkmates:** `mate`, `mateIn1`, `mateIn2`, `backRankMate`, `smotheredMate`
- **Tactics:** `fork`, `pin`, `skewer`, `discoveredAttack`, `doubleCheck`, `sacrifice`
- **Piece-specific:** `queenEndgame`, `rookEndgame`, `bishopEndgame`, `knightEndgame`, `pawnEndgame`
- **Concepts:** `promotion`, `castling`, `enPassant`, `defensiveMove`, `kingSafety`

See full list: https://database.lichess.org/#puzzles

---

## 🐛 Troubleshooting

### "No puzzles found" from Lichess import
- **Solution:** Broaden themes or rating range
- **Solution:** Use "ANY" match mode instead of "ALL"

### "Invalid FEN" error
- **Solution:** Check FEN format has 6 parts separated by spaces
- **Example:** `rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq e6 0 2`

### Convert script errors
- **Solution:** Make sure input JSON is from review UI or puzzle creator
- **Solution:** Check that moves are in UCI format (e2e4, not e4)

### Puzzle doesn't work in app
- **Solution:** Verify solutionMoves uses UCI notation
- **Solution:** Test the puzzle in Lichess first
- **Solution:** Check that toMove matches FEN turn indicator

### Browser console errors in HTML tools
- **Solution:** Make sure you're opening files via `open` command or file:// protocol
- **Solution:** Check browser console (F12) for specific error messages

---

## 📖 Additional Resources

- **[PUZZLE_WORKFLOW.md](PUZZLE_WORKFLOW.md)** - Complete step-by-step guide
- **[../docs/chess_reference.md](../docs/chess_reference.md)** - UCI notation explained
- **[../docs/ARCHITECTURE.md](../docs/ARCHITECTURE.md)** - How puzzles work in app
- **[Lichess Themes](https://database.lichess.org/#puzzles)** - Full theme list

---

## 🎓 Example: Creating a New Level

Let's create Level 12: "Knight Forks" for beginners.

```bash
# Step 1: Import candidates
cd tools
./create_puzzles.sh lichess

# In prompts:
# Output: knight_forks_beginner
# Themes: fork knightEndgame
# Rating: 600-900
# Count: 50
# Match: ANY

# Step 2: Review and select
cd puzzle_reviewer
open review_ui_with_editor.html
# Load: ../puzzle_importer/output/knight_forks_beginner_candidates.json
# Select 15 best puzzles
# Export Selected Puzzles → save to Downloads

# Step 3: Convert
python3 convert_puzzles.py
# Input: ~/Downloads/selected_puzzles.json
# Level ID: 0012
# Title: Knight Forks
# Description: Win material with knight forks
# Output: puzzle_set_0012.json

# Step 4: Deploy
mv puzzle_set_0012.json ../../assets/data/puzzles/

# Done! Test in app
```

**Total time:** ~15 minutes

---

## 🆕 What's New (Latest Updates)

### February 2025
- ✨ **Interactive puzzle launcher** (`create_puzzles.sh`) - One command for all workflows
- 🎯 **Interactive Lichess importer** - No more editing config files
- 🔄 **Auto format converter** - Transform tool outputs to app format
- 📖 **Complete workflow guide** - Step-by-step documentation
- 🎨 **Updated puzzle creator** - Export directly in app format

### Migration from Old Workflow
Old way:
1. Edit `LEVEL_THEMES` in `import_puzzles.py`
2. Run import script
3. Manually convert JSON structure
4. Fix format issues

New way:
1. Run `./create_puzzles.sh lichess`
2. Select puzzles in UI
3. Auto-convert to app format
4. Done!

**10x faster!** 🚀

---

**Questions?** Check [PUZZLE_WORKFLOW.md](PUZZLE_WORKFLOW.md) or open an issue.
