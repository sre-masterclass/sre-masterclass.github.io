#!/bin/bash
# scripts/git-push-all-safe.sh
# Safer version: Pushes to both private and public repositories using safe methods

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Pushing to both private and public repositories (SAFE MODE)...${NC}"
echo ""

# First push to private (includes everything)
echo -e "${BLUE}1️⃣  Pushing to private repository...${NC}"
bash scripts/git-push-private.sh

echo ""
echo -e "${BLUE}2️⃣  Pushing to public repository...${NC}"
bash scripts/git-push-public-safe.sh

echo ""
echo -e "${GREEN}🎉 Successfully pushed to both repositories!${NC}"
echo ""
echo -e "${BLUE}📋 Final Summary:${NC}"
echo -e "${GREEN}   ✅ Private repository: Updated with all content${NC}"
echo -e "${GREEN}   ✅ Public repository: Updated with public content only${NC}"
echo -e "${GREEN}   🔒 Private content automatically filtered from public repo${NC}"
echo -e "${GREEN}   📦 Both repositories are now synchronized${NC}"
echo -e "${GREEN}   🛡️  Zero risk of file deletion in main repository${NC}"
