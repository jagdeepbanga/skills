#!/usr/bin/env bash
#
# worktree-finish.sh — integrate the base branch, verify, push, open the PR.
#
#   worktree-finish.sh                 integrate, verify, push, open PR
#   worktree-finish.sh --no-pr         push only
#   worktree-finish.sh --cleanup       remove this worktree and branch (after merge)
#   worktree-finish.sh --base develop  integrate against a specific branch
#
# Verification commands come from .iww-verify.sh at the repo root if present;
# otherwise a few common defaults are attempted.

set -euo pipefail

die() { printf 'error: %s\n' "$1" >&2; exit 1; }

# The remote's default branch. refs/remotes/origin/HEAD is frequently unset
# (git remote add + fetch never creates it), so fall back to a local ref rather
# than producing a bare "origin/".
default_base() {
  head="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null)" || head=""
  head="${head#origin/}"
  if [ -z "$head" ]; then
    for candidate in main master; do
      if git rev-parse --verify --quiet "refs/remotes/origin/$candidate" >/dev/null; then
        head="$candidate"
        break
      fi
    done
  fi
  printf 'origin/%s' "${head:-main}"
}

BASE=""
OPEN_PR=1
CLEANUP=0

while [ $# -gt 0 ]; do
  case "$1" in
    --no-pr)   OPEN_PR=0; shift ;;
    --cleanup) CLEANUP=1; shift ;;
    --base)    BASE="${2:-}"; [ -n "$BASE" ] || die "--base needs a branch"; shift 2 ;;
    -h|--help) sed -n '2,12p' "$0"; exit 0 ;;
    *)         die "unknown option: $1" ;;
  esac
done

git rev-parse --git-dir >/dev/null 2>&1 || die "not inside a git repository"

GIT_DIR="$(cd "$(git rev-parse --git-dir)" && pwd)"
COMMON="$(cd "$(git rev-parse --git-common-dir)" && pwd)"
MAIN="$(dirname "$COMMON")"
DIR="$(git rev-parse --show-toplevel)"
BRANCH="$(git rev-parse --abbrev-ref HEAD)"

[ "$GIT_DIR" != "$COMMON" ] || die "this is the main checkout, not a worktree; nothing to finish"

# ---------------------------------------------------------------- cleanup
if [ "$CLEANUP" -eq 1 ]; then
  echo "==> removing worktree $DIR"
  cd "$MAIN"
  git worktree remove "$DIR" || die "worktree has uncommitted changes; commit or discard them first"
  git branch -d "$BRANCH" 2>/dev/null \
    || echo "    branch $BRANCH not deleted (unmerged); use 'git branch -D $BRANCH' if you are sure"
  git worktree prune
  echo "==> done"
  exit 0
fi

# ---------------------------------------------------------------- guards
if [ -n "$(git status --porcelain)" ]; then
  git status --short
  echo >&2
  if [ -n "$(git ls-files --others --exclude-standard)" ]; then
    cat >&2 <<'EOF'
Some of the above are untracked. If any were created by the worktree setup
(.env, local config, build output), add them to .gitignore rather than
committing them.

EOF
  fi
  die "uncommitted changes; commit them before finishing"
fi

if [ -n "$(git stash list 2>/dev/null)" ]; then
  cat >&2 <<'EOF'
warning: this repository has stash entries.

    refs/stash is shared across every worktree, so an entry here may belong to
    another session. Do not pop or drop it. Resolve with the person who made it.

EOF
fi

# ---------------------------------------------------------------- integrate
# Fetch first, so the base branch is resolved against fresh remote refs.
if git remote get-url origin >/dev/null 2>&1; then
  echo "==> fetching origin"
  git fetch --quiet origin
fi

if [ -z "$BASE" ]; then
  if git remote get-url origin >/dev/null 2>&1; then
    BASE="$(default_base)"
  else
    BASE="main"
  fi
fi
git rev-parse --verify --quiet "$BASE" >/dev/null \
  || die "base branch '$BASE' not found; pass one with --base"

echo "==> integrating $BASE"
if ! git merge --no-edit "$BASE"; then
  cat >&2 <<EOF

Merge conflict against $BASE.

    Resolve it here in this worktree. You know your own changes best.
    If the conflict reveals that another ticket touches the same files, note
    that in your report: the pair should have been serialized, and the ticket
    breakdown needs to learn it.

    Then rerun: worktree-finish.sh

EOF
  exit 1
fi

# ---------------------------------------------------------------- verify
echo "==> verifying"
if [ -f "$MAIN/.iww-verify.sh" ]; then
  bash "$MAIN/.iww-verify.sh" || die "verification failed; only green is finishable"
else
  RAN=0
  if [ -f package.json ]; then
    for script in typecheck lint test; do
      if node -e "process.exit(require('./package.json').scripts?.['$script']?0:1)" 2>/dev/null; then
        echo "    npm run $script"
        npm run --silent "$script" || die "npm run $script failed; only green is finishable"
        RAN=1
      fi
    done
  fi
  if [ -f artisan ]; then
    echo "    php artisan test"
    php artisan test || die "php artisan test failed; only green is finishable"
    RAN=1
  fi
  [ "$RAN" -eq 0 ] && echo "    no verification configured; add .iww-verify.sh at the repo root"
fi

# ---------------------------------------------------------------- push + PR
git remote get-url origin >/dev/null 2>&1 || { echo "==> no origin remote; stopping here"; exit 0; }

echo "==> pushing $BRANCH"
git push -u origin "$BRANCH"

if [ "$OPEN_PR" -eq 1 ]; then
  if command -v gh >/dev/null 2>&1; then
    if gh pr view --json url --jq .url 2>/dev/null; then
      echo "==> PR already open, updated by the push"
    else
      echo "==> opening PR"
      gh pr create --base "${BASE#origin/}" --head "$BRANCH" --fill
    fi
  else
    echo "==> gh not installed; open the PR manually for branch $BRANCH"
  fi
fi

cat <<EOF

==> done

    Leave this worktree in place until the PR merges, in case review asks for
    changes. After it merges:

        worktree-finish.sh --cleanup

EOF
