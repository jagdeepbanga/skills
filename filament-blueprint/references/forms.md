# Form Field Specifications

> **For planning agents**: Copy all relevant information from this file into
> your plan. The implementing agent will only see your plan, not this file.
> Include full namespaces, docs URLs, and config for every component you
> specify.

When planning form fields, include enough detail that the implementing agent can
write the field without looking anything up.

## Namespace Pattern

All form components: `Filament\Forms\Components\{Component}`

## Component Reference

Use this table to pick the right component:

| Data Type           | Component          | Docs URL                                                |
| ------------------- | ------------------ | ------------------------------------------------------- |
| string              | `TextInput`        | https://filamentphp.com/docs/5.x/forms/text-input       |
| text                | `Textarea`         | https://filamentphp.com/docs/5.x/forms/textarea         |
| rich text           | `RichEditor`       | https://filamentphp.com/docs/5.x/forms/rich-editor      |
| markdown            | `MarkdownEditor`   | https://filamentphp.com/docs/5.x/forms/markdown-editor  |
| code/json           | `CodeEditor`       | https://filamentphp.com/docs/5.x/forms/code-editor      |
| boolean             | `Toggle`           | https://filamentphp.com/docs/5.x/forms/toggle           |
| boolean (consent)   | `Checkbox`         | https://filamentphp.com/docs/5.x/forms/checkbox         |
| enum                | `Select`           | https://filamentphp.com/docs/5.x/forms/select           |
| enum (visible)      | `Radio`            | https://filamentphp.com/docs/5.x/forms/radio            |
| enum (buttons)      | `ToggleButtons`    | https://filamentphp.com/docs/5.x/forms/toggle-buttons   |
| enum (multi-select) | `CheckboxList`     | https://filamentphp.com/docs/5.x/forms/checkbox-list    |
| foreign key         | `Select`           | https://filamentphp.com/docs/5.x/forms/select           |
| belongsTo (table)   | `ModalTableSelect` | https://filamentphp.com/docs/5.x/forms/select           |
| morphTo             | `MorphToSelect`    | https://filamentphp.com/docs/5.x/forms/select  |
| date                | `DatePicker`       | https://filamentphp.com/docs/5.x/forms/date-time-picker |
| datetime            | `DateTimePicker`   | https://filamentphp.com/docs/5.x/forms/date-time-picker |
| time                | `TimePicker`       | https://filamentphp.com/docs/5.x/forms/date-time-picker |
| color               | `ColorPicker`      | https://filamentphp.com/docs/5.x/forms/color-picker     |
| file                | `FileUpload`       | https://filamentphp.com/docs/5.x/forms/file-upload      |
| flat json array     | `TagsInput`        | https://filamentphp.com/docs/5.x/forms/tags-input       |
| flat json object    | `KeyValue`         | https://filamentphp.com/docs/5.x/forms/key-value        |
| hasMany (few)       | `Repeater`         | https://filamentphp.com/docs/5.x/forms/repeater         |
| dynamic blocks      | `Builder`          | https://filamentphp.com/docs/5.x/forms/builder          |
| numeric range       | `Slider`           | https://filamentphp.com/docs/5.x/forms/slider           |
| hidden value        | `Hidden`           | https://filamentphp.com/docs/5.x/forms/hidden           |

**Toggle vs Checkbox**: Use `Toggle` for settings/preferences ("Enable X"). Use
`Checkbox` for agreements/confirmations ("I agree to X").

**Enum field selection**:

| Scenario                           | Component       |
| ---------------------------------- | --------------- |
| Many options, searchable           | `Select`        |
| Few options (<6), see all          | `Radio`         |
| Few options, button style, see all | `ToggleButtons` |
| Multiple selection, see all        | `CheckboxList`  |

**Enum interfaces**: When using enums, implement interfaces from
`Filament\Support\Contracts`:

| Component       | Required   | Optional              |
| --------------- | ---------- | --------------------- |
| `Select`        | `HasLabel` | -                     |
| `Radio`         | `HasLabel` | `HasDescription`      |
| `CheckboxList`  | `HasLabel` | `HasDescription`      |
| `ToggleButtons` | `HasLabel` | `HasColor`, `HasIcon` |

Pass enum class directly: `->options(Status::class)`

**Relationship field selection**:

| Scenario                                   | Component                                    |
| ------------------------------------------ | -------------------------------------------- |
| belongsTo, simple title display            | `Select` with `->relationship()`             |
| belongsTo, need multiple columns visible   | `ModalTableSelect`                           |
| belongsToMany, <10 fixed options           | `CheckboxList` with `->relationship()`       |
| belongsToMany, searchable                  | `Select` with `->relationship()->multiple()` |
| belongsToMany, need filtering/multi-column | `ModalTableSelect` with `->multiple()`       |
| morphTo                                    | `MorphToSelect`                              |

**When to use ModalTableSelect**: Use instead of Select when users need to
search/filter by multiple columns, see more than just a title (price, SKU,
status), or when the related table has many records requiring pagination.
Requires a separate table configuration class via `->tableConfiguration()`.

