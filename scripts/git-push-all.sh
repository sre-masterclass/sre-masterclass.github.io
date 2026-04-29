#!/bin/bash
# scripts/git-push-all.sh
# Pushes to both private and public repositories

set -e

echo "🚀 Pushing to both private and public repositories..."
echo ""

# First push to private (includes everything)
echo "1️⃣  Pushing to private repository..."
bash scripts/git-push-private.sh

echo ""
echo "2️⃣  Pushing to public repository..."
bash scripts/git-push-public.sh

echo ""
echo "🎉 Successfully pushed to both repositories!"
echo ""
echo "📋 Final Summary:"
echo "   ✅ Private repository: Updated with all content"
echo "   ✅ Public repository: Updated with public content only"
echo "   🔒 Private content automatically filtered from public repo"
echo "   📦 Both repositories are now synchronized"
