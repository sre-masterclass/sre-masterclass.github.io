# Git Commands Cheat Sheet
## Dual-Repository Setup - Quick Reference

### 🚀 Essential Daily Commands

| Action | Command |
|--------|---------|
| **Push to private only** | `bash scripts/git-push-private.sh` |
| **Push to public only** | `bash scripts/git-push-public.sh` |
| **Push to both repos** | `bash scripts/git-push-all.sh` |
| **Check status** | `git status` |
| **Check current branch** | `git branch` |
| **Check remotes** | `git remote -v` |

### 🔧 Setup Commands (One-time)

```bash
# Add remotes
git remote add public https://github.com/sre-masterclass/sre-masterclass.git
git remote add private https://github.com/sre-masterclass/sre-masterclass-private.git

# Optional: Configure aliases
git config alias.push-public '!bash scripts/git-push-public.sh'
git config alias.push-private '!bash scripts/git-push-private.sh'
git config alias.push-all '!bash scripts/git-push-all.sh'
```

### 📝 Standard Git Workflow

```bash
# 1. Create/switch to feature branch
git checkout -b feature/my-new-feature

# 2. Make changes and commit
git add .
git commit -m "Descriptive commit message"

# 3. Switch to main and merge
git checkout main
git merge feature/my-new-feature

# 4. Push to repositories
bash scripts/git-push-all.sh

# 5. Clean up feature branch
git branch -d feature/my-new-feature
```

### 🔍 Verification Commands

```bash
# Check what would be pushed
git log public/main..HEAD --oneline   # to public
git log private/main..HEAD --oneline  # to private

# List changed files
git diff --name-only HEAD~1..HEAD

# Check for uncommitted changes
git diff-index --quiet HEAD --
echo $?  # 0 = clean, 1 = dirty
```

### 🛠️ Troubleshooting Commands

```bash
# Fix script permissions
chmod +x scripts/git-push-*.sh
chmod +x .git/hooks/pre-push

# Reset to clean state
git fetch private main
git reset --hard private/main
git clean -fd

# Check script exists and is executable
ls -la scripts/git-push-*.sh

# View recent commits
git log --oneline -10

# Check remote URLs
git remote get-url public
git remote get-url private
```

### ⚡ Quick Fixes

| Problem | Solution |
|---------|----------|
| **Script permission denied** | `chmod +x scripts/git-push-*.sh` |
| **Not on main branch** | `git checkout main` |
| **Uncommitted changes** | `git add . && git commit -m "WIP"` |
| **Remote not found** | `git remote add [name] [url]` |
| **Stale branch info** | `git fetch --all` |

### 📊 Content Guidelines

| Content Type | Location | Push To |
|-------------|----------|---------|
| Application code | `services/`, `monitoring/` | Both repos |
| Public documentation | `docs/design/`, `docs/development/` | Both repos |
| Video scripts | `course/video-scripts/` | Private only |
| Course planning | `course/planning/` | Private only |
| Production workflows | `course/production/` | Private only |

### 🚨 Emergency Commands

```bash
# If you accidentally pushed private content to public:
# 1. Force clean public push
bash scripts/git-push-public.sh

# 2. Verify public repo is clean
git clone https://github.com/sre-masterclass/sre-masterclass.git temp-verify
ls temp-verify/  # Should NOT contain course/ directory
rm -rf temp-verify
```

### 📱 Git Aliases (If Configured)

```bash
git push-public   # Same as bash scripts/git-push-public.sh
git push-private  # Same as bash scripts/git-push-private.sh
git push-all      # Same as bash scripts/git-push-all.sh
```

### 🎯 Best Practice Reminders

- ✅ Always work on feature branches for significant changes
- ✅ Use descriptive commit messages
- ✅ Test locally before pushing
- ✅ Keep private content in `course/` directory
- ❌ Never use `git push public main` directly
- ❌ Never ignore pre-push hook warnings

---

**Print this page and keep it handy!** 📄
