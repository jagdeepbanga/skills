# Common Planning Mistakes

> **For planning agents**: Use this checklist before finalizing your plan. The
> implementing agent will only see your plan, not this file. Verify you haven't
> made any of these common errors.

Check your plan against these before finalizing.

## Vague Specifications

| Bad                          | Good                                                     |
| ---------------------------- | -------------------------------------------------------- |
| "Add a status field"         | Full field spec with Component, Docs, Validation, Config |
| "Use appropriate validation" | `Validation: required, email, max:255`                   |
| "Make it searchable"         | `Config: ->searchable()`                                 |
| "Show as badge"              | `Config: ->badge(), ->color(fn ...)`                     |
| "Standard CRUD"              | Specify each field and column                            |
| "Check permissions"          | `user has 'view orders' permission`                      |

## Missing Namespaces (Most Common)

Every component MUST have a full namespace. Check each one:

| Element        | Correct Namespace Pattern                 |
| -------------- | ----------------------------------------- |
| Form fields    | `Filament\Forms\Components\TextInput`     |
| Table columns  | `Filament\Tables\Columns\TextColumn`      |
| Table filters  | `Filament\Tables\Filters\SelectFilter`    |
| Actions        | `Filament\Actions\Action`                 |
| Bulk actions   | `Filament\Actions\BulkAction`             |
| Infolist       | `Filament\Infolists\Components\TextEntry` |
| Layout         | `Filament\Schemas\Components\Section`     |
| Reactive utils | `Filament\Schemas\Components\Utilities\*` |

**Bad**: `Component: Select` **Good**:
`Component: Filament\Forms\Components\Select`

## Missing Elements

Each field/column/action should have:

- [ ] Component with full namespace
- [ ] Docs URL
- [ ] Validation (for form fields)
- [ ] Config with exact method syntax

## Missing Scaffold Commands

- [ ] No `php artisan make:filament-resource` command
- [ ] No `php artisan make:filament-relation-manager` command
- [ ] Missing `--no-interaction` flag

See [resources.md] and [relationships.md].

## Layout Not Specified

Forms and infolists default to 2 columns. If you want different:

- [ ] Specify `Columns: 1` for single column (uses `$schema->columns(1)`)
- [ ] Specify `ColumnSpan: full` for full-width sections

See [schema-layouts.md].

## Nested Columns Too Narrow

Column settings multiply through nesting. Check your effective field width:

- [ ] Form has 2 columns AND sections have 2 columns = 25% width (TOO NARROW)
- [ ] Either use form columns OR section columns, not both set to 2
- [ ] If both need 2 columns, use `ColumnSpan: full` on sections first

| Form/Infolist Columns | Section Columns | Effective Width | OK? |
| --------------------- | --------------- | --------------- | --- |
| 2                     | 2               | 25%             | NO  |
| 2                     | 1 (default)     | 50%             | YES |
| 1                     | 2               | 50%             | YES |
| 2 + ColumnSpan: full  | 2               | 50%             | YES |

See [schema-layouts.md].

## Unclear Authorization

- [ ] Resource needs restrictions but no authorization specified
- [ ] Vague descriptions like "check if allowed" instead of specific rules
- [ ] Custom action needs authorization but none specified

Not all resources need policies. Specify
`Authorization: All authenticated users` if no restrictions are needed.

See [authorization.md].

## Missing Tests

- [ ] No authorization tests
- [ ] No validation tests
- [ ] No custom action tests

See [testing.md].

## Components That Don't Exist

| Wrong             | Use Instead                      |
| ----------------- | -------------------------------- |
| `Card`            | `Section`                        |
| `BelongsToSelect` | `Select` with `->relationship()` |
| `MultiSelect`     | `Select` with `->multiple()`     |
| `BadgeColumn`     | `TextColumn` with `->badge()`    |
| `BooleanColumn`   | `IconColumn` with `->boolean()`  |
| `DateColumn`      | `TextColumn` with `->date()`     |

## Wrong Namespaces

| Wrong                | Right                                       |
| -------------------- | ------------------------------------------- |
| `Filament\Forms\Get` | `Filament\Schemas\Components\Utilities\Get` |
| `Filament\Forms\Set` | `Filament\Schemas\Components\Utilities\Set` |

See [reactive-fields.md], [forms.md], [tables.md].

## Wrong Methods

| Wrong          | Right      |
| -------------- | ---------- |
| `->reactive()` | `->live()` |
