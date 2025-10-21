#!/bin/bash
# Quick puzzle workflow launcher
# Usage: ./create_puzzles.sh [workflow]
#   workflow: lichess, custom, or convert

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

show_menu() {
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "  🎯 PUZZLE CREATION WORKFLOW"
    echo "═══════════════════════════════════════════════════════════"
    echo ""
    echo "Choose a workflow:"
    echo ""
    echo "  1) 📥 Import from Lichess Database"
    echo "     Generate puzzle candidates by theme/rating"
    echo ""
    echo "  2) 🎨 Create Custom Puzzles"
    echo "     Build puzzles from scratch with drag-and-drop"
    echo ""
    echo "  3) 🔄 Convert to App Format"
    echo "     Transform exported puzzles to final format"
    echo ""
    echo "  4) 📖 View Full Documentation"
    echo ""
    echo "  5) ❌ Exit"
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo ""
}

run_lichess_workflow() {
    echo ""
    echo "🚀 Starting Lichess Import Workflow..."
    echo ""

    cd "$SCRIPT_DIR/puzzle_importer"

    # Check if dependencies are installed
    if ! python3 -c "import pandas" 2>/dev/null; then
        echo "⚠️  Dependencies not installed. Installing now..."
        pip3 install -r requirements.txt
    fi

    # Run interactive importer
    python3 import_puzzles_interactive.py

    echo ""
    echo "📋 Next Steps:"
    echo "  1. Open review UI: cd puzzle_reviewer && open review_ui_with_editor.html"
    echo "  2. Load the generated candidates JSON from puzzle_importer/output/"
    echo "  3. Select your best puzzles and export"
    echo "  4. Run this script again and choose 'Convert to App Format'"
    echo ""
}

run_custom_workflow() {
    echo ""
    echo "🎨 Opening Puzzle Creator..."
    echo ""
    echo "💡 Tips:"
    echo "  - Build positions with drag-and-drop"
    echo "  - Import Lichess candidates to edit"
    echo "  - Export in 'App Format' or 'Simple Format'"
    echo ""

    cd "$SCRIPT_DIR/puzzle_reviewer"
    open puzzle_creator.html

    echo "✅ Puzzle creator opened in browser"
    echo ""
    echo "📋 After creating puzzles:"
    echo "  - Export Simple Format → run 'Convert to App Format' workflow"
    echo "  - OR Export App Format → move file to assets/data/puzzles/"
    echo ""
}

run_convert_workflow() {
    echo ""
    echo "🔄 Starting Conversion Workflow..."
    echo ""

    cd "$SCRIPT_DIR/puzzle_reviewer"

    python3 convert_puzzles.py

    echo ""
    echo "✅ Conversion complete!"
    echo ""
    echo "📋 Final Step:"
    echo "  Move the generated puzzle_set_XXXX.json to:"
    echo "  assets/data/puzzles/puzzle_set_XXXX.json"
    echo ""
}

view_docs() {
    echo ""
    echo "📖 Opening documentation..."
    echo ""

    if command -v mdcat &> /dev/null; then
        mdcat "$SCRIPT_DIR/PUZZLE_WORKFLOW.md"
    elif command -v bat &> /dev/null; then
        bat "$SCRIPT_DIR/PUZZLE_WORKFLOW.md"
    else
        cat "$SCRIPT_DIR/PUZZLE_WORKFLOW.md"
    fi

    echo ""
    echo "📄 Full documentation: $SCRIPT_DIR/PUZZLE_WORKFLOW.md"
    echo ""
}

# Handle command-line argument
if [ "$1" == "lichess" ]; then
    run_lichess_workflow
    exit 0
elif [ "$1" == "custom" ]; then
    run_custom_workflow
    exit 0
elif [ "$1" == "convert" ]; then
    run_convert_workflow
    exit 0
elif [ "$1" == "docs" ]; then
    view_docs
    exit 0
fi

# Interactive menu
while true; do
    show_menu
    read -p "Enter choice [1-5]: " choice

    case $choice in
        1)
            run_lichess_workflow
            ;;
        2)
            run_custom_workflow
            ;;
        3)
            run_convert_workflow
            ;;
        4)
            view_docs
            ;;
        5)
            echo ""
            echo "👋 Goodbye!"
            echo ""
            exit 0
            ;;
        *)
            echo "❌ Invalid choice. Please enter 1-5."
            ;;
    esac

    # Pause before showing menu again
    read -p "Press Enter to continue..."
done
