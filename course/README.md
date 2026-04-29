# Private Course Content

⚠️ **CONFIDENTIAL** - This directory contains proprietary course materials and should NEVER be pushed to public repositories.

## Directory Structure

### `video-scripts/`
- Video scripts, outlines, and technical validations
- Interactive HTML tools and demos
- Module-specific course content

### `production/`
- Content creation templates and style guides
- Production workflows and progress tracking
- Internal process documentation

### `planning/`
- Project specifications and planning documents
- Business strategy and roadmaps
- Internal development plans

## Security Notice

This content is automatically filtered when pushing to public remotes using our git automation scripts. The following directories are considered private:

- `course/` (this entire directory)
- Any legacy `docs/video_scripts/`, `docs/content-production/`, `docs/planning/` directories

## Usage

- Work normally with all content in your local repository
- Use `git push-private` to push everything to the private repository
- Use `git push-public` to push only public content to the public repository
- Use `git push-all` to push to both repositories

## Workflow Documentation

For detailed guidance on using the dual-repository setup:

- **📖 Complete Workflow Guide**: `production/workflows/dual-repository-workflow.md`
- **⚡ Quick Commands Reference**: `production/workflows/git-commands-cheatsheet.md`
- **🔒 Security Checklist**: `production/workflows/security-checklist.md`

## Important

Never manually push to the public repository without using the provided scripts, as this could accidentally expose private content.
