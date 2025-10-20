# tools/puzzle_importer/import_puzzles.py
import pandas as pd
import json
import chess
from pathlib import Path

# Load your level themes mapping
LEVEL_THEMES = {
    "level_0010": {
        "title": "get out of check",
        "themes": ["mateIn1", "rookEndgame", "backRankMate"],
        "rating_range": [600, 800],
        "max_candidates": 50,
        "notes": "King is in check, find a way to move, block, or capture to get out of check"
    }
}

def filter_puzzles_for_level(df, level_id, level_config):
    """Get candidate puzzles for a level"""

    # Filter by themes
    theme_mask = df['Themes'].str.contains('|'.join(level_config['themes']), na=False)

    # Filter by rating
    min_rating, max_rating = level_config['rating_range']
    rating_mask = (df['Rating'] >= min_rating) & (df['Rating'] <= max_rating)

    # Combine filters
    candidates = df[theme_mask & rating_mask].copy()

    # Sort by popularity (high quality puzzles)
    candidates = candidates.sort_values('Popularity', ascending=False)

    # Take top N candidates
    candidates = candidates.head(level_config['max_candidates'])

    return candidates

def convert_to_your_format(puzzle_row):
    """Convert Lichess puzzle to your JSON format"""

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

def generate_hint(themes_str):
    """Generate a hint based on puzzle themes"""
    theme_hints = {
        "fork": "Look for a move that attacks two pieces at once",
        "pin": "Can you trap a piece against a more valuable one?",
        "backRankMate": "The back rank looks vulnerable...",
        "mate": "You can checkmate in this position!",
        "mateIn1": "Checkmate in one move!",
        "mateIn2": "Checkmate in two moves!",
        "hangingPiece": "A piece is undefended...",
        "promotion": "Can you promote a pawn?",
        "exposedKing": "The enemy king is exposed!",
        "kingSafety": "Think about king safety",
        "defensiveMove": "How can you defend?",
        "queenEndgame": "Use your queen effectively",
        "rookEndgame": "Rook power!",
        "bishopEndgame": "Control those diagonals",
        "knightEndgame": "Knights are tricky!",
    }

    themes = themes_str.split()
    for theme in themes:
        if theme in theme_hints:
            return theme_hints[theme]

    return "Find the best move"

def main():
    print("Loading Lichess puzzle database...")
    df = pd.read_csv('lichess_db_puzzle.csv')

    print(f"Loaded {len(df)} puzzles")

    output_dir = Path('output')
    output_dir.mkdir(exist_ok=True)

    for level_id, config in LEVEL_THEMES.items():
        print(f"\nProcessing {level_id}: {config['title']}...")

        candidates = filter_puzzles_for_level(df, level_id, config)

        print(f"  Found {len(candidates)} candidates")

        if len(candidates) == 0:
            print(f"  WARNING: No puzzles found for {level_id}!")
            continue

        # Convert to your format
        puzzles = [convert_to_your_format(row) for _, row in candidates.iterrows()]

        # Save to JSON
        output_file = output_dir / f"{level_id}_candidates.json"
        with open(output_file, 'w') as f:
            json.dump(puzzles, f, indent=2)

        print(f"  Saved to {output_file}")

    print("\n✅ Done! Review puzzles in the 'output' directory")
    print("Open review_ui.html in your browser to review and select puzzles")

if __name__ == '__main__':
    main()
