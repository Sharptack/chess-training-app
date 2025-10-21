#!/usr/bin/env python3
"""
Puzzle Converter
----------------
Converts puzzles from review UI / puzzle creator format
to the final puzzle_set_XXXX.json format required by the app.
"""

import json
import sys
from pathlib import Path

def convert_puzzle_to_app_format(puzzle, puzzle_index):
    """
    Convert a puzzle from tool format to app format.

    Tool format:
    {
      "id": "puzzle_12345",
      "fen": "...",
      "moveSequence": ["e2e4", "e7e5"],
      "hint": "Find the fork!",
      "rating": 800,
      "themes": ["fork"]
    }

    App format:
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
      "failureMessage": "Not quite right. Try again!",
      "solutionMoves": ["e2e4"],
      "solutionSequence": [
        { "move": "e7e5", "isUserMove": false, "comment": "Opponent moves" },
        { "move": "e2e4", "isUserMove": true, "comment": "Fork!" }
      ]
    }
    """

    # Extract FEN to determine whose turn it is
    fen_parts = puzzle['fen'].split()
    to_move = "white" if fen_parts[1] == 'w' else "black"

    # Generate title based on themes
    themes = puzzle.get('themes', [])
    title = generate_title(themes)
    subtitle = generate_subtitle(themes, to_move)

    # Determine difficulty based on rating
    rating = puzzle.get('rating', 800)
    if rating < 900:
        difficulty = 1
    elif rating < 1200:
        difficulty = 2
    elif rating < 1500:
        difficulty = 3
    elif rating < 1800:
        difficulty = 4
    else:
        difficulty = 5

    # Build solution sequence (alternating user/opponent moves)
    move_sequence = puzzle.get('moveSequence', [])
    solution_sequence = build_solution_sequence(move_sequence, to_move, themes)

    # Extract user moves only for solutionMoves
    user_moves = [item['move'] for item in solution_sequence if item['isUserMove']]

    # Success/failure messages
    success_message = generate_success_message(themes)
    failure_message = "Not quite right. Try again!"

    return {
        "id": puzzle.get('id', f"puzzle_{puzzle_index:04d}"),
        "title": title,
        "subtitle": subtitle,
        "fen": puzzle['fen'],
        "toMove": to_move,
        "themes": themes,
        "difficulty": difficulty,
        "hints": [puzzle.get('hint', 'Find the best move')],
        "successMessage": success_message,
        "failureMessage": failure_message,
        "solutionMoves": user_moves,
        "solutionSequence": solution_sequence
    }

def build_solution_sequence(moves, starting_turn, themes):
    """
    Build solutionSequence with alternating user/opponent moves.

    Lichess puzzles start with the opponent's move, then user responds.
    """
    sequence = []
    is_user_move = False  # Opponent moves first in Lichess puzzles

    for i, move in enumerate(moves):
        comment = generate_move_comment(i, is_user_move, len(moves), themes)

        sequence.append({
            "move": move,
            "isUserMove": is_user_move,
            "comment": comment
        })

        # Alternate
        is_user_move = not is_user_move

    return sequence

def generate_move_comment(move_index, is_user_move, total_moves, themes):
    """Generate appropriate comment for a move"""
    # Last move (usually the winning move)
    if move_index == total_moves - 1:
        if 'mate' in themes or 'mateIn1' in themes or 'mateIn2' in themes:
            return "Checkmate!"
        elif 'fork' in themes:
            return "Fork! Winning material"
        elif 'pin' in themes:
            return "Pinned!"
        elif 'skewer' in themes:
            return "Skewer! The king must move"
        elif 'discoveredAttack' in themes:
            return "Discovered attack!"
        elif 'promotion' in themes:
            return "Promotion!"
        else:
            return "Winning move!"

    # Opponent moves
    if not is_user_move:
        if move_index == 0:
            return "Opponent's move"
        else:
            return "Opponent responds"

    # User intermediate moves
    return "Continue the sequence"

def generate_title(themes):
    """Generate title based on themes"""
    theme_titles = {
        'mateIn1': 'Checkmate in One',
        'mateIn2': 'Checkmate in Two',
        'mateIn3': 'Checkmate in Three',
        'mate': 'Checkmate',
        'fork': 'Fork',
        'pin': 'Pin',
        'skewer': 'Skewer',
        'discoveredAttack': 'Discovered Attack',
        'doubleCheck': 'Double Check',
        'promotion': 'Pawn Promotion',
        'backRankMate': 'Back Rank Mate',
        'sacrifice': 'Sacrifice',
        'defensiveMove': 'Defensive Move',
        'escapingCheck': 'Escaping Check',
        'hangingPiece': 'Hanging Piece',
        'attraction': 'Attraction',
        'deflection': 'Deflection',
        'clearance': 'Clearance',
        'interference': 'Interference',
    }

    for theme in themes:
        if theme in theme_titles:
            return theme_titles[theme]

    return "Tactical Puzzle"

