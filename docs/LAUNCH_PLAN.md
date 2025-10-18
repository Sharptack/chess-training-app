# Chess Training App - Launch Plan (Phase 7)

**Target**: Chess Club Testing Launch
**Timeline**: 5-6 weeks
**Phase**: 7 (continuing from Phase 6.7)
**Goal**: Deliver content-complete app ready for real-world testing

**Note**: This is a temporary working document. After Phase 7 completion, add summary to CHANGELOG.md and delete this file.

---

## Terminology: "Bot" vs "Game"

**User-Facing (UI/Docs)**: "Games" - What players experience
- "Select Your Game" (not "Select Your Bot")
- "Game completed"
- Game types: full_game, endgame_practice, opening_practice

**Code/Internal**: "Bot" - AI opponent configuration
- `Bot` model (keeps existing code structure)
- `BotRepository`, `bot_factory.dart`, etc.
- Bot represents the Stockfish/MockBot opponent

**Why Hybrid**: "Games" is conceptually accurate (full games, endgame practice, opening practice). "Bot" is technically accurate (AI opponent). This avoids large refactoring while keeping UI clear.

**Phase 7.1 Change**: Rename `bot_selector_page.dart` → `game_selector_page.dart` for UI consistency.

---

## Campaign & Level Structure

See **[CAMPAIGN_STRUCTURE.md](./CAMPAIGN_STRUCTURE.md)** for complete breakdown.

**Summary**:
- 14 campaigns (13 active + 1 reserved)
- 55 levels total
- Fundamentals (18 levels) + Beginner 1 (37 levels)
- Each level: 1 video + 10-15 puzzles + 1-5 games
- Bosses at campaign level (not level level)

---

## Phase 7.1: Campaign System Implementation ✅ COMPLETE
**Branch**: `main` (merged)
**Goal**: Restructure app for campaign-based progression
**Duration**: October 13, 2025 (1 day)

### Tasks - ALL COMPLETE ✅

**Campaign Model & Repository**:
- [x] Create Campaign model (id, title, description, levelIds, boss)
- [x] Create CampaignRepository for loading campaign JSON
- [x] Create 2 campaign JSON files (campaign_01, campaign_02) + 8 placeholder levels

**UI Updates**:
- [x] Build HomePage (home screen, features/home/)
  - Grid of campaigns with lock states
  - Shows campaign info and boss details
- [x] Build CampaignPage (campaign detail, features/campaign/)
  - Shows levels + campaign boss
- [x] Refactor level_page.dart to show 3 tiles (Lesson, Puzzles, Games)
  - Removed Boss tile from level page
  - Updated layout from 2x2 grid to 3-tile layout (1 top, 2 bottom)
  - Added "Level Progress" card showing completion status

**Level Model Updates**:
- [x] Remove `boss` field from Level model (boss now in Campaign)
- [x] Add `campaignId` field to Level model
- [x] Update Level JSON schema for new structure
- [x] Migrate existing level_0001.json and level_0002.json to new format

**Routing**:
- [x] Update app_router.dart: home → campaigns → campaign detail → levels
- [x] Add campaign detail route
- [x] Move boss route to campaign level (/campaign/:id/boss)

**Game Model & UI**:
- [x] Rename `bot_selector_page.dart` → `game_selector_page.dart`
- [x] Update UI text to use "Game" terminology
- [x] Fix PlayPage to filter bots by level.playBotIds
- **Note**: No separate Game model needed - Bot model serves this purpose

**Unlock Logic** (moved from Phase 7.2):
- [x] Implement level unlock logic (sequential unlocking)
- [x] Add `isLevelUnlockedProvider` to check if level is unlocked
- [x] First level always unlocked, others unlock after previous complete

**Bug Fixes**:
- [x] Fixed puzzle loading "invalid radix 10 number" error
- [x] Fixed game count mismatch between pages
- [x] Fixed level completion message (now says "Level complete!")
- [x] Added campaigns directory to pubspec.yaml assets

**Deliverable**: ✅ Campaign-based navigation working, levels display 3 components, unlock progression functional

---

## Phase 7.2: Campaign Unlocking ✅ COMPLETE
**Branch**: `phase-7.2-campaign-unlocking` (merged to main)
**Goal**: Complete campaign unlock system
**Duration**: October 14, 2025 (1 day)

### Tasks - ALL COMPLETE ✅

**Campaign Boss Progress Tracking**:
- [x] Add `markCampaignBossCompleted()` to ProgressRepository
- [x] Add `getCampaignBossProgress()` to ProgressRepository
- [x] Add `campaignBossProgressProvider` for campaign-level boss tracking
- [x] Update `markBossCompleted()` to use campaign-level tracking

**Campaign Unlock Logic**:
- [x] Add `isCampaignUnlockedProvider` (Campaign 1 always unlocked)
- [x] Campaign 2+ unlock after previous campaign boss defeated
- [x] Add `campaignLevelCompletionProvider` to track X/Y levels completed
- [x] Simplify `campaignBossUnlockRequirementsProvider` to show "X/Y levels complete"

