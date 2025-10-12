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

## Phase 7.1: Campaign System Implementation (Week 1, 3-4 days)
**Branch**: `phase-7.1-campaign-system`
**Goal**: Restructure app for campaign-based progression

### Tasks

**Campaign Model & Repository**:
- [ ] Create Campaign model (id, title, description, levelIds, boss)
- [ ] Create CampaignRepository for loading campaign JSON
- [ ] Create 13 campaign JSON files (see CAMPAIGN_STRUCTURE.md)

**UI Updates**:
- [ ] Build CampaignPage (new home screen)
  - Grid/list of campaigns
  - Show campaign progress (X/Y levels completed)
  - Lock campaigns until previous boss defeated
- [ ] Refactor level_page.dart to show 3 tiles (Lesson, Puzzles, Games)
  - Remove Boss tile from level page
  - Update layout from 2x2 grid to 3-tile layout
  - Keep unlock requirements progress display (show lesson/puzzles/games completion status for boss unlock visibility)

**Level Model Updates**:
- [ ] Remove `boss` field from Level model (boss now in Campaign)
- [ ] Add `games` array to Level model (replaces `play.botIds`)
- [ ] Update Level JSON schema for new structure
- [ ] Migrate existing level_0001.json and level_0002.json to new format

**Routing**:
- [ ] Update app_router.dart: home → campaigns → levels
- [ ] Add campaign detail route
- [ ] Update navigation throughout app

**Game Model & UI** (new):
- [ ] Create Game model (id, title, type, botId, startingFen, allowedMoves, completionsRequired)
- [ ] Rename `bot_selector_page.dart` → `game_selector_page.dart`
- [ ] Update UI text to use "Game" terminology (already mostly done)

**Note**: Keep existing `Bot` model and infrastructure. Game model references Bot via `botId`.

**Deliverable**: Campaign-based navigation working, levels display 3 components

---

## Phase 7.2: Unlocking System (Week 1, 2-3 days)
**Branch**: `phase-7.2-unlock-system`
**Goal**: Implement full unlock progression

### Unlock Logic

- Level 1 starts unlocked
- Each level unlocks after previous level completes
- Level completion = lesson viewed + puzzles passed + all games completed
- Campaign boss unlocks after all levels in campaign complete
- Next campaign unlocks after boss defeated

### Tasks

**ProgressRepository Updates**:
- [ ] Add `isLevelUnlocked(String levelId)` method
  - Checks if previous level complete
  - Level 1 always unlocked
- [ ] Add `isCampaignBossUnlocked(String campaignId)` method
  - Checks if all levels in campaign complete
- [ ] Add `isCampaignUnlocked(String campaignId)` method
  - Campaign 1 always unlocked
  - Others unlock after previous boss defeated

**Provider Updates**:
- [ ] Update unlock requirements provider for campaign-level bosses
- [ ] Calculate total game completions (sum across all games in level)
- [ ] Update level completion logic (lesson + puzzles + all games)

**UI Updates**:
- [ ] Add lock overlays to CampaignPage (locked campaigns)
- [ ] Add lock overlays to campaign detail view (locked levels)
- [ ] Update BossPage lock overlay for campaign-level bosses
- [ ] Show unlock requirements in UI

**Deliverable**: Full unlock progression working end-to-end

---

## Phase 7.3: Mobile Responsiveness (Week 1-2, 2-3 days)
**Branch**: `phase-7.3-mobile-responsive`
**Goal**: Ensure app works on phones and tablets (iOS & Android)

### Testing Matrix

**iOS Devices**:
- [ ] iPhone SE (smallest)
- [ ] iPhone 15 Pro Max
- [ ] iPad

**Android Devices**:
- [ ] Pixel 5
- [ ] Pixel 8 Pro
- [ ] Galaxy Tab

### Layout Fixes
- [ ] Chess board scaling on small screens
- [ ] Button sizes (minimum 48x48 touch targets)
- [ ] Text readability (font size adjustments)
- [ ] Campaign/level grid layouts
- [ ] Portrait mode optimization (lock to portrait for simplicity)
- [ ] Safe areas (iPhone notch, Android navigation bar)

### Platform Testing Setup
- [ ] iOS build configuration (Bundle ID, signing, provisioning)
- [ ] TestFlight setup for beta distribution
- [ ] Android build configuration (package name, signing keys)
- [ ] Google Play Console Internal Testing track setup
- [ ] Test deployment to TestFlight
- [ ] Test deployment to Internal Testing
- [ ] Document installation instructions for testers

**Deliverable**: Installable builds on both platforms, responsive UI

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

### 7.7.1 Deployment (1 day)
- [ ] Build and deploy iOS to TestFlight
- [ ] Build and deploy Android to Internal Testing
- [ ] Test installation on devices

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
