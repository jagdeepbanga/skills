# Bulk Actions

> **For planning agents**: Copy the non-obvious details into your plan. Agents
> commonly miss authorization patterns and memory optimization.

Docs: https://filamentphp.com/docs/5.x/actions/overview

## Structure

Custom bulk actions use `Filament\Actions\BulkAction` and must be inside a
`Filament\Actions\BulkActionGroup`:

```
Table Actions:
  Toolbar:
    - CreateAction
    - BulkActionGroup containing:
        - DeleteBulkAction
        - Custom: ChangeStatusBulkAction
```

## Authorization: deleteAny vs delete

By default, bulk actions use `{ability}Any` policy methods for performance (one
check instead of N checks):

| Action      | Default Policy     | Per-Record Policy                             |
| ----------- | ------------------ | --------------------------------------------- |
| Delete      | `deleteAny()`      | `->authorizeIndividualRecords('delete')`      |
| ForceDelete | `forceDeleteAny()` | `->authorizeIndividualRecords('forceDelete')` |
| Restore     | `restoreAny()`     | `->authorizeIndividualRecords('restore')`     |

Use `authorizeIndividualRecords()` only when permissions vary per record.

## Memory Optimization

Filament loads all selected records into memory by default for:

1. Individual policy authorization
2. Model event firing (deleting, deleted, etc.)

**For large datasets**, use chunking:

```
Action: Archive Orders (bulk)
  Config: ->chunkSelectedRecords(250)
```

**If you don't need authorization or events**, skip fetching entirely:

```
Action: Export Selected (bulk)
  Config: ->fetchSelectedRecords(false)
  Note: Action receives array of IDs instead of Collection
```

## Common Config

```
Action: Change Status (bulk)
  Component: Filament\Actions\BulkAction
  Config:
    ->requiresConfirmation()
    ->deselectRecordsAfterCompletion()
    ->chunkSelectedRecords(250)
    ->successNotificationTitle(function (Illuminate\Support\Collection $selectedRecords): string {
        return $selectedRecords->count() . ' orders updated';
    })
```

## Testing Bulk Actions

```
Tests:
  Pattern: selectTableRecords($records)
           ->callAction(TestAction::make(DeleteBulkAction::class)->table()->bulk())
           ->assertNotified()
  Note: Use TestAction with ->table()->bulk() for bulk action context
```

## Common Mistakes

- Putting bulk actions outside BulkActionGroup
- Using `delete()` policy instead of `deleteAny()` for performance
- Loading all records when only IDs needed (use `->fetchSelectedRecords(false)`)
- Forgetting `->deselectRecordsAfterCompletion()`
- Not chunking large datasets
