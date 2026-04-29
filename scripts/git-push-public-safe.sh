#!/bin/bash
# scripts/git-push-public-safe.sh
# Safer version: Pushes only public content to the public repository
# Uses git worktree to avoid file deletion risks

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Preparing to push public content (SAFE MODE)...${NC}"

# Function to cleanup on exit
cleanup() {
    if [ -d "/tmp/sre-public-worktree" ]; then
        echo -e "${YELLOW}🧹 Cleaning up temporary worktree...${NC}"
        rm -rf "/tmp/sre-public-worktree"
        git worktree prune 2>/dev/null || true
    fi
}
trap cleanup EXIT

# Preflight checks
echo -e "${BLUE}🔍 Running preflight checks...${NC}"

# Ensure we're on main branch
current_branch=$(git branch --show-current)
if [ "$current_branch" != "main" ]; then
    echo -e "${RED}❌ ERROR: Must be on main branch to push to public. Currently on: $current_branch${NC}"
    exit 1
fi

# Check if there are uncommitted changes
if ! git diff-index --quiet HEAD --; then
    echo -e "${RED}❌ ERROR: You have uncommitted changes. Please commit or stash them first.${NC}"
    git status --porcelain
    exit 1
fi

# Check if public remote exists
if ! git remote | grep -q "^public$"; then
    echo -e "${RED}❌ ERROR: 'public' remote not found.${NC}"
    echo "Please add it with: git remote add public https://github.com/yourusername/sre-masterclass.git"
    exit 1
fi

# Check if public remote is accessible
echo -e "${BLUE}🌐 Checking public remote accessibility...${NC}"
if ! git ls-remote --heads public >/dev/null 2>&1; then
    echo -e "${RED}❌ ERROR: Cannot access public remote. Check your network connection and authentication.${NC}"
    exit 1
fi

# Show what will be pushed
echo -e "${BLUE}📋 Changes to be pushed:${NC}"
if git log --oneline public/main..HEAD | head -5; then
    echo ""
else
    echo -e "${YELLOW}⚠️  No new commits to push.${NC}"
fi

# Define private paths to exclude
PRIVATE_PATHS=(
    "course/"
    "docs/video_scripts/"
    "docs/content-production/"
    "docs/planning/"
)

# Create temporary worktree
echo -e "${BLUE}📦 Creating temporary worktree...${NC}"
TEMP_DIR="/tmp/sre-public-worktree"
git worktree add "$TEMP_DIR" HEAD

# Change to the temporary worktree
cd "$TEMP_DIR"

# Remove private directories
echo -e "${BLUE}🔒 Removing private content...${NC}"
for path in "${PRIVATE_PATHS[@]}"; do
    if [ -d "$path" ]; then
        echo -e "${YELLOW}   Removing: $path${NC}"
        rm -rf "$path"
    fi
done

# Check if there are any changes to commit
if [ -n "$(git status --porcelain)" ]; then
    # Add all changes (deletions of private content)
    git add -A
    git commit -m "Remove private content for public push (temporary commit)" --quiet
    
    # Push to public remote
    echo -e "${BLUE}⬆️  Pushing to public repository...${NC}"
    git push public HEAD:main --force-with-lease
else
    echo -e "${YELLOW}ℹ️  No private content found to remove.${NC}"
    echo -e "${BLUE}⬆️  Pushing to public repository...${NC}"
    git push public HEAD:main --force-with-lease
fi

# Return to original directory
cd - >/dev/null

echo -e "${GREEN}✅ Successfully pushed public content to public repository!${NC}"
echo ""
echo -e "${BLUE}📋 Summary:${NC}"
echo -e "${GREEN}   - Private content automatically filtered out${NC}"
echo -e "${GREEN}   - Public repository updated with latest changes${NC}"
echo -e "${GREEN}   - Local repository completely unchanged${NC}"
echo -e "${GREEN}   - No risk of file deletion in main repository${NC}"
