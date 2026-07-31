# Reactive Field Specifications

> **For planning agents**: Copy all relevant information from this file into
> your plan. The implementing agent will only see your plan, not this file.
> Include full namespaces and config for reactive fields.

When a field needs to read or update other fields, specify this in your plan so
the implementing agent knows to use the Get/Set utilities.

Docs: https://filamentphp.com/docs/5.x/forms/overview#field-utility-injection

## What to Include

| Element                      | Why the Implementing Agent Needs It |
| ---------------------------- | ----------------------------------- |
| Which fields trigger updates | So they add `->live()`              |
| What happens on update       | So they write the callback          |
| Correct imports              | So they don't use wrong namespaces  |

## Required Imports

When your plan includes reactive fields, add this to the plan so the
implementing agent knows the correct namespaces:

```
Imports:
  - Filament\Schemas\Components\Utilities\Get
  - Filament\Schemas\Components\Utilities\Set
```

## Plan Format

When fields react to each other, specify the relationship:

```
Field: country
  Component: Filament\Forms\Components\Select
  Docs: https://filamentphp.com/docs/5.x/forms/select
  Config: ->options(Country::class), ->live()
  Reactive: when changed, reset state field to null

Field: state
  Component: Filament\Forms\Components\Select
  Docs: https://filamentphp.com/docs/5.x/forms/select
  Config: ->options(fn (Get $get): Collection => State::where('country_id', $get('country'))->pluck('name', 'id'))
  Reactive: options depend on country field

Field: quantity
  Component: Filament\Forms\Components\TextInput
  Docs: https://filamentphp.com/docs/5.x/forms/text-input
  Config: ->numeric(), ->live()
  Reactive: triggers total recalculation

Field: total
  Component: Filament\Forms\Components\TextInput
  Docs: https://filamentphp.com/docs/5.x/forms/text-input
  Config: ->numeric(), ->disabled(), ->dehydrated(false)
  Reactive: calculated as quantity * price, display only
```

## Common Patterns to Specify

### Dependent dropdown

```
Reactive: options depend on {other_field} field
```

### Reset on change

```
Reactive: when changed, reset {other_field} to null
```

### Calculated field

```
Reactive: calculated as {formula}, display only
```

### Conditional visibility

```
Reactive: visible only when {field} equals {value}
```

## Does Not Exist

| Wrong Namespace      | Correct Namespace                           |
| -------------------- | ------------------------------------------- |
| `Filament\Forms\Get` | `Filament\Schemas\Components\Utilities\Get` |
| `Filament\Forms\Set` | `Filament\Schemas\Components\Utilities\Set` |

| Wrong Method   | Correct Method |
| -------------- | -------------- |
| `->reactive()` | `->live()`     |
