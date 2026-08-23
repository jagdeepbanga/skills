---
name: implement-with-worktree
description: Implement one ticket in its own git worktree and branch, verify green in isolation, then push and raise a PR. Use this whenever implementing a ready-for-agent ticket in a repo where other Claude Code sessions may be running at the same time, and whenever the user mentions parallel sessions, working two tickets at once, sessions clobbering each other, conflicting branches, lost stashes, or commits landing on the wrong branch. Also use it before starting any ticket in a repo that already has multiple worktrees.
license: MIT
metadata:
  author: Jagdeep Singh
  source: https://github.com/mattpocock/skills/issues/493
---

# Implement with worktree

One ticket = one session = its own worktree and branch. Never work in a tree
another session may share.

This skill wraps `/implement`. It does not replace it. It establishes isolation
before implementation starts, keeps the git operations that corrupt sibling
sessions out of your hands, and turns integration into a serial step. The actual
coding workflow stays whatever `/implement` (or your normal process) says it is.

Two Claude Code sessions in one checkout share a single working directory, a
single index, and a single HEAD, and the resulting failures are data races
rather than reasoning mistakes. Worktrees close most of them; the rest are held
shut by the rules below. The mechanism of each, and how to recover when one has
already happened, is in
[`references/failure-modes.md`](references/failure-modes.md).

## Where the scripts live

The scripts ship with this skill, not with the project you are working in.
Resolve the skill directory once and use `$IWW` in every command below:

```bash
IWW=~/.claude/skills/implement-with-worktree   # wherever this skill is installed
```

## Who runs what

Creating and removing worktrees is the human's job: a new directory appearing on
their disk is theirs to authorise. So `worktree-start.sh` and
`worktree-finish.sh --cleanup` are commands you **hand to the user**, not
commands you run. Everything between those two — implementing, verifying,
integrating, pushing, raising the PR — is yours.

## Before starting

**Confirm you are in a linked worktree, not the main checkout.**

```bash
test "$(git rev-parse --git-dir)" != "$(git rev-parse --git-common-dir)" \
  && echo "isolated" || echo "MAIN CHECKOUT"
```

If this prints `MAIN CHECKOUT`, stop before touching a file. Tell the user which
ticket you are about to start and give them the command from step 1 to run.

**Confirm the domains are disjoint.** This is the one thing git cannot solve for
you. Read the ticket, then list the files and modules it will touch. If any of
them overlap with a sibling ticket that is currently in flight, or if this ticket
renames an identifier a sibling imports, the pair runs serially no matter what
the blocking edges say. Worktrees convert silent clobbering into an explicit
merge conflict, which is a large improvement, but the judgment of whether to
parallelize at all stays with you. When in doubt, serialize.

**Confirm the runtime is isolated too.** Worktrees isolate git state, not ports,
databases, or gitignored files. A sibling session running migrations against the
same database will still break your test run and cost you the same red/green
attribution problem you were trying to avoid. Read
[`references/runtime-isolation.md`](references/runtime-isolation.md) before
running anything that binds a port or touches a database.

## Process

1. **Isolate first.** Ask the user to run this from the main checkout, before
   you touch any file:

   ```bash
   $IWW/scripts/worktree-start.sh <ticket-id> [base-branch] [port]
   ```

   It fetches, branches `ticket/<ticket-id>` off the remote default, creates
   `../<repo>-<ticket-id>`, assigns a free port, and runs the repo's
   `.iww-setup.sh` if there is one. Work resumes in that tree: edits,
   verification, commits, all of it.

2. **Implement the ticket there.** Follow `/implement` or your normal TDD
   workflow. Typecheck and run single test files as you go; run the full suite
   once at the end. Because the tree contains only your changes, a red result is
   unambiguously yours, which is the main practical payoff of the isolation.

   End the final commit message with `Closes #<ticket-id>` so merging the PR
   closes the ticket.

