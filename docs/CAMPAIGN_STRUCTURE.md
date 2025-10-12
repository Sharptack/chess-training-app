# Chess Training App - Campaign & Level Structure

Complete breakdown of all 14 campaigns and 55 levels planned for initial launch.

---

## Overview

- **Total Campaigns**: 14 (13 active, 1 reserved for future)
- **Total Levels**: 55
- **Structure**: Fundamentals (18 levels) + Beginner 1 (37 levels)

---

## Fundamentals (Campaigns 1-4, 18 levels)

### Campaign 1 - Fundamentals 1 (5 levels)
1. Check vs. Checkmate
2. Pawn Promotion
3. Stopping Check 1 – Capture
4. Stopping Check 2 – Block
5. Stopping Check 3 – Move

**Boss**: Rook Guardian (400 ELO)

---

### Campaign 2 - Fundamentals 2 (5 levels)
6. Checkmate in 1 with Queen
7. Bishop Practice
8. Checkmate in 1 with Queen (Part 2)
9. Knight Practice
10. Checkmate in 1 with Rook

**Boss**: Knight Defender (500 ELO)

---

### Campaign 3 - Fundamentals 3 (5 levels)
11. Basic Opening Principles
12. Rook Practice
13. Two Rooks Ladder Mate
14. Pause Before Each Move and "En Prise"
15. Review a Beginner Game / Play a Game

**Boss**: Opening Master (600 ELO)

---

### Campaign 4 - Fundamentals 4 (3 levels)
16. Castling
17. Point System
18. King and Queen Checkmate

**Boss**: Endgame Specialist (700 ELO)

---

## Beginner 1 (Campaigns 5-13, 37 levels)

### Campaign 5 (4 levels)
19. Italian
20. Counting Defenders
21. Making Trades
22. Review a Beginner Game

**Boss**: Italian Master (800 ELO)

---

### Campaign 6 (6 levels)
23. Scholar's Mate
24. It's OK to Attack
25. Play 10 Games from That Position
26. Review a Game
27. Back Rank Mate
28. Defending Scholar's Mate

**Boss**: Scholar's Nemesis (900 ELO)

---

### Campaign 7 (4 levels)
29. Knight Fork
30. Fried Liver
31. Forks on c7/c2
32. Play a Live Game or Two

**Boss**: Fork Master (950 ELO)

---

### Campaign 8 (4 levels)
33. Pins
34. Ruy Lopez
35. Remove the Defender
36. Passed Pawns

**Boss**: Lopez Grandmaster (1000 ELO)

---

### Campaign 9 (4 levels)
37. Ruy Lopez (Part 2)
38. Discovered Attack
39. King and Rook Mate
40. Play a Live Game

**Boss**: Discovery King (1050 ELO)

---

### Campaign 10 (4 levels)
41. King and Two Pawns vs. King
42. Play a Live Game
43. Skewers
44. King and Bishop vs. King

**Boss**: Endgame Tactician (1100 ELO)

---

### Campaign 11 (4 levels)
45. Battery Checkmates
46. Pawn Double Attacks
47. King and Pawn vs. King
48. Game Reviews

**Boss**: Battery Commander (1150 ELO)

---

### Campaign 12 - Defense (4 levels)
49. Kick the Knight
50. Luft
51. Defending Batteries
52. Stopping Passed Pawns

**Boss**: Defensive Wall (1200 ELO)

---

### Campaign 13 (4 levels)
53. Activate the Knight
54. Activate the Bishop
55. Open Files
56. Review / Play

**Boss**: Activation Expert (1250 ELO)

---

### Campaign 14 (Reserved)
*Reserved for future expansion*

---

## Level Structure

Each level contains:
- **1 Video Lesson** (5-10 minutes)
- **10-15 Puzzles** (themed to lesson topic)
- **1-5 Games** (variety of types)

### Game Types

