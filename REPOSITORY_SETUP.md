# Repository Setup Guide

This document explains how to configure and use the dual-repository setup for the SRE Masterclass project.

## Overview

This project uses a **single local repository** with **two remote repositories**:

- **Public Repository**: Contains the application code and public documentation
- **Private Repository**: Contains everything (application + course content + planning)

## Initial Setup

### 1. Add Remote Repositories

```bash
# Add public remote (replace with your public repo URL)
git remote add public https://github.com/yourusername/sre-masterclass.git

# Add private remote (replace with your private repo URL) 
git remote add private https://github.com/yourusername/sre-masterclass-private.git

# Verify remotes
git remote -v
```

### 2. Configure Git Aliases (Optional but Recommended)

```bash
git config alias.push-public '!bash scripts/git-push-public.sh'
git config alias.push-private '!bash scripts/git-push-private.sh'
git config alias.push-all '!bash scripts/git-push-all.sh'
```

## Directory Structure

### Public Content (goes to both repositories)
- `services/` - Application microservices
- `monitoring/` - Monitoring stack configuration
- `entropy-engine/` - Chaos engineering engine
- `entropy-dashboard/` - Chaos engineering dashboard
- `tests/` - Integration and load tests
- `scripts/` - Utility scripts
- `docs/design/` - Technical architecture documentation
- `docs/development/` - Development guides and technical docs
- All configuration files (docker-compose.yml, etc.)

### Private Content (only goes to private repository)
- `course/` - **ALL course content**
  - `course/video-scripts/` - Video scripts and outlines
  - `course/production/` - Content production materials
  - `course/planning/` - Project planning documents

## Daily Workflow

### Normal Development
Work normally with all files in your local repository. Commit changes as usual:

```bash
git add .
git commit -m "Your commit message"
```

### Publishing Changes

#### Option 1: Push to Private Repository Only
```bash
# Using script
bash scripts/git-push-private.sh

# Or using alias (if configured)
git push-private

# Or directly
git push private main
```

#### Option 2: Push to Public Repository Only
```bash
# Using safer script (RECOMMENDED)
bash scripts/git-push-public-safe.sh

# Or using original script (has file deletion risk)
bash scripts/git-push-public.sh

# Or using alias (if configured)
git push-public

# ⚠️ Never use: git push public main (bypasses filtering)
```

#### Option 3: Push to Both Repositories
```bash
# Using safer script (RECOMMENDED)
bash scripts/git-push-all-safe.sh

# Or using original script (has file deletion risk)
bash scripts/git-push-all.sh

# Or using alias (if configured)
git push-all
```

### ⚠️ SAFETY WARNING
The original `git-push-public.sh` script temporarily deletes files and has a risk of data loss if the push fails. The new `-safe` versions use git worktrees to eliminate this risk. **Always use the `-safe` versions unless you have a specific reason not to.**

## Security Features

### 1. Pre-Push Hook
- Automatically prevents pushing private content to public remote
- Triggers when using `git push public main` directly
- Provides helpful error messages and suggestions

### 2. Automated Filtering
- `git-push-public.sh` automatically removes private directories
- Creates temporary branch, filters content, pushes, then cleans up
- Your local repository remains unchanged

### 3. Clear Directory Structure
- All private content consolidated in `course/` directory
- Easy to identify what should remain private

## Troubleshooting

### "Public remote not found"
```bash
git remote add public https://github.com/yourusername/sre-masterclass.git
```

### "Private remote not found"
```bash
git remote add private https://github.com/yourusername/sre-masterclass-private.git
```

### Accidentally pushed private content to public repo
1. Contact GitHub support to remove sensitive data
2. Force push a clean version using the public script
3. Review your workflow to prevent future incidents

### Scripts not executable
```bash
chmod +x scripts/git-push-*.sh
chmod +x .git/hooks/pre-push
```

## Best Practices

1. **Always use the provided scripts** for pushing to public repository
2. **Never use `git push public main` directly** - it bypasses security
3. **Commit regularly** to maintain good history
4. **Test locally** before pushing to either repository
5. **Keep private content in `course/` directory** for clear separation

## File Locations

- **Scripts**: `scripts/git-push-*.sh`
- **Git Hook**: `.git/hooks/pre-push`
- **Private Content**: `course/`
- **Documentation**: `REPOSITORY_SETUP.md`, `course/README.md`

## Support

If you encounter issues with this setup:
1. Check that all scripts are executable
2. Verify your remote URLs are correct
3. Ensure you're on the `main` branch when pushing
4. Review the error messages - they usually contain helpful guidance
