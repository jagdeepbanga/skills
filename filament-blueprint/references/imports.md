# Import Specifications

> **For planning agents**: Copy all relevant information from this file into
> your plan. The implementing agent will only see your plan, not this file.
> Include full namespaces, docs URLs, and config for every component you
> specify.

When planning CSV import functionality, include enough detail for the
implementing agent to create the Importer class without making decisions.

## What to Include

| Element        | Why the Implementing Agent Needs It       |
| -------------- | ----------------------------------------- |
| Importer class | Location and model it imports             |
| Columns        | Each `ImportColumn` with config and rules |
| Action         | Where `ImportAction` is placed            |
| Options        | Custom form fields for import options     |
| Hooks          | Side effects (notifications, logging)     |

## Command

```
php artisan make:filament-importer {Name} --no-interaction
```

| Flag         | Purpose                                |
| ------------ | -------------------------------------- |
| `--generate` | Generate columns from model attributes |

## Namespace Pattern

| Class        | Namespace                               |
| ------------ | --------------------------------------- |
| Importer     | `Filament\Actions\Imports\Importer`     |
| ImportColumn | `Filament\Actions\Imports\ImportColumn` |
| ImportAction | `Filament\Actions\ImportAction`         |

Docs: https://filamentphp.com/docs/5.x/actions/import

## Importer Plan Format

```
Importer: OrderImporter
  Location: App\Filament\Imports\OrderImporter
  Model: App\Models\Order

  Columns:
    Column: customer_name
      Config: ->requiredMapping()
      Rules: required, max:255

    Column: email
      Config: ->requiredMapping()
      Rules: required, email

    Column: status
      Config: ->guess(['order_status', 'state'])
      Rules: required, in:pending,confirmed,shipped

    Column: total
      Config: ->numeric(2)
      Rules: required, numeric, min:0

    Column: user_id
      Config: ->relationship(resolveUsing: fn (string $state): ?User => User::where('email', $state)->first())
      Rules: required

  Options Form:
    Field: notify_customers
      Component: Filament\Forms\Components\Toggle
      Config: ->default(false)

  Hooks:
    afterSave: Send notification if notify_customers option is true
```

## ImportColumn Configuration

| Method                            | Purpose                             |
| --------------------------------- | ----------------------------------- |
| `->requiredMapping()`             | Column must be mapped from CSV      |
| `->guess(['header1', 'header2'])` | Auto-match CSV headers              |
| `->rules([...])`                  | Laravel validation rules            |
| `->boolean()`                     | Cast to boolean (yes/no/true/false) |
| `->numeric(?int $decimals)`       | Cast to number with decimal places  |
| `->integer()`                     | Cast to integer                     |
| `->multiple(string $delimiter)`   | Split by delimiter into array       |
| `->relationship(resolveUsing:)`   | Resolve belongsTo by callback       |
| `->fillRecordUsing(Closure)`      | Custom logic to fill the model      |
| `->ignoreBlankState()`            | Skip if CSV cell is empty           |

## Action Plan Format

```
Action: Import Orders
  Component: Filament\Actions\ImportAction
  Docs: https://filamentphp.com/docs/5.x/actions/import
  Location: table header
  Config: ->importer(OrderImporter::class)

Action: Import (with options)
  Component: Filament\Actions\ImportAction
  Location: table header
  Config: ->importer(OrderImporter::class), ->chunkSize(100), ->maxRows(10000)
```

## Common Import Patterns

**Resolve relationship by email/code**:

```
Column: user_id
  Config: ->relationship(resolveUsing: fn (string $state): ?User => User::where('email', $state)->first())
```

**Create or update existing**:

```
Importer: ProductImporter
  Resolve Record: Find by SKU, or create new
  (Implement in resolveRecord() method)
```

**Boolean from various formats**:

```
Column: is_active
  Config: ->boolean()
  (Accepts: 1/0, true/false, yes/no, y/n, on/off)
```

## Don't Write

| Bad (vague)              | Good (specific)                             |
| ------------------------ | ------------------------------------------- |
| "Import orders from CSV" | See Importer plan format above              |
| "Map the columns"        | Specify each column with config and rules   |
| "Validate the data"      | `Rules: required, email, max:255`           |
| "Handle relationships"   | `Config: ->relationship(resolveUsing: ...)` |
