# Relationship Specifications

> **For planning agents**: Copy all relevant information from this file into
> your plan. The implementing agent will only see your plan, not this file.
> Include full namespaces, docs URLs, and config for every component you
> specify.

Decide how to handle each relationship, then specify it precisely so the
implementing agent knows exactly what to build.

## Decision Guide

Start with relationship type, then consider which signals apply:

| Relationship  | Default approach                                           |
| ------------- | ---------------------------------------------------------- |
| belongsTo     | `Select` with `->relationship()`                           |
| belongsTo     | `ModalTableSelect` when multi-column search needed         |
| hasOne        | Inline fields or `Select`                                  |
| hasMany       | `Repeater` for few items, `RelationManager` for many       |
| belongsToMany | `Select` with `->relationship()->multiple()` (recommended) |
| belongsToMany | `ModalTableSelect` with `->multiple()` for complex search  |
| morphTo       | `MorphToSelect`                                            |

### belongsToMany: Select vs CheckboxList vs RelationManager

**Use `Select->multiple()` (recommended default):**

- Variable number of options
- Compact UI, less vertical space
- Dynamic search from backend
- Better performance with many options

**Use `CheckboxList` only when:**

- Fixed, small set of options (under ~10)
- All options should be visible at once
- No search needed

**Use `RelationManager` when:**

- Users need to interact with more than just the title
- Related records have editable fields beyond the association
- Need to view/edit pivot data (quantities, dates, etc.)

### ModalTableSelect: When to Use

Use `ModalTableSelect` instead of `Select` when:

- Users need to search/filter by multiple columns (not just title)
- Users need to see more than one field (price, SKU, status, dates)
- The related table has many records requiring pagination
- Complex filtering is needed before selection

**Important**: ModalTableSelect requires a separate table configuration class.
The table columns and filters are defined in that class, not in the field
itself.

```
Field: products
  Component: Filament\Forms\Components\ModalTableSelect
  Docs: https://filamentphp.com/docs/5.x/forms/select
  Config: ->relationship('products', 'name'), ->multiple(), ->tableConfiguration(ProductsTable::class)

Table Configuration: ProductsTable
  Location: App\Filament\Tables\ProductsTable
  Columns:
    - name (searchable)
    - sku (searchable)
    - price
    - stock_quantity
  Filters:
    - category (SelectFilter)
    - in_stock (TernaryFilter)
```

### MorphToSelect: Polymorphic Relationships

Use `MorphToSelect` for morphTo relationships:

```
Field: commentable
  Component: Filament\Forms\Components\MorphToSelect
  Docs: https://filamentphp.com/docs/5.x/forms/select
  Config: ->types([Post::class, Video::class])
```

### hasMany: Repeater vs RelationManager

**Use `Repeater` when:**

- Order matters (drag-to-reorder)
- Inline editing without modals
- Few items expected, simple fields

**Use `RelationManager` when:**

- Many items expected
- Users need search/filter/sort
- Related records have independent lifecycle

## Plan Format: Form Field

When a relationship is handled as a form field:

```
Field: user_id
  Component: Filament\Forms\Components\Select
  Docs: https://filamentphp.com/docs/5.x/forms/select
  Validation: required
  Config: ->relationship('user', 'name'), ->searchable(), ->preload()

Field: tags
  Component: Filament\Forms\Components\Select
  Docs: https://filamentphp.com/docs/5.x/forms/select
  Config: ->relationship('tags', 'name'), ->multiple(), ->searchable(), ->preload()

Field: items
  Component: Filament\Forms\Components\Repeater
  Docs: https://filamentphp.com/docs/5.x/forms/repeater
  Config: ->relationship('items'), ->collapsible()
  Schema:
    Field: product_id ...
    Field: quantity ...
```

## Plan Format: RelationManager

When a relationship needs its own table, include the scaffold command:

```
php artisan make:filament-relation-manager OrderResource items name --no-interaction
```

| Flag             | Include When                                   |
| ---------------- | ---------------------------------------------- |
| `--attach`       | belongsToMany/MorphToMany (attach/detach)      |
| `--associate`    | HasMany/MorphMany (associate/dissociate)       |
| `--generate`     | Auto-generate form/table from model columns    |
| `--soft-deletes` | Related model uses SoftDeletes trait           |
| `--view`         | Generate a view modal for the relation manager |

Then specify the RelationManager:

```
## RelationManagers

RelationManager: OrderItemsRelationManager
  Location: App\Filament\Resources\Orders\RelationManagers\ItemsRelationManager
  Relationship: items (hasMany OrderItem)
  Title attribute: name
  Can create: yes
  Can edit: yes
  Can delete: yes
  Can reorder: no

  Form:
    Field: product_id
      Component: Filament\Forms\Components\Select
      Validation: required
      Config: ->relationship('product', 'name'), ->searchable()
    Field: quantity
      Component: Filament\Forms\Components\TextInput
      Validation: required, integer, min:1
      Config: ->integer()->default(1)

  Table:
    Column: product.name
      Component: Filament\Tables\Columns\TextColumn
      Config: ->searchable()
    Column: quantity
      Component: Filament\Tables\Columns\TextColumn

  Infolist (if --view):
    Entry: product.name
      Component: Filament\Infolists\Components\TextEntry
    Entry: quantity
      Component: Filament\Infolists\Components\TextEntry
```

The Form is used for create/edit modals. The Infolist is used when `--view` flag
is included.

## Pivot Tables

See [pivot-tables.md] for detailed pivot table patterns including
`getRecordSelect()` and `tableSelect()`.

For belongsToMany, specify pivot columns:

```
Model: Order
  Relationships:
    - belongsToMany: Product via order_products
      Pivot columns: quantity, unit_price
```

## Refreshing RelationManagers

When an action on the main page (not the RelationManager) needs to refresh a
RelationManager's table, use Livewire events:

```
Action: RecalculateItems
  Behavior:
    - Update item prices
    - Dispatch 'refresh-items' event to ItemsRelationManager

RelationManager: ItemsRelationManager
  RefreshEvent: refresh-items
```

The implementing agent will:

1. Add `$this->dispatch('refresh-items')` to the action
2. Add `#[On('refresh-items')]` attribute to an empty method in the
   RelationManager

Note: If the action is on the RelationManager itself, the table refreshes
automatically—no event dispatch needed.

## Don't Write

| Bad (vague)                 | Good (specific)                          |
| --------------------------- | ---------------------------------------- |
| "Link to user"              | See Select with `->relationship()` above |
| "Show related items"        | Specify Repeater or RelationManager      |
| "Standard relation manager" | Specify exact columns and capabilities   |
