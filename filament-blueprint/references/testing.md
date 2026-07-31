# Test Specifications

> **For planning agents**: Copy relevant test scenarios into your plan. The
> implementing agent will only see your plan, not this file. List specific test
> cases for authorization, validation, and custom actions.

Docs: https://filamentphp.com/docs/5.x/testing/overview

List what to test so the implementing agent writes the right test cases.

## What to Include

| Category         | Why Worth Testing               |
| ---------------- | ------------------------------- |
| Authorization    | Prevents security issues        |
| Validation       | Prevents bad data               |
| Component config | Verifies fields/columns/actions |
| Custom actions   | Custom logic can break          |
| Filters          | Query logic can break           |
| RelationManagers | Relationship logic              |

## Plan Format

```
## Tests

OrderResource:
  Authorization:
    - users without 'view orders' permission cannot access list page
    - users can only see orders where user_id matches their id
    - users with 'view all orders' permission can see all orders
    - approve action is hidden for non-pending orders

  Validation (use dataset pattern):
    - name is required
    - name max 255 characters
    - email is required
    - email must be valid email format
    - email max 255 characters
    - status must be valid enum value

  Component Config:
    - status field is disabled when order is shipped
    - total column is sortable and displays as money
    - approve action has success color and check icon

  Actions:
    - approve action sets status to 'confirmed'
    - approve action sets confirmed_at to current time
    - approve action is only visible when status is 'pending'
    - ship action requires tracking_number to be set

  Filters:
    - status filter shows only orders with selected status
    - trashed filter shows soft-deleted orders

  Sorting:
    - can sort by created_at
    - can sort by total

  RelationManagers:
    - OrderItemsRelationManager renders with correct records
    - can create order item through relation manager
```

## Validation Testing with Datasets

When multiple validation rules need testing, use the Pest dataset pattern to
avoid repetitive test code. This is especially useful for create/edit forms.

Plan format for dataset validation:

```
Validation (use dataset pattern):
  - name: required, max:255
  - email: required, email, max:255
  - status: required, in:pending,confirmed,shipped
```

The implementing agent will write a single test with a dataset:

> **Pattern Reference**: This shows the test syntax the implementing agent will
> use. Include test descriptions in your plan; they handle the assertions.

```php
it('validates the form data', function (array $data, array $errors) {
    $newUserData = User::factory()->make();

    livewire(CreateUser::class)
        ->fillForm([
            'name' => $newUserData->name,
            'email' => $newUserData->email,
            ...$data,
        ])
        ->call('create')
        ->assertHasFormErrors($errors)
        ->assertNotNotified()
        ->assertNoRedirect();
})->with([
    '`name` is required' => [['name' => null], ['name' => 'required']],
    '`name` is max 255 characters' => [['name' => Str::random(256)], ['name' => 'max']],
    '`email` is a valid email address' => [['email' => Str::random()], ['email' => 'email']],
    '`email` is required' => [['email' => null], ['email' => 'required']],
    '`email` is max 255 characters' => [['email' => Str::random(256)], ['email' => 'max']],
]);
```

## Testing Methods Reference

### Component Existence Testing (Most Powerful)

Use existence assertions with callbacks to test **any configuration** on any
component. The callback receives the component instance and returns `true` if
correct.

**`assertSchemaComponentExists`** - works for forms, infolists, sections, any
schema component:

> **Pattern Reference**: These examples show the testing syntax. Include test
> descriptions in your plan; the implementing agent handles assertions.

```php
// Form field config
->assertSchemaComponentExists('status', checkComponentUsing: function (Select $field): bool {
    return $field->isDisabled() && $field->getLabel() === 'Order Status';
})

// Section config
->assertSchemaComponentExists('details', checkComponentUsing: function (Section $section): bool {
    return $section->isCollapsible();
})
```

**`assertTableColumnExists`** - for table columns:

