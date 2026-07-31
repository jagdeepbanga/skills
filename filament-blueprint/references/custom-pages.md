# Custom Pages

> **For planning agents**: Copy all relevant information from this file into
> your plan. The implementing agent will only see your plan, not this file.

Custom pages are standalone pages in a panel that don't belong to a Resource.
Use them for dashboards, reports, or any page that isn't CRUD.

## Commands

```
php artisan make:filament-page {Name} --no-interaction
php artisan make:filament-page {Name} --resource={Resource} --type=custom --no-interaction
```

| Flag            | Purpose                              |
| --------------- | ------------------------------------ |
| `--resource`    | Create page within a Resource        |
| `--type=custom` | Specify page type for resource pages |

## What to Include

| Element  | Why the Implementing Agent Needs It   |
| -------- | ------------------------------------- |
| Command  | So they scaffold correctly            |
| Location | So they know where the file goes      |
| Route    | For resource pages: the route pattern |
| Uses     | Traits needed (InteractsWithRecord)   |
| Register | Must add to resource's getPages()     |
| Content  | What the page displays                |

## Plan Format: Standalone Page

```
Page: Dashboard
  Command: php artisan make:filament-page Dashboard --no-interaction
  Location: App\Filament\Pages\Dashboard
  Docs: https://filamentphp.com/docs/5.x/navigation/custom-pages

  Navigation:
    Group: none (top level)
    Icon: Heroicon::Home
    Sort: -2

  Content:
    - StatsOverviewWidget showing key metrics
    - RecentOrdersWidget showing latest orders
```

## Plan Format: Resource Page

For pages tied to a specific record, use the `InteractsWithRecord` trait:

```
Page: ManageOrderItems
  Command: php artisan make:filament-page ManageOrderItems --resource=OrderResource --type=custom --no-interaction
  Location: App\Filament\Resources\Orders\Pages\ManageOrderItems
  Docs: https://filamentphp.com/docs/5.x/resources/custom-pages

  Uses: Filament\Resources\Pages\Concerns\InteractsWithRecord
  Route: {record}/manage-items
  Register: Add to OrderResource::getPages()

  Mount: $this->record = $this->resolveRecord($record)

  Content:
    - Drag-and-drop reordering of order items
    - Inline quantity editing
```

The `InteractsWithRecord` trait provides `$this->record`, authorization,
breadcrumbs, and widget data. The route must include `{record}` parameter.

## Settings Pages

For application settings, use the Spatie Laravel Settings plugin.

**First, check if the app already has a settings pattern** - follow existing
conventions. If this is the first settings page, use spatie/laravel-settings.

### Commands

These commands must be included in the plan's Commands section:

```
# Create settings class (spatie/laravel-settings)
php artisan make:setting {Name} --no-interaction

# Create settings migration (spatie/laravel-settings)
php artisan make:settings-migration create_{name}_settings --no-interaction

# Create Filament settings page
php artisan make:filament-settings-page {PageName} {SettingsClass} --generate --no-interaction
```

The `--generate` flag creates form fields from the settings class properties.

### Plan Format

```
Settings Page: ManageGeneralSettings
  Package: filament/spatie-laravel-settings-plugin
  Docs: https://filamentphp.com/plugins/filament-spatie-settings

  Commands:
    php artisan make:setting GeneralSettings --no-interaction
    php artisan make:settings-migration create_general_settings --no-interaction
    php artisan make:filament-settings-page ManageGeneralSettings GeneralSettings --generate --no-interaction

  Settings Class: App\Settings\GeneralSettings
    Properties:
      - site_name: string, default: 'My App'
      - site_active: bool, default: true
      - contact_email: string, default: ''

  Page Location: App\Filament\Pages\ManageGeneralSettings

  Navigation:
    Group: Settings
    Icon: Heroicon::Cog6Tooth
```

**Important**: All three commands must be in the plan. The implementing agent
needs to run them in order: settings class, migration, then page.

## Don't Write

| Bad (vague)                  | Good (specific)                              |
| ---------------------------- | -------------------------------------------- |
| "Add a settings page"        | Settings page with class and properties      |
| "Custom page for orders"     | Specify if standalone or resource page       |
| "Page to manage order items" | Include InteractsWithRecord, route, register |
