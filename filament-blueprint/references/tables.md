# Table Column Specifications

> **For planning agents**: Copy all relevant information from this file into
> your plan. The implementing agent will only see your plan, not this file.
> Include full namespaces, docs URLs, and config for every component you
> specify.

When planning table columns and filters, include enough detail that the
implementing agent can write them without looking anything up.

## Namespace Patterns

Columns: `Filament\Tables\Columns\{Column}` Filters:
`Filament\Tables\Filters\{Filter}`

## Column Reference

| Data Type          | Component         | Docs URL                                                   |
| ------------------ | ----------------- | ---------------------------------------------------------- |
| string/text        | `TextColumn`      | https://filamentphp.com/docs/5.x/tables/columns/text       |
| boolean            | `IconColumn`      | https://filamentphp.com/docs/5.x/tables/columns/icon       |
| boolean (editable) | `ToggleColumn`    | https://filamentphp.com/docs/5.x/tables/columns/toggle     |
| image              | `ImageColumn`     | https://filamentphp.com/docs/5.x/tables/columns/image      |
| color              | `ColorColumn`     | https://filamentphp.com/docs/5.x/tables/columns/color      |
| checkbox (edit)    | `CheckboxColumn`  | https://filamentphp.com/docs/5.x/tables/columns/checkbox   |
| select (edit)      | `SelectColumn`    | https://filamentphp.com/docs/5.x/tables/columns/select     |
| text (edit)        | `TextInputColumn` | https://filamentphp.com/docs/5.x/tables/columns/text-input |

Note: Dates, money, badges all use `TextColumn` with config methods.

**IconColumn for booleans**: Use `->boolean()` to display true/false as icons.

**TextColumn config by data type**:

- Short text: (none)
- Long text: `->limit(50)`
- Status/enum: `->badge()`
- Date: `->date(), ->sortable()` (dates should always be sortable)
- DateTime: `->dateTime(), ->sortable()`
- Money: `->money('usd'), ->sortable()`
- Integer: `->numeric(0), ->sortable()` (0 decimal places)
- Decimal: `->numeric(2), ->sortable()` (specify decimal places)

**Enum columns**: For enum columns with `->badge()`, the enum can implement
interfaces from `Filament\Support\Contracts`:

- `HasLabel` (required) - displays human-readable text
- `HasColor` (optional) - automatic badge color
- `HasIcon` (optional) - automatic badge icon

No manual color/icon config needed if enum implements these interfaces.

## Plan Format

```
Column: id
  Component: Filament\Tables\Columns\TextColumn
  Docs: https://filamentphp.com/docs/5.x/tables/columns/text
  Config: ->sortable()

Column: status
  Component: Filament\Tables\Columns\TextColumn
  Docs: https://filamentphp.com/docs/5.x/tables/columns/text
  Config: ->badge(), ->color(fn (string $state): string => match($state) { 'pending' => 'warning', 'confirmed' => 'success', default => 'gray' })

Column: created_at
  Component: Filament\Tables\Columns\TextColumn
  Docs: https://filamentphp.com/docs/5.x/tables/columns/text
  Config: ->dateTime(), ->sortable()

Column: user.name
  Component: Filament\Tables\Columns\TextColumn
  Docs: https://filamentphp.com/docs/5.x/tables/columns/text
  Config: ->label('Customer'), ->searchable()
```

## Filter Reference

| Purpose      | Component       | Docs URL                                                |
| ------------ | --------------- | ------------------------------------------------------- |
| Boolean      | `Filter`        | https://filamentphp.com/docs/5.x/tables/filters/custom  |
| Custom       | `Filter`        | https://filamentphp.com/docs/5.x/tables/filters/custom  |
| Dropdown     | `SelectFilter`  | https://filamentphp.com/docs/5.x/tables/filters/select  |
| Yes/No/All   | `TernaryFilter` | https://filamentphp.com/docs/5.x/tables/filters/ternary |
| Soft deletes | `TrashedFilter` | https://filamentphp.com/docs/5.x/tables/filters/ternary |

## Filter Plan Format

```
Filter: status
  Component: Filament\Tables\Filters\SelectFilter
  Docs: https://filamentphp.com/docs/5.x/tables/filters/select
  Config: ->options(OrderStatus::class), ->multiple()

Filter: is_active
  Component: Filament\Tables\Filters\Filter
  Docs: https://filamentphp.com/docs/5.x/tables/filters/custom
  Config: ->query(fn (Builder $query): Builder => $query->where('is_active', true))

Filter: created_from (custom with form field)
  Component: Filament\Tables\Filters\Filter
  Docs: https://filamentphp.com/docs/5.x/tables/filters/custom
  Form: DatePicker::make('created_from')
  Config: ->query(fn (Builder $query, array $data): Builder => $query->when($data['created_from'], fn (Builder $query, string $date): Builder => $query->whereDate('created_at', '>=', $date)))

Filter: trashed
  Component: Filament\Tables\Filters\TrashedFilter
  Docs: https://filamentphp.com/docs/5.x/tables/filters/ternary
```

## Summarizers

Add footer aggregations to columns. Namespace:
`Filament\Tables\Columns\Summarizers\{Summarizer}`

| Aggregation | Component | Config Example                 |
| ----------- | --------- | ------------------------------ |
| Sum         | `Sum`     | `->summarize(Sum::make())`     |
| Average     | `Average` | `->summarize(Average::make())` |
| Count       | `Count`   | `->summarize(Count::make())`   |
| Range       | `Range`   | `->summarize(Range::make())`   |

```
Column: total
  Component: Filament\Tables\Columns\TextColumn
  Docs: https://filamentphp.com/docs/5.x/tables/columns/text
  Config: ->money('usd'), ->sortable(), ->summarize(Sum::make()->money('usd'))
```

## Don't Write

| Bad (vague)                  | Good (specific)                                                 |
| ---------------------------- | --------------------------------------------------------------- |
| "Show the status as a badge" | `Config: ->badge(), ->color(fn (string $state): string => ...)` |
| "Make it sortable"           | `Config: ->sortable()`                                          |
| "Add a status filter"        | See filter plan format above                                    |

## Grouping

Group table rows by a common attribute. Docs:
https://filamentphp.com/docs/5.x/tables/grouping

```
Table:
  Grouping:
    Default: status
    Options: [status, category, author.name]
    Collapsible: true
```

For relationship grouping, use dot notation: `author.name`

## Toolbar Actions

Actions can be placed in the table header or toolbar. Important: in v5, bulk
actions are registered inside `toolbarActions()` (there is no separate
`bulkActions()` method). Setting `toolbarActions()` replaces the defaults, so
include your bulk actions there, wrapped in a `BulkActionGroup`:

```
Table Actions:
  Toolbar:
    - CreateAction
    - ExportAction
    - BulkActionGroup containing:
      - DeleteBulkAction
      - Other bulk actions...
```

Always specify bulk actions inside a `BulkActionGroup` when using
`toolbarActions()`. See [bulk-actions.md] for custom bulk action details.

## Colors and Icons

See [styling.md] for available colors and Heroicon usage.
