# Chess Training App

An interactive chess learning app for kids featuring video lessons, tactical puzzles, and bot practice games. Designed for safe, offline-first tablet use with campaign-based progression.

---

## Project Status

**Current Phase**: Phase 6.7 Complete ✅
**Next Phase**: Phase 7 - Chess Club Launch Preparation
**Target**: Chess club testing launch in 5-6 weeks

### What's Working
- Video lessons with progress tracking
- Interactive puzzles (multi-move sequences)
- Bot gameplay with Stockfish engine (5 difficulty levels)
- Boss battles with unlock requirements
- Custom starting positions (endgame practice)
- Move restrictions (opening practice)
- Undo, move history, game variety

### In Development (Phase 7)
- Campaign system (14 campaigns, 55 levels)
- Games architecture (full games, endgame practice, opening practice)
- Full content creation (55 videos, 550+ puzzles, 100-150 games)
- Analytics tracking
- Mobile deployment (iOS TestFlight, Android Internal Testing)

---

## Tech Stack

- **Framework**: Flutter 3.x
- **State Management**: Riverpod
- **Local Storage**: Hive (progress, settings)
- **Navigation**: go_router
- **Chess Engine**: chess package
- **AI Opponent**: Stockfish (UCI protocol)
- **Video**: video_player + chewie

---

## Project Structure

```
lib/
├── features/           # Feature modules (campaign, level, lesson, puzzles, play, boss)
├── core/               # Shared utilities (widgets, game logic, theme)
├── data/               # Data layer (models, repositories, sources)
└── state/              # Global state (Riverpod providers)

assets/
├── data/               # JSON configurations (campaigns, levels, puzzles, bots)
├── videos/             # Video lessons (Phase 7.4)
└── images/             # Chess piece SVGs

docs/
├── LAUNCH_PLAN.md      # Phase 7 detailed plan (temporary)
├── CAMPAIGN_STRUCTURE.md  # 14 campaigns, 55 levels breakdown
├── PROGRESS.md         # Current status and roadmap
├── BACKLOG.md          # Post-launch features (prioritized)
├── ARCHITECTURE.md     # Technical documentation
├── CHANGELOG.md        # Development history (Phases 0-6.7)
└── chess_reference.md  # FEN/SAN notation guide for content creation
```

---

## Getting Started

### Prerequisites

- Flutter SDK 3.x or later
- Dart SDK
- iOS development: Xcode (macOS)
- Android development: Android Studio

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/chess-training-app.git
cd chess-training-app
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

### Development Branches

**Main**: Stable, production-ready (Phase 6.7 complete)

**Phase 7 branches** (launch preparation):
- `phase-7.1-campaign-system` - Campaign architecture
- `phase-7.2-unlock-system` - Unlocking progression
- `phase-7.3-mobile-responsive` - Mobile deployment
- `phase-7.4-content-creation` - Content production
- `phase-7.5-analytics` - Metrics tracking
- `phase-7.6-polish` - QA and polish
- `phase-7.7-launch` - Chess club testing

**Post-launch**: Feature-based branches (e.g., `feature/spaced-repetition`)

---

## Key Features

### Campaign-Based Progression (Phase 7.1)
- 14 campaigns with 55 levels total
- Fundamentals (18 levels) + Beginner 1 (37 levels)
- Bosses at campaign level
- Progressive unlocking system

### Three Learning Components per Level
1. **Video Lesson** (5-10 minutes)
   - Recorded instruction on specific topics
   - Progress tracking (2s = started, 90% = completed)

2. **Puzzles** (10-15 per level)
   - Tactical training with themed puzzles
   - Multi-move sequences
   - Hint system

3. **Games** (1-5 per level)
   - **Full Games**: Play complete games against bots
   - **Endgame Practice**: Custom starting positions (FEN)
   - **Opening Practice**: Move restrictions for learning sequences

### Bot System
- Stockfish integration with adjustable difficulty
- 5 difficulty levels (200-1600 ELO)
- Custom positions and move restrictions
- Progress tracking (win or play minimum moves)

### Boss Battles
- One boss per campaign
- Unlocks after all levels in campaign complete
- Choose color (White/Black)
- One-win completion

---

## Content Structure

See [CAMPAIGN_STRUCTURE.md](docs/CAMPAIGN_STRUCTURE.md) for complete breakdown.

**Summary**:
- **Campaigns**: 14 (13 active + 1 reserved)
- **Levels**: 55
- **Videos**: 55 lessons (~6 hours total)
- **Puzzles**: 550+ (10+ per level)
- **Games**: 100-150 (variety of types)
- **Bosses**: 13 campaign bosses

