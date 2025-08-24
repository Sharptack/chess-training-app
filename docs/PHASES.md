# Project Phases

This document tracks the development roadmap for the Chess Training App.  
Each phase builds on the previous one, with branches created per phase for clean history.

---

## Phase 0: Foundation ✅
Branch: `phase-0-foundation`  
Depends on: none  
Focus: Scaffold the app and core architecture.

- [x] Set up project with folder structure (`lib/features/...`, `lib/core/...`)
- [x] Add `theme.dart` + `constants.dart` for centralized styling
- [x] Navigation: basic Home → Level → Feature placeholders working  
**Testing:** Manual run, navigation sanity check

---

## Phase 0.5: Content Loading & Error Handling
Branch: `phase-0.5-content-loading`  
Depends on: Phase 0  
Focus: Make content external and resilient.

- [ ] Add JSON loading (levels, puzzles, videos)
- [ ] Build error/loading/empty state widgets (reusable)
- [ ] Simple CLI validation script (`tools/validate_content.dart`)  
**Testing:** Load mock JSON, verify error/empty states

---

## Phase 1: Level & Video Lessons
Branch: `phase-1-video-lessons`  
Depends on: Phase 0.5  
Focus: First interactive learning flow.

- [ ] Build `LevelPage` with `VideoLessonWidget` pulling from JSON
- [ ] Show progress tracking (`Progress` class, minimal: started, completed)  
**Testing:** Load video lesson, confirm progress saves

---

## Phase 2: Chessboard Core
Branch: `phase-2-chessboard-core`  
Depends on: Phase 1  
Focus: Build reusable chessboard widget.

- [ ] Implement chessboard with drag & drop (no rules yet)
- [ ] Make board reusable across puzzles, play, and analysis  
**Testing:** Manual drag/drop validation

---

## Phase 2.5: Chess Engine Integration Planning
Branch: `phase-2.5-engine-planning`  
Depends on: Phase 2  
Focus: Prepare for engine integration.

- [ ] Research & test integration with lightweight engine (Stockfish, Lichess cloud, or Dart port)
- [ ] Define the API we’ll call, but don’t wire it up fully yet  
**Testing:** None required (planning/research phase)

---

## Phase 3: Puzzles (basic)
Branch: `phase-3-puzzles-basic`  
Depends on: Phase 2.5  
Focus: First puzzle implementation.

- [ ] Load a few puzzles from JSON
- [ ] Allow moves, detect puzzle completion  
**Testing:** Solve a puzzle successfully; incorrect moves handled gracefully

---

## Phase 4: Minimal Bot (mock AI)
Branch: `phase-4-minimal-bot`  
Depends on: Phase 3  
Focus: Add practice partner with placeholder intelligence.

- [ ] Create a “dummy” bot with simple/random moves
- [ ] Add difficulty knobs (thinking time, blunder rate placeholders)  
**Testing:** Play against bot, confirm adjustable parameters work

---

## Phase 5: Real Bot (engine-backed)
Branch: `phase-5-real-bot`  
Depends on: Phase 4  
Focus: Engine-driven AI opponent.

- [ ] Hook bot into chess engine with adjustable difficulty (elo simulation, move strength, blunders)
- [ ] Progress → track attempts, accuracy  
**Testing:** Play sample games against engine; confirm accuracy tracking

---

## Phase 6: Unlock System
Branch: `phase-6-unlock-system`  
Depends on: Phase 5  
Focus: Add progression gating.

- [ ] Implement requirements: puzzles completed, accuracy thresholds, boss unlocked
- [ ] Gate Level 2 based on Level 1 completion  
**Testing:** Verify unlock conditions trigger properly

---

## Phase 7: Spaced Repetition (puzzles)
Branch: `phase-7-spaced-repetition`  
Depends on: Phase 6  
Focus: Memory-based puzzle scheduling.

- [ ] Schedule puzzles for review based on mistakes/accuracy
- [ ] Store `attemptsCount`, `avgAccuracy`, `commonMistakes` in progress  
**Testing:** Confirm review queue updates after puzzle attempts

---

## Phase 7.5: Basic Analytics
Branch: `phase-7.5-basic-analytics`  
Depends on: Phase 7  
Focus: Local event tracking.

- [ ] Add event tracking hooks (puzzle attempts, video completions, unlocks)
- [ ] Store locally; future upgrade to sync online  
**Testing:** Check local logs for accurate event tracking

---

## 🚀 Future List (Post-MVP / Parking Lot)

(Not yet scheduled, may shift order depending on needs)

- [ ] Performance/memory: lazy loading, caching, compression
- [ ] Offline-first polish: “sync later” state handling
- [ ] Content creation workflow: level editor, CMS integration
- [ ] Accessibility: high contrast, screen reader support, alt input
- [ ] Platform differences: chessboard scaling on tablets, iOS vs Android file handling
- [ ] Theming 2.0: multiple skins, custom piece sets
