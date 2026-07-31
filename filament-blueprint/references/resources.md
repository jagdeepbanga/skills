# Resource Specifications

> **For planning agents**: Copy all relevant information from this file into
> your plan. The implementing agent will only see your plan, not this file.

Specify each Resource completely with all fields, columns, actions, and
navigation details.

## Scaffold Command

**For new resources only.** Do not include for existing resources.

```
php artisan make:filament-resource {Model} --no-interaction
```

| Flag                       | Include When                                |
| -------------------------- | ------------------------------------------- |
| `--generate`               | Auto-generate form/table from model columns |
| `--view`                   | Resource needs a View page                  |
| `--soft-deletes`           | Model uses SoftDeletes trait                |
| `--simple`                 | Modal forms instead of separate pages       |
| `--model`                  | Create the model class if it doesn't exist  |
| `--migration`              | Create a migration for the model            |
| `--factory`                | Create a factory for the model              |
| `--record-title-attribute` | Set attribute used to label records in UI   |

For updating existing resources, see the update plan format in [overview.md].

## What to Include

| Element          | Why the Implementing Agent Needs It |
| ---------------- | ----------------------------------- |
| Scaffold command | So they run it first                |
| Location         | So they know where files go         |
| Navigation       | For sidebar placement               |
| Form fields      | For create/edit pages               |
| Table columns    | For list page                       |
| Filters          | For list page filtering             |
| Actions          | For table and page actions          |

## Plan Format

```
Resource: OrderResource
  Command: php artisan make:filament-resource Order --generate --view --soft-deletes --no-interaction
  Location: App\Filament\Resources\Orders\OrderResource
  Docs: https://filamentphp.com/docs/5.x/resources/overview

  Navigation:
    Group: Shop
    Icon: Heroicon::OutlinedShoppingCart
    Sort: 1

  Form:
    Field: user_id
      Component: Filament\Forms\Components\Select
      Docs: https://filamentphp.com/docs/5.x/forms/select
      Validation: required
      Config: ->relationship('user', 'name'), ->searchable(), ->preload()

    Field: status
      Component: Filament\Forms\Components\Select
      Docs: https://filamentphp.com/docs/5.x/forms/select
      Validation: required
      Config: ->options(OrderStatus::class)

    Field: notes
      Component: Filament\Forms\Components\Textarea
      Docs: https://filamentphp.com/docs/5.x/forms/textarea
      Validation: nullable, max:1000
      Config: ->rows(4)

  Table:
    Column: id
      Component: Filament\Tables\Columns\TextColumn
      Docs: https://filamentphp.com/docs/5.x/tables/columns/text
      Config: ->sortable()

    Column: user.name
      Component: Filament\Tables\Columns\TextColumn
      Docs: https://filamentphp.com/docs/5.x/tables/columns/text
      Config: ->label('Customer'), ->searchable()

    Column: status
      Component: Filament\Tables\Columns\TextColumn
      Docs: https://filamentphp.com/docs/5.x/tables/columns/text
      Config: ->badge(), ->color(fn (string $state): string => match($state) { 'pending' => 'warning', 'confirmed' => 'success', default => 'gray' })

    Filter: status
      Component: Filament\Tables\Filters\SelectFilter
      Docs: https://filamentphp.com/docs/5.x/tables/filters/select
      Config: ->options(OrderStatus::class)

  Actions:
    Action: Approve
      Component: Filament\Actions\Action
      Docs: https://filamentphp.com/docs/5.x/actions/overview
      Location: table row
      ...
```

## Location Patterns

In Filament v5, resources are grouped under a plural folder:

| Element          | Pattern                                                                      |
| ---------------- | ---------------------------------------------------------------------------- |
| Resource         | `App\Filament\Resources\{Models}\{Model}Resource`                            |
| Pages            | `App\Filament\Resources\{Models}\Pages\{Page}`                               |
| RelationManagers | `App\Filament\Resources\{Models}\RelationManagers\{Relation}RelationManager` |
| Actions          | `App\Filament\Resources\{Models}\Actions\{Action}`                           |

Examples:

- `App\Filament\Resources\Orders\OrderResource`
- `App\Filament\Resources\Orders\Pages\CreateOrder`
- `App\Filament\Resources\Orders\RelationManagers\ItemsRelationManager`
- `App\Filament\Resources\Orders\Actions\ApproveOrderAction`

## Global Search

Resources can appear in the panel's global search. Specify in your plan:

```
Resource: OrderResource
  RecordTitleAttribute: name
  GloballySearchableAttributes: [name, email, sku]
```

The `RecordTitleAttribute` is what displays in search results. Add
`GloballySearchableAttributes` for additional searchable columns.

## View Pages

When using `--view` flag, **you MUST define an `Infolist:` section** in your
plan. Without it, the View page shows a disabled form, which looks poor.

```
Resource: OrderResource
  Command: php artisan make:filament-resource Order --view --no-interaction

  Infolist:
    Columns: 1
    Entry: customer_name
      Component: Filament\Infolists\Components\TextEntry
      Docs: https://filamentphp.com/docs/5.x/infolists/text-entry
    Entry: status
      Component: Filament\Infolists\Components\TextEntry
      Config: ->badge()
    ...
```

See [infolists.md] for entry specifications.

## Don't Write

| Bad (vague)                | Good (specific)                               |
| -------------------------- | --------------------------------------------- |
| "Create an order resource" | Full specification above                      |
| "Standard CRUD"            | Specify each field and column                 |
| "With filters"             | Specify each filter with component and config |