**Example Campaign**:
```
Campaign 1 - Fundamentals 1 (5 levels)
├── Level 1: Check vs. Checkmate
├── Level 2: Pawn Promotion
├── Level 3: Stopping Check 1 - Capture
├── Level 4: Stopping Check 2 - Block
├── Level 5: Stopping Check 3 - Move
└── Boss: Rook Guardian (400 ELO)
```

---

## Development Roadmap

### Completed (Phases 0-6.7)
- Foundation and content loading ✅
- Video lessons with progress tracking ✅
- Chess engine integration (chess package) ✅
- Interactive puzzles with multi-move support ✅
- Bot gameplay with Stockfish ✅
- Boss battles with unlock requirements ✅
- Custom positions, move restrictions, undo, move history ✅

### Current (Phase 7 - 5-6 weeks)
See [LAUNCH_PLAN.md](docs/LAUNCH_PLAN.md) for detailed timeline.

**Week 1**: Campaign system + unlocking logic
**Week 2**: Mobile builds + start content creation
**Week 3**: Complete all content (videos, puzzles, games)
**Week 4**: Analytics + polish
**Week 5**: QA testing + TestFlight/Internal Testing
**Week 6**: Chess club launch

### Post-Launch
See [BACKLOG.md](docs/BACKLOG.md) for prioritized features.

**Tier 1** (High Priority):
- Spaced repetition system
- Scrollable move history (post-game review)
- Goal-based games ("Castle by move 10")
- Timed puzzle rush
- Custom bot AI (beginner-like behavior)

**Tier 2+**: User accounts, parental dashboard, multiplayer, themes, monetization

---

## Documentation

- **[LAUNCH_PLAN.md](docs/LAUNCH_PLAN.md)** - Phase 7 detailed plan (temporary)
- **[CAMPAIGN_STRUCTURE.md](docs/CAMPAIGN_STRUCTURE.md)** - Content breakdown
- **[PROGRESS.md](docs/PROGRESS.md)** - Current status and roadmap
- **[BACKLOG.md](docs/BACKLOG.md)** - Post-launch features
- **[ARCHITECTURE.md](docs/ARCHITECTURE.md)** - Technical documentation
- **[CHANGELOG.md](docs/CHANGELOG.md)** - Development history
- **[chess_reference.md](docs/chess_reference.md)** - FEN/SAN notation guide for puzzle creation

---

## Development Tools

### Puzzle Creation Workflow (NEW!)

Create puzzles easily with our streamlined workflow:

```bash
cd tools
./create_puzzles.sh
```

**Interactive menu with three options:**
1. **Import from Lichess** - Find quality puzzles by theme/rating (10-15 min for 15 puzzles)
2. **Create Custom** - Build puzzles from scratch with drag-and-drop (2-3 min per puzzle)
3. **Convert Format** - Auto-convert to app format (instant)

**Quick Example:**
```bash
./create_puzzles.sh lichess    # Generate candidates
# → Review in browser UI
# → Select best puzzles
./create_puzzles.sh convert    # Auto-convert to app format
# → Move to assets/data/puzzles/
```

**Documentation:**
- **[tools/QUICK_START.md](tools/QUICK_START.md)** - 2-minute quick start
- **[tools/PUZZLE_WORKFLOW.md](tools/PUZZLE_WORKFLOW.md)** - Complete guide
- **[tools/README.md](tools/README.md)** - Tool overview

**Features:**
- ✅ Interactive Lichess database search (5.4M puzzles)
- ✅ Visual puzzle review with chessboard preview
- ✅ Drag-and-drop puzzle creator
- ✅ Auto-format conversion to app format
- ✅ Edit puzzles visually (FEN, moves, hints)
- ✅ Batch import/export

---

## Contributing

This is currently a private project in development for chess club testing. Contributions welcome after public launch.

### Development Workflow
1. Create feature branch from main
2. Follow existing code style and architecture patterns
3. Test thoroughly before merging
4. Update documentation as needed

---

## Testing

### Current Testing Strategy
- Manual testing on iOS Simulator and Android Emulator
- Physical device testing (iPad, Android tablets)
- Chess club pilot testing (Phase 7.7)

### Future Testing (Post-MVP)
- Unit tests for game logic
- Widget tests for UI components
- Integration tests for complete flows
- End-to-end tests for user journeys

---

## License

[Add license information]

---

## Contact

[Add contact information for bug reports and feedback]

---

## Acknowledgments

- Chess package by [@simolus3](https://github.com/simolus3/chess.dart)
- Stockfish chess engine
- Flutter and Dart communities
- Chess club students (alpha testers)

---

**Status**: Active Development - Phase 7 in progress
**Last Updated**: January 2025
