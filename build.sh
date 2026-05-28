#!/bin/bash
set -e

echo ""
echo "  ⬡  MACRO — app builder"
echo "  ──────────────────────"
echo ""

# 1. Make sure we're in the right folder
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "  [1/4] Installing dependencies..."
pip3 install py2app pyobjc-framework-Quartz pynput customtkinter --quiet

echo "  [2/4] Building icon.icns from iconset..."
iconutil -c icns icon.iconset -o icon.icns

echo "  [3/4] Building .app bundle..."
python3 setup.py py2app --quiet 2>&1 | grep -v "^$" || true

echo "  [4/4] Done!"
echo ""

APP_PATH="$SCRIPT_DIR/dist/MACRO.app"

if [ -d "$APP_PATH" ]; then
    echo "  ✓  Built: dist/MACRO.app"
    echo ""
    echo "  To install: drag dist/MACRO.app into /Applications"
    echo ""
    echo "  ⚠  First launch: macOS may block it."
    echo "     Go to System Settings → Privacy & Security → click 'Open Anyway'"
    echo "     Also grant Accessibility access when prompted (needed for keypresses)"
    echo ""
    # Optionally open the dist folder
    open "$SCRIPT_DIR/dist"
else
    echo "  ✗  Build failed — check output above"
    exit 1
fi
