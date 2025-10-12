# Chess Training App - Feature Backlog

Post-launch features, enhancements, and ideas. Organized by priority tier based on user value and technical complexity.

**Last Updated**: After Phase 7 planning (Campaign restructure)

---

## 🔥 Tier 1: High Priority (Next 3-6 Months)

Features that directly improve core learning experience or address critical gaps.

### Spaced Repetition System
**Priority**: High | **Effort**: 2-3 weeks | **Status**: Deferred from Phase 7

**Description**:
Complete adaptive spaced repetition with SM-2 or FSRS algorithm for optimal memory retention. Currently basic puzzle progression exists; this adds intelligent review scheduling.

**Requirements**:
- Cumulative puzzle pools (Level 3 includes puzzles from L1-L3)
- Score threshold requirements (80%+ accuracy to pass level)
- Interval-based review scheduling (1, 3, 7, 14, 30 days)
- Session-based puzzle queue (10-15 puzzles per session)
- Progress toward threshold UI: "24/30 correct - 80%"

**Models Needed**:
- `PuzzleSchedule` - nextReviewDate, easeFactor, intervalDays
- Enhanced `PuzzlePerformance` with time-decay factors

**Challenges**:
- Potential frustration for struggling learners (never-ending review loops)
- Extensive playtesting needed for difficulty calibration
- Balance between challenge and engagement

**Why Deferred**: Needs real-world usage data to calibrate properly. Better to validate core experience first with chess club testing.

---

### Scrollable Move History (Post-Game Review)
**Priority**: High | **Effort**: 1 week | **Status**: Planned

**Description**:
After games finish (bot games, boss battles), allow users to click through move history and review the game move-by-move.

**Features**:
- Move navigator (prev/next buttons or slider)
- Display board position at any point in the game
- Highlight last move
- Optional: Show engine evaluation at each position
- Optional: Annotations for key moments ("Great move!", "Blunder")

**UI Components**:
- Move list (scrollable)
- Navigation controls
- Board view (read-only, no moves allowed)

**Technical**:
- Store complete game PGN in Hive after completion
- Use chess package to replay moves
- Update chess_board_widget to support read-only mode

---

### Goal-Based Games
**Priority**: High | **Effort**: 1-2 weeks | **Status**: Planned

**Description**:
Create games with specific objectives beyond just winning. Helps teach chess principles and strategy concepts.

**Example Goals**:
- "Castle your king by move 10"
- "Capture 3 pieces before move 15"
- "Control the center (e4, d4, e5, d5) by move 8"
- "Develop all minor pieces before move 12"
- "Achieve a checkmate using only Queen and Rook"