**UI Updates**:
- [x] Update home_page to use real unlock logic
- [x] Add campaign progress display (X/Y levels) on campaign cards
- [x] Add lock overlay with "Complete [Previous Campaign]" message
- [x] Simplify boss unlock overlay to single requirement

**Deliverable**: ✅ Campaign unlock working, boss tracking at campaign level, simplified UI

---

## Phase 7.3: Mobile Responsiveness ✅ COMPLETE
**Branch**: `phase-7.3-mobile-responsiveness` (merged to main)
**Goal**: Ensure app works on phones and tablets (iOS & Android)
**Duration**: October 18, 2025 (1 day)

### Tasks - ALL COMPLETE ✅

**Responsive Utilities System**:
- [x] Created ResponsiveUtils class with breakpoint detection
- [x] Added device type helpers (isMobile, isTablet, isDesktop)
- [x] Implemented responsive value getters (padding, spacing, icon sizes)
- [x] Added BuildContext extensions for easy access
- [x] Breakpoints: Mobile (<600px), Tablet (600-900px), Desktop (>900px)

**UI Updates**:
- [x] HomePage: Responsive grid (1→2→3 columns) with dynamic spacing
- [x] CampaignPage: Responsive grid (2→3→4 columns)
- [x] LevelPage: Responsive tile heights based on screen size
- [x] GameView: Responsive padding, board sizing, icon sizes
- [x] PuzzlesPage: Replaced hardcoded heights with responsive values
- [x] CheckCheckmatePage: Responsive board sizing and button layout
- [x] LessonPage: Responsive padding, fixed text overflow issues

**Layout Fixes**:
- [x] Chess board scaling on small screens (LayoutBuilder with responsive padding)
- [x] Campaign/level grid responsive layouts (dynamic column counts)
- [x] Button/icon sizes scale with device type (14-56px range)
- [x] Text readability with proper wrapping (softWrap, maxLines, overflow)
- [x] Orientation: Supports all orientations (portrait and landscape)
- [x] Safe areas handled by Flutter framework

**Bug Fixes**:
- [x] Fixed lesson page text overflow (yellow/black stripes)
- [x] Fixed debug button overflow (Row → Wrap widget)
- [x] Fixed video loading case sensitivity (sample.mp4 → Sample.mp4)
- [x] Fixed invalid thumbnail reference (removed non-existent field)

**Testing Performed**:
- [x] Tablet emulator (Pixel Tablet) - portrait mode working
- [x] Phone emulator testing completed
- [x] Hot reload verification
- [x] Video playback verified
- [x] All layouts adapt correctly to screen size

**Deliverable**: ✅ App responsive on phones and tablets, all orientations supported, tested on emulators

**Note**: Platform build configuration and deployment tasks moved to Phase 7.7 (Distribution & Launch)

---

## Phase 7.4: Content Creation (Week 2-3, 10-14 days)
**Branch**: `phase-7.4-content-creation`
**Goal**: Create all 13 campaigns (55 levels)

See CAMPAIGN_STRUCTURE.md for detailed content breakdown.

### 7.4.1 Video Content (7-10 days)
**Target**: 55 video lessons (~6 hours total)

**Workflow**: Script → Record → Edit → Export → Add to assets

**Progress Tracking**:
- [ ] Campaigns 1-4 videos (18 videos)
- [ ] Campaigns 5-7 videos (14 videos)
- [ ] Campaigns 8-10 videos (12 videos)
- [ ] Campaigns 11-13 videos (12 videos)

### 7.4.2 Puzzle Creation (3-5 days)
**Target**: 550+ puzzles (10+ per level)

**Progress Tracking**:
- [ ] Levels 1-18 puzzles (180 puzzles, 1-2 moves)
- [ ] Levels 19-40 puzzles (220 puzzles, 2-4 moves)
- [ ] Levels 41-55 puzzles (150 puzzles, 3-6 moves)

### 7.4.3 Game Configuration (2-3 days)
**Target**: 100-150 games across 55 levels

**Progress Tracking**:
- [ ] Create 55 level JSON files
- [ ] Create 13 campaign JSON files
- [ ] Configure 100-150 games (60% full, 20% endgame, 20% opening)
- [ ] Configure 13 campaign bosses

### 7.4.4 Organization (1 day)
- [ ] Bulk file naming/organization
- [ ] Asset verification (all videos, puzzles, JSONs present)
- [ ] Optional: Python script for JSON generation

**Deliverable**: Content-complete app with 13 campaigns

---

## Phase 7.5: Analytics Foundation (Week 3-4, 3-4 days)
**Branch**: `phase-7.5-analytics`
**Goal**: Track key metrics for testing feedback

### Metrics to Track

**Engagement**:
- [ ] Parent sign-up rate / onboarding completion
- [ ] First-session length
- [ ] First 3-day retention
- [ ] DAU / WAU
- [ ] Session frequency per week
- [ ] Average session length (target: 20-40 min)

**Progress**:
- [ ] Lesson/puzzle/game completion rates
- [ ] Campaign progression funnel
- [ ] Boss battle win rate

**Drop-off**:
- [ ] Skip rate (video/puzzle/game)
- [ ] Where users quit
- [ ] Feature usage breakdown

