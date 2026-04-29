#!/bin/bash
# scripts/git-push-public.sh
# Pushes only public content to the public repository

set -e

echo "🚀 Preparing to push public content..."

# Ensure we're on main branch
current_branch=$(git branch --show-current)
if [ "$current_branch" != "main" ]; then
    echo "❌ ERROR: Must be on main branch to push to public. Currently on: $current_branch"
    exit 1
fi

# Check if there are uncommitted changes
if ! git diff-index --quiet HEAD --; then
    echo "❌ ERROR: You have uncommitted changes. Please commit or stash them first."
    git status --porcelain
    exit 1
fi

# Check if public remote exists
if ! git remote | grep -q "^public$"; then
    echo "❌ ERROR: 'public' remote not found."
    echo "Please add it with: git remote add public https://github.com/yourusername/sre-masterclass.git"
    exit 1
fi

# Create temporary branch for public push
temp_branch="temp-public-push-$(date +%s)"
echo "📦 Creating temporary branch: $temp_branch"
git checkout -b "$temp_branch"

# Remove private directories from this branch
echo "🔒 Removing private content..."
PRIVATE_PATHS=(
    "course/"
    "docs/video_scripts/"
    "docs/content-production/"
    "docs/planning/"
)

for path in "${PRIVATE_PATHS[@]}"; do
    if [ -d "$path" ]; then
        echo "   Removing: $path"
        git rm -rf "$path" 2>/dev/null || true
    fi
done

# Check if there are any changes to commit
if git diff-index --quiet HEAD --; then
    echo "ℹ️  No private content found to remove."
else
    # Commit the removal (this commit only exists in temp branch)
    git commit -m "Remove private content for public push" --quiet
fi

# Push to public remote
echo "⬆️  Pushing to public repository..."
git push public "$temp_branch":main --force-with-lease

# Return to main branch and cleanup
echo "🧹 Cleaning up..."
git checkout main --quiet
git branch -D "$temp_branch" --quiet

echo "✅ Successfully pushed public content to public repository!"
echo ""
echo "📋 Summary:"
echo "   - Private content automatically filtered out"
echo "   - Public repository updated with latest changes"
echo "   - Local repository unchanged"