**TextInput for numbers**:

- Integer: `->integer()` (not `->numeric()`)
- Decimal: `->numeric()->step(0.01)`
- Money input: `->numeric()->prefix('$')`

**DatePicker/DateTimePicker**: Often need constraints:

- Future dates only: `->minDate(now())`
- Past dates only: `->maxDate(now())`
- Date range: `->minDate(now())->maxDate(now()->addYear())`

**Slider**: For numeric range selection:

- Basic range: `->range(minValue: 0, maxValue: 100)`
- Step size: `->range(minValue: 0, maxValue: 100)->step(10)`
- Decimal places: `->range(minValue: 0, maxValue: 100)->decimalPlaces(2)`

## Plan Format

```
Field: status
  Component: Filament\Forms\Components\Select
  Docs: https://filamentphp.com/docs/5.x/forms/select
  Validation: required
  Config: ->options(OrderStatus::class)

Field: user_id
  Component: Filament\Forms\Components\Select
  Docs: https://filamentphp.com/docs/5.x/forms/select
  Validation: required
  Config: ->relationship('user', 'name'), ->searchable(), ->preload()

Field: notes
  Component: Filament\Forms\Components\Textarea
  Docs: https://filamentphp.com/docs/5.x/forms/textarea
  Validation: nullable, max:1000
  Config: ->rows(4)
```

## Layout

See [schema-layouts.md] for complete layout component specifications including
Section, Tabs, Wizard, Grid, Split, and configuration options.

Layout components use namespace: `Filament\Schemas\Components\{Component}`

### Column Configuration

Forms default to 2 columns. **If you want single-column layout, you MUST specify
`Columns: 1` in your plan.** The implementing agent will use
`$schema->columns(1)`.

```
Form:
  Columns: 1

  Section: Customer Details
    ColumnSpan: full
    Fields:
      Field: name ...
      Field: email ...
```

### Nested Column Width

**Critical**: Column settings multiply through nesting. Calculate effective
field width before specifying columns.

| Form Columns | Section Columns | Effective Field Width | Result     |
| ------------ | --------------- | --------------------- | ---------- |
| 2            | 1 (default)     | 50%                   | OK         |
| 2            | 2               | 25%                   | Too narrow |
| 1            | 2               | 50%                   | OK         |
| 1            | 1               | 100%                  | Full width |
| 2            | 1, field span 2 | 100%                  | Full width |

**Rule**: If your form has 2 columns, sections should NOT also specify 2
columns—fields become too narrow (25% width). Either:

- Use `Form Columns: 1` with `Section Columns: 2`
- Use `Form Columns: 2` with sections at default (no columns specified)
- Use `ColumnSpan: full` on sections to break out of the parent grid

```
Form:
  Columns: 2

  Section: Basic Info
    ColumnSpan: full      ← Section spans both form columns
    Columns: 2            ← Now safe to use 2 columns (50% effective width)
    Fields:
      Field: first_name ...
      Field: last_name ...
```

## Validation Notes

**Unique fields in v5**: use the field's `->unique()` method (in `Config:`), not
a raw `unique:` rule string. The method ignores the current record on edit when
`ignoreRecord: true` is passed (and Filament auto-ignores when the form has an
associated model, as in a resource). Use `->scopedUnique()` if soft-deletes or
multi-tenancy scopes must be respected.

```
Field: email
  Component: Filament\Forms\Components\TextInput
  Validation: required, email
  Config: ->unique(ignoreRecord: true)
```

Not: `unique:users,email,{id}` or `->unique(ignoreRecord: true)`

## Temporary Fields

For fields that should not be saved to the database (confirmation fields,
calculated preview fields):

```
Field: password_confirmation
  Component: Filament\Forms\Components\TextInput
  Validation: required, same:password
  Config: ->password(), ->saved(false)
```

The `->saved(false)` method excludes the field from `getState()` and prevents
any relationship saving.

## Create vs Edit Visibility

Use `->hiddenOn()` for fields that should only appear on create or edit:

```
Field: items (Repeater, only on create - use RelationManager on edit)
  Component: Filament\Forms\Components\Repeater
  Config: ->relationship('items'), ->hiddenOn('edit')

Field: status (only editable after creation)
  Component: Filament\Forms\Components\Select
  Config: ->options(Status::class), ->hiddenOn('create')
```

**Important for Repeaters**: If a resource has a RelationManager for a hasMany
relationship on the Edit page, use `->hiddenOn('edit')` on the Repeater in the
form so users don't see duplicated UI.

## Don't Write

| Bad (vague)                  | Good (specific)                                          |
| ---------------------------- | -------------------------------------------------------- |
| "Add a status field"         | See plan format above                                    |
| "Use appropriate validation" | `Validation: required, email, max:255`                   |
| "Make it searchable"         | `Config: ->searchable()`                                 |
| "Add a user selector"        | `Config: ->relationship('user', 'name'), ->searchable()` |