**Qualitative**:
- [ ] Net Promoter Score (NPS)
- [ ] Feedback forms

### Tasks
- [ ] Create SessionData and LevelAnalytics models
- [ ] Extend ProgressRepository with analytics methods
- [ ] Implement background tracking
- [ ] Export analytics to JSON/CSV
- [ ] Optional: Dev-only dashboard

**Deliverable**: Silent analytics tracking, exportable data

---

## Phase 7.6: Polish & Testing (Week 4-5, 5-7 days)
**Branch**: `phase-7.6-polish`
**Goal**: Bug fixes, UX improvements, QA

### 7.6.1 Code Cleanup (1-2 days)
- [ ] Remove unused VideoPlayerView widget
- [ ] Remove debug prints
- [ ] Add dartdoc comments
- [ ] Run `flutter analyze`
- [ ] Format code

### 7.6.2 UX Polish (2-3 days)
- [ ] Improve loading states
- [ ] Add success animations
- [ ] Enhance error messages
- [ ] Add onboarding flow
- [ ] Settings page (sound toggle, progress export)

### 7.6.3 Performance Testing (1 day)
- [ ] Test older devices
- [ ] Check memory usage
- [ ] Optimize assets
- [ ] Test offline functionality

### 7.6.4 QA Testing (2-3 days)
- [ ] Complete Level 1 start-to-finish
- [ ] Verify Level 2 unlocks
- [ ] Complete Campaign 1
- [ ] Verify boss unlocks
- [ ] Defeat boss, verify Campaign 2 unlocks
- [ ] Test edge cases
- [ ] Test all 3 game types
- [ ] Verify analytics working

**Deliverable**: Stable, polished app ready for testing

---

## Phase 7.7: Distribution & Launch (Week 5-6, ongoing)
**Branch**: `phase-7.7-launch`
**Goal**: Deploy and begin chess club testing

### 7.7.1 Build Configuration & Deployment (2 days)

**iOS Setup**:
- [ ] Configure Bundle ID and app signing
- [ ] Set up provisioning profiles
- [ ] TestFlight setup for beta distribution
- [ ] Build and deploy iOS to TestFlight
- [ ] Test installation on iOS devices

**Android Setup**:
- [ ] Configure package name
- [ ] Generate signing keys
- [ ] Google Play Console Internal Testing track setup
- [ ] Build and deploy Android to Internal Testing
- [ ] Test installation on Android devices

**Documentation**:
- [ ] Document installation instructions for testers

### 7.7.2 Tester Onboarding (1 day)
- [ ] Create tester instructions
- [ ] Set up feedback collection
- [ ] Prepare chess club kickoff meeting

### 7.7.3 Launch & Monitor (Ongoing)
- [ ] Launch with 5-10 chess club students
- [ ] Monitor daily (crashes, feedback, analytics)
- [ ] Weekly check-ins
- [ ] Iterate on feedback

**Deliverable**: App in hands of users, feedback loop active

---

## Timeline Summary

| Week | Sub-Phase | Branch | Deliverable |
|------|-----------|--------|-------------|
| 1 | 7.1-7.2 | phase-7.1-campaign-system<br>phase-7.2-unlock-system | Campaign system + unlocking |
| 1-2 | 7.3 | phase-7.3-mobile-responsive | iOS/Android builds |
| 2-3 | 7.4 | phase-7.4-content-creation | All content complete |
| 3-4 | 7.5 | phase-7.5-analytics | Analytics tracking |
| 4-5 | 7.6 | phase-7.6-polish | QA complete |
| 5-6 | 7.7 | phase-7.7-launch | Testing begins |

---

## Success Metrics

**Quantitative**: 70%+ complete Campaign 1, 50%+ return after 3 days, <2% crash rate

**Qualitative**: "I want to play more", observable improvement, minimal confusion

**Key Questions**: Which levels too hard/easy? Preferred features? Drop-off points?

---

## Post-Launch Iteration

**Week 1-2 (Alpha)**: Fix critical bugs, adjust difficulty
**Week 3-4 (Beta)**: Expand to 20-30 testers, balance content
**Month 2**: Polish, implement feedback
**Month 3+**: App store prep, backlog features

---

## After Phase 7 Complete

1. **Add to CHANGELOG.md**: Phase 7 summary
2. **Delete this file**: No longer needed
3. **Work from BACKLOG.md**: Feature-based development
4. **New branch naming**: `feature/feature-name` (no more phases)

---

## Quick Reference

**Current Phase**: 7 (Launch Preparation)
**Previous**: Phase 6.7 (Play Enhancements) ✅
**Next**: Post-launch features

**Branch Pattern**: `phase-7.X-descriptive-name`

**Links**:
- [CAMPAIGN_STRUCTURE.md](./CAMPAIGN_STRUCTURE.md) - Full content breakdown
- [PROGRESS.md](./PROGRESS.md) - Current status
- [BACKLOG.md](./BACKLOG.md) - Post-launch features
- [CHANGELOG.md](./CHANGELOG.md) - Phases 0-6.7
- [ARCHITECTURE.md](./ARCHITECTURE.md) - Technical docs
