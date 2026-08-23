# Skills

A collection of agent skills for [Claude Code](https://claude.ai/code).

**GitHub:** [jagdeepbanga/skills](https://github.com/jagdeepbanga/skills)

## What are skills?

Skills are reusable instruction sets that extend Claude Code's behavior. Each skill lives in its own directory and is loaded on demand when a matching user request is detected.

## Available skills

| Skill | Description |
|-------|-------------|
| [`ask-matt`](./ask-matt/) | Ask which skill or flow fits your situation. A router over the skills in this repo. |
| [`code-review`](./code-review/) | Review changes since a fixed point along two axes — Standards (does it follow this repo's coding standards?) and Spec (does it match what the issue/PRD asked for?), in parallel sub-agents. |
| [`codebase-design`](./codebase-design/) | Shared vocabulary for designing deep modules — interfaces, seams, deepening opportunities, testability. |
| [`diagnosing-bugs`](./diagnosing-bugs/) | Diagnosis loop for hard bugs and performance regressions. |
| [`domain-modeling`](./domain-modeling/) | Build and sharpen a project's domain model — ubiquitous language and architectural decisions. |
| [`grill-me`](./grill-me/) | A relentless interview to sharpen a plan or design. |
| [`grill-with-docs`](./grill-with-docs/) | A relentless interview to sharpen a plan or design, creating docs (ADRs and glossary) as you go. |
| [`grilling`](./grilling/) | Grill the user relentlessly about a plan, decision, or idea. |
| [`handoff`](./handoff/) | Compact the current conversation into a handoff document for another agent to pick up. |
| [`implement`](./implement/) | Implement a piece of work based on a spec or set of tickets. |
| [`implement-with-worktree`](./implement-with-worktree/) | Implement one ticket in its own git worktree and branch, so parallel Claude Code sessions cannot corrupt each other, then push and raise a PR. |
| [`improve-codebase-architecture`](./improve-codebase-architecture/) | Scan a codebase for deepening opportunities, present them as a visual HTML report, then grill the one you pick. |
| [`laravel-new`](./laravel-new/) | Preferred tech stack and conventions for new Laravel projects — Laravel 13+, PostgreSQL via Sail, Vite + Tailwind 4 + TypeScript, pnpm, spatie/laravel-data + laravel-ray, Pint + Larastan (level 7), and CI. |
| [`prototype`](./prototype/) | Build a throwaway prototype to answer a design question. |
| [`research`](./research/) | Investigate a question against high-trust primary sources and capture the findings as a Markdown file. |
| [`resolving-merge-conflicts`](./resolving-merge-conflicts/) | Resolve an in-progress git merge/rebase conflict. |
| [`setup-matt-pocock-skills`](./setup-matt-pocock-skills/) | Configure this repo for the engineering skills — issue tracker, triage labels, domain doc layout. Run once before first use. |
| [`tdd`](./tdd/) | Test-driven development — red-green-refactor and integration tests. |
| [`teach`](./teach/) | Teach the user a new skill or concept, within this workspace. |
| [`to-questionnaire`](./to-questionnaire/) | Turn a decision you can't fully answer into a questionnaire for someone else to fill in. |
| [`to-spec`](./to-spec/) | Turn the current conversation into a spec and publish it to the project issue tracker. |
| [`to-tickets`](./to-tickets/) | Break a plan, spec, or conversation into tracer-bullet tickets with blocking edges, published to the tracker. |
| [`triage`](./triage/) | Move issues and external PRs through a state machine of triage roles — categorise, verify, grill, and write agent-ready briefs. |
| [`wait-what`](./wait-what/) | Stop. That last message did not land — re-pitch it. |
| [`wayfinder`](./wayfinder/) | Plan a huge chunk of work as a shared map of decision tickets, resolved one at a time until the path is clear. |
| [`wizard`](./wizard/) | Generate an interactive bash wizard for steps only a human can perform — provisioning, credentials, dashboards, migrations. |
| [`write-a-skill`](./write-a-skill/) | Create new agent skills with proper structure, progressive disclosure, and bundled resources. |
| [`writing-for-agents`](./writing-for-agents/) | Reference for writing documents agents consume — skills, AGENTS.md, pointed-at docs. |
| [`writing-great-skills`](./writing-great-skills/) | Reference for writing and editing skills well — the vocabulary and principles that make a skill predictable. |

## Installing skills

These skills install with the [`skills`](https://github.com/vercel-labs/skills)
CLI, which reads this repo, detects Claude Code, and drops the skills into
Claude Code's skills directory for you. No global install of the CLI is needed —
`npx skills@latest` runs the latest version each time.

Skills auto-load the next time you start Claude Code. To load them in the
current session without restarting, run `/reload-plugins`.

### Install all skills globally

`--global` installs to your user-level skills directory (`~/.claude/skills/`),
so every project can use them. `--all` grabs every skill in the repo
non-interactively.

```bash
npx skills@latest add jagdeepbanga/skills --global --all
```

### Install a single skill

Pass the skill's folder name with `--skill` (repeatable, or comma-separated for
several):

```bash
npx skills@latest add jagdeepbanga/skills --skill write-a-skill --global
```

To browse what's available before installing, list without installing:

```bash
npx skills@latest add jagdeepbanga/skills --list
```

## Refreshing skills from the repo

By default the CLI symlinks skills, so `update` re-pulls the source and points
your installed skills at the latest version. Run `/reload-plugins` (or restart
Claude Code) afterwards to pick up the changes.

**Refresh all global skills:**

```bash
npx skills@latest update --global
```

**Refresh a single skill** — pass its name:

```bash
npx skills@latest update write-a-skill --global
```

## Skill structure

Each skill follows this layout:

```
skill-name/
├── SKILL.md           # Main instructions (required)
├── REFERENCE.md       # Detailed docs (if needed)
├── EXAMPLES.md        # Usage examples (if needed)
└── scripts/           # Utility scripts (if needed)
```

`SKILL.md` must include a YAML frontmatter block with `name` and `description` fields. The description is how Claude decides when to activate the skill.

## Creating a new skill

With `write-a-skill` installed, ask Claude Code to create one:

```
/write-a-skill
```

Claude will walk you through gathering requirements, drafting the skill files, and reviewing the result. Once done, add the new skill directory to this repo and update the table above.
