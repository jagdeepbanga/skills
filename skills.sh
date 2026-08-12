#!/usr/bin/env bash
#
# skills.sh — keep agent skills fresh from this repo, without re-copying.
#
# The repo is the single source of truth. This script points Claude Code
# (and, via its ~/.claude/skills scan, opencode) at the repo's skill
# directories with symlinks, and removes the stale copies previously made
# by `npx skills` so nothing gets loaded twice.
#
# After running it, restart opencode and/or run /reload-plugins in Claude Code.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$SCRIPT_DIR"
DEST_DIR="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
STORE_DIR="${AGENT_SKILLS_DIR:-$HOME/.agents/skills}"
CLEAN_STORE=1
DO_PULL=0
DO_STATUS=0
DRY_RUN=0

print_usage() {
  cat <<'EOF'
Usage: skills.sh [command] [options]

Commands:
  status              Show current link state for every repo skill
  pull                git pull the repo, then refresh
  (default)           Refresh: link repo skills, prune stale links, clean old copies

Options:
  --repo <dir>        Skill source dir (default: where this script lives)
  --dest <dir>        Claude Code skills dir (default: ~/.claude/skills)
  --no-clean          Don't remove old repo-skill copies from ~/.agents/skills
  --dry-run           Print what would be done without changing anything
  -h, --help          Show this help

Environment overrides: CLAUDE_SKILLS_DIR, AGENT_SKILLS_DIR, SKILLS_REPO_DIR
EOF
}

run() {
  if [[ "$DRY_RUN" == 1 ]]; then
    printf '[dry-run] %s\n' "$*"
  else
    "$@"
  fi
}

repo_skill_names() {
  find "$REPO_DIR" -mindepth 2 -maxdepth 2 -name 'SKILL.md' -type f |
    while IFS= read -r f; do basename "$(dirname "$f")"; done | sort -u
}

link_skill() {
  local name="$1" dest="$REPO_DIR/$name" link="$DEST_DIR/$name" current=""
  if [[ -e "$link" || -L "$link" ]] && [[ ! -L "$link" ]]; then
    echo "SKIP  $name — $link exists and is not a symlink; remove it manually"
    return
  fi
  [[ -L "$link" ]] && current="$(readlink "$link")"
  if [[ "$current" == "$dest" ]]; then
    echo "OK    $name -> $dest"
    return
  fi
  run ln -sfn "$dest" "$link"
  echo "LINK  $name -> $dest"
}

prune() {
  [[ -d "$DEST_DIR" ]] || return
  local link name target
  for link in "$DEST_DIR"/*; do
    [[ -L "$link" ]] || continue
    name="$(basename "$link")"
    target="$(readlink "$link")"
    case "$target" in
      "$REPO_DIR"/*) ;;
      *) continue ;;
    esac
    if ! printf '%s\n' "$REPO_SKILLS" | grep -qxF -- "$name"; then
      echo "PRUNE $link — no longer a repo skill"
      run rm "$link"
    fi
  done
}

clean_store() {
  [[ "$CLEAN_STORE" == 1 ]] || return
  [[ -d "$STORE_DIR" ]] || return
  local name
  while IFS= read -r name; do
    [[ -n "$name" ]] || continue
    if [[ -e "$STORE_DIR/$name" || -L "$STORE_DIR/$name" ]]; then
      echo "CLEAN $STORE_DIR/$name — repo is the source now"
      run rm -rf "$STORE_DIR/$name"
    fi
  done <<< "$REPO_SKILLS"
}

print_status() {
  echo "Repo : $REPO_DIR"
  echo "Dest : $DEST_DIR"
  echo "Store: $STORE_DIR"
  echo
  printf '%-30s %s\n' 'SKILL' 'STATUS'
  local name link st
  while IFS= read -r name; do
    [[ -n "$name" ]] || continue
    link="$DEST_DIR/$name"
    st="missing"
    if [[ -L "$link" ]]; then
      st="linked -> $(readlink "$link")"
    elif [[ -e "$link" ]]; then
      st="exists (not a symlink)"
    fi
    if [[ -e "$STORE_DIR/$name" || -L "$STORE_DIR/$name" ]]; then
      st="$st; stale copy in store"
    fi
    printf '%-30s %s\n' "$name" "$st"
  done <<< "$REPO_SKILLS"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    pull) DO_PULL=1 ;;
    status) DO_STATUS=1 ;;
    --repo) REPO_DIR="$2"; shift 2 ;;
    --dest) DEST_DIR="$2"; shift 2 ;;
    --no-clean) CLEAN_STORE=0 ;;
    --dry-run) DRY_RUN=1 ;;
    -h|--help) print_usage; exit 0 ;;
    *) echo "Unknown argument: $1"; echo; print_usage; exit 1 ;;
  esac
  shift
done

REPO_DIR="$(cd "$REPO_DIR" && pwd)"
REPO_SKILLS="$(repo_skill_names)"

if [[ -z "$REPO_SKILLS" ]]; then
  echo "No SKILL.md files found under $REPO_DIR" >&2
  exit 1
fi

if [[ "$DO_STATUS" == 1 ]]; then
  print_status
  exit 0
fi

if [[ "$DO_PULL" == 1 ]]; then
  if git -C "$REPO_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    run git -C "$REPO_DIR" pull --ff-only
  else
    echo "WARN $REPO_DIR is not a git repo — skipping pull"
  fi
fi

mkdir -p "$DEST_DIR"
prune
while IFS= read -r name; do
  [[ -n "$name" ]] || continue
  link_skill "$name"
done <<< "$REPO_SKILLS"
clean_store

echo
echo "Done. Restart opencode (or run /reload-plugins in Claude Code) to pick up changes."
