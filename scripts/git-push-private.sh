#!/bin/bash
# scripts/git-push-private.sh
# Pushes all content (including private) to the private repository

set -e

echo "🔐 Preparing to push all content to private repository..."

# Ensure we're on main branch
current_branch=$(git branch --show-current)
if [ "$current_branch" != "main" ]; then
    echo "❌ ERROR: Must be on main branch to push to private. Currently on: $current_branch"
    exit 1
fi

# Check if private remote exists
if ! git remote | grep -q "^private$"; then
    echo "❌ ERROR: 'private' remote not found."
    echo "Please add it with: git remote add private https://github.com/yourusername/sre-masterclass-private.git"
    exit 1
fi

# Push to private remote
echo "⬆️  Pushing all content to private repository..."
git push private main

echo "✅ Successfully pushed all content to private repository!"
echo ""
echo "📋 Summary:"
echo "   - All content (public + private) pushed to private repository"
echo "   - Private repository is now up to date"
echo "   - Course materials and planning documents included"
