# Filament: Managing Relationships (Reference)

Source: <https://filamentphp.com/docs/5.x/resources/managing-relationships> (Filament v5.x)

Verbatim extracts of the "Choosing the right tool for the job", "Relation pages", and "Adding relation pages to resource sub-navigation" sections of Filament's "Managing relationships" documentation, reproduced for offline reference. Relative doc links have been expanded to absolute URLs.

## Choosing the right tool for the job

Filament provides many ways to manage relationships in the app. Which feature you should use depends on the type of relationship you are managing, and which UI you are looking for.

### Relation managers - interactive tables underneath your resource forms

> **Info:** These are compatible with `HasMany`, `HasManyThrough`, `BelongsToMany`, `MorphMany` and `MorphToMany` relationships.

[Relation managers](https://filamentphp.com/docs/5.x/resources/managing-relationships#creating-a-relation-manager) are interactive tables that allow administrators to list, create, attach, associate, edit, detach, dissociate and delete related records without leaving the resource's Edit or View page.

### Select & checkbox list - choose from existing records or create a new one

> **Info:** These are compatible with `BelongsTo`, `MorphTo` and `BelongsToMany` relationships.

Using a [select](https://filamentphp.com/docs/5.x/forms/select#integrating-with-an-eloquent-relationship), users will be able to choose from a list of existing records. You may also [add a button that allows you to create a new record inside a modal](https://filamentphp.com/docs/5.x/forms/select#creating-new-records), without leaving the page.

When using a `BelongsToMany` relationship with a select, you'll be able to select multiple options, not just one. Records will be automatically added to your pivot table when you submit the form. If you wish, you can swap out the multi-select dropdown with a simple [checkbox list](https://filamentphp.com/docs/5.x/forms/checkbox-list#integrating-with-an-eloquent-relationship). Both components work in the same way.

### Repeaters - CRUD multiple related records inside the owner's form

> **Info:** These are compatible with `HasMany` and `MorphMany` relationships.

[Repeaters](https://filamentphp.com/docs/5.x/forms/repeater#integrating-with-an-eloquent-relationship) are standard form components, which can render a repeatable set of fields infinitely. They can be hooked up to a relationship, so records are automatically read, created, updated, and deleted from the related table. They live inside the main form schema, and can be used inside resource pages, as well as nesting within action modals.

From a UX perspective, this solution is only suitable if your related model only has a few fields. Otherwise, the form can get very long.

### Layout form components - saving form fields to a single relationship

> **Info:** These are compatible with `BelongsTo`, `HasOne` and `MorphOne` relationships.

All layout form components ([Grid](https://filamentphp.com/docs/5.x/schemas/layouts#grid-component), [Section](https://filamentphp.com/docs/5.x/schemas/sections), [Fieldset](https://filamentphp.com/docs/5.x/schemas/layouts#fieldset-component), etc.) have a [`relationship()` method](https://filamentphp.com/docs/5.x/forms/overview#saving-data-to-relationships). When you use this, all fields within that layout are saved to the related model instead of the owner's model:

```php
use Filament\Forms\Components\FileUpload;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Schemas\Components\Fieldset;

Fieldset::make('Metadata')
    ->relationship('metadata')
    ->schema([
        TextInput::make('title'),
        Textarea::make('description'),
        FileUpload::make('image'),
    ])
```

In this example, the `title`, `description` and `image` are automatically loaded from the `metadata` relationship, and saved again when the form is submitted. If the `metadata` record does not exist, it is automatically created.

This feature is explained more in depth in the [Forms documentation](https://filamentphp.com/docs/5.x/forms/overview#saving-data-to-relationships). Please visit that page for more information about how to use it.

## Relation pages

Using a `ManageRelatedRecords` page is an alternative to using a relation manager, if you want to keep the functionality of managing a relationship separate from editing or viewing the owner record.

This feature is ideal if you are using [resource sub-navigation](https://filamentphp.com/docs/5.x/resources/overview#resource-sub-navigation), as you are easily able to switch between the View or Edit page and the relation page.

To create a relation page, you should use the `make:filament-page` command:

```bash
php artisan make:filament-page ManageCustomerAddresses --resource=CustomerResource --type=ManageRelatedRecords
```

When you run this command, you will be asked a series of questions to customize the page, for example, the name of the relationship and its title attribute.

You must register this new page in your resource's `getPages()` method:

```php
public static function getPages(): array
{
    return [
        'index' => Pages\ListCustomers::route('/'),
        'create' => Pages\CreateCustomer::route('/create'),
        'view' => Pages\ViewCustomer::route('/{record}'),
        'edit' => Pages\EditCustomer::route('/{record}/edit'),
        'addresses' => Pages\ManageCustomerAddresses::route('/{record}/addresses'),
    ];
}
```

> **Warning:** When using a relation page, you do not need to generate a relation manager with `make:filament-relation-manager`, and you do not need to register it in the `getRelations()` method of the resource.

Now, you can customize the page in exactly the same way as a relation manager, with the same `table()` and `form()`.

### Adding relation pages to resource sub-navigation

If you're using [resource sub-navigation](https://filamentphp.com/docs/5.x/resources/overview#resource-sub-navigation), you can register this page as normal in `getRecordSubNavigation()` of the resource:

```php
use App\Filament\Resources\Customers\Pages;
use Filament\Resources\Pages\Page;

public static function getRecordSubNavigation(Page $page): array
{
    return $page->generateNavigationItems([
        // ...
        Pages\ManageCustomerAddresses::class,
    ]);
}
```
