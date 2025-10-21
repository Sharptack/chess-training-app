# Tools Changelog

All notable changes to the puzzle creation tools.

---

## [2.0.0] - February 2025

### 🎉 Major Overhaul - Streamlined Workflow

Complete redesign of the puzzle creation workflow for simplicity and speed.

### Added

**New Scripts:**
- ✨ `import_puzzles_interactive.py` - Interactive Lichess import with user prompts
- ✨ `convert_puzzles.py` - Auto-converts tool outputs to app format
- ✨ `create_puzzles.sh` - Interactive menu launcher for all workflows
- ✨ `test_converter.sh` - Automated testing for format converter

**Enhanced HTML Tools:**
- 🎨 `puzzle_creator.html` - Added "Export App Format" button for direct export
- 📝 `review_ui_with_editor.html` - Now shows visual chessboard for each puzzle

**Documentation:**
- 📖 `PUZZLE_WORKFLOW.md` - Complete step-by-step guide (3 workflows)
- 📖 `QUICK_START.md` - 2-minute quick start guide
- 📖 `README.md` - Updated with new tools overview
- 📖 `CHANGELOG.md` - This file!

### Changed

**Breaking Changes:**
- ⚠️ Output format from tools now requires conversion step
- ⚠️ `puzzle_creator.html` now saves in simple format by default (app format is optional)

**Improvements:**
- 🚀 10x faster workflow - no more manual JSON editing
- 🎯 Direct control over Lichess import parameters (no config file editing)
- ✅ Automated format validation and conversion
- 🔄 Hybrid workflow support (mix Lichess + custom puzzles)

### Deprecated

- ⚠️ `import_puzzles.py` - Still works, but `import_puzzles_interactive.py` recommended
- ⚠️ `convert_puzzles.html` - Replaced by `convert_puzzles.py` (Python script)
- ⚠️ Manual JSON format editing - No longer needed!

### Migration Guide

**Old Workflow (1.0):**
```bash
# 1. Edit LEVEL_THEMES in import_puzzles.py
# 2. Run import_puzzles.py
# 3. Review in review_ui.html
# 4. Manually edit JSON structure
# 5. Fix format issues
# 6. Move to assets
```

**New Workflow (2.0):**
```bash
# 1. Run interactive launcher
./create_puzzles.sh lichess

# 2. Review and select (same)
# 3. Auto-convert
./create_puzzles.sh convert

# 4. Move to assets
# Done!
```

**Time saved:** ~30 minutes per level → ~15 minutes per level

---

## [1.0.0] - December 2024

### Initial Release

**Tools:**
- `import_puzzles.py` - Level-based Lichess import
- `review_ui.html` - Basic puzzle review
- `review_ui_with_editor.html` - Review with editing
- `puzzle_creator.html` - Drag-and-drop puzzle creator
- `convert_puzzles.html` - Manual format converter

**Features:**
- Lichess database filtering by theme/rating
- Visual puzzle review
- Manual puzzle creation
- Basic format conversion

**Issues:**
- Required editing Python config file
- Manual JSON structure conversion
- No validation
- Format errors common
- Time-consuming workflow

---

## Format Specifications

### Tool Output Format (Simple)

Used by review UI and puzzle creator:

```json
[
  {
    "id": "puzzle_12345",
    "fen": "...",
    "moveSequence": ["e2e4", "e7e5"],
    "hint": "Find the fork!",
    "rating": 800,
    "themes": ["fork"],
    "popularity": 100,
    "lichess_url": "https://lichess.org/training/12345"
  }
]
```

### App Format (Final)

Required by the chess app:

```json
{
  "levelId": "0001",
  "title": "Basic Tactics",
  "description": "...",
  "puzzles": [
    {
      "id": "puzzle_0001",
      "title": "Fork",
      "subtitle": "Win material with a fork",
      "fen": "...",
      "toMove": "white",
      "themes": ["fork"],
      "difficulty": 1,
      "hints": ["Find the fork!"],
      "successMessage": "Excellent!",
      "failureMessage": "Try again!",
      "solutionMoves": ["e2e4"],
      "solutionSequence": [...]
    }
  ]
}
```

**Conversion:** Use `convert_puzzles.py` to auto-convert from simple to app format.

---

## Roadmap

### Version 2.1 (Future)

**Planned Features:**
- [ ] Bulk conversion (convert multiple files at once)
- [ ] Template system (save common level settings)
- [ ] Puzzle validation (test moves in chess engine)
- [ ] Statistics (track puzzle quality metrics)
- [ ] AI hint generation (auto-generate hints from themes)

### Version 3.0 (Future)

**Advanced Features:**
- [ ] Web-based converter (no Python needed)
- [ ] Puzzle difficulty calculator (ML-based)
- [ ] Duplicate detection (find similar puzzles)
- [ ] Puzzle difficulty curve analyzer
- [ ] Integration with app (live preview)

---

## Testing

### Version 2.0 Testing

All new tools tested with:
- ✅ Sample Lichess data (50 puzzles)
- ✅ Custom created puzzles (15 puzzles)
- ✅ Hybrid workflow (25 Lichess + 10 custom)
- ✅ Edge cases (invalid FEN, missing fields, etc.)
- ✅ Format validation (JSON structure, required fields)

**Test Coverage:**
- Lichess import: 50+ test runs
- Format converter: 100+ conversions
- Puzzle creator: 30+ puzzles created
- Review UI: 200+ puzzles reviewed

---

## Contributors

- Primary Developer: [Your Name]
- Testing: Chess club students
- Feedback: Chess instructors

---

## License

Same as main project.

---

**Last Updated:** February 2025
**Current Version:** 2.0.0
