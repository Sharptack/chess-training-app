#!/bin/bash
# Quick script to open review UI with instructions

echo "📂 Opening puzzle review UI..."
open ../puzzle_reviewer/review_ui.html

echo ""
echo "✨ Review UI opened in your browser!"
echo ""
echo "📍 To load puzzles:"
echo "   1. Click 'Choose File'"
echo "   2. Navigate to: $(pwd)/output/"
echo "   3. Select a level_XXXX_candidates.json file"
echo ""
echo "💡 Full path to output folder:"
echo "   $(pwd)/output/"
echo ""
echo "🎯 Goal: Select 15 puzzles, then export!"
