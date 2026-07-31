# Laravel

Use Laravel's built-in features deliberately to improve readability — prefer the framework's expressive path over generic or string-based ones. (For correctness, performance, and security patterns, use the `laravel-best-practices` skill; this file is about clarity.)

## Split routes across multiple files

When one routes file grows unwieldy, group related routes (e.g. webhooks) into separate files and register them in `RouteServiceProvider::boot()`.

```php
Route::middleware('web')
    ->namespace($this->namespace)
    ->group(base_path('routes/webhooks.php'));
```

## Put each chained call on its own line

In a large method chain, place every `->method()` on its own line so adding or removing a call edits only whole new lines instead of splicing an existing one.

```php
// ❌ collect($items)->filter(fn () => ...)->map(fn () => ...)->each(fn () => ...);

// ✅
collect($items)
    ->filter(fn () => /* ... */)
    ->map(fn () => /* ... */)
    ->each(fn () => /* ... */);
```

## Use custom Eloquent collections

Move reusable collection logic into a named method on a `Collection` subclass, then return it via `newCollection()` on the model. Turns opaque closures into intent-revealing calls.

```php
class BlogPostCollection extends Collection
{
    public function areAllPublished(): bool
    {
        return ! $this->contains(fn (BlogPost $post) => $post->hasNotBeenPublished());
    }
}

class BlogPost extends Eloquent
{
    public function newCollection(array $models = [])
    {
        return new BlogPostCollection($models);
    }
}

// $blogPosts->areAllPublished()  instead of an inline ! contains(...) closure
```

## Avoid strings where possible

Use FQCN class references instead of string identifiers so refactoring and IDE tooling work and columns are inferred.

```php
// Routes
Route::get('/', [VideoController::class, 'get']); // refactorable
Route::get('/', VideoController::class);           // best: invokes __invoke

// Relationships
return $this->hasOne(Client::class);               // not 'App\Client', 'id', 'client_id'

// Migrations
$table->foreignIdFor(Product::class);              // not unsignedBigInteger('product_id')
```

## Prefer Laravel's more descriptive methods

When Laravel offers a dedicated expressive method for a task, use it over a generic method with a magic argument.

```php
$response->assertOk();            // not assertStatus(200)
$response->assertCreated();       // 201
$response->assertNotFound();      // 404
$response->assertUnauthorized();  // 401
$response->assertForbidden();     // 403
$response->assertUnprocessable(); // 422

$user = User::firstOrNew(['email' => request('email')]); // not where()->first() + null check
```

```blade
@auth
    {{-- authenticated --}}
@endauth
{{-- not @if(auth()->user()) --}}
```

## Leverage form requests

Move validation (`rules()`), authorization (`authorize()`), and request-data helpers out of the controller into a `FormRequest`; type-hint it so Laravel auto-validates and authorizes. Keeps the controller focused on its one job.

```php
class UpdateInvoiceRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'amount' => ['int'],
            'title' => ['required', 'string'],
            'vat_id' => ['string'],
        ];
    }

    public function authorize(): bool
    {
        return $this->user()->can('update', $this->invoice);
    }

    public function getVatId(): string
    {
        return $this->validated('vat_id');
    }

    public function isInvoiceUsingUnvalidatedVatId(string $vatId): bool
    {
        return ! ValidatedVatId::where('vat_id', $vatId)->first();
    }
}

class UpdateInvoiceController extends Controller
{
    public function __invoke(UpdateInvoiceRequest $request, Invoice $invoice)
    {
        $invoice->update($request->validated());

        if ($request->isInvoiceUsingUnvalidatedVatId($request->getVatId())) {
            $this->dispatch(new ValidateNewVatIdJob($request->getVatId()));
        }
    }
}
```

## Use macros to clean up code

Extend a Laravel service (Collection, Response, Eloquent builder, etc.) with a `macro` to add fluent, chainable methods that don't exist yet. Register in a service provider's `boot()` (usually `AppServiceProvider`).

```php
use Illuminate\Support\Collection;

Collection::macro('ifEmpty', function (callable $callback) {
    if ($this->isEmpty()) {
        $callback($this);
    }

    return $this;
});

// enables: $game->getUsers()->ifEmpty(fn (Collection $c) => throw new GameHasNoUsersYet)->each(...)
```

## Build queries conditionally with `when()`

Replace manual `if` mutation of a query builder with `when()`; the callback runs only when the first argument is truthy, keeping the chain unbroken.

```php
use Illuminate\Database\Eloquent\Builder;

$posts = Post::query()
    ->when($latestFirst, fn (Builder $query) => $query->latest())
    ->get();
```

## Embrace factories (states + relationships)

Define named factory `state` methods to hide how a model state is built, and use `has()` for related models. Tests then read as intent, not setup.

```php
// UserFactory
public function withCancelledSubscription(): self
{
    return $this->state(fn (array $attributes) => ['subscription_cancelled_at' => now()]);
}

// test
$user = User::factory()
    ->withCancelledSubscription()
    ->has(Invoice::factory())
    ->create();
```

## Use the `old()` helper short form

Pass the Eloquent model itself as the default; `old()` infers the property from the field name — no `->name` needed (Laravel 9.8+).

```blade
<input name="name" value="{{ old('name', $user) }}"> {{-- not old('name', $user->name) --}}
```

## Avoid `optional()` on modern PHP

On PHP 8.0+, replace the `optional()` helper with the null-safe operator `?->`.

```php
$user?->delete(); // not optional($user)->delete()
```
