# Infolist Entry Specifications

> **For planning agents**: Copy all relevant information from this file into
> your plan. The implementing agent will only see your plan, not this file.
> Include full namespaces, docs URLs, and config for every component you
> specify.

When planning infolist entries (for View pages), include enough detail that the
implementing agent can write them without looking anything up.

## Namespace Pattern

All infolist components: `Filament\Infolists\Components\{Component}`

## Entry Reference

| Data Type   | Component         | Docs URL                                                    |
| ----------- | ----------------- | ----------------------------------------------------------- |
| string/text | `TextEntry`       | https://filamentphp.com/docs/5.x/infolists/text-entry       |
| boolean     | `IconEntry`       | https://filamentphp.com/docs/5.x/infolists/icon-entry       |
| image       | `ImageEntry`      | https://filamentphp.com/docs/5.x/infolists/image-entry      |
| color       | `ColorEntry`      | https://filamentphp.com/docs/5.x/infolists/color-entry      |
| code        | `CodeEntry`       | https://filamentphp.com/docs/5.x/infolists/code-entry       |
| key-value   | `KeyValueEntry`   | https://filamentphp.com/docs/5.x/infolists/key-value-entry  |
| hasMany     | `RepeatableEntry` | https://filamentphp.com/docs/5.x/infolists/repeatable-entry |
| custom view | `ViewEntry`       | https://filamentphp.com/docs/5.x/infolists/custom-entries   |

Note: Dates, money, badges all use `TextEntry` with config methods.

**Enum entries**: Same as tables—enum can implement `HasLabel` (required),
`HasColor` and `HasIcon` (optional) from `Filament\Support\Contracts` for
automatic badge styling.

## Plan Format

```
Entry: status
  Component: Filament\Infolists\Components\TextEntry
  Docs: https://filamentphp.com/docs/5.x/infolists/text-entry
  Config: ->badge(), ->color(fn (string $state): string => match($state) { 'pending' => 'warning', 'confirmed' => 'success', default => 'gray' })

Entry: created_at
  Component: Filament\Infolists\Components\TextEntry
  Docs: https://filamentphp.com/docs/5.x/infolists/text-entry
  Config: ->dateTime()

Entry: is_active
  Component: Filament\Infolists\Components\IconEntry
  Docs: https://filamentphp.com/docs/5.x/infolists/icon-entry
  Config: ->boolean()
```

## Layout

See [schema-layouts.md] for complete layout component specifications including
Section, Tabs, Grid, Split, and configuration options.

Layout components use namespace: `Filament\Schemas\Components\{Component}`

### Column Configuration

Infolists default to 2 columns. **If you want single-column layout, you MUST
specify `Columns: 1` in your plan.** The implementing agent will use
`$schema->columns(1)`.

```
Infolist:
  Columns: 1

  Section: Customer Details
    ColumnSpan: full
    Entries:
      Entry: name ...
      Entry: email ...
```

### Nested Column Width

**Critical**: Column settings multiply through nesting. Calculate effective
entry width before specifying columns.

| Infolist Columns | Section Columns | Effective Entry Width | Result     |
| ---------------- | --------------- | --------------------- | ---------- |
| 2                | 1 (default)     | 50%                   | OK         |
| 2                | 2               | 25%                   | Too narrow |
| 1                | 2               | 50%                   | OK         |
| 1                | 1               | 100%                  | Full width |

**Rule**: If your infolist has 2 columns, sections should NOT also specify 2
columns—entries become too narrow (25% width). Either:

- Use `Infolist Columns: 1` with `Section Columns: 2`
- Use `Infolist Columns: 2` with sections at default (no columns specified)
- Use `ColumnSpan: full` on sections to break out of the parent grid

## Don't Write

| Bad (vague)          | Good (specific)        |
| -------------------- | ---------------------- |
| "Show the status"    | See plan format above  |
| "Display as a badge" | `Config: ->badge()`    |
| "Format as date"     | `Config: ->dateTime()` |
