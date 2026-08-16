#!/bin/bash

# sync-upstream.sh - Sync with upstream duckdb/duckdb-skills
# This script helps you keep your Vibe-compatible duckdb-skills fork
# updated with the latest changes from the original repository.
#
# Usage: ./sync-upstream.sh

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UPSTREAM="upstream"
UPSTREAM_REPO="https://github.com/duckdb/duckdb-skills.git"
BRANCH="main"

echo "=========================================="
echo "DuckDB Skills Sync Script for Vibe"
echo "=========================================="
echo ""
echo "Current directory: $REPO_DIR"
echo ""

# Step 1: Check if we're in the right directory
if [ ! -d "$REPO_DIR/.git" ]; then
    echo "ERROR: Not in a git repository. Please run from the repo root."
    exit 1
fi

# Step 2: Verify upstream is set up
if ! git remote | grep -q "$UPSTREAM"; then
    echo "Setting up upstream remote..."
    git remote add $UPSTREAM $UPSTREAM_REPO
    echo "✓ Upstream remote added: $UPSTREAM"
else
    echo "✓ Upstream remote exists: $(git remote get-url $UPSTREAM)"
fi

echo ""
echo "------------------------------------------"
echo "Step 1: Fetching latest from upstream..."
echo "------------------------------------------"
git fetch $UPSTREAM

# Step 3: Check if there are changes
LOCAL=$(git rev-parse @)
REMOTE=$(git rev-parse "$UPSTREAM/$BRANCH")
BASE=$(git merge-base @ "$UPSTREAM/$BRANCH" 2>/dev/null || echo "")

if [ "$LOCAL" = "$REMOTE" ]; then
    echo "✓ Your repo is already up to date with upstream!"
    echo ""
    echo "Nothing to sync."
    exit 0
elif [ -z "$BASE" ]; then
    # No common ancestor - fork was created fresh
    echo "⚠ No common history with upstream (fork was created fresh)."
    echo "  Will compare directly with upstream."
    echo "✓ Upstream has changes."
else
    echo "✓ Upstream has changes you don't have locally."
fi

echo ""
echo "------------------------------------------"
echo "Step 2: Checking for changes..."
echo "------------------------------------------"
echo ""
echo "Upstream commit: $(git log -1 --oneline $UPSTREAM/$BRANCH)"
echo "Local commit:   $(git log -1 --oneline @)"
echo ""

# Step 4: Show what will change
echo "Files changed in upstream:"
if [ -z "$BASE" ]; then
    # No common history - list all files in upstream skills
    echo "(Your fork was created fresh, so all upstream skills are 'new' for you)"
    git ls-tree -r --name-only "$UPSTREAM/$BRANCH" -- skills/ | sed 's/^/  new: /' || echo "  (Could not list files - check upstream branch)"
else
    git diff --name-status "$BASE".."$UPSTREAM/$BRANCH" -- skills/ || echo "  (Could not diff - check branches)"
fi

echo ""
echo "------------------------------------------"
echo "Step 3: Review and confirm"
echo "------------------------------------------"
echo ""
echo "This script will:"
echo "  1. Merge changes from upstream/$BRANCH"
echo "  2. Apply Vibe-specific modifications:"
echo "     - Replace .claude with .vibe in paths"
echo "     - Replace Claude with Vibe in descriptions"
echo "  3. Commit the changes"
echo ""
echo "WARNING: This will modify your local repository."
echo "         If you have uncommitted changes, they may be overwritten."
echo ""

read -p "Do you want to proceed with the sync? (y/n): " -n 1 -r
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "Sync cancelled."
    exit 0
fi

echo ""
echo "------------------------------------------"
echo "Step 4: Merging upstream changes..."
echo "------------------------------------------"

# Merge upstream changes
if [ -z "$BASE" ]; then
    # No common history - need to copy files manually
    echo "No common history detected. Copying files from upstream..."
    
    # Create a temp directory to check out upstream files
    TEMP_DIR=$(mktemp -d)
    git clone --depth 1 --branch $BRANCH $UPSTREAM_REPO $TEMP_DIR 2>/dev/null
    
    # Copy skills directory (overwrite existing files)
    if [ -d "$TEMP_DIR/skills" ]; then
        cp -rf $TEMP_DIR/skills/* skills/
        echo "✓ Copied skills from upstream"
    else
        echo "✗ Could not find skills directory in upstream"
    fi
    
    # Clean up
    rm -rf $TEMP_DIR
else
    # Normal merge
    git merge "$UPSTREAM/$BRANCH" --no-edit
    echo "✓ Merged upstream changes"
fi

echo ""

# Step 5: Apply Vibe-specific modifications
echo "------------------------------------------"
echo "Step 5: Applying Vibe-specific modifications"
echo "------------------------------------------"
echo ""

# List of files that need modification
FILES_TO_MODIFY=(
    "skills/read-memories/SKILL.md"
    "skills/convert-file/SKILL.md"
)

for file in "${FILES_TO_MODIFY[@]}"; do
    if [ -f "$file" ]; then
        echo "Modifying: $file"
        
        # Special handling for read-memories (full path replacement)
        if [[ "$file" == *"read-memories/SKILL.md"* ]]; then
            # Replace .claude/projects with .vibe/logs/session
            sed -i.bak 's#\.claude/projects#\.vibe/logs/session#g' "$file" && rm -f "$file.bak"
            sed -i.bak 's#/claude/projects#/vibe/logs/session#g' "$file" && rm -f "$file.bak"
        fi
        
        # General replacements for all files
        sed -i.bak 's#\.claude#\.vibe#g' "$file" && rm -f "$file.bak"
        sed -i.bak 's#/claude#/vibe#g' "$file" && rm -f "$file.bak"
        # Replace Claude Code with Vibe
        sed -i.bak 's#Claude Code#Vibe#g' "$file" && rm -f "$file.bak"
        sed -i.bak 's#Claude#Vibe#g' "$file" && rm -f "$file.bak"
        echo "  ✓ Applied modifications"
    else
        echo "  ! File not found: $file (may have been added/removed)"
    fi
done

echo ""
echo "------------------------------------------"
echo "Step 6: Review changes before committing"
echo "------------------------------------------"
git status
echo ""
git diff --stat

echo ""
echo "------------------------------------------"
echo "Step 7: Commit the sync"
echo "------------------------------------------"

read -p "Do you want to commit these changes? (y/n): " -n 1 -r
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "Changes not committed. You can review and commit manually."
    exit 0
fi

echo ""
Commit message="Merge upstream and apply Vibe modifications"
if [ -n "$(git log -1 --oneline $UPSTREAM/$BRANCH)" ]; then
    Commit message="Merge upstream ($UPSTREAM/$BRANCH) and apply Vibe modifications"
fi

git add -A
git commit -m "$Commit message"

echo ""
echo "✓ Changes committed"
echo ""
echo "------------------------------------------"
echo "Sync complete!"
echo "------------------------------------------"
echo ""
echo "To push to your fork:"
echo "  git push origin $BRANCH"
echo ""
