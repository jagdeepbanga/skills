---
name: filament-blueprint
description: Produce a detailed, self-contained Filament v5 implementation plan (a "blueprint") from a feature request, for a separate implementing agent to build from. Use in planning mode when asked to plan, spec, or design a Filament feature, panel, resource, or workflow before any code is written — especially complex features with multiple models, relationships, state transitions, or authorization. Not for writing the code itself.
license: proprietary
metadata:
  author: Filament
  source: https://filamentphp.com/docs/5.x/introduction/ai
  upstream: filament/blueprint — planning guidelines mirrored verbatim under references/ (proprietary Filament package)
---

# Filament Blueprint

## What this produces
A **blueprint**: one self-contained spec document (e.g. `BLUEPRINT.md`) that an **implementing agent** builds from directly — *without loading these guidelines or the Filament docs*. The implementer should never have to guess a namespace, choose a component, or ask a clarifying question. Everything it needs is in the document.

Planning and implementing are separate jobs. This skill is the **planning agent**; it copies every exact detail — namespaces, `make:` commands, method signatures, documentation URLs — into the blueprint so the implementing agent's context stays clean.

## When to activate
- In **planning mode**, before any code, when asked to plan / spec / design a Filament feature.
- For complex features: multiple models, relationships, state transitions, authorization, wizards, imports/exports, multi-tenancy.
- **Not** for writing the code — that's the implementing agent's job, in a fresh session.

## Prime directive: self-containment
The implementing agent sees **only your blueprint**. So it must inline, never hand-wave:
- Full namespaces — not "the Select component" but `Filament\Forms\Components\Select`.
- Exact scaffold commands, each with `--no-interaction`.
- Exact validation and config — not "add validation" but `Validation: required, email, max:255`.
- A verified documentation URL for every field, column, action, and filter.

If a section says "see the docs" or "use appropriate X," it isn't done — paste the specifics. `references/checklist.md` lists the vague phrasings that fail.

## Workflow
1. **Clarify until there are no TBDs.** Anything affecting schema or authorization gets a question, never a guess — `references/overview.md` ("Before You Plan") has the trigger→ask table. A blueprint has zero open questions.
2. **Plan in dependency order:** Models → Resources → Authorization → Tests. You can't spec a form field before the attribute it binds exists.
3. **Map the domain to primitives.** Each concept/flow → Resource / RelationManager / Page / Action / Widget. Every state transition (`draft → sent → paid`) is a named **Action** with a guard condition — never a raw edit.
4. **Verify syntax before writing.** Confirm each component method against the current docs (`references/overview.md` → "Verifying Syntax"); keep the URL in the plan as a backup reference.
5. **Write the blueprint** using the required formats below and the reference files.
6. **Self-review against `references/checklist.md`.** The blueprint is done only when an implementer could build it blind.

## Required formats
Every element inlines these lines (full detail in `references/overview.md`):

- **Field** — Component (full namespace), Docs (URL), Validation, Config
- **Column** — Component (full namespace), Docs (URL), Config
- **Filter** — Component (full namespace), Docs (URL), Config
- **Action** — Component (full namespace), Docs, Location, Visibility, Authorization, Behavior (steps)
- **Resource** — Command (new only), Location (full path), Docs
- **Reactive fields** — import `Filament\Schemas\Components\Utilities\Get` / `Set`, and `->live()` in Config

### Namespaces (the implementer writes imports from these)
| Element | Namespace |
| --- | --- |
| Form field | `Filament\Forms\Components\{Component}` |
| Table column | `Filament\Tables\Columns\{Column}` |
| Table filter | `Filament\Tables\Filters\{Filter}` |
| Action / bulk action | `Filament\Actions\{Action}` |
| Infolist entry | `Filament\Infolists\Components\{Entry}` |
| Layout | `Filament\Schemas\Components\{Component}` |
| Reactive utils (Get/Set) | `Filament\Schemas\Components\Utilities\*` |

### Locations (v5 groups a resource under its plural folder)
`App\Filament\Resources\{Models}\` → `{Model}Resource`, `Pages\{Page}`, `RelationManagers\{Relation}RelationManager`, `Actions\{Action}`.

## Conventions agents get wrong
- **Every action lives in `Filament\Actions`** in v5 — row, header, and bulk alike (`Action`, `BulkAction`, `DeleteAction`, …).
- **Extract a complex action** to its own class with `public static function make(): Action` — never `setUp()`, never extend an Action class.
- **`->live()`, not `->reactive()`.** `Get`/`Set` come from `Filament\Schemas\Components\Utilities`, not `Filament\Forms`.
- **These components don't exist** — use the real one: `Card`→`Section`; `BadgeColumn`→`TextColumn->badge()`; `BooleanColumn`→`IconColumn->boolean()`; `DateColumn`→`TextColumn->date()`; `MultiSelect`→`Select->multiple()`; `BelongsToSelect`→`Select->relationship()`.
- **hasMany:** a `Repeater` for a few inline items, otherwise a `RelationManager` (`php artisan make:filament-relation-manager …`). belongsToMany defaults to `Select->relationship()->multiple()`.
- **Icons use the `Heroicon` enum** (`Filament\Support\Icons\Heroicon`, e.g. `Heroicon::CheckCircle`); colors are `primary`/`info`/`danger`/`warning`/`success`/`gray`.
- **Filament enums** implement `Filament\Support\Contracts\HasLabel` (add `HasColor`/`HasIcon` for badges).
- **Column width multiplies through nesting** — a 2-column form with 2-column sections = 25% width. See `references/schema-layouts.md`.

## Reference files
The `filament/blueprint` planning guidelines, mirrored under `references/`. Read `overview.md` first, `checklist.md` last; open the rest as the feature needs them.

- **overview.md** — plan structure, required sections, clarify/verify tables *(start here)*
- **checklist.md** — pre-submission mistakes to catch *(finish here)*
- Domain & structure — `models.md`, `resources.md`, `custom-pages.md`, `relationships.md`, `pivot-tables.md`
- Schema surfaces — `forms.md`, `tables.md`, `infolists.md`, `schema-layouts.md`, `reactive-fields.md`, `wizards.md`
- Behavior & access — `actions.md`, `bulk-actions.md`, `authorization.md`, `multi-tenancy.md`
- Data movement — `imports.md`, `exports.md`
- Dashboards & polish — `widgets.md`, `styling.md`
- Verifying it works — `testing.md`

## Hand-off
Implement in a **fresh session** with clean context, pointed only at the blueprint — not at this skill. The blueprint is the contract; the implementer builds it verbatim, applying the `filament-best-practices` skill's conventions as it writes code.

## Related
- `filament-best-practices` — the implementation-time companion: apply it in the fresh session when building from a blueprint.
