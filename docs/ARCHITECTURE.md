# Chess Training App Architecture

## Tech Stack

### Core Technologies
- **Framework**: Flutter 3.x
- **State Management**: Riverpod (StateNotifier + FutureProvider + StreamProvider)
- **Local Storage**: Hive (progress, attempts, settings)
- **Navigation**: go_router (nested routing, deep linking support)
- **Chess Engine**: chess package (production-grade rules)
- **AI Opponent**: Stockfish package (UCI protocol)

### Key Packages
- `video_player` + `chewie` - Video lesson playback
- `flutter_svg` - Chess piece rendering (SVG assets)
- `flutter_riverpod` - Reactive state management
- `hive` + `hive_flutter` - NoSQL local storage
- `go_router` - Declarative routing
- `chess` - Chess rules and notation
- `stockfish` - Chess AI engine

---

## Architecture Patterns

### 1. Feature-Based Organization
```
lib/
├── features/           # Feature modules
│   ├── campaign/       # Campaign selection (home)
│   ├── level/          # Level detail view
│   ├── lesson/
│   ├── puzzles/
│   ├── play/
│   └── boss/
├── core/              # Shared utilities
│   ├── widgets/       # Reusable UI components
│   ├── game_logic/    # Chess engine, bots
│   └── theme/         # Material 3 theming
├── data/              # Data layer
│   ├── models/        # Domain models
│   ├── repositories/  # Data access
│   └── sources/       # Data sources (assets, API future)
└── state/             # Global state (Riverpod providers)
```

### 2. Repository Pattern
**Purpose**: Separation of data access from business logic

**Flow**:
```
UI (Widget)
  ↓ ref.watch(provider)
Provider (Riverpod)
  ↓ calls
Repository
  ↓ reads from
Data Source (AssetSource / Hive)
```

**Example**:
```dart
// puzzles_page.dart watches provider
final puzzleSetAsync = ref.watch(puzzleSetProvider(levelId));

// Provider delegates to repository
final puzzleSetProvider = FutureProvider.family<PuzzleSet, String>((ref, levelId) {
  return ref.read(puzzleRepositoryProvider).getPuzzleSet(levelId);
});

// Repository handles data fetching
class PuzzleRepository {
  Future<PuzzleSet> getPuzzleSet(String levelId) async {
    final json = await _assetSource.loadJson('puzzles/puzzle_set_$levelId.json');
    return PuzzleSet.fromJson(json);
  }
}
```

### 3. Result<T> Pattern for Error Handling
**Purpose**: Type-safe error handling without exceptions

```dart
// Instead of throwing exceptions
Result<Level> result = await levelRepository.getLevel(levelId);

result.when(
  success: (level) => showLevel(level),
  failure: (failure) => showError(failure.message),
);
```

### 4. Provider-Based State Management
**Key Providers**:
- `campaignProvider` - FutureProvider.family for campaign data (Phase 7.1)
- `allCampaignsProvider` - FutureProvider for all campaigns (Phase 7.1)
- `levelProvider` - FutureProvider.family for level data
- `puzzleSetProvider` - FutureProvider.family for puzzle sets
- `lessonProgressProvider` - StateNotifierProvider for lesson progress
- `puzzleProgressProvider` - StateNotifierProvider for puzzle completion
- `playProgressProvider` - Computed provider for bot game progress
- `isLevelUnlockedProvider` - Computed provider for level unlock status (Phase 7.1)
- `bossUnlockRequirementsProvider` - Computed provider for boss unlock status
- `campaignBossUnlockRequirementsProvider` - Computed provider for campaign boss unlock (Phase 7.1)

**State Flow**:
```
User Action (makeMove)
  ↓
Update State (GameStateNotifier)
  ↓
Riverpod notifies listeners
  ↓
UI rebuilds (ref.watch detects change)
  ↓
Progress saved to Hive
  ↓
Provider invalidated
  ↓
UI reflects new state
```

---

## File Structure

### Core (`lib/core/`)

#### `core/constants.dart`
- `AppConstants` - App-wide configuration
- `GameConstants` - Chess game tuning (piece values, bot timing)
- `AssetPaths` - Centralized asset path management

