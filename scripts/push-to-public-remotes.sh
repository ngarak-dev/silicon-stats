#!/usr/bin/env bash
# Run from a Mac/Linux machine that already has this checkout AND
# credentials for GitHub (gh auth login or HTTPS credential helper)
# and optionally Origin.
set -euo pipefail

BRANCH="${1:-cursor/public-repo-cicd-646b}"
GH_REMOTE_URL="https://github.com/ngarak-dev/silicon-stats.git"
ORIGIN_REMOTE_URL="https://origin.cursor.com/ngarak-dev/silicon-stats.git"

echo "==> Ensuring remotes"
git remote remove github 2>/dev/null || true
git remote add github "$GH_REMOTE_URL"
git remote remove origin-ss 2>/dev/null || true
git remote add origin-ss "$ORIGIN_REMOTE_URL"

echo "==> Pushing $BRANCH -> github main"
git push -u github "$BRANCH:main"

echo "==> Pushing $BRANCH -> Origin main (may prompt for Origin auth)"
git push -u origin-ss "$BRANCH:main" || {
  echo "Origin push failed (auth). GitHub push already done; fix Origin separately."
}

echo "==> Optional first release tag (triggers DMG workflow on GitHub)"
read -r -p "Create and push tag v0.1.0 to GitHub? [y/N] " ans
if [[ "${ans:-}" =~ ^[Yy]$ ]]; then
  git tag -f v0.1.0 "$BRANCH"
  git push github v0.1.0
  echo "Watch: https://github.com/ngarak-dev/silicon-stats/actions"
fi

echo "Done."
