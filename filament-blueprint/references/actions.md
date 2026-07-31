# Action Specifications

> **For planning agents**: Copy all relevant information from this file into
> your plan. The implementing agent will only see your plan, not this file.
> Include full namespaces, docs URLs, and config for every component you
> specify.

When planning custom actions, include enough detail that the implementing agent
can write them without making decisions.

## Namespace

All actions use: `Filament\Actions\Action`

In Filament v5, all action classes are in the `Filament\Actions` namespace:

| Action Type        | Namespace                            |
| ------------------ | ------------------------------------ |
| Custom action      | `Filament\Actions\Action`            |
| Custom bulk action | `Filament\Actions\BulkAction`        |
| Delete             | `Filament\Actions\DeleteAction`      |
| DeleteBulkAction   | `Filament\Actions\DeleteBulkAction`  |
| Create             | `Filament\Actions\CreateAction`      |
| Edit               | `Filament\Actions\EditAction`        |
| View               | `Filament\Actions\ViewAction`        |
| Restore            | `Filament\Actions\RestoreAction`     |
| ForceDelete        | `Filament\Actions\ForceDeleteAction` |
| Replicate          | `Filament\Actions\ReplicateAction`   |

Docs: https://filamentphp.com/docs/5.x/actions/overview

For colors and icons, see [styling.md].

**Which location to use**:

- Row: Single record actions (approve, view, duplicate) - needs access to
  `$record`
- Bulk: Multiple record actions (delete many, export selected) - works on 1-N
  selected records
- Header: Not tied to records (create, import, generate report) - global
  operations

## Grouping Actions

When a table row or page header has more than 3 actions, group them into an
`ActionGroup` to save horizontal space:

```
Actions:
  ActionGroup:
    Component: Filament\Actions\ActionGroup
    Docs: https://filamentphp.com/docs/5.x/actions/grouping-actions
    Location: table row
    Icon: Heroicon::EllipsisVertical
    Actions:
      Action: Duplicate ...
      Action: Archive ...
      Action: Delete ...
```

## Plan Format

```
Action: Approve
  Component: Filament\Actions\Action
  Docs: https://filamentphp.com/docs/5.x/actions/overview
  Location: table row
  Icon: Heroicon::Check
  Color: success
  Visibility: only when status is 'pending'
  Authorization: user has 'approve orders' permission
  Confirmation: "Are you sure you want to approve this order?"
  Behavior:
    - Set status to 'confirmed'
    - Set confirmed_at to now
    - Send confirmation email to customer
  Notification: "Order approved successfully"

Action: Export
  Component: Filament\Actions\Action
  Docs: https://filamentphp.com/docs/5.x/actions/overview
  Location: page header
  Icon: Heroicon::ArrowDownTray
  Authorization: user has 'export orders' permission
  Behavior:
    - Generate CSV of all visible orders
    - Download file

Action: Delete Selected
  Component: Filament\Actions\BulkAction
  Docs: https://filamentphp.com/docs/5.x/actions/overview
  Location: bulk
```

## Actions with Modal Forms

When an action needs user input, add a Modal section with form fields:

```
Action: Ship Order
  Component: Filament\Actions\Action
  Docs: https://filamentphp.com/docs/5.x/actions/modals
  Location: table row
  Icon: Heroicon::Truck
  Color: success
  Visibility: only when status is 'confirmed'

  Modal:
    Heading: Ship Order
    Description: Enter shipping details

    Field: tracking_number
      Component: Filament\Forms\Components\TextInput
      Validation: required, max:100

    Field: carrier
      Component: Filament\Forms\Components\Select
      Validation: required
      Config: ->options(['ups' => 'UPS', 'fedex' => 'FedEx', 'usps' => 'USPS'])

    FillFrom: (optional) pre-fill from record
      - carrier: $record->preferred_carrier

  Behavior:
    - Set status to 'shipped'
    - Set shipped_at to now
    - Save tracking_number and carrier from form data
    - Send shipping notification email
```

## Modal Configuration

| Element      | Purpose                              |
| ------------ | ------------------------------------ |
| Heading      | Modal title                          |
| Description  | Explanatory text below heading       |
| SubmitLabel  | Custom submit button text            |
| FillFrom     | Pre-populate form fields from record |
| Field: ...   | Form fields (see [forms.md])         |
| Confirmation | Simple yes/no confirmation (no form) |

## Extracting Actions to Separate Files

When actions are complex enough to warrant their own file, use a static `make()`
method:

```
Action: ApproveOrderAction
  Location: App\Filament\Resources\Orders\Actions\ApproveOrderAction
  Pattern: static function make(): Action
```

The implementing agent should create:

> **Pattern Reference**: This shows what the implementing agent will produce.
> Include the Location in your plan so they create the file correctly.

```php
class ApproveOrderAction
{
    public static function make(): Action
    {
        return Action::make('approve')
            // ... configuration
    }
}
```

Do not use `setUp()` or extend Action classes. Use
`static function make(): Action`.

## Don't Write

| Bad (vague)             | Good (specific)                                       |
| ----------------------- | ----------------------------------------------------- |
| "Add an approve action" | See plan format above                                 |
| "Process the order"     | List exact behavior steps                             |
| "Show when appropriate" | `Visibility: only when status is 'pending'`           |
| "Check permissions"     | `Authorization: user has 'approve orders' permission` |
| "Notify the user"       | `Notification: "Order approved successfully"`         |
