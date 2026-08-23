#!/usr/bin/env bash
#
# worktree-start.sh — create an isolated worktree for one ticket.
#
#   worktree-start.sh <ticket-id> [base-branch] [port]
#
#   worktree-start.sh TICKET-101
#   worktree-start.sh TICKET-101 develop
#   worktree-start.sh TICKET-101 main 3105
#
# Runs .iww-setup.sh from the repo root inside the new worktree if present.
# See ../references/runtime-isolation.md, beside this script.

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

[ $# -ge 1 ] || die "usage: worktree-start.sh <ticket-id> [base-branch] [port]"

TICKET="$1"
BASE="${2:-}"
PORT="${3:-}"

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

command -v git >/dev/null || die "git not found"
git rev-parse --git-dir >/dev/null 2>&1 || die "not inside a git repository"

# Always operate from the main checkout, never from inside another worktree.
COMMON="$(cd "$(git rev-parse --git-common-dir)" && pwd)"
MAIN="$(dirname "$COMMON")"
cd "$MAIN"

REPO="$(basename "$MAIN")"
SLUG="$(printf '%s' "$TICKET" | tr '[:upper:]' '[:lower:]' | tr -c '[:alnum:]' '_' | sed 's/_*$//')"
BRANCH="ticket/$TICKET"
DIR="$(dirname "$MAIN")/$REPO-$TICKET"

[ -e "$DIR" ] && die "$DIR already exists"
git show-ref --verify --quiet "refs/heads/$BRANCH" && die "branch $BRANCH already exists"

# Fetch first, so the base branch is resolved against fresh remote refs.
if git remote get-url origin >/dev/null 2>&1; then
  echo "==> fetching origin"
  git fetch --quiet origin
fi

# Resolve the base branch: explicit argument, else the remote default, else local main/master.
if [ -z "$BASE" ]; then
  if git remote get-url origin >/dev/null 2>&1; then
    BASE="$(default_base)"
  else
    for candidate in main master; do
      git show-ref --verify --quiet "refs/heads/$candidate" && BASE="$candidate" && break
    done
  fi
fi
[ -n "$BASE" ] || die "could not determine a base branch; pass one explicitly"
git rev-parse --verify --quiet "$BASE" >/dev/null \
  || die "base branch '$BASE' not found; pass one explicitly"

# Pick the first free port at or above 3100 unless one was given.
if [ -z "$PORT" ]; then
  PORT=3100
  while lsof -iTCP:"$PORT" -sTCP:LISTEN >/dev/null 2>&1; do
    PORT=$((PORT + 1))
    [ "$PORT" -gt 3200 ] && die "no free port between 3100 and 3200; pass one explicitly"
  done
fi

echo "==> creating worktree"
echo "    ticket $TICKET"
echo "    branch $BRANCH"
echo "    base   $BASE"
echo "    dir    $DIR"
echo "    port   $PORT"

git worktree add "$DIR" -b "$BRANCH" "$BASE"

if [ -f "$MAIN/.iww-setup.sh" ]; then
  echo "==> running .iww-setup.sh"
  IWW_TICKET="$TICKET" IWW_SLUG="$SLUG" IWW_DIR="$DIR" IWW_MAIN="$MAIN" IWW_PORT="$PORT" \
    bash "$MAIN/.iww-setup.sh"
else
  cat <<EOF

    No .iww-setup.sh found at the repo root, so dependencies, .env, database,
    and ports are NOT isolated. Two sessions can still collide through those.
    For a template, see:
    $SKILL_DIR/references/runtime-isolation.md
EOF
fi

cat <<EOF

==> ready

    cd $DIR && claude

    One ticket, one session, this tree only. Inside it: commit to this
    branch, and set work aside with a WIP commit. Stash, --amend, branch
    switching, and worktree management stay with the human.

EOF
