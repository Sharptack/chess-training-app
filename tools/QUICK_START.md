# Puzzle Creation Quick Start

**The fastest way to create puzzles for your chess app.**

---

## ⚡ Super Quick Start (2 minutes)

```bash
cd tools
./create_puzzles.sh lichess
```

Follow the prompts, then review and select puzzles. Done!

---

## 🎯 Choose Your Path

### Path A: I want Lichess puzzles (easiest, fastest)

```bash
# 1. Generate candidates
./create_puzzles.sh lichess
# → Enter themes, rating, count

# 2. Review and select (opens browser)
cd puzzle_reviewer
open review_ui_with_editor.html
# → Load from output/, select 15, export

# 3. Convert to app format
cd ..
./create_puzzles.sh convert
# → Enter level details, done!

# 4. Move to app
mv puzzle_reviewer/puzzle_set_XXXX.json ../assets/data/puzzles/
```

**Time:** 10-15 minutes for 15 puzzles

---

### Path B: I want custom puzzles (full control)

```bash
# 1. Open creator
./create_puzzles.sh custom

# 2. Build puzzles in browser
# → Drag pieces, add moves, save to library

# 3. Export app format
# → Click "Export App Format" button
# → Enter level details

# 4. Move to app
mv ~/Downloads/puzzle_set_XXXX.json ../assets/data/puzzles/
```

**Time:** 2-3 minutes per puzzle

---

### Path C: I want both (best quality)

```bash
# 1. Import Lichess candidates
./create_puzzles.sh lichess

# 2. Open creator
./create_puzzles.sh custom

# 3. Import tab → Load candidates
# 4. Edit/add custom puzzles
# 5. Export all together
```

---

## 📦 What You Need

### For Lichess Import
- Python 3
- Dependencies: `pip3 install -r puzzle_importer/requirements.txt`
- Lichess database: Download from https://database.lichess.org/#puzzles
- Place in: `tools/puzzle_importer/lichess_db_puzzle.csv`

### For Custom Creator
- Just a web browser! (Chrome, Firefox, Safari)
- No dependencies needed

---

## 🆘 Help

### "No puzzles found"
→ Broaden themes or rating range, use ANY match mode

### "Invalid FEN"
→ Check format has 6 parts: `rnbq... w KQkq - 0 1`

### "Converter errors"
→ Make sure input is from review UI or puzzle creator

### "Puzzle doesn't work in app"
→ Check UCI notation (e2e4 not e4), test on Lichess first

---

## 📖 Full Documentation

- **[README.md](README.md)** - Tool overview
- **[PUZZLE_WORKFLOW.md](PUZZLE_WORKFLOW.md)** - Complete guide
- **[../docs/chess_reference.md](../docs/chess_reference.md)** - UCI notation

---

## 💡 Pro Tips

1. **Test first:** Generate 50 candidates, select best 15
2. **Quality over quantity:** One great puzzle > three mediocre ones
3. **Use specific themes:** `mateIn1` better than just `mate`
4. **Edit freely:** Review UI lets you fix anything
5. **Hybrid approach:** 10 Lichess + 5 custom = great level

---

## 🎓 Example: "Checkmate in 1" level

```bash
# Generate candidates
./create_puzzles.sh lichess
# Themes: mateIn1
# Rating: 600-800
# Count: 50

# Review
open puzzle_reviewer/review_ui_with_editor.html
# Select 15 best

# Convert
./create_puzzles.sh convert
# Level: 0015
# Title: Checkmate in One
# Description: Practice spotting one-move checkmates

# Deploy
mv puzzle_reviewer/puzzle_set_0015.json ../assets/data/puzzles/

# Test in app!
```

**Done in 15 minutes!**

---

## 🚀 Next Steps

1. Try creating your first level (follow example above)
2. Read [PUZZLE_WORKFLOW.md](PUZZLE_WORKFLOW.md) for advanced techniques
3. Explore themes: https://database.lichess.org/#puzzles
4. Share your best puzzles!

---

**Questions?** Run `./create_puzzles.sh docs` for full documentation.
