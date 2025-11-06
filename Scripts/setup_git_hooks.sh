#!/bin/bash

# Setup script for git hooks
# Installs and configures git hooks for Audientia

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOKS_DIR="$PROJECT_ROOT/.git/hooks"

echo "🔧 Setting up git hooks for Audientia..."
echo ""

# Check if we're in a git repository
if [ ! -d "$PROJECT_ROOT/.git" ]; then
    echo "❌ Error: Not a git repository"
    exit 1
fi

# Make pre-commit hook executable
if [ -f "$HOOKS_DIR/pre-commit" ]; then
    chmod +x "$HOOKS_DIR/pre-commit"
    echo "✅ Pre-commit hook installed and made executable"
else
    echo "⚠️  Warning: Pre-commit hook not found at $HOOKS_DIR/pre-commit"
fi

# Check for required tools
echo ""
echo "📦 Checking for required tools..."

MISSING_TOOLS=()

# Swift tools
if ! command -v swiftlint &> /dev/null; then
    MISSING_TOOLS+=("swiftlint")
fi

if ! command -v swiftformat &> /dev/null; then
    MISSING_TOOLS+=("swiftformat")
fi

# Rust tools
if ! command -v rustfmt &> /dev/null; then
    MISSING_TOOLS+=("rustfmt")
fi

if ! command -v cargo &> /dev/null; then
    MISSING_TOOLS+=("cargo")
fi

# C++ tools
if ! command -v clang-format &> /dev/null; then
    MISSING_TOOLS+=("clang-format")
fi

# JavaScript tools (optional)
if ! command -v eslint &> /dev/null; then
    echo "ℹ️  ESLint not found (optional for JavaScript)"
fi

if ! command -v prettier &> /dev/null; then
    echo "ℹ️  Prettier not found (optional for JavaScript)"
fi

if [ ${#MISSING_TOOLS[@]} -gt 0 ]; then
    echo ""
    echo "⚠️  Missing tools:"
    for tool in "${MISSING_TOOLS[@]}"; do
        echo "  - $tool"
    done
    echo ""
    echo "Install with:"
    echo "  brew install swiftlint swiftformat llvm"
    echo "  # For Rust: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
else
    echo "✅ All required tools are installed"
fi

echo ""
echo "✨ Git hooks setup complete!"
echo ""
echo "The pre-commit hook will run automatically on 'git commit'"
echo "To bypass (not recommended): git commit --no-verify"
echo ""
echo "For more information, see: .git/hooks/README.md"

