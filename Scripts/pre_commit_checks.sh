#!/bin/bash

# Run pre-commit checks manually
# This script runs the same checks as the git pre-commit hook
# Useful for testing changes before committing
#
# Usage:
#   ./Scripts/pre_commit_checks.sh                    # Check staged files (or modified if none staged)                                                        
#   ./Scripts/pre_commit_checks.sh <file>...          # Check specific files/directories                                                                       
#   ./Scripts/pre_commit_checks.sh --all              # Check all files (staged + unstaged + untracked)                                                           
#   ./Scripts/pre_commit_checks.sh --staged           # Check only staged files
#
# Note: Files don't need to be staged when passed as arguments

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOKS_DIR="$PROJECT_ROOT/.git/hooks"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 Running pre-commit checks manually...${NC}\n"

# Check if pre-commit hook exists
if [ ! -f "$HOOKS_DIR/pre-commit" ]; then
    echo -e "${RED}❌ Error: Pre-commit hook not found at $HOOKS_DIR/pre-commit${NC}"
    echo -e "${YELLOW}Run: ./Scripts/setup_git_hooks.sh${NC}"
    exit 1
fi

# Determine which files to check
if [ $# -eq 0 ]; then
    # No arguments - check staged files first, then modified files if none staged
    FILES_TO_CHECK=$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null || echo "")

    if [ -z "$FILES_TO_CHECK" ]; then
        # No staged files - check modified (unstaged) files
        FILES_TO_CHECK=$(git diff --name-only --diff-filter=ACM 2>/dev/null || echo "")
        
        if [ -z "$FILES_TO_CHECK" ]; then
            echo -e "${YELLOW}⚠️  No staged or modified files found.${NC}"
        echo -e "${BLUE}ℹ️  Usage:${NC}"
            echo -e "  ${BLUE}./Scripts/pre_commit_checks.sh${NC}              # Check staged files (or modified if none staged)"
            echo -e "  ${BLUE}./Scripts/pre_commit_checks.sh <file>...${NC}    # Check specific files/directories"
            echo -e "  ${BLUE}./Scripts/pre_commit_checks.sh --all${NC}         # Check all modified files (staged + unstaged)"
            echo -e "  ${BLUE}./Scripts/pre_commit_checks.sh --staged${NC}    # Check only staged files"
        exit 0
        else
            echo -e "${BLUE}ℹ️  No staged files found. Checking modified (unstaged) files instead...${NC}"
        fi
    fi
else
    # Arguments provided - check those files
    FILES_TO_CHECK=""
    
    # Handle special flags
    if [ "$1" = "--all" ]; then
        # Check all files (staged + unstaged + untracked)
        STAGED=$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null || echo "")
        UNSTAGED=$(git diff --name-only --diff-filter=ACM 2>/dev/null || echo "")
        UNTRACKED=$(git ls-files --others --exclude-standard 2>/dev/null | grep -E '\.(swift|rs|cpp|hpp|h|js|ts|json|yml|yaml|md)$' || echo "")
        FILES_TO_CHECK="$STAGED $UNSTAGED $UNTRACKED"
        echo -e "${BLUE}ℹ️  Checking all files (staged + unstaged + untracked)...${NC}"
    elif [ "$1" = "--staged" ]; then
        # Check only staged files
        FILES_TO_CHECK=$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null || echo "")
        if [ -z "$FILES_TO_CHECK" ]; then
            echo -e "${YELLOW}⚠️  No staged files found${NC}"
            exit 0
        fi
        echo -e "${BLUE}ℹ️  Checking only staged files...${NC}"
    else
        # Check specific files/directories provided as arguments
    for arg in "$@"; do
        if [ -f "$arg" ]; then
            FILES_TO_CHECK="$FILES_TO_CHECK $arg"
        elif [ -d "$arg" ]; then
            # If it's a directory, find all relevant files
            FILES_TO_CHECK="$FILES_TO_CHECK $(find "$arg" -type f \( -name "*.swift" -o -name "*.rs" -o -name "*.cpp" -o -name "*.hpp" -o -name "*.h" -o -name "*.js" -o -name "*.ts" -o -name "*.json" -o -name "*.yml" -o -name "*.yaml" -o -name "*.md" \) 2>/dev/null || true)"
        else
            echo -e "${YELLOW}⚠️  Warning: $arg is not a valid file or directory${NC}"
        fi
    done
    fi
    
    FILES_TO_CHECK=$(echo $FILES_TO_CHECK | tr ' ' '\n' | sort -u | tr '\n' ' ')
fi

if [ -z "$FILES_TO_CHECK" ]; then
    echo -e "${YELLOW}⚠️  No files to check${NC}"
    exit 0
fi

echo -e "${BLUE}Files to check:${NC}"
for file in $FILES_TO_CHECK; do
    if [ -f "$file" ]; then
        echo "  - $file"
    fi
done
echo ""

# Temporarily stage files if they're not already staged
ORIGINAL_STAGED=$(git diff --cached --name-only 2>/dev/null || echo "")
FILES_TO_STAGE=""
FILES_TO_UNSTAGE=""

for file in $FILES_TO_CHECK; do
    if [ -f "$file" ]; then
        # Check if file is already staged
        if echo "$ORIGINAL_STAGED" | grep -q "^$file$"; then
            # File is already staged, keep it staged
            continue
        else
            # File is not staged, stage it temporarily
            FILES_TO_STAGE="$FILES_TO_STAGE $file"
        fi
    fi
done

# Stage files temporarily
if [ -n "$FILES_TO_STAGE" ]; then
    echo -e "${BLUE}ℹ️  Temporarily staging files for checking...${NC}"
    git add $FILES_TO_STAGE 2>/dev/null || true
    RESTORE_STAGED=true
else
    RESTORE_STAGED=false
fi

# Run the pre-commit hook
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

if bash "$HOOKS_DIR/pre-commit"; then
    EXIT_CODE=0
else
    EXIT_CODE=$?
fi

# Restore original staging if we modified it
if [ "$RESTORE_STAGED" = "true" ]; then
    echo ""
    echo -e "${BLUE}ℹ️  Restoring original staging (unstaging temporarily staged files)...${NC}"
    echo -e "${BLUE}   Note: Your changes are NOT lost - they're just unstaged now.${NC}"
    git reset HEAD $FILES_TO_STAGE 2>/dev/null || true
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [ $EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}✅ All pre-commit checks passed!${NC}"
    echo -e "${GREEN}You can safely commit these changes.${NC}"
else
    echo -e "${RED}❌ Pre-commit checks failed${NC}"
    echo -e "${YELLOW}Please fix the issues before committing.${NC}"
fi

exit $EXIT_CODE

