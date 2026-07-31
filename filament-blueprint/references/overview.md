# Plan Structure

> **For planning agents**: Your plan is the ONLY thing the implementing agent
> sees. Copy all relevant information from the guideline files into your plan.
> The implementing agent cannot access these files—if something isn't in your
> plan, they won't know it.

Your plan is a specification document for an implementing agent. It must be
complete enough that the implementing agent can write code without making
decisions.

## Before You Plan

Ask the user to clarify ambiguities before producing the plan. Don't guess.

| If the request mentions... | Ask about...                                   |
| -------------------------- | ---------------------------------------------- |
| "Users can manage orders"  | Which users? All? Only their own? Admins only? |
| "Add a status field"       | What are the possible statuses?                |
| "Show related products"    | Inline (Repeater) or separate table?           |
| "Track order history"      | What events? Who can see it?                   |
| "Add notifications"        | Email? In-app? Both? What triggers them?       |
| "Make it searchable"       | Which fields? Global search too?               |
| Multiple panels mentioned  | Which resources belong to which panel?         |
| Vague authorization        | What permissions exist? Role-based or custom?  |

**When to ask vs proceed:**

- Ask when the answer affects database schema or authorization
- Ask when there are multiple valid approaches with different tradeoffs
- Proceed when the choice is cosmetic or easily changed later

## Verifying Syntax

Before finalizing your plan, verify configuration methods using search-docs:

| Verify                  | How                                       |
| ----------------------- | ----------------------------------------- |
| Component method exists | Search Filament docs for current API      |
| Validation rule syntax  | Search Laravel validation rules           |
| Namespace is correct    | Check namespace tables in guideline files |
| Method renamed in v5    | Search docs for breaking changes          |

**Keep URLs in plans**: After verifying, include documentation URLs as backup
references. Don't replace URLs with "search for X" - implementing agents need
direct links.

## Planning Order

Build your plan in this order:

1. **Models first** - Define tables, attributes, relationships
2. **Resources second** - Forms, tables, actions depend on model structure
3. **Authorization third** - Policies reference models and resources
4. **Tests last** - Test what you've specified above

This order ensures you don't reference things that aren't yet defined.

## Required Formats

Every plan element MUST include these lines. Do not omit any.

**Field**: Component (full namespace), Docs (URL), Validation, Config

**Column**: Component (full namespace), Docs (URL), Config

**Action**: Component (full namespace), Docs, Location, Visibility,
Authorization, Behavior (steps)

**Filter**: Component (full namespace), Docs (URL), Config

**Resource**: Command (for new), Location (full path), Docs

**Reactive fields**: Add `Imports:` block with
`Filament\Schemas\Components\Utilities\Get` and `Set`, use `->live()` in Config

### Why Namespaces Matter

The implementing agent uses namespaces to write correct imports. Without them,
the agent must guess or look them up, which wastes time and causes errors.

**Always include full namespaces**:

| Element        | Namespace Pattern                         |
| -------------- | ----------------------------------------- |
| Form fields    | `Filament\Forms\Components\{Component}`   |
| Table columns  | `Filament\Tables\Columns\{Column}`        |
| Table filters  | `Filament\Tables\Filters\{Filter}`        |
| Actions        | `Filament\Actions\{Action}`               |
| Infolist       | `Filament\Infolists\Components\{Entry}`   |
| Layout         | `Filament\Schemas\Components\{Component}` |
| Reactive utils | `Filament\Schemas\Components\Utilities\*` |

## New vs Update Plans

Plans either create new things or modify existing ones. Use the appropriate
format:

| Scenario        | Commands                 | Specifications                   |
| --------------- | ------------------------ | -------------------------------- |
| New resource    | Include scaffold command | Full specification               |
| Update resource | No scaffold command      | Only changes (Add/Modify/Remove) |
| New model       | Create migration         | Full attributes                  |
| Update model    | Alter migration          | Only changed attributes          |

## Required Sections

Every plan needs these sections:

### 1. Commands

List every artisan command to run before writing code. See [resources.md],
[relationships.md], [custom-pages.md], [widgets.md], [imports.md], [exports.md].

### 2. Models

Define every model with exact attributes and relationships. See [models.md].

### 3. Resources

Specify every Resource with fields, columns, and actions. See [resources.md].

### 4. Authorization

Describe who can do what for each Resource. See [authorization.md].

### 5. Widgets (if needed)

Stats, charts, or table widgets for dashboards or resource pages. See
[widgets.md].

### 6. Tests

List what to test. See [testing.md].

## File Directory

| File                 | Purpose                                |
| -------------------- | -------------------------------------- |
| [overview.md]        | Plan structure and required sections   |
| [models.md]          | Model attributes, relationships, enums |
| [resources.md]       | Resource specification format          |
| [custom-pages.md]    | Standalone pages and resource pages    |
| [forms.md]           | Form field components and validation   |
| [tables.md]          | Table columns, filters, summarizers    |
| [infolists.md]       | Infolist entries for View pages        |
| [schema-layouts.md]  | Layout components (Section, Tabs, etc) |
| [relationships.md]   | Relationship handling decisions        |
| [actions.md]         | Custom actions with modals             |
| [reactive-fields.md] | Reactive fields (Get/Set)              |
| [authorization.md]   | Policies and permissions               |
| [imports.md]         | CSV import specifications              |
| [exports.md]         | CSV/XLSX export specifications         |
| [widgets.md]         | Dashboard widgets                      |
| [testing.md]         | Test specifications                    |
| [styling.md]         | Colors and icons                       |
| [pivot-tables.md]    | Pivot table relationships              |
| [multi-tenancy.md]   | Tenant-scoped resources                |
| [bulk-actions.md]    | Bulk actions                           |
| [wizards.md]         | Multi-step forms                       |
| [checklist.md]       | Pre-submission checklist               |

## When You're Stuck

If requirements are unclear or contradictory, don't produce a partial plan.

| Situation                          | What to do                                   |
| ---------------------------------- | -------------------------------------------- |
| Requirements contradict each other | Ask user which takes priority                |
| Feature seems impossible           | Ask user if you understood correctly         |
| Multiple valid approaches          | Explain tradeoffs, ask user to choose        |
| Missing critical information       | Ask user (see "Before You Plan" above)       |
| Request is too large               | Propose splitting into phases, confirm scope |
| Existing code doesn't match plan   | Note the discrepancy, ask how to proceed     |

Don't guess on schema or authorization decisions. Better to ask than to produce
a plan the implementing agent can't use.

## Before Finalizing

**You must review [checklist.md] before submitting your plan.** It contains
critical details that make plans effective for Filament projects—missing these
causes implementation failures.
