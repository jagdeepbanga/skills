# Schema Layout Specifications

> **For planning agents**: Copy all relevant information from this file into
> your plan. The implementing agent will only see your plan, not this file.
> Include full namespaces, docs URLs, and config for every component you
> specify.

Layout components are shared between forms and infolists. They control how
fields/entries are grouped and arranged.

## Namespace Pattern

All schema components: `Filament\Schemas\Components\{Component}`

## Layout Components

| Component  | Purpose                    | Docs URL                                          |
| ---------- | -------------------------- | ------------------------------------------------- |
| `Section`  | Grouped fields with header | https://filamentphp.com/docs/5.x/schemas/sections |
| `Fieldset` | Fieldset with legend       | https://filamentphp.com/docs/5.x/schemas/layouts  |
| `Tabs`     | Tabbed sections            | https://filamentphp.com/docs/5.x/schemas/tabs     |
| `Grid`     | Custom grid layout         | https://filamentphp.com/docs/5.x/schemas/layouts  |
| `Flex`     | Flexible width layout      | https://filamentphp.com/docs/5.x/schemas/layouts  |

For multi-step forms with validation gates, see [wizards.md].

## When to Use Each Layout

| Scenario                                 | Component  |
| ---------------------------------------- | ---------- |
| Logical grouping, all fields visible     | `Section`  |
| Simple fieldset with legend              | `Fieldset` |
| Many fields, distinct categories         | `Tabs`     |
| Explicit grid with no styling            | `Grid`     |
| Main content + sidebar (flexible widths) | `Flex`     |

**Guidelines** (not rules):

- `Section`: Use when form fits on screen and users need to see all fields
- `Tabs`: Use when there are distinct categories users may navigate between
- `Flex`: Use for sidebar layouts where one section grows and another stays
  fixed

Field count alone doesn't determine layout. Consider: Are there natural
groupings? Do users fill sections independently? Is there a workflow order?

## Plan Format

```
Form:
  Columns: 2

  Section: Customer Details
    Component: Filament\Schemas\Components\Section
    Docs: https://filamentphp.com/docs/5.x/schemas/sections
    ColumnSpan: full
    Columns: 2
    Icon: Heroicon::User
    Collapsible: yes
    Fields:
      Field: first_name ...
      Field: last_name ...

  Section: Order Items
    Component: Filament\Schemas\Components\Section
    Docs: https://filamentphp.com/docs/5.x/schemas/sections
    ColumnSpan: full
    Fields:
      Field: items ...
```

### Tabs Format

```
Form:
  Tabs:
    Component: Filament\Schemas\Components\Tabs
    Docs: https://filamentphp.com/docs/5.x/schemas/tabs

    Tab: Details
      Icon: Heroicon::InformationCircle
      Fields:
        Field: name ...
        Field: description ...

    Tab: Pricing
      Icon: Heroicon::CurrencyDollar
      Fields:
        Field: price ...
        Field: cost ...

    Tab: Inventory
      Icon: Heroicon::CubeTransparent
      Badge: count of variants
      Fields:
        Field: sku ...
        Field: quantity ...
```

### Flex Format (Sidebar Layout)

Use `Flex` for layouts where one section grows to fill space and another stays
fixed width (like a sidebar):

```
Form:
  Flex:
    Component: Filament\Schemas\Components\Flex
    Docs: https://filamentphp.com/docs/5.x/schemas/layouts
    Config: ->from('md')

    Section: Details (grows)
      Fields:
        Field: title ...
        Field: content ...

    Section: Meta (fixed width)
      Config: ->grow(false)
      Fields:
        Field: status ...
        Field: published_at ...
```

The `->from('md')` makes it stack on small screens and go side-by-side on
medium+.

## Column Configuration

Forms and infolists default to 2 columns. **If you want single-column layout,
you MUST specify `Columns: 1` in your plan.** The implementing agent will use
`$schema->columns(1)`.

```
Form:
  Columns: 1
  ...
```

### Field/Entry Column Span

Individual fields can span multiple columns:

```
Field: description
  Component: Filament\Forms\Components\Textarea
  Config: ->columnSpan(2)      ← Spans both columns in a 2-column form

Field: notes
  Component: Filament\Forms\Components\Textarea
  Config: ->columnSpanFull()   ← Spans all columns regardless of count
```

### Nested Column Width

**Critical**: Column settings multiply through nesting. Calculate effective
width before specifying columns.

| Parent Columns | Section Columns | Effective Width | Result     |
| -------------- | --------------- | --------------- | ---------- |
| 2              | 1 (default)     | 50%             | OK         |
| 2              | 2               | 25%             | Too narrow |
| 1              | 2               | 50%             | OK         |
| 1              | 1               | 100%            | Full width |
| 2              | 1, field span 2 | 100%            | Full width |

**Rule**: If your form/infolist has 2 columns, sections should NOT also specify
2 columns—fields become too narrow (25% width). Either:

- Use `Columns: 1` at parent level with `Section Columns: 2`
- Use `Columns: 2` at parent level with sections at default (no columns)
- Use `ColumnSpan: full` on sections to break out of the parent grid

### Breaking Out of Parent Grid

When a section needs its own column layout independent of the parent:

```
Form:
  Columns: 2

  Section: Basic Info
    ColumnSpan: full      ← Section spans both form columns
    Columns: 2            ← Now safe to use 2 columns (50% effective width)
    Fields:
      Field: first_name ...
      Field: last_name ...

  Section: Full-width Content
    ColumnSpan: full
    Columns: 1            ← Single column for wide fields
    Fields:
      Field: description ...
```

## Section Configuration

| Config             | Purpose                          |
| ------------------ | -------------------------------- |
| `Columns: N`       | Number of columns within section |
| `ColumnSpan: full` | Span all parent columns          |
| `Icon: Heroicon::` | Icon in section header           |
| `Collapsible: yes` | Can be collapsed                 |
| `Collapsed: yes`   | Starts collapsed                 |
| `Aside: yes`       | Render as sidebar card           |
| `Compact: yes`     | Reduced padding                  |

## Don't Write

| Bad (vague)           | Good (specific)                            |
| --------------------- | ------------------------------------------ |
| "Group the fields"    | `Section: Customer Details` with fields    |
| "Use tabs"            | Full Tabs specification with Tab names     |
| "Make it collapsible" | `Collapsible: yes`                         |
| "Two columns"         | `Columns: 2` at correct nesting level      |
| "Full width"          | `ColumnSpan: full` or `->columnSpanFull()` |
| "Sidebar layout"      | `Flex` with `->grow(false)` on sidebar     |
