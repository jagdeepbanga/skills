# Failure modes and recovery

Each prohibition in SKILL.md maps to a specific way parallel sessions corrupt
each other. Understanding the mechanism makes the rule stick better than the rule
alone, and the recovery steps matter because these incidents look like data loss
when they are usually recoverable.

## The amend race

**Mechanism.** Session A stages its files and runs `git commit --amend`. Between
A reading HEAD and A writing the new commit, session B's commit lands. The amend
replaces B's commit, not A's, and A's staged files are folded into a commit that
belongs to a different ticket. Nothing errors. The commit message still says B's
ticket. The change appears to have simply vanished from A's side and appears as
an unexplained extra diff on B's side.

**Recovery.** The original commit is still reachable through the reflog for the
default 90 days:

```bash
git reflog                        # find the pre-amend HEAD, e.g. HEAD@{3}
git branch rescue-b HEAD@{3}      # park it somewhere safe
git log --oneline rescue-b -3     # confirm it is B's commit
```

Then cherry-pick or reset onto the rescued commit as appropriate.

**Prevention.** Do not amend at all in a parallel context. If the commit message
needs fixing, fix it during rebase before pushing, or fix it in the PR title.

## The vanishing stash

**Mechanism.** `refs/stash` lives in the common git directory, so it is shared by
every worktree in the repo. This is the one race that worktrees do not fix.
Session A stashes; session B stashes; B pops and receives A's entry, or A pops and
takes B's. On a stash drop the ref disappears and the entry looks gone.

**Recovery.** A dropped stash is a dangling commit, so it survives until garbage
collection:

```bash
git fsck --unreachable | grep commit | cut -d' ' -f3 \
  | xargs -n1 git log --merges --no-walk --format='%H %ci %s'
```

Identify yours by timestamp and message, then:

```bash
git stash apply <sha>
```

**Prevention.** Never stash. A WIP commit on your own branch is strictly better
in a parallel context: it is on a ref only you control, it survives a crash, it
shows up in the reflog with a real message, and it can be squashed away before
the PR.

```bash
git commit -am "wip: partial work on TICKET-101" --no-verify
# later
git reset --soft HEAD~1     # unstage it back to working tree
```

## Contaminated verification

**Mechanism.** A whole-tree typecheck or test run reads every file in the working
directory, including a sibling's half-finished edits. A red result then has three
possible causes: your change, their change, or the interaction. Attributing it
costs real time on every single run, which quietly destroys the throughput
advantage that made parallelism attractive.

**Recovery.** None needed; it is a time cost rather than data loss. But note that
the traditional workaround, stashing the tree to get a clean verification run, is
the thing that triggers the vanishing stash above. That pairing is why the two
rules have to travel together.

**Prevention.** This is what worktrees solve directly. Once each session has its
own tree, a red result is yours by construction.

## HEAD moving underneath you

**Mechanism.** In a shared checkout, session A runs `git checkout feature/b` to
look at something. Session B, mid-commit, reads a HEAD that no longer points
where it thought. B's commit lands on A's branch. Because both sessions are
committing frequently, this can go unnoticed until a PR contains commits from a
ticket nobody assigned to it.

**Recovery.** Move the misplaced commits to the branch they belong on:

```bash
git checkout ticket/correct
git cherry-pick <sha>
git checkout ticket/wrong
git reset --hard HEAD~1        # only safe if unpushed
```

If already pushed, revert on the wrong branch and cherry-pick to the right one.
Do not force-push a shared branch.

**Prevention.** One worktree per branch, and never switch branches inside a
worktree.

## Silent semantic clobbering

**Mechanism.** Ticket A renames an identifier that ticket B imports. In a shared
tree, B's session sees the rename appear mid-run and either adapts to it,
producing a change that makes no sense in B's diff, or fails in a way that looks
like B's own bug.

**Recovery.** Nothing automated. This is a review problem.

**Prevention.** Worktrees convert this from silent clobbering into an explicit
merge conflict, which is a genuine improvement, but they do not remove the need
for the disjoint-domains check before starting. Renames across a module boundary
are the strongest single signal that two tickets should be serialized rather than
parallelized.

When a merge conflict does reveal an overlap, feed it back into ticket breakdown:
blocking edges usually encode logical dependency only, not file overlap, so the
same mistake will recur until the breakdown step learns to check both.
