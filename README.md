# Skills

A collection of agent skills for [Claude Code](https://claude.ai/code).

**GitHub:** [jagdeepbanga/skills](https://github.com/jagdeepbanga/skills)

## What are skills?

Skills are reusable instruction sets that extend Claude Code's behavior. Each skill lives in its own directory and is loaded on demand when a matching user request is detected.

## Available skills

| Skill | Description |
|-------|-------------|
| [`write-a-skill`](./write-a-skill/) | Create new agent skills with proper structure, progressive disclosure, and bundled resources |

## Installing skills

Use the Claude Code CLI to install skills directly from this repo:

```bash
claude skill install github:jagdeepbanga/skills/write-a-skill
```

To install all skills:

```bash
claude skill install github:jagdeepbanga/skills
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

## Contributing

1. Fork this repo
2. Create your skill using `/write-a-skill` or manually following the structure above
3. Add it to the skills table in this README
4. Open a pull request
