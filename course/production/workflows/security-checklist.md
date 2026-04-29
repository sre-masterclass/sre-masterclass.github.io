# Security Checklist
## Dual-Repository Setup - Protecting Private Content

### 🔒 Pre-Push Security Checklist

Before pushing any content, verify:

- [ ] **Current branch is `main`**: `git branch` shows `* main`
- [ ] **No uncommitted changes**: `git status` shows "working tree clean"
- [ ] **Using correct push method**: Using scripts, not direct `git push`
- [ ] **Private content in correct location**: All course content in `course/` directory

### 🛡️ Content Classification Checklist

#### ✅ **SAFE FOR PUBLIC** (Can go in both repositories)
- [ ] Application source code (`services/`, `monitoring/`, etc.)
- [ ] Technical architecture documentation (`docs/design/`)
- [ ] Development guides and setup instructions (`docs/development/`)
- [ ] Open source configuration files
- [ ] Generic scripts and utilities
- [ ] Public README and contributing guidelines

#### 🚨 **MUST REMAIN PRIVATE** (Only in private repository)
- [ ] Video scripts and course content (`course/video-scripts/`)
- [ ] Course planning and strategy documents (`course/planning/`)
- [ ] Content production workflows (`course/production/`)
- [ ] Business strategy and roadmaps
- [ ] Internal process documentation
- [ ] Commercial content templates

### 🔍 Pre-Commit Security Review

Before committing changes, check:

- [ ] **No hardcoded secrets**: API keys, passwords, tokens
- [ ] **No personal information**: Email addresses, phone numbers, private URLs
- [ ] **No internal references**: Internal server names, private services
- [ ] **Appropriate file permissions**: No executable files where not needed
- [ ] **Clean commit messages**: No internal project names or sensitive context

### 🎯 Push Strategy Security

| Scenario | Recommended Action | Security Level |
|----------|-------------------|----------------|
| **Only changed public code** | `bash scripts/git-push-all.sh` | ✅ Safe |
| **Only changed private content** | `bash scripts/git-push-private.sh` | ✅ Safe |
| **Changed both public and private** | `bash scripts/git-push-all.sh` | ✅ Safe |
| **Unsure about content** | `bash scripts/git-push-private.sh` first | ⚠️ Cautious |
| **Emergency public update** | `bash scripts/git-push-public.sh` | ⚠️ Verify content |

### 🚨 Security Violations - Immediate Response

#### **If Private Content Accidentally Pushed to Public:**

**IMMEDIATE ACTIONS:**
1. **Stop all work** - Don't make additional commits
2. **Contact GitHub support** to remove sensitive data from history
3. **Force clean push**:
   ```bash
   bash scripts/git-push-public.sh
   ```
4. **Verify cleanup**:
   ```bash
   git clone https://github.com/sre-masterclass/sre-masterclass.git verify-clean
   ls -la verify-clean/  # Should NOT contain course/ directory
   rm -rf verify-clean
   ```

**FOLLOW-UP ACTIONS:**
- [ ] Review workflow that led to the violation
- [ ] Update security procedures if needed
- [ ] Document incident and lessons learned
- [ ] Verify no other repositories were affected

### 🔧 Security Verification Commands

#### **Daily Security Checks:**
```bash
# Verify remotes are correct
git remote -v

# Check what would be pushed to public
git log public/main..HEAD --name-only

# Verify no private files in public push
git diff public/main..HEAD --name-only | grep -E "^course/"
# Should return nothing (empty)

# Check for sensitive patterns in staged files
git diff --cached | grep -i -E "(password|secret|api_key|private)"
```

#### **Security Audit Commands:**
```bash
# List all files that would go to public repo
git ls-tree -r --name-only HEAD | grep -v -E "^course/"

# Check file permissions
find . -type f -perm +111 | grep -v ".git" | grep -v "scripts/"

# Search for potential secrets
git log --all -p | grep -i -E "(password|secret|api_key|token)" | head -20
```

### 📋 Security Configuration Checklist

#### **Git Configuration:**
- [ ] Pre-push hook is installed: `ls -la .git/hooks/pre-push`
- [ ] Hook is executable: `test -x .git/hooks/pre-push && echo "OK"`
- [ ] Scripts are executable: `ls -la scripts/git-push-*.sh`
- [ ] Remotes are configured: `git remote -v`

#### **GitHub Repository Settings:**
- [ ] **Private repo** is set to private visibility
- [ ] **Public repo** has appropriate visibility
- [ ] **Branch protection** rules configured (optional)
- [ ] **Security alerts** enabled for dependencies

#### **Local Environment:**
- [ ] No sensitive data in shell history
- [ ] Secure SSH keys with passphrases
- [ ] Two-factor authentication enabled on GitHub
- [ ] Local Git config doesn't contain sensitive data

### 🎓 Team Security Training

#### **All Team Members Must:**
- [ ] Understand the dual-repository structure
- [ ] Know which content is public vs private
- [ ] Use only the provided push scripts
- [ ] Never bypass security checks
- [ ] Report security violations immediately

#### **Required Knowledge:**
- [ ] Location of private content (`course/` directory)
- [ ] How to use push scripts correctly
- [ ] What to do if security violation occurs
- [ ] How to verify content before pushing

### 📝 Security Incident Log Template

```
Date: [YYYY-MM-DD]
Time: [HH:MM UTC]
Incident: [Brief description]
Impact: [What was exposed]
Response: [Actions taken]
Resolution: [How it was fixed]
Prevention: [Changes to prevent recurrence]
```

### ⚠️ Security Red Flags

**STOP and review if you see:**
- [ ] Files with "private", "secret", or "confidential" in names
- [ ] Email addresses or personal information in commits
- [ ] API keys, tokens, or passwords in code
- [ ] Internal server names or private URLs
- [ ] Business strategy or financial information
- [ ] Unpublished course content outside `course/` directory

### 🔄 Regular Security Maintenance

#### **Weekly:**
- [ ] Review recent commits for sensitive data
- [ ] Verify push scripts are working correctly
- [ ] Check no private content in public repo

#### **Monthly:**
- [ ] Audit file permissions and configurations
- [ ] Review and update security procedures
- [ ] Test emergency response procedures

#### **Before Major Releases:**
- [ ] Complete security audit of all content
- [ ] Verify all team members understand procedures
- [ ] Test all push scripts and verification commands

---

**Remember: When in doubt, push to private only!** 🔒