#### `core/widgets/`
- `chess_board_widget.dart` - Interactive chessboard (drag & click)
- `piece_widget.dart` - Draggable chess piece rendering
- `game_view.dart` - Shared game UI (Play + Boss modes)
- `async_value_view.dart` - Loading/error state wrapper
- `progress_badge.dart` - ▶️/⏳/✅ indicators
- `locked_badge.dart` - Boss unlock overlay with checklist

#### `core/game_logic/`
- `chess_board_state.dart` - Chess engine adapter (wraps chess package)
- `chess_notation.dart` - Square/coordinate conversion utilities
- `game_state.dart` - Human vs Bot game management (ChangeNotifier)
- `bot_factory.dart` - Creates Stockfish or Mock bots
- `stockfish_bot.dart` - Stockfish UCI integration with fallback
- `mock_bot.dart` - Evaluation-based bot (5 difficulty levels)

#### `core/errors/`
- `failure.dart` - Domain failure types (ParseFailure, NotFoundFailure, etc.)

#### `core/utils/`
- `result.dart` - Result<T> type (Success | Failure)

#### `core/theme/`
- `app_theme.dart` - Material 3 light/dark themes

---

### Data Layer (`lib/data/`)

#### `data/models/`
Core domain models (all with `fromJson`/`toJson`):

- `campaign.dart` - Campaign configuration (levels, boss)
- `level.dart` - Level configuration (lesson, puzzles, games)
- `game.dart` - Game configuration (type, bot, FEN, restrictions)
- `video_item.dart` - Video lesson metadata
- `puzzle.dart` - Puzzle with FEN, solution moves, hints
- `puzzle_set.dart` - Collection of puzzles per level
- `bot.dart` - Bot configuration (ELO, engine settings, custom FEN)
- `boss.dart` - Boss configuration (same as Bot + unlock requirements)
- `progress.dart` - Generic progress (started/completed timestamps)
- `bot_progress.dart` - Bot-specific progress (games played/won)

**Model Highlights**:
- `Campaign` - Groups 3-6 levels with one boss at end
- `Campaign.boss` - Boss with unlock requirements (all levels must be complete)
- `Level.games` - Array of Game objects (replaces old botIds)
- `Game.type` - full_game, endgame_practice, opening_practice
- `Game.startingFen` - Custom starting position (endgame practice)
- `Game.allowedMoves` - Move restrictions (opening practice)
- `Bot.minMovesForCompletion` - Minimum moves to count toward progress
- `Bot.engineSettings` - Stockfish skill level, blunder chance, move time
- `Puzzle.moveSequence` - Multi-move tactical sequences

#### `data/repositories/`
Data access layer:

- `campaign_repository.dart` - Load campaign configurations (Phase 7.1)
- `level_repository.dart` - Load level configurations
- `puzzle_repository.dart` - Load puzzle sets
- `bot_repository.dart` - Load bot configurations
- `progress_repository.dart` - Persist/retrieve progress (Hive)

**Key Methods**:
```dart
// LevelRepository
Future<Result<Level>> getLevel(String levelId);

// PuzzleRepository
Future<Result<PuzzleSet>> getPuzzleSet(String levelId);

// ProgressRepository (Hive)
Future<void> markLessonCompleted(String levelId);
Future<void> markLevelPuzzlesCompleted(String levelId, String puzzleId);
Future<void> recordBotGameCompleted(String levelId, String botId, bool humanWon);
Future<void> markCampaignBossCompleted(String campaignId); // Phase 7.2
Future<Progress?> getCampaignBossProgress(String campaignId); // Phase 7.2
Future<Progress?> getProgress(String levelId, String itemId);
Future<BotProgress?> getBotProgress(String levelId, String botId);
```

#### `data/sources/local/`
- `asset_source.dart` - JSON file loading from assets

---

### Features (`lib/features/`)

#### `features/campaign/`
- `campaign_page.dart` - Campaign selection grid (home screen, Phase 7.1)
- `campaign_detail_page.dart` - Level selection within campaign (Phase 7.1)

