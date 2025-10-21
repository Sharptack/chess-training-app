#!/bin/bash
# Test the puzzle converter with sample data

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ""
echo "🧪 Testing Puzzle Converter"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Create test data
TEST_INPUT="$SCRIPT_DIR/puzzle_reviewer/test_input.json"
TEST_OUTPUT="$SCRIPT_DIR/puzzle_reviewer/test_output.json"

cat > "$TEST_INPUT" << 'EOF'
[
  {
    "id": "puzzle_test001",
    "fen": "r1bqkbnr/pppp1ppp/2n5/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R w KQkq - 0 1",
    "moveSequence": ["f3e5", "c6e5", "d1h5"],
    "hint": "Attack the f7 pawn!",
    "rating": 800,
    "themes": ["fork", "attackingF2F7"],
    "popularity": 100,
    "lichess_url": "https://lichess.org/training/test001"
  },
  {
    "id": "puzzle_test002",
    "fen": "6k1/7p/8/5Q2/8/8/7R/6K1 b - - 0 1",
    "moveSequence": ["g8h8", "f5f8"],
    "hint": "Checkmate in one!",
    "rating": 650,
    "themes": ["mateIn1", "queenEndgame"],
    "popularity": 95,
    "lichess_url": "https://lichess.org/training/test002"
  }
]
EOF

echo "✅ Created test input with 2 puzzles"
echo ""
echo "📄 Test Input:"
cat "$TEST_INPUT"
echo ""
echo "───────────────────────────────────────────────────────────"
echo ""

# Run converter in non-interactive mode
cd "$SCRIPT_DIR/puzzle_reviewer"

echo "🔄 Running converter..."
python3 convert_puzzles.py \
  "$TEST_INPUT" \
  "test" \
  "Test Level" \
  "Test puzzles for validation" \
  "$TEST_OUTPUT"

echo ""
echo "───────────────────────────────────────────────────────────"
echo ""
echo "📄 Test Output:"
cat "$TEST_OUTPUT"
echo ""
echo "───────────────────────────────────────────────────────────"
echo ""

# Validate output
if [ -f "$TEST_OUTPUT" ]; then
    # Check if it's valid JSON
    if python3 -c "import json; json.load(open('$TEST_OUTPUT'))" 2>/dev/null; then
        echo "✅ Valid JSON output"

        # Check required fields
        has_level_id=$(python3 -c "import json; print('levelId' in json.load(open('$TEST_OUTPUT')))")
        has_puzzles=$(python3 -c "import json; print('puzzles' in json.load(open('$TEST_OUTPUT')))")

        if [ "$has_level_id" = "True" ] && [ "$has_puzzles" = "True" ]; then
            echo "✅ Has required fields (levelId, puzzles)"

            # Check puzzle structure
            puzzle_count=$(python3 -c "import json; print(len(json.load(open('$TEST_OUTPUT'))['puzzles']))")
            echo "✅ Converted $puzzle_count puzzles"

            # Check first puzzle has required fields
            first_puzzle_valid=$(python3 << 'PYTHON'
import json
data = json.load(open('test_output.json'))
puzzle = data['puzzles'][0]
required = ['id', 'title', 'subtitle', 'fen', 'toMove', 'themes', 'difficulty',
            'hints', 'successMessage', 'failureMessage', 'solutionMoves', 'solutionSequence']
print(all(field in puzzle for field in required))
PYTHON
)

            if [ "$first_puzzle_valid" = "True" ]; then
                echo "✅ Puzzle has all required fields"
                echo ""
                echo "🎉 ALL TESTS PASSED!"
                echo ""
                echo "📋 You can now use the converter with confidence:"
                echo "   ./create_puzzles.sh convert"
            else
                echo "❌ Puzzle missing required fields"
                exit 1
            fi
        else
            echo "❌ Missing levelId or puzzles field"
            exit 1
        fi
    else
        echo "❌ Invalid JSON output"
        exit 1
    fi
else
    echo "❌ Output file not created"
    exit 1
fi

# Cleanup
echo ""
echo "🧹 Cleaning up test files..."
rm -f "$TEST_INPUT" "$TEST_OUTPUT"
echo "✅ Done!"
echo ""
echo "═══════════════════════════════════════════════════════════"