**Implementation**:
- Extend Bot model with `goal` field (type, description, criteria)
- Create GoalTracker service (evaluates position against goal)
- Show goal progress in UI (e.g., "2/3 pieces captured")
- Success = achieve goal AND complete game (win or draw)
- Failure = miss goal criteria (e.g., didn't castle by move 10)

**Content Opportunities**:
- Opening principles (development, castling, center control)
- Tactical themes (piece hunting, king safety)
- Endgame technique (mate with limited material)

---

### Timed Puzzle Rush
**Priority**: High | **Effort**: 1-2 weeks | **Status**: Planned

**Description**:
Speed-based puzzle challenge separate from main puzzle progression. Players solve as many puzzles as possible within a time limit.

**Features**:
- Time controls: 3 minutes, 5 minutes, 10 minutes
- Unlimited puzzles (pull from pool, randomized)
- Score = number of puzzles solved correctly
- Leaderboard (optional, post-MVP)
- Available as a level component OR separate game mode

**Key Differences from Main Puzzles**:
- **Main Puzzle Page**: All puzzles shown, no time limit, score threshold to pass (e.g., 8/10 correct)
- **Puzzle Rush**: Continuous stream, time pressure, high score tracking

**UI**:
- Timer countdown (prominent)
- Current streak indicator
- Quick feedback (green checkmark / red X)
- End screen with stats (puzzles solved, accuracy, time per puzzle)

**Design Question**: Should this be a separate mode (accessible from home) or integrated as a level component?
- **Separate Mode**: Always available, doesn't block progression
- **Level Component**: Tied to campaign, teaches speed tactics

---

### Custom Bot AI (Non-Stockfish)
**Priority**: High | **Effort**: 2-3 weeks | **Status**: Planned

**Description**:
Create bots that play more like beginner humans (not just weaker Stockfish). Stockfish even at low skill makes "random-looking" moves but they're still computer-like.

**Beginner-Like Bot Behaviors**:
- Blunders pieces randomly (not just miscalculated tactics)
- Focuses on attacking king (ignores quiet positional moves)
- Moves same piece repeatedly (beginner fixation)
- Ignores opponent's threats occasionally
- Prefers captures over development
- Hangs pieces in obvious ways

**Implementation Options**:
1. **Rules-Based Bot**: Weighted move selection (70% reasonable, 20% questionable, 10% blunder)
2. **Enhanced MockBot**: Extend existing mock_bot.dart with personality profiles
3. **Human Game Database**: Train on actual beginner games (more advanced)

**Personality Profiles**:
- "Aggressive Andy" (only looks for attacks, hangs pieces)
- "Timid Tina" (always retreats, never attacks)
- "Grabby Gary" (takes every free piece, walks into traps)

**Testing**: Playtest with chess club to confirm "feels human" vs "feels like broken computer"

---

### Cloud Video Storage Migration
**Priority**: Medium (High if bundle size exceeds 100MB) | **Effort**: 2-3 weeks | **Status**: Deferred

**Description**:
Move video lessons from bundled assets to cloud storage. Reduces app bundle size, enables faster content updates.

**When to Implement**:
- App bundle size exceeds 100MB (App Store warnings)
- Have 10+ hours of video content (currently planning 55 videos × 7 min avg = ~6 hours)
- Need frequent video updates without app releases
- Ready to invest in infrastructure (~$5-10/month)

**Recommended Solution**: Cloudflare R2
- **Cost**: $0.015/GB storage, **$0 egress fees** (vs AWS S3 $0.09/GB egress)
- Example: 5GB videos, 1000 users, 100 views each = $0.08/month (vs $120+/month on Firebase)

**Implementation Phases**:
1. **Basic Streaming** (2-3 days): Update VideoItem model with cloud URLs, network player already works
2. **Caching & Offline** (1 week): Download manager, flutter_cache_manager, storage management
3. **Production** (3-5 days): All videos migrated, CDN configured, analytics

**Fallback**: Keep first 10 videos bundled, rest on cloud (hybrid approach)

See Phase 7.3 notes in PROGRESS.md for detailed cost analysis.

---

## 🎯 Tier 2: Medium Priority (6-12 Months)

Features that enhance experience but aren't critical for core learning.

### User Accounts & Cloud Sync
**Priority**: Medium | **Effort**: 3-4 weeks

**Features**:
- User authentication (email/password, Google Sign-In, Apple Sign-In)
- Progress sync across devices
- Family accounts (parental controls, multiple kids)
- Cloud backup of puzzle attempts, game history
- Profile customization (avatar, username)

**Technical Stack**:
- Firebase Auth or Supabase
- Firestore for progress storage
- End-to-end encryption for sensitive data
- Offline-first with conflict resolution (keep current Hive, sync to cloud)

**Privacy Considerations**:
- COPPA compliance (parental consent for kids under 13)
- Minimal data collection (only chess progress)
- Opt-in analytics only
- Data deletion on request (GDPR)

**Why Medium Priority**: App works great offline-first. Only needed for multi-device users or if adding social features.

---

### Parental Dashboard & Controls
**Priority**: Medium | **Effort**: 2-3 weeks

**Features**:
- Progress overview for all kids under account
- Time spent per feature (lessons, puzzles, bots)
- Skill progression graphs (puzzle accuracy over time, bot ELO progression)
- Session time limits (30 min/day max)
- Content restrictions (disable specific campaigns, time controls)
- Weekly email reports ("Your child completed 3 levels this week")

**UI**:
- Separate parent login (PIN code)
- In-app dashboard with charts
- Export progress reports (PDF/CSV)

**Depends On**: User accounts system

---

### Advanced Analytics & Insights
**Priority**: Medium | **Effort**: 2 weeks

**Description**:
Beyond basic tracking (Phase 7.4), provide AI-driven insights and personalized recommendations.

**Insights Examples**:
- "Your child excels at tactical puzzles but struggles with endgames"
- "Ready for harder opponents - consider Campaign 5"
- "Puzzle accuracy improving: 60% → 78% over 2 weeks"
- "Most engaged with lessons (45% of time) vs play (30%)"

**Visualizations**:
- Skill progression graphs (ELO equivalent)
- Puzzle accuracy by theme (tactics, endgames, openings)
- Time spent heatmap (which days/times most active)
- Drop-off funnel (where users abandon campaigns)

**Implementation**:
- Extend Phase 7.4 analytics foundation
- Add aggregation and trend analysis
- Optional: Cloud analytics (Mixpanel, Amplitude) for cohort analysis

---

### Hint System Enhancement
**Priority**: Medium | **Effort**: 1 week

**Current**: Basic hint button shows one hint per puzzle

**Enhanced Features**:
- **Progressive hints**:
  1. "Look for a tactical theme" (e.g., "fork", "pin")
  2. "Focus on this piece" (highlight piece to move)
  3. "Move this piece here" (show exact move)
- **Hint cost system**: Limited hints per level (e.g., 5 hints per campaign)
- **Earn hints**: Unlock more by completing puzzles without hints
- **Visual indicators**: Highlight squares on board for stronger hints

**Gamification**: "Solve without hints = bonus star"

---

### Achievement & Badge System
**Priority**: Medium | **Effort**: 1-2 weeks

**Achievement Types**:
- **Milestone Badges**: Complete 5/10/20 levels, defeat 5 bosses
- **Skill Badges**: 100% puzzle accuracy in a level, defeat boss without losses
- **Consistency Badges**: 7-day streak, 30-day streak
- **Special Badges**: Speed demon (Puzzle Rush high score), tactical genius (10 puzzles in a row)

**Display**:
- Badge showcase on profile page
- Unlock animations (confetti, sound effects)
- Share achievements (export image or via social if implemented)
- Optional: Leaderboard integration (compare with friends)

**Psychology**: Positive reinforcement, encourages daily engagement

---

### Onboarding & Tutorial Flow
**Priority**: Medium (High for new users) | **Effort**: 1 week

**Features**:
- Interactive chess tutorial (how pieces move) - for absolute beginners
- App navigation tutorial (first launch walkthrough)
  - "This is the campaign screen"
  - "Tap a level to see lesson, puzzles, and play"
  - "Complete all levels to unlock the boss"
- First puzzle walkthrough (step-by-step guidance)
- First bot game tutorial with hints

**Implementation**:
- Overlay tutorial system (package: tutorial_coach_mark or custom)
- Skip option for experienced users
- Progress tracking (tutorialCompleted flag in Hive)
- Video explainers for each feature (reuse lesson video format)

**Why Important**: Reduces confusion for first-time users, especially if distributing beyond chess club

---

### Theme System 2.0
**Priority**: Low | **Effort**: 1-2 weeks

**Features**:
- Multiple board themes (wood, marble, neon, space)
- Custom piece sets (classic, 3D, cartoon, minimalist)
- Color schemes (blue/green/purple for accessibility)
- Kid-friendly themes (dinosaurs, robots, fantasy chess pieces)

**Implementation**:
- Theme configuration in Hive
- Asset bundles for each theme (SVGs for piece sets)
- Theme selector in settings page
- Preview before applying

**Why Low Priority**: Current theme is clean and functional. Nice-to-have but doesn't impact learning.

---

### Analysis Mode (Post-Game Review Enhanced)
**Priority**: Low | **Effort**: 2 weeks

**Features** (extends Tier 1 "Scrollable Move History"):
- Stockfish evaluation at each position (centipawn score)
- Identify blunders and mistakes (move annotations)
- Show best moves ("Engine suggests Nf6 instead")
- Practice positions from past games ("Try this position again")
- Export games to PGN format

**UI**:
- Evaluation bar (scrollable with moves)
- Move annotations (!, ?, !!, ??, etc.)
- Alternative move tree (what if you played differently?)

**Why Low Priority**: Advanced feature, most value for intermediate/advanced players

---

## 🌟 Tier 3: Low Priority (12+ Months / Nice-to-Have)

Features that are fun or expand reach but not core to learning experience.

### Multiplayer Mode
**Priority**: Low | **Effort**: 4-6 weeks

**Features**:
- **Local multiplayer**: Same device, pass-and-play
- **Online multiplayer**: Matchmaking, ELO-based pairing
- **Friend challenges**: Direct invites
- **Spectator mode**: Watch friends play live

**Technical Challenges**:
- Real-time synchronization (Firebase Realtime Database or WebSockets)
- Matchmaking algorithm (pair similar skill levels)
- Cheating prevention (time limits, move validation server-side)
- Chat moderation (kid-safe, profanity filter)

**Why Low Priority**: Core app is single-player learning. Multiplayer is social/competitive, not instructional. High complexity for uncertain value.

---

### Opening Trainer (Dedicated Mode)
**Priority**: Low | **Effort**: 2 weeks

**Features**:
- Learn specific openings (Italian Game, Spanish Opening, French Defense, etc.)
- Practice opening lines with move restrictions (already implemented in bot system!)
- Opening repertoire builder (save your favorite openings)
- Mistake correction (show correct response if wrong move)

**Content Needed**:
- Opening database (JSON or PGN with variations)
- Annotations and explanations per opening
- Progressive depth (main line → variations → traps)

**Why Low Priority**: Can already do this with custom bots + move restrictions. Dedicated mode is nicer UX but not essential.

---

### Endgame Trainer (Dedicated Mode)
**Priority**: Low | **Effort**: 2 weeks

**Features**:
- Classic endgames (King+Rook vs King, King+Queen vs King, pawn endgames)
- Practice technique (already supported with custom FEN!)
- Step-by-step guides with video lessons
- Endgame puzzles (separate from main puzzles)

**Content**:
- Tablebase integration (optional, advanced - 100% perfect play)
- Endgame lessons and videos
- Progressive difficulty (basic checkmates → pawn endgames → rook endgames)

**Why Low Priority**: Can already do this with custom FEN bots. Dedicated mode is polish.

---

### Content Creation Tools (Admin Panel)
**Priority**: Low (High for scaling content) | **Effort**: 3-4 weeks

**Features**:
- **Level editor**: Drag-and-drop campaign/level creator
- **Puzzle creator**: Set up position on board, define solution
- **Bot configurator**: Adjust ELO, settings, custom positions visually
- **Video uploader**: Cloud storage integration with metadata
- **Preview mode**: Test level before publishing

**Implementation**:
- Web-based editor (React/Vue + Firebase or standalone Flutter web)
- JSON export for campaigns/levels/puzzles
- Version control for content (track changes)

**Why Low Priority**: Can create content manually with JSON (current approach). Tools speed up process but not needed for 55 levels. Revisit if expanding to 100+ levels or enabling user-generated content.

---

### Curriculum Expansion
**Priority**: Ongoing | **Effort**: Continuous

**Current**: 55 levels planned (14 campaigns)
**Long-term Goal**: 100+ levels with deeper coverage

**Future Content Types**:
- Advanced tactics (sacrifices, combinations)
- Positional play (pawn structure, weak squares)
- Famous games analysis (Kasparov, Fischer, Carlsen)
- Tournament preparation (time management, psychology)

**Themes to Cover** (beyond current 14 campaigns):
- Intermediate strategy (campaigns 15-20)
- Advanced tactics (campaigns 21-25)
- Master-level endgames (campaigns 26-30)

---

### Daily Challenges
**Priority**: Low | **Effort**: 1-2 weeks

**Features**:
- New puzzle each day (Lichess Puzzle of the Day API)
- Streak tracking (consecutive days solved)
- Bonus rewards for streaks (unlock cosmetics, hints)
- Leaderboard for daily puzzle speed

**Depends On**: User accounts (for global leaderboard) or local-only streaks

---

### Seasonal Events
**Priority**: Very Low | **Effort**: 1 week per event

**Ideas**:
- Halloween themed puzzles (spooky board themes, special bosses)
- Christmas chess tournament (multi-player bracket)
- Summer puzzle challenge (50 puzzles in July, badge reward)
- Back-to-school boot camp (refresher course)

**Why Very Low**: Fun but requires ongoing content creation. Focus on core content first.

---

### Tablet Optimization (Enhanced)
**Priority**: Medium | **Effort**: 1 week

**Features**:
- Landscape mode layouts (side-by-side lesson + board)
- Larger chess pieces and buttons (accessibility)
- Split-screen support (lesson video + practice board)
- Keyboard shortcuts for navigation (iPad with keyboard)
- Stylus support (draw on board for teaching, annotation mode)

**Note**: Basic tablet support happening in Phase 7.2. This is enhanced/luxury tablet features.

---

### Multiple Language Support (i18n)
**Priority**: Low | **Effort**: 2-3 weeks + translation costs

**Languages**:
- Spanish (high priority - large chess community)
- French
- German
- Mandarin Chinese
- Hindi

**Implementation**:
- Flutter i18n package (intl or easy_localization)
- Localization files (JSON/ARB)
- Professional translation (not machine - chess terms need accuracy)
- RTL support for Arabic/Hebrew (future)

**Why Low Priority**: English-first for chess club testing. Expand after validating core experience.

---

## 🚀 Tier 4: Blue Sky Ideas (Far Future / Experimental)

Ambitious features that are exciting but highly complex or uncertain value.

### AI Chess Tutor (GPT-Powered)
**Priority**: Very Low | **Effort**: 3+ months

**Features**:
- GPT-powered move explanations ("That move was strong because...")
- Personalized learning paths ("You struggle with forks, let's practice")
- Natural language chess questions ("How do I defend against scholar's mate?")
- Game commentary in real-time ("Great pin! Now follow up with...")

**Challenges**:
- Requires cloud API (OpenAI, Anthropic) - cost per query
- Accuracy concerns (GPT can make chess mistakes)
- Latency (slow responses frustrate kids)
- Content moderation (ensure kid-safe responses)

**Why Very Low**: Bleeding edge, expensive, uncertain benefit vs current structured lessons

---

### VR/AR Chess
**Priority**: Very Low | **Effort**: 6+ months

**Features**:
- 3D chess board in AR (point phone at table, virtual pieces appear)
- VR chess battles (Oculus Quest, immersive experience)
- Life-size pieces (walk around board)
- Immersive chess worlds (medieval castle, space station)

**Why Very Low**: Requires VR/AR hardware (limits audience), massive development effort, unclear learning benefit

---

### Chess Camera (Physical Board Scanner)
**Priority**: Very Low | **Effort**: 2-3 months

**Features**:
- Point camera at physical chess board
- Recognize position using computer vision
- Import to app for analysis
- Play against bot from that position

**Use Case**: Kids playing on real board, want to check position or continue game in app

**Why Very Low**: Complex CV problem, limited use case (app is primary experience, not physical board)

---

## 🛠️ Technical Improvements (Non-Feature)

### Testing Infrastructure
**Priority**: High (before scaling) | **Effort**: 2-3 weeks

**Test Types**:
- **Unit Tests**: Chess logic, bot AI, puzzle validation, progress calculations
- **Widget Tests**: UI components, progress badges, chess board interactions
- **Integration Tests**: Full game flows, boss unlock, puzzle progression
- **End-to-End Tests**: Complete user journeys (Level 1 → Campaign 1 complete)

**Coverage Goal**: 70%+ for critical paths (game logic, progress tracking)

**Why Important**: Prevents regressions, speeds up development, enables confident refactoring

---

### CI/CD Pipeline
**Priority**: Medium | **Effort**: 1 week

**Pipeline Stages**:
1. **Lint & Format**: Flutter analyze, dart format
2. **Unit Tests**: Run all tests, coverage report
3. **Build**: iOS + Android builds (parallel)
4. **Deploy**: TestFlight / Internal Testing (automated)
5. **Release**: Staged rollout to App Store / Play Store

**Tools**:
- GitHub Actions (free tier sufficient for small project)
- Fastlane (automate iOS/Android deployment)
- Codemagic or Bitrise (Flutter-specific, paid)

**Why Medium**: Manual builds work fine for now. CI/CD speeds up iteration when releasing frequently.

---

### Error Tracking & Monitoring
**Priority**: High (for production) | **Effort**: 1 week

**Tools**:
- Sentry or Firebase Crashlytics (crash reports)
- ANR (Application Not Responding) detection
- Network error tracking
- Performance monitoring (slow page loads, memory leaks)

**Alerts**:
- Crash rate > 1% (critical)
- ANR rate > 0.5% (high)
- API failures (if using cloud)
- Slow page loads (>5s)

**Why High**: Essential once real users are testing. Can't fix bugs you don't know exist.

---

### Performance Optimizations
**Priority**: Medium | **Effort**: 1-2 weeks

**Optimizations**:
- Image caching for piece SVGs (preload on app start)
- Puzzle repository in-memory cache (avoid repeated JSON parsing)
- Stockfish process pooling (reuse engine instances)
- Lazy loading for heavy widgets
- Asset compression (reduce bundle size)
- Provider memoization (reduce unnecessary rebuilds)

**Metrics to Improve**:
- App load time <2 seconds (currently ~3s)
- Page transitions <300ms
- Memory usage <150MB
- Battery drain minimal

**Why Medium**: Performance is acceptable now. Optimize if analytics show issues on older devices.

---

## 📋 Monetization (Future Business Model)

### Freemium Model
**Priority**: Low (post-public launch) | **Effort**: 2 weeks

**Free Tier**:
- First 3 campaigns (15 levels)
- Daily puzzles (limited to 10/day)
- Basic bots (up to 800 ELO)

**Premium Features** ($4.99/month or $29.99/year):
- All 14+ campaigns unlocked
- Unlimited puzzles and puzzle rush
- Advanced bots (800-1600 ELO)
- Analysis mode (move review)
- Ad-free experience
- Priority support

**Implementation**:
- In-app purchases (RevenueCat or native StoreKit/Google Billing)
- Subscription management (cancellation, renewal)
- Trial period (7 days free)

**Why Low Priority**: Focus on quality product first. Monetize after validating with free users.

---

### Classroom/School Licensing (B2B)
**Priority**: Medium (B2B opportunity) | **Effort**: 3-4 weeks

**Features**:
- Bulk licenses for schools (discounted per-student pricing)
- Teacher dashboard (view all students' progress)
- Custom curriculum creation (teachers assign specific levels)
- Homework assignments (complete X puzzles by Friday)
- Class leaderboards (gamification for classroom)
- Progress reports (export for parent-teacher conferences)

**Pricing**: $20-50 per student/year (volume discounts)

**Market**: Chess clubs, after-school programs, homeschool co-ops

**Why Medium**: Good revenue potential, but requires sales/marketing effort. Consider after 1000+ users.

---

## 🔄 Maintenance & Ongoing Work

### Content Update System
**Priority**: Medium | **Effort**: 2 weeks

**Features**:
- Hot content updates (no app update required for new levels/puzzles)
- Version checking (fetch latest content on launch)
- Rollback mechanism (revert to previous content if bugs)
- A/B testing for content difficulty (test two versions, keep better one)

**Implementation**:
- Content served from Firebase Remote Config or custom API
- Background sync when Wi-Fi available
- Cache invalidation strategy
- Backward compatibility (old app versions still work)

**Why Medium**: Nice-to-have for frequent content updates. Manual app releases work fine initially.

---

### Help & Support System
**Priority**: Medium | **Effort**: 1 week

**Features**:
- In-app FAQ (common questions)
- Video tutorials (how to use each feature)
- Contact support form (email or in-app messaging)
- Bug report tool (screenshot + logs auto-attached)
- Community forum (moderated, optional)

**Why Medium**: Important for public launch, less critical for closed testing with chess club.

---

## 📊 Prioritization Framework

### High Priority = Next 3-6 Months
- Directly improves learning experience
- Addresses user pain points from testing
- High impact, reasonable effort
- Examples: Spaced repetition, move history, goal-based games

### Medium Priority = 6-12 Months
- Enhances experience but not critical
- Enables new use cases (multi-device, social)
- Moderate impact, moderate to high effort
- Examples: User accounts, parental dashboard, advanced analytics

### Low Priority = 12+ Months
- Nice-to-have polish or reach expansion
- Lower impact or uncertain value
- Requires validation before investing
- Examples: Multiplayer, themes, daily challenges

### Very Low / Blue Sky = Future / Experimental
- Ambitious, experimental, or niche
- High effort, uncertain ROI
- Cool ideas to revisit later
- Examples: AI tutor, VR chess, physical board scanner

---

## 🎯 How to Use This Backlog

1. **After chess club testing**: Review feedback, identify pain points
2. **Prioritize from Tier 1**: Pick features that address feedback
3. **Update priorities**: Move features up/down based on real user data
4. **Add new ideas**: Capture feature requests from users here
5. **Quarterly review**: Re-evaluate priorities every 3 months

---

## 📝 Feature Request Tracking

**GitHub Issues**: Use "enhancement" label for feature requests
**User Feedback**: Log requests in Google Sheet (link in progress tracker)
**Voting**: Consider Canny or similar tool for user-voted feature prioritization

---

## Quick Links

- **[LAUNCH_PLAN.md](./LAUNCH_PLAN.md)** - Detailed 5-6 week plan to chess club launch
- **[PROGRESS.md](./PROGRESS.md)** - Current status and roadmap
- **[ARCHITECTURE.md](./ARCHITECTURE.md)** - Technical structure
- **[CHANGELOG.md](./CHANGELOG.md)** - Development history
