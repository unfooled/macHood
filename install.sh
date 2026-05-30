#!/bin/bash
set -e

echo ""
echo "⚡ MacHood — Dependency Installer"
echo "──────────────────────────────────"
echo ""

# Check Python3
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 not found."
    echo "   Install it from https://python.org and re-run this script."
    exit 1
fi

echo "✅ Python 3 found: $(python3 --version)"
echo ""
echo "📦 Installing required packages..."
echo ""

pip3 install pyobjc-framework-Quartz pynput

echo ""
echo "✅ All done! You can now run MacHood.app"
echo ""