#### `features/lesson/`
- `lesson_page.dart` - Video player with Chewie
- ~~`video_player_view.dart`~~ - Removed in Phase 7.6 (redundant with LessonPlayer)
- Progress tracking: 2s = started, 90% = completed
- 30-second timeout for network videos

#### `features/puzzles/`
- `puzzles_page.dart` - Interactive puzzle solving
- Multi-move sequences with computer responses
- Hint system, reset, auto-advance
- Progress tracking per puzzle
- Smart resume (starts at first incomplete)

#### `features/play/`
- `play_page.dart` - Game interface (full games, endgame, opening practice)
- `game_selector_page.dart` - Game selection (was bot_selector_page.dart, Phase 7.1)
- Resignation, undo, move history
- Progress: win OR loss with min moves played
- 3 game types: full_game, endgame_practice, opening_practice
- Custom FEN and move restrictions support

#### `features/boss/`
- `boss_page.dart` - Boss battle with intro screen
- Color selection (play as White/Black)
- Unlock requirements checklist overlay (campaign-level, Phase 7.2)
- One-win completion (marks boss defeated)
- Accessed from campaign page (not level page)

#### `features/level/`
- `level_page.dart` - 3-tile layout (Lesson, Puzzles, Games) - Phase 7.1 update
- Progress badges on each tile
- Boss moved to campaign level
- Unlock requirements progress display remains on level page (shows lesson/puzzles/games completion toward boss unlock)

---

### State Management (`lib/state/`)

#### `providers.dart`
All Riverpod providers in one file:

**Data Providers**:
- `campaignProvider` - FutureProvider.family<Campaign, String>
- `allCampaignsProvider` - FutureProvider<List<Campaign>>
- `levelProvider` - FutureProvider.family<Level, String>
- `puzzleSetProvider` - FutureProvider.family<PuzzleSet, String>
- `botsProvider` - FutureProvider<List<Bot>>

**Progress Providers**:
- `lessonProgressProvider` - Provider.family<Progress?, (String, String)>
- `puzzleProgressProvider` - Provider.family<Progress?, (String, String)>
- `playProgressProvider` - Provider.family<Progress?, String> (computed)
- `campaignBossProgressProvider` - Provider.family<Progress?, String> (Phase 7.2)
- `bossUnlockRequirementsProvider` - Provider.family<BossUnlockRequirements, String>
- `campaignBossUnlockRequirementsProvider` - Provider.family<BossUnlockRequirements, String> (Phase 7.2)
- `isCampaignUnlockedProvider` - Provider.family<bool, String> (Phase 7.2)
- `campaignLevelCompletionProvider` - Provider.family<(int, int), String> (Phase 7.2)

**Progress Functions** (invalidate providers after saving):
```dart
Future<void> markLessonCompleted(WidgetRef ref, String levelId);
Future<void> markLevelPuzzlesCompleted(WidgetRef ref, String levelId, String puzzleId);
Future<void> recordBotGameCompleted(WidgetRef ref, String levelId, String botId, bool humanWon);
Future<void> markBossCompleted(WidgetRef ref, String campaignId); // Updated Phase 7.2
```

**Game State Providers**:
- `gameStateNotifierProvider` - StateNotifierProvider<GameState>
- Used for Play and Boss modes

---

## Data Flow Examples

### 1. Video Lesson Completion
```
User watches video → 90% progress
  ↓
lesson_page.dart calls markLessonCompleted()
  ↓
Progress saved to Hive (timestamp)
  ↓
lessonProgressProvider invalidated
  ↓
level_page.dart rebuilds with ✅ badge
  ↓
bossUnlockRequirementsProvider recalculates
  ↓
Boss tile updates unlock checklist
```

### 2. Puzzle Completion
```
User solves puzzle correctly
  ↓
puzzles_page.dart increments completion counter
  ↓
Last puzzle → markLevelPuzzlesCompleted()
  ↓
Progress saved to Hive
  ↓
puzzleProgressProvider invalidated
  ↓
level_page.dart shows ✅ on puzzle tile
  ↓
bossUnlockRequirementsProvider updates
```

