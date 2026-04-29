#!/bin/bash
# This script configures the GitHub repository with labels, branch protections, etc.
# This is intended to be run by maintainers.
# Requires the GitHub CLI (gh) to be installed and authenticated.

echo "Configuring GitHub repository..."

# Add labels
echo "Creating labels..."
gh label create "bug" --description "Something isn't working" --color "d73a4a" --force
gh label create "enhancement" --description "New feature or request" --color "a2eeef" --force
gh label create "documentation" --description "Improvements or additions to documentation" --color "0075ca" --force
gh label create "question" --description "Further information is requested" --color "d876e3" --force
gh label create "chaos-scenario" --description "New chaos scenario proposal" --color "fbca04" --force
gh label create "triage-needed" --description "This issue needs to be triaged" --color "fef2c0" --force
gh label create "priority-high" --description "This should be dealt with ASAP" --color "b60205" --force
gh label create "priority-medium" --description "This should be dealt with soon" --color "fbca04" --force
gh label create "priority-low" --description "This can be dealt with whenever" --color "0e8a16" --force
gh label create "module-1" --description "Related to Module 1" --color "c5def5" --force
gh label create "module-2" --description "Related to Module 2" --color "c5def5" --force
gh label create "module-3" --description "Related to Module 3" --color "c5def5" --force
gh label create "module-4" --description "Related to Module 4" --color "c5def5" --force
gh label create "module-5" --description "Related to Module 5" --color "c5def5" --force
gh label create "in-progress" --description "This is being worked on" --color "cccccc" --force
gh label create "needs-testing" --description "This needs to be tested" --color "cccccc" --force
gh label create "ready-for-review" --description "This is ready for review" --color "cccccc" --force


# Branch protection rules
echo "Configuring branch protection for main..."
gh api \
  --method PUT \
  -H "Accept: application/vnd.github+json" \
  /repos/:owner/:repo/branches/main/protection \
  -f required_status_checks='{"strict":true,"contexts":["validate-environment"]}' \
  -f enforce_admins=true \
  -f required_pull_request_reviews='{"dismiss_stale_reviews":false,"require_code_owner_reviews":true,"required_approving_review_count":1}' \
  -f restrictions=null

echo "GitHub repository configuration complete."
exit 0