3. **Integrate, verify, and raise the PR.** With the tree green and everything
   committed:

   ```bash
   $IWW/scripts/worktree-finish.sh
   ```

   This merges the base branch, reruns verification on the integrated result
   (`.iww-verify.sh` if the repo has one), pushes the branch, and opens the PR
   via `gh`. Only a green integrated result is finishable.

   On a merge conflict the script stops and hands the tree to you: resolve it
   here, since you know your own changes best, then rerun the script. A conflict
   that reveals a real domain overlap with a sibling ticket means the pair
   should have been serialized — say so in your report, so the next ticket
   breakdown catches it.

   If the project merges locally to a shared branch rather than through PRs, see
   [Local serial merge](#local-serial-merge) below, because that path needs a
   lock.

4. **Leave the worktree in place until the PR merges.** Review may ask for
   changes, and this is the tree those changes belong in. Once the PR is merged,
   tell the user they can reclaim it:

   ```bash
   $IWW/scripts/worktree-finish.sh --cleanup
   ```

## Rules

Each of these keeps one specific corruption out of a sibling session.

- **Set work aside with a WIP commit on your own branch**, never a stash:
  `git commit -am "wip" --no-verify`. It sits on a ref only you control,
  survives a crash, and squashes away before the PR. `refs/stash` is shared by
  every worktree in the repo, so a sibling's `git stash pop` can consume your
  entry — the one race worktrees do not close.

- **Fix a commit forward with a new commit.** Amending is safe only on something
  you authored in this worktree during this session and have not pushed;
  anywhere else, the amend race silently rewrites a sibling's commit. A wrong
  commit message can wait for the PR title.

- **Stay on the branch this worktree was created for.** It is pinned to one
  branch on purpose, and in a shared checkout a `checkout`/`switch` moves HEAD
  under another session between the moment it reads git state and the moment it
  acts. To see another branch, ask for a worktree for it.

- **Ask the human for worktree changes.** `git worktree add` and
  `git worktree remove` belong to them; the scripts in step 1 and step 4 are how
  they do it.

- **Run every git command from inside this worktree.** Everything you need is
  here, so there is no reason to `cd` elsewhere to reach git.

- **Treat shared branches as append-only.** `main` and `master` take new
  commits and nothing else: no amend, rebase, reset, or force-push. Rebasing
  your own unpushed ticket branch onto a fresh base is fine and encouraged.

- **Keep every edit inside this ticket's scope.** Report an unrelated bug you
  find rather than fixing it — at review time a drive-by fix in a parallel run
  is indistinguishable from a clobber.

## Local serial merge

Some projects merge to a shared branch locally instead of through PRs. That path
works, but merging is then a critical section and only one session may hold it at
a time. Take a lock:

```bash
LOCK="$(git rev-parse --git-common-dir)/iww-merge.lock"
mkdir "$LOCK" 2>/dev/null || { echo "another session is merging; wait"; exit 1; }
trap 'rmdir "$LOCK"' EXIT
```

`mkdir` is atomic, so this is a real mutex rather than a check-then-act race.
Hold it across the whole pull, merge, verify, push sequence, and rerun the full
suite and typecheck on the merged result before pushing. Only green completes the
merge.

## Reporting back

When the ticket is done, report:

- The PR URL and the branch name.
- Which files the ticket touched, so the next parallelization decision has real
  data rather than a guess.
- Any merge conflict that revealed a domain overlap, named explicitly, along with
  the sibling ticket it overlapped with.
- That the worktree is still present and awaiting cleanup, with the command.

## Reference files

- [`references/runtime-isolation.md`](references/runtime-isolation.md) —
  per-worktree ports, databases, env files, and dependency directories, plus
  `.iww-setup.sh` templates for Node, Laravel, and Docker Compose. Read this
  before the first run in a new repo.
- [`references/failure-modes.md`](references/failure-modes.md) — what each rule
  above is holding shut, and how to recover if one already happened.