### 3. Bot Game Progress
```
Game ends (checkmate/stalemate)
  ↓
GameState sets gameCompletedNormally = true
  ↓
GameStateNotifier notifies listeners
  ↓
play_page.dart ref.listen detects change
  ↓
recordBotGameCompleted() called
  ↓
BotProgress updated in Hive (gamesPlayed++, gamesWon if human won)
  ↓
playProgressProvider invalidated
  ↓
level_page.dart + bot_selector_page.dart rebuild with updated counts
```

### 4. Boss Unlock Check
```
User completes lesson/puzzles/play
  ↓
Progress function invalidates bossUnlockRequirementsProvider
  ↓
Provider recalculates:
  - lesson.completed? ✅
  - puzzles.completed? (check puzzle count)
  - play.completed? (check total games vs required)
  ↓
Returns BossUnlockRequirements(isUnlocked: bool, checklist: [...])
  ↓
level_page.dart shows/hides locked overlay
  ↓
Boss tile clickable if unlocked
```

---

## Technical Decisions

### Why Riverpod over Bloc?
- Better async support (FutureProvider, StreamProvider)
- Provider.family for parameterized state
- Automatic disposal and caching
- Less boilerplate than Bloc events/states
- Compile-time safety

### Why Hive over SQLite?
- Simpler API for key-value storage
- No schema migrations needed
- Type-safe with adapters
- Perfect for progress tracking (no complex queries)
- Fast read/write for local data

### Why go_router?
- Type-safe navigation
- Deep linking support (future web/sharing)
- Nested routing (campaign → level → feature)
- Declarative route configuration
- Better than Navigator 1.0 imperative approach

### Why chess package?
- Battle-tested chess rules (10k+ pubs.dev points)
- Handles all edge cases (castling, en passant, promotion)
- FEN import/export
- Move validation and generation
- Saves weeks of chess logic development

### Why Stockfish package?
- Production-grade chess AI
- Adjustable difficulty (skill levels -20 to +20)
- UCI protocol support
- Cross-platform (Android, iOS, desktop)
- Free and open source

### Why JSON over database for content?
- Offline-first (no network required)
- Version controlled (Git tracks changes)
- Easy to edit (human-readable)
- Fast parsing with code generation
- No migration complexity

### Why feature-based structure?
- Scales better than layer-based (models/, views/, controllers/)
- Co-locates related code (easier to find)
- Clear module boundaries
- Easy to add new features without touching existing code
- Follows Flutter best practices

---

## Asset Management

### Directory Structure
```
assets/
├── data/
│   ├── levels/
│   │   ├── level_0001.json
│   │   ├── level_0002.json
│   │   └── ...
│   ├── puzzles/
│   │   ├── puzzle_set_0001.json
│   │   ├── puzzle_set_0002.json
│   │   └── ...
│   └── bots/
│       └── bots.json
└── images/
    └── pieces/
        ├── piece_white_pawn.svg
        ├── piece_black_queen.svg
        └── ...
```

### AssetPaths Helper (constants.dart)
```dart
class AssetPaths {
  // Chess pieces
  static String chessPiece(String color, String type) =>
    'assets/images/pieces/piece_${color}_${type}.svg';

  // Data files
  static String level(String levelId) => 'assets/data/levels/level_$levelId.json';
  static String puzzleSet(String levelId) => 'assets/data/puzzles/puzzle_set_$levelId.json';
  static const String botsConfig = 'assets/data/bots/bots.json';
}
```

---

## Performance Optimizations

### Current Optimizations
1. **FutureProvider caching** - Levels/puzzles cached automatically by Riverpod
2. **Lazy loading** - Features only load data when navigated to
3. **SVG caching** - flutter_svg caches rendered pieces
4. **Hive indexes** - Fast lookups for progress by (levelId, itemId)
5. **Stateless widgets** - Most UI widgets are stateless, rebuild efficiently
6. **Provider.family** - Separate state per level, no global rebuilds

### Future Optimizations (Post-MVP)
- Image caching for piece SVGs (preload on app start)
- Puzzle repository in-memory cache (avoid repeated JSON parsing)
- Stockfish process pooling (reuse engine instances)
- Video thumbnail generation (faster lesson previews)
- Asset compression (reduce app bundle size)

