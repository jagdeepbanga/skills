# Wizards (Multi-Step Forms)

> **For planning agents**: Copy the non-obvious details into your plan. Agents
> commonly miss the traits and method differences between pages and actions.

Docs: https://filamentphp.com/docs/5.x/schemas/wizards

## Page Wizards vs Form Wizards

**For resource pages**, use the HasWizard trait instead of putting Wizard in the
form schema:

```
Page: CreateOrder (wizard)
  Extends: CreateRecord
  Uses: Filament\Resources\Pages\CreateRecord\Concerns\HasWizard

  Method: getSteps(): array
    Returns array of Wizard\Step components
```

**For EditRecord pages**, the trait is different:

```
Page: EditOrder (wizard)
  Extends: EditRecord
  Uses: Filament\Resources\Pages\EditRecord\Concerns\HasWizard

  Method: getSteps(): array
    Returns array of Wizard\Step components
```

**For action modals**, use `steps()` instead of `schema()`:

```
Action: Create Order
  Config:
    ->steps([...])
    ->skippableSteps()
    ->startOnStep(2)
```

Note: Actions use `->skippableSteps()` while the Wizard component uses
`->skippable()`.

## Step Plan Format

When specifying wizard steps, include:

```
Steps:
  Step: Customer
    Icon: Heroicon::User
    Description: Select or create customer
    Fields:
      Field: customer_id
        Component: Filament\Forms\Components\Select
        Config: ->relationship('customer', 'name'), ->searchable()
        Validation: required

  Step: Items
    Icon: Heroicon::ShoppingCart
    Description: Add order items
    Fields:
      Field: items
        Component: Filament\Forms\Components\Repeater
        Config: ->relationship('items'), ->schema([...])
        Validation: required, min:1

  Step: Review
    Icon: Heroicon::CheckCircle
    Description: Confirm order details
```

Step namespace: `Filament\Schemas\Components\Wizard\Step`

Each step validates its fields before allowing progression.

## Common Mistakes

- Using `Filament\Schemas\Components\Wizard` on resource pages instead of the
  `HasWizard` trait
- Using `->skippable()` on action wizards (correct: `->skippableSteps()`)
- Forgetting that `getSteps()` must return an array of `Wizard\Step` components