def generate_subtitle(themes, to_move):
    """Generate subtitle based on themes and who moves"""
    player = "White" if to_move == "white" else "Black"

    if 'mate' in themes or 'mateIn1' in themes or 'mateIn2' in themes or 'mateIn3' in themes:
        return f"Deliver checkmate for {player}"
    elif 'fork' in themes:
        return f"Win material with a fork"
    elif 'pin' in themes:
        return f"Pin the opponent's piece"
    elif 'skewer' in themes:
        return f"Skewer to win material"
    elif 'promotion' in themes:
        return f"Promote the pawn"
    elif 'defensiveMove' in themes or 'escapingCheck' in themes:
        return f"Get out of check"
    elif 'hangingPiece' in themes:
        return f"Capture the hanging piece"
    else:
        return f"Find the best move for {player}"

def generate_success_message(themes):
    """Generate success message based on themes"""
    if 'mate' in themes or 'mateIn1' in themes or 'mateIn2' in themes or 'mateIn3' in themes:
        return "Excellent! Checkmate!"
    elif 'fork' in themes:
        return "Great fork! Material won!"
    elif 'pin' in themes:
        return "Perfect pin!"
    elif 'promotion' in themes:
        return "Excellent promotion!"
    else:
        return "Success!"

def get_user_input():
    """Get puzzle set metadata from user"""
    print("\n" + "="*60)
    print("🔄 PUZZLE CONVERTER")
    print("="*60)

    # Input file
    print("\n📥 INPUT FILE:")
    input_file = input("Enter path to puzzles JSON (from review UI or creator): ").strip()

    if not input_file:
        print("❌ No file specified!")
        sys.exit(1)

    input_path = Path(input_file)
    if not input_path.exists():
        print(f"❌ File not found: {input_path}")
        sys.exit(1)

    # Level metadata
    print("\n📋 LEVEL METADATA:")
    level_id = input("Level ID (e.g., 0001, 0002): ").strip() or "0001"
    title = input("Level Title (e.g., 'Basic Tactics'): ").strip() or "Tactical Puzzles"
    description = input("Level Description: ").strip() or "Practice tactical patterns"

    # Output file
    print("\n📤 OUTPUT:")
    output_file = input(f"Output filename [puzzle_set_{level_id}.json]: ").strip()
    if not output_file:
        output_file = f"puzzle_set_{level_id}.json"

    return {
        "input_file": input_path,
        "level_id": level_id,
        "title": title,
        "description": description,
        "output_file": output_file
    }

def main():
    if len(sys.argv) > 1:
        # Command-line mode
        input_file = Path(sys.argv[1])
        if not input_file.exists():
            print(f"❌ File not found: {input_file}")
            sys.exit(1)

        level_id = sys.argv[2] if len(sys.argv) > 2 else "0001"
        title = sys.argv[3] if len(sys.argv) > 3 else "Tactical Puzzles"
        description = sys.argv[4] if len(sys.argv) > 4 else "Practice tactical patterns"
        output_file = sys.argv[5] if len(sys.argv) > 5 else f"puzzle_set_{level_id}.json"

        config = {
            "input_file": input_file,
            "level_id": level_id,
            "title": title,
            "description": description,
            "output_file": output_file
        }
    else:
        # Interactive mode
        config = get_user_input()

    # Load puzzles
    print(f"\n📖 Loading puzzles from {config['input_file']}...")
    with open(config['input_file'], 'r') as f:
        puzzles = json.load(f)

    print(f"✅ Loaded {len(puzzles)} puzzles")

    # Convert each puzzle
    print("\n🔄 Converting puzzles to app format...")
    converted_puzzles = []
    for i, puzzle in enumerate(puzzles, 1):
        try:
            converted = convert_puzzle_to_app_format(puzzle, i)
            converted_puzzles.append(converted)
        except Exception as e:
            print(f"⚠️  Error converting puzzle {i}: {e}")
            print(f"   Puzzle data: {puzzle}")
            continue

    # Build final puzzle set
    puzzle_set = {
        "levelId": config['level_id'],
        "title": config['title'],
        "description": config['description'],
        "puzzles": converted_puzzles
    }

    # Save
    output_path = Path(config['output_file'])
    with open(output_path, 'w') as f:
        json.dump(puzzle_set, f, indent=2)

    print(f"\n✅ SUCCESS!")
    print(f"   Converted: {len(converted_puzzles)} puzzles")
    print(f"   Saved to: {output_path}")

    # Show recommended next steps
    print("\n📋 NEXT STEPS:")
    print(f"   1. Review the output file: {output_path}")
    print(f"   2. Move to: assets/data/puzzles/puzzle_set_{config['level_id']}.json")
    print(f"   3. Test in the app!")
    print("\n" + "="*60)

if __name__ == '__main__':
    main()