1. **Full Game** (60%)
   - Play complete game against bot
   - Standard starting position
   - Win or play minimum moves to complete

2. **Endgame Practice** (20%)
   - Custom starting position (FEN)
   - Practice specific endgame scenarios
   - Examples: King+Rook vs King, pawn endgames

3. **Opening Practice** (20%)
   - Move restrictions for learning openings
   - Must play specific sequence
   - Examples: Italian opening, Ruy Lopez

### Example Level JSON

```json
{
  "id": "level_001",
  "title": "Check vs. Checkmate",
  "campaignId": "campaign_01",
  "video": {
    "id": "video_001",
    "title": "Understanding Check and Checkmate",
    "url": "assets/videos/level_001.mp4",
    "durationSeconds": 420
  },
  "puzzleSetId": "puzzle_set_001",
  "requiredPuzzlesForCompletion": 8,
  "games": [
    {
      "id": "game_001_01",
      "title": "Practice Against Beginner Bot",
      "type": "full_game",
      "botId": "bot_001",
      "completionsRequired": 1
    },
    {
      "id": "game_001_02",
      "title": "Checkmate Practice",
      "type": "endgame_practice",
      "startingFen": "8/8/8/8/8/2k5/2q5/2K5 w - - 0 1",
      "completionsRequired": 2
    }
  ]
}
```

---

## Campaign Structure

Each campaign contains:
- **Multiple levels** (3-6 levels per campaign)
- **1 Boss battle** (unlocks after all levels complete)
- **Unlock requirements** (all lessons, puzzles, games in campaign)

### Example Campaign JSON

```json
{
  "id": "campaign_01",
  "title": "Fundamentals 1",
  "description": "Master the basics: check, checkmate, and escaping danger",
  "levelIds": ["level_001", "level_002", "level_003", "level_004", "level_005"],
  "boss": {
    "id": "boss_campaign_01",
    "name": "Rook Guardian",
    "elo": 400,
    "engineSettings": {
      "skillLevel": -8,
      "randomBlunderChance": 0.7
    },
    "unlockRequirements": {
      "allLessonsMustBeComplete": true,
      "allPuzzlesMustBeComplete": true,
      "requiredGamesTotal": 15
    }
  }
}
```

---

## Difficulty Progression

### ELO Ranges
- **Levels 1-10**: 200-400 ELO
- **Levels 11-30**: 400-800 ELO
- **Levels 31-55**: 800-1400 ELO
- **Campaign Bosses**: +100-200 ELO above last level in campaign

### Puzzle Complexity
- **Levels 1-18** (Fundamentals): 1-2 move puzzles
- **Levels 19-40** (Beginner tactics): 2-4 moves
- **Levels 41-55** (Intermediate): 3-6 moves

### Games per Level
- **Early levels** (1-10): 1-2 games (focus on fundamentals)
- **Mid levels** (11-40): 2-3 games (building skills)
- **Later levels** (41-55): 2-4 games (variety and practice)

---

## Content Creation Checklist

### Per Level (55 total)
- [ ] Video script (5-10 bullet points)
- [ ] Video recording (5-10 minutes)
- [ ] 10-15 puzzles (themed to lesson)
- [ ] 1-5 games configured (JSON)
- [ ] Level JSON file created

### Per Campaign (13 total)
- [ ] Campaign JSON file created
- [ ] Boss configured (name, ELO, unlock requirements)
- [ ] All levels in campaign complete
- [ ] Campaign tested end-to-end

### Total Content
- [ ] 55 video lessons (~6 hours total)
- [ ] 550+ puzzles
- [ ] 100-150 games configured
- [ ] 13 bosses
- [ ] All JSON files created and validated

---

## Quick Links

- **[LAUNCH_PLAN.md](./LAUNCH_PLAN.md)** - Implementation timeline
- **[PROGRESS.md](./PROGRESS.md)** - Current status
- **[ARCHITECTURE.md](./ARCHITECTURE.md)** - Technical details
