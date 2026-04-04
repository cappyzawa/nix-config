#!/bin/bash
# Template: Content Capture Workflow
# Purpose: Extract content from web pages (text, screenshots, PDF)
# Usage: ./capture-workflow.sh <url> [output-dir]

set -euo pipefail

TARGET_URL="${1:?Usage: $0 <url> [output-dir]}"
OUTPUT_DIR="${2:-.}"

echo "Capturing: $TARGET_URL"
mkdir -p "$OUTPUT_DIR"

# Optional: Load authentication state
# if [[ -f "./auth-state.json" ]]; then
#     echo "Loading authentication state..."
#     agent-browser state load "./auth-state.json"
# fi

# Navigate to target
agent-browser open "$TARGET_URL"
agent-browser wait --load networkidle

# Get metadata
TITLE=$(agent-browser get title)
URL=$(agent-browser get url)
echo "Title: $TITLE"
echo "URL: $URL"

# Capture full page screenshot
agent-browser screenshot --full "$OUTPUT_DIR/page-full.png"
echo "Saved: $OUTPUT_DIR/page-full.png"

# Get page structure with refs
agent-browser snapshot -i > "$OUTPUT_DIR/page-structure.txt"
echo "Saved: $OUTPUT_DIR/page-structure.txt"

# Extract all text content
agent-browser get text body > "$OUTPUT_DIR/page-text.txt"
echo "Saved: $OUTPUT_DIR/page-text.txt"

# Save as PDF
agent-browser pdf "$OUTPUT_DIR/page.pdf"
echo "Saved: $OUTPUT_DIR/page.pdf"

# Cleanup
agent-browser close

echo ""
echo "Capture complete:"
ls -la "$OUTPUT_DIR"
