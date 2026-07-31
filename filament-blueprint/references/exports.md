# Export Specifications

> **For planning agents**: Copy all relevant information from this file into
> your plan. The implementing agent will only see your plan, not this file.
> Include full namespaces, docs URLs, and config for every component you
> specify.

When planning CSV/XLSX export functionality, include enough detail for the
implementing agent to create the Exporter class without making decisions.

## What to Include

| Element        | Why the Implementing Agent Needs It       |
| -------------- | ----------------------------------------- |
| Exporter class | Location and model it exports             |
| Columns        | Each `ExportColumn` with formatting       |
| Action         | Where action is placed (header or bulk)   |
| Formats        | CSV, XLSX, or both                        |
| Query          | Any filtering/scoping of exported records |

## Command

```
php artisan make:filament-exporter {Name} --no-interaction
```

| Flag         | Purpose                                |
| ------------ | -------------------------------------- |
| `--generate` | Generate columns from model attributes |

## Namespace Pattern

| Class            | Namespace                                     |
| ---------------- | --------------------------------------------- |
| Exporter         | `Filament\Actions\Exports\Exporter`           |
| ExportColumn     | `Filament\Actions\Exports\ExportColumn`       |
| ExportAction     | `Filament\Actions\ExportAction`               |
| ExportBulkAction | `Filament\Actions\ExportBulkAction`           |
| ExportFormat     | `Filament\Actions\Exports\Enums\ExportFormat` |

Docs: https://filamentphp.com/docs/5.x/actions/export

## Exporter Plan Format

```
Exporter: OrderExporter
  Location: App\Filament\Exports\OrderExporter
  Model: App\Models\Order

  Columns:
    Column: id
      Label: Order ID

    Column: customer_name

    Column: email

    Column: status
      Config: ->formatStateUsing(fn (string $state): string => ucfirst($state))

    Column: total
      Config: ->formatStateUsing(fn (int $state): string => '$' . number_format($state / 100, 2))

    Column: created_at
      Config: ->formatStateUsing(fn (\Carbon\Carbon $state): string => $state->format('Y-m-d H:i'))

    Column: user.name
      Label: Assigned To

  Formats: CSV, XLSX

  Query Modification:
    - Exclude cancelled orders
    - Order by created_at desc
```

## ExportColumn Configuration

| Method                        | Purpose                             |
| ----------------------------- | ----------------------------------- |
| `->label(string)`             | Column header in export file        |
| `->formatStateUsing(Closure)` | Transform value for export          |
| `->enabledByDefault(bool)`    | Include in default column selection |
| `->state(Closure)`            | Compute custom value                |

## Action Plan Format

**Header action (export all/filtered)**:

```
Action: Export Orders
  Component: Filament\Actions\ExportAction
  Docs: https://filamentphp.com/docs/5.x/actions/export
  Location: table header
  Config: ->exporter(OrderExporter::class)
```

**With format options**:

```
Action: Export Orders
  Component: Filament\Actions\ExportAction
  Location: table header
  Config: ->exporter(OrderExporter::class), ->formats([ExportFormat::Csv, ExportFormat::Xlsx])
```

**Bulk action (export selected)**:

```
Action: Export Selected
  Component: Filament\Actions\ExportBulkAction
  Docs: https://filamentphp.com/docs/5.x/actions/export
  Location: bulk (in BulkActionGroup)
  Config: ->exporter(OrderExporter::class)
```

## Common Export Patterns

**Format money**:

```
Column: total
  Config: ->formatStateUsing(fn (int $state): string => '$' . number_format($state / 100, 2))
```

**Format dates**:

```
Column: created_at
  Config: ->formatStateUsing(fn (?\Carbon\Carbon $state): ?string => $state?->format('Y-m-d'))
```

**Related model attribute**:

```
Column: user.name
  Label: Customer Name
```

**Computed column**:

```
Column: full_address
  Config: ->state(fn (Order $record): string => "{$record->street}, {$record->city}, {$record->zip}")
```

**Boolean to text**:

```
Column: is_active
  Config: ->formatStateUsing(fn (bool $state): string => $state ? 'Yes' : 'No')
```

## Don't Write

| Bad (vague)                | Good (specific)                                                                     |
| -------------------------- | ----------------------------------------------------------------------------------- |
| "Export orders to CSV"     | See Exporter plan format above                                                      |
| "Include relevant columns" | List each column with formatting                                                    |
| "Format the dates"         | `->formatStateUsing(fn (\Carbon\Carbon $state): string => $state->format('Y-m-d'))` |
| "Add export button"        | Specify ExportAction or ExportBulkAction                                            |