---

## Testing Strategy (Future)

### Unit Tests (Planned)
- Chess logic (game_state.dart, chess_board_state.dart)
- Bot move generation (mock_bot.dart, stockfish_bot.dart)
- Puzzle validation (solution matching)
- Progress calculations (playProgressProvider logic)

### Integration Tests (Planned)
- Full game flow (start → play → completion → progress saved)
- Boss unlock flow (complete requirements → unlock → defeat boss)
- Puzzle progression (Level 1 → Level 2 with shared puzzles)

### Widget Tests (Planned)
- Progress badges render correctly
- Locked overlay appears/disappears
- Move history displays properly

---

## Known Technical Debt

### High Priority (Address in Phase 7.5)
- Extract puzzle validation logic to service class (currently in puzzles_page.dart)
- Add dartdoc comments to public repository methods
- Split large widgets (puzzles_page.dart ~400 lines, level_page.dart ~300 lines)

### Medium Priority (Post-MVP)
- Hive migration strategy for schema changes
- GameState disposal race condition prevention
- Null safety consistency (some bang operators, fix with proper null checks)
- Provider memoization (avoid unnecessary rebuilds)

### Low Priority (Nice to Have)
- Unit tests for game logic
- Integration tests for core flows
- Dynamic Stockfish switching based on device performance
- Compression for JSON assets

---

## Security & Privacy

### Current Approach (Offline-First)
- **No network calls** - All data local
- **No user accounts** - No PII collected
- **No analytics** - No tracking (yet)
- **No external dependencies** - Self-contained app

### Future Considerations (Cloud Features)
- **If adding cloud sync**: End-to-end encryption for progress data
- **If adding analytics**: Anonymized, aggregated only, opt-in
- **If adding user accounts**: COPPA compliance (parental consent for kids)
- **Video hosting**: CDN with signed URLs (prevent hotlinking)

---

## Deployment Pipeline (Future)

### Current Workflow
1. Develop on feature branch
2. Test locally on iOS Simulator / Android Emulator
3. Merge to main when stable
4. Manual build and test on physical tablets

### Future CI/CD (Post-MVP)
1. **GitHub Actions**:
   - Run tests on PR
   - Build iOS/Android on merge
   - Deploy to TestFlight / Internal Testing
2. **Versioning**:
   - Semantic versioning (1.0.0, 1.1.0, etc.)
   - Git tags for releases
3. **App Store Submission**:
   - Automated screenshots (fastlane)
   - Metadata management
   - Staged rollout (10% → 50% → 100%)

---

## Quick Reference

### Adding a New Level
1. Create `assets/data/levels/level_XXXX.json`
2. Create `assets/data/puzzles/puzzle_set_XXXX.json`
3. Add video lesson to assets (or cloud storage)
4. Configure bots in `assets/data/bots/bots.json`
5. Define boss with unlock requirements in level JSON
6. Update campaign_page.dart to show new level tile

### Adding a New Feature
1. Create feature folder: `lib/features/my_feature/`
2. Add page: `my_feature/pages/my_feature_page.dart`
3. Add route to `lib/router/app_router.dart`
4. Create provider in `lib/state/providers.dart`
5. Add navigation from appropriate page
6. Update progress tracking if needed

### Modifying Chess Logic
- **Rules/validation**: Edit `lib/core/game_logic/chess_board_state.dart`
- **Bot AI**: Edit `lib/core/game_logic/mock_bot.dart` or `stockfish_bot.dart`
- **Game flow**: Edit `lib/core/game_logic/game_state.dart`
- **UI**: Edit `lib/core/widgets/chess_board_widget.dart`

---

## Resources

- [Flutter Docs](https://docs.flutter.dev/)
- [Riverpod Docs](https://riverpod.dev/)
- [Hive Docs](https://docs.hivedb.dev/)
- [chess package](https://pub.dev/packages/chess)
- [Stockfish UCI Protocol](https://www.chessprogramming.org/UCI)
- [Material 3 Design](https://m3.material.io/)