```php
->assertTableColumnExists('total', function (TextColumn $column): bool {
    return $column->isSortable() && $column->isMoney();
}, $record)
```

**`assertActionExists`** - for actions:

```php
->assertActionExists('approve', function (Action $action): bool {
    return $action->getColor() === 'success';
})
```

### Resource Pages

| Test               | Method                                       |
| ------------------ | -------------------------------------------- |
| Page loads         | `->assertOk()`                               |
| Records visible    | `->assertCanSeeTableRecords($records)`       |
| Records hidden     | `->assertCanNotSeeTableRecords($records)`    |
| Record count       | `->assertCountTableRecords(4)`               |
| Form state         | `->assertSchemaStateSet(['field' => 'val'])` |
| Notification shown | `->assertNotified()`                         |
| Redirect occurred  | `->assertRedirect()`                         |
| No redirect        | `->assertNoRedirect()`                       |

### Table Testing

| Test           | Method                                                 |
| -------------- | ------------------------------------------------------ |
| Search         | `->searchTable('query')`                               |
| Sort           | `->sortTable('column')` or `->sortTable('col','desc')` |
| Filter         | `->filterTable('name', $value)`                        |
| Select records | `->selectTableRecords($records)`                       |

### Action Testing

| Test           | Method                                                   |
| -------------- | -------------------------------------------------------- |
| Call action    | `->callAction('name')` or `->callAction(Action::class)`  |
| Call with data | `->callAction('name', data: ['field' => $val])`          |
| Table action   | `->callAction(TestAction::make('name')->table($record))` |
| Action visible | `->assertActionVisible('name')`                          |
| Action hidden  | `->assertActionHidden('name')`                           |

### Validation Testing

| Test         | Method                                       |
| ------------ | -------------------------------------------- |
| Has errors   | `->assertHasFormErrors(['field' => 'rule'])` |
| No errors    | `->assertHasNoFormErrors()`                  |
| Not notified | `->assertNotNotified()`                      |

### RelationManager Testing

> **Pattern Reference**: The implementing agent will use this pattern.

```
livewire(PostsRelationManager::class, [
    'ownerRecord' => $user,
    'pageClass' => EditUser::class,
])
    ->assertOk()
    ->assertCanSeeTableRecords($user->posts);
```

### Repeater Testing

Repeaters generate UUIDs internally, which breaks tests. Use `Repeater::fake()`
to replace UUIDs with numeric keys:

> **Pattern Reference**: These patterns are essential for repeater testing.
> Include repeater test scenarios in your plan; they need to know about UUIDs.

```php
$undoRepeaterFake = Repeater::fake();

livewire(EditPost::class, ['record' => $post])
    ->assertSchemaStateSet([
        'quotes' => [
            ['content' => 'First quote'],
            ['content' => 'Second quote'],
        ],
    ]);

$undoRepeaterFake();
```

For repeater actions on specific items, pass `item` with the key. For
relationship repeaters, prefix record ID with `record-`:

```php
->callAction(TestAction::make('delete')->schemaComponent('quotes')->arguments(['item' => 'record-1']))
```

## Priority Order

1. **Authorization** (high value) - Prevents unauthorized access
2. **Validation** (high value) - Prevents invalid data
3. **Custom actions** (medium value) - Tests your custom logic
4. **Filters** (medium value) - Tests query logic
5. **RelationManagers** (lower value) - Test if custom logic exists

## What Not to Test

Don't specify tests for:

- Column visibility (Filament handles)
- Form layout rendering (Filament handles)
- Built-in actions without customization (ViewAction, EditAction, DeleteAction)
- Filament internals

## Don't Write

| Bad (vague)               | Good (specific)                             |
| ------------------------- | ------------------------------------------- |
| "Test authorization"      | List exact scenarios above                  |
| "Test validation works"   | "name: required, max:255"                   |
| "Test the approve action" | "approve action sets status to 'confirmed'" |
