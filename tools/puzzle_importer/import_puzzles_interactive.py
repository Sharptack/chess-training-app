#!/usr/bin/env python3
"""
Interactive Puzzle Importer
----------------------------
Import puzzles from Lichess database with custom parameters.
No need to edit LEVEL_THEMES - just run and input your criteria!
"""

import pandas as pd
import json
from pathlib import Path

def get_user_input():
    """Get puzzle search parameters from user"""
    print("\n" + "="*60)
    print("🎯 INTERACTIVE PUZZLE IMPORTER")
    print("="*60)

    # Output name
    output_name = input("\n📁 Output filename (e.g., 'forks_800-1000'): ").strip()
    if not output_name:
        output_name = f"custom_{pd.Timestamp.now().strftime('%Y%m%d_%H%M%S')}"

    # Themes
    print("\n🎨 THEMES:")
    print("Common themes: mate, mateIn1, mateIn2, fork, pin, skewer, discoveredAttack,")
    print("              backRankMate, promotion, queenEndgame, rookEndgame, etc.")
    print("See: https://database.lichess.org/#puzzles")

    themes_input = input("\nEnter themes (space-separated): ").strip()
    themes = themes_input.split() if themes_input else ["mate"]

    # Rating range
    print("\n⭐ RATING RANGE:")
    print("Difficulty guide: 600-800 (beginner), 800-1200 (intermediate),")
    print("                  1200-1600 (advanced), 1600+ (expert)")

    min_rating = int(input("\nMinimum rating [600]: ").strip() or "600")
    max_rating = int(input("Maximum rating [800]: ").strip() or "800")

    # Max candidates
    max_candidates = int(input("\nMax puzzles to generate [50]: ").strip() or "50")

    # Require ALL themes or ANY theme?
    print("\n🔍 THEME MATCHING:")
    print("  1. ANY - Puzzle has at least one of the themes (more results)")
    print("  2. ALL - Puzzle has all the themes (fewer, more specific results)")
    match_mode = input("\nMatch mode (1=ANY, 2=ALL) [1]: ").strip() or "1"

    return {
        "output_name": output_name,
        "themes": themes,
        "rating_range": [min_rating, max_rating],
        "max_candidates": max_candidates,
        "match_all_themes": match_mode == "2"
    }

def filter_puzzles(df, config):
    """Filter puzzles based on user criteria"""
    print(f"\n🔎 Searching {len(df)} puzzles...")

    # Filter by rating
    min_rating, max_rating = config['rating_range']
    rating_mask = (df['Rating'] >= min_rating) & (df['Rating'] <= max_rating)

    # Filter by themes
    if config['match_all_themes']:
        # ALL themes must be present
        theme_mask = pd.Series([True] * len(df))
        for theme in config['themes']:
            theme_mask &= df['Themes'].str.contains(theme, na=False, regex=False)
    else:
        # ANY theme must be present
        theme_pattern = '|'.join(config['themes'])
        theme_mask = df['Themes'].str.contains(theme_pattern, na=False)

    # Combine filters
    candidates = df[theme_mask & rating_mask].copy()

    # Sort by popularity (best quality first)
    candidates = candidates.sort_values('Popularity', ascending=False)

    # Take top N
    candidates = candidates.head(config['max_candidates'])

    return candidates

def generate_hint(themes_str):
    """Generate a hint based on puzzle themes"""
    theme_hints = {
        "fork": "Look for a move that attacks two pieces at once",
        "pin": "Can you trap a piece against a more valuable one?",
        "skewer": "Attack the valuable piece to win the one behind it",
        "backRankMate": "The back rank looks vulnerable...",
        "mate": "You can checkmate in this position!",
        "mateIn1": "Checkmate in one move!",
        "mateIn2": "Checkmate in two moves!",
        "mateIn3": "Find the checkmate sequence!",
        "hangingPiece": "A piece is undefended...",
        "promotion": "Can you promote a pawn?",
        "exposedKing": "The enemy king is exposed!",
        "kingSafety": "Think about king safety",
        "defensiveMove": "How can you defend?",
        "discoveredAttack": "Move one piece to reveal another's attack",
        "doubleCheck": "Give check with two pieces at once!",
        "queenEndgame": "Use your queen effectively",
        "rookEndgame": "Rook power!",
        "bishopEndgame": "Control those diagonals",
        "knightEndgame": "Knights are tricky!",
        "sacrifice": "Sometimes you must give to receive",
        "attackingF2F7": "The f2/f7 square is weak",
        "attraction": "Lure the piece to a bad square",
        "deflection": "Move the defender away",
        "clearance": "Clear the path for your attack",
        "interference": "Block the defender's line",
    }

    themes = themes_str.split()
    for theme in themes:
        if theme in theme_hints:
            return theme_hints[theme]

    return "Find the best move"

def convert_to_format(puzzle_row):
    """Convert Lichess puzzle to export format"""
    moves = puzzle_row['Moves'].split()

    return {
        "id": f"puzzle_{puzzle_row['PuzzleId']}",
        "fen": puzzle_row['FEN'],
        "moveSequence": moves,
        "themes": puzzle_row['Themes'].split(),
        "rating": int(puzzle_row['Rating']),
        "popularity": int(puzzle_row['Popularity']),
        "lichess_url": f"https://lichess.org/training/{puzzle_row['PuzzleId']}",
        "hint": generate_hint(puzzle_row['Themes'])
    }

def main():
    # Check if database exists
    db_file = Path('lichess_db_puzzle.csv')
    if not db_file.exists():
        print("\n❌ ERROR: lichess_db_puzzle.csv not found!")
        print("Please download the Lichess puzzle database first.")
        print("See README.md for instructions.")
        return

    # Get user input
    config = get_user_input()

    # Load database
    print(f"\n📚 Loading Lichess puzzle database...")
    df = pd.read_csv('lichess_db_puzzle.csv')
    print(f"✅ Loaded {len(df):,} puzzles")

    # Filter puzzles
    candidates = filter_puzzles(df, config)

    print(f"\n📊 RESULTS:")
    print(f"  Found: {len(candidates)} puzzles")
    print(f"  Themes: {', '.join(config['themes'])}")
    print(f"  Rating: {config['rating_range'][0]}-{config['rating_range'][1]}")

    if len(candidates) == 0:
        print("\n⚠️  No puzzles found! Try:")
        print("  - Broadening theme list")
        print("  - Widening rating range")
        print("  - Using ANY match mode instead of ALL")
        return

    # Convert to format
    puzzles = [convert_to_format(row) for _, row in candidates.iterrows()]

    # Save to output
    output_dir = Path('output')
    output_dir.mkdir(exist_ok=True)

    output_file = output_dir / f"{config['output_name']}_candidates.json"
    with open(output_file, 'w') as f:
        json.dump(puzzles, f, indent=2)

    print(f"\n✅ Saved to: {output_file}")
    print("\n📋 NEXT STEPS:")
    print("  1. Open review_ui_with_editor.html in your browser")
    print("  2. Load the candidates file from output/")
    print("  3. Review, edit, and select your best puzzles")
    print("  4. Export selected puzzles")
    print("  5. Run convert_puzzles.py to create final puzzle set")
    print("\n" + "="*60)

if __name__ == '__main__':
    main()
