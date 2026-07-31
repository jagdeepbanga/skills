# Styling References

> **For planning agents**: Copy exact color names and icon syntax into your
> plan. The implementing agent will only see your plan, not this file. Include
> the Heroicon import if using the class-based icon format.

Colors and icons used throughout Filament components.

## Colors

Available for `->color()`: `primary`, `info`, `danger`, `warning`, `success`,
`gray`

```
Config: ->color('success')
Config: ->color(fn (string $state): string => match($state) {
  'pending' => 'warning',
  'approved' => 'success',
  'rejected' => 'danger',
  default => 'gray',
})
```

## Icons

When your plan includes icons, add this import:

```
Imports:
  - Filament\Support\Icons\Heroicon
```

Then reference icons as:

```
Config: ->icon(Heroicon::CheckCircle)
Config: ->icon(Heroicon::ExclamationTriangle)
Config: ->icon(Heroicon::ArrowDownTray)
```
