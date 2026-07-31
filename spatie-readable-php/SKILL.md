---
name: spatie-readable-php
description: Apply Spatie's "Writing Readable PHP" techniques when writing, refactoring, or reviewing PHP or Laravel code for readability — happy-path/guard-clause structure, expressive naming, avoiding else, modern PHP operators (`?->`, `??`, `??=`, `match`, named arguments), array and collection pipelines, PHPStan-friendly type hints and generics, and Laravel readability patterns (form requests, custom collections, conditional queries, factories). Use when the goal is clearer, more maintainable code, not just mechanical formatting.
license: MIT
metadata:
  author: Spatie
  source: https://spatie.be/courses/writing-readable-php
---

# Writing Readable PHP

Make PHP read the way a human reads it. Code is read far more often than it is written — by teammates and by your future self — so structure, naming, and control flow should optimize for the reader. Whitespace and ordering have zero runtime cost; spend them on clarity.

Distilled from Spatie's *Writing Readable PHP* course, organized as an index of reference files. Each file teaches a technique and *why* it reads better.

## When to Apply

- Writing, refactoring, or reviewing any PHP or Laravel code where clarity matters — even when the user doesn't say "readable".
- A method reads as tangled: nested conditionals, `else` branches, buried happy path, cryptic names, boolean flag arguments.
- Adding or tightening type hints, PHPDoc generics, or PHPStan coverage.

## Related skills — stay in your lane

- **[`spatie-laravel-php`](../spatie-laravel-php/SKILL.md)** owns the mechanical *style guide* (PSR-12, casing, class structure, docblock rules). This skill owns *readability judgment* — how to restructure code so it reads well. Where they touch (e.g. happy-path-last), they agree; don't restate formatting rules here.
- **[`laravel-best-practices`](../laravel-best-practices/SKILL.md)** owns *correctness, performance, and security* (N+1, caching, authorization). Reach for it when the concern is behavior, not clarity.

## How to Apply

1. **Consistency first.** Match what the file and its siblings already do. These techniques are defaults for new code, not a mandate to churn a working file into a different style.
2. Map each readability concern in the code to the index below, and read the mapped reference file before editing.
3. Apply the smallest change that makes the code read better. Prefer the happy path last, expressive names, and early returns over cleverness.
4. Re-read the diff as a human reader would: does each method now read top-to-bottom as a sequence of clear steps?

## Reference Index

| Concern | Read |
| --- | --- |
| Whitespace, breathing space, happy path, dead code, property grouping | [`references/visuals.md`](references/visuals.md) |
| Naming: expressiveness, abbreviations, booleans-as-timestamps, English, consistency | [`references/naming.md`](references/naming.md) |
| Control flow: avoiding `else`, guard clauses, ordering functions, extracting conditionals, custom exceptions | [`references/code-structure.md`](references/code-structure.md) |
| Modern PHP: strict checks, `?->`, `??`, `??=`, named args, destructuring, `array_map`/`array_filter`, `match`, `void` | [`references/modern-php.md`](references/modern-php.md) |
| Type hints, PHPDoc generics, `class-string`, array shapes, PHPStan setup and CI | [`references/static-analysis.md`](references/static-analysis.md) |
| Laravel readability: routes files, method chains, custom collections, enums over strings, form requests, macros, conditional queries, factories | [`references/laravel.md`](references/laravel.md) |

## Core Principles (summary)

- **Optimize for the happy path.** Handle edge cases first as guard clauses; leave the core action as the last, unwrapped step.
- **Be expressive.** A name should say what a thing *is* or *does*; if a comment is needed to explain a name, rename it.
- **Avoid `else`.** Early returns flatten nesting and keep each condition close to its consequence.
- **Prefer modern PHP.** Null-safe (`?->`), null-coalescing (`??`, `??=`), `match`, named arguments, and array functions replace verbose branching.
- **Type everything.** Full type hints and PHPDoc generics let both humans and PHPStan understand the code without running it.
