# Pivot Table Relationships

> **For planning agents**: Copy the non-obvious details into your plan. Agents
> commonly miss `getRecordSelect()` and the requirement for `withPivot()` on
> both sides.

Docs: https://filamentphp.com/docs/5.x/resources/managing-relationships

## Scaffolding

Use `--attach` for belongsToMany relationships:

```
Command: php artisan make:filament-relation-manager OrderResource products name --attach --no-interaction
```

This adds `AttachAction`, `DetachAction`, and `DetachBulkAction` automatically.

## Model Setup

**Critical**: `withPivot()` must be on BOTH sides of the relationship with
identical columns:

```
Model: Order
  Relationship: belongsToMany(Product::class)->withPivot(['quantity', 'price'])->withTimestamps()

Model: Product
  Relationship: belongsToMany(Order::class)->withPivot(['quantity', 'price'])->withTimestamps()
```

## AttachAction with Pivot Fields

Use `getRecordSelect()` to get the built-in select, then add pivot fields:

```
RelationManager: ProductsRelationManager
  AttachAction:
    Schema: function (AttachAction $action): array {
        return [
            $action->getRecordSelect(),
            // Additional fields save to pivot automatically
            Field: quantity
            Field: price
        ];
    }
```

## Customizing the Record Select

```
AttachAction Config:
  ->preloadRecordSelect()
  ->recordSelectOptionsQuery(function (Builder $query): Builder {
      return $query->where('active', true);
  })
  ->recordSelectSearchColumns(['name', 'sku'])
  ->multiple()
  ->recordSelect(function (Select $select): Select {
      return $select->placeholder('Select a product');
  })
```

## Modal Table Selection

Replace the dropdown with a full table interface:

```
AttachAction:
  Config: ->tableSelect(ProductsTable::class)
  Note: ProductsTable class must have static configure() method
```

## Displaying Pivot Columns

Pivot columns work like normal columns if they're in `withPivot()`:

```
Table Columns:
  Column: name
  Column: quantity    // Just works - from pivot
  Column: price       // Just works - from pivot
```

## Non-Standard Relationship Names

If your inverse relationship doesn't follow conventions, set on the table:

```
RelationManager:
  Table Config: $table->inverseRelationship('section')
```

## Common Mistakes

- Only adding `withPivot()` to one side (must be BOTH)
- Forgetting `->withTimestamps()` when pivot has timestamps
- Not using `getRecordSelect()` in AttachAction schema
- Using `$record->quantity` instead of `$record->pivot->quantity` in custom
  column state closures
- Setting inverseRelationship on the wrong place (it goes on `$table`)
