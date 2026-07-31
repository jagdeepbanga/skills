# Modern PHP

Prefer modern PHP language features (8.0+) — strict checks, null-coalescing, the null-safe operator, `match`, named arguments, array functions — to write more concise code with less mental overhead than the verbose branching they replace.

## Prefer strict checking

Use `===`/`!==`, never `==`/`!=`. Loose comparison juggles types (`"1337" == 1337` is `true`; any truthy value passes `== true`), causing subtle bugs. Strict comparison restricts code to its intended type.

```php
if ($variable === true) { // certain it's boolean true, not just truthy
```

## Check substrings with `str_contains`

Use `str_contains()` (PHP 8.0), not `strpos(...) !== false` — the latter's name and `false`-vs-`0` return are non-obvious.

```php
if (str_contains($sentence, $word)) { // was: strpos($sentence, $word) !== false
```

## Null-safe operator

Use `?->` instead of a null guard before a method or property call.

```php
$user?->save(); // was: if (! is_null($user)) { $user->save(); }
```

## Named arguments to skip optional params

Pass args by name to omit intervening optional args, removing the noise of placeholder values.

```php
$request = Request::create(uri: '/my-url', method: 'POST', content: 'my content');
// was: Request::create('/my-url', 'POST', [], [], [], [], 'my content');
```

## Null coalescing operator

Use `??` to supply a fallback when the left side is `null` or unset. Chain it for multiple fallbacks (each on its own line). It also safely reaches nested array keys without checking each level.

```php
$publishDate = $blogPost->publish_date ?? Date::now();

return $page->title
    ?? $page->category->title
    ?? 'Missing page title';

$result = $data['deeply']['nested']['array']['value'] ?? 'default';
```

## Null coalescing assignment operator

Use `??=` to assign a default only when the variable is currently `null`/unset.

```php
$object ??= new MyClass(); // was: $object = $object ?? new MyClass();
```

## Null coalesce in array iteration

Use `?? []` to iterate optional array keys without nested `isset()` checks.

```php
foreach ($myArray[$key] ?? [] as $items) {
    foreach ($items[$anotherKey] ?? [] as $deeperItems) {
        // ...
    }
}
```

## Array destructuring

Destructure array elements directly in `foreach` (works for associative and numeric keys) instead of manual assignments.

```php
foreach ($products as ['id' => $id, 'name' => $name]) { /* ... */ }
foreach ($products as [$id, $name, $price]) { /* ... */ }
```

Spread an associative array into a function with `...` when its keys match the parameter names.

```php
foreach ($products as $productProperties) {
    processProduct(...$productProperties); // keys id/name/price map to $id/$name/$price
}
```

## Use `array_map` to transform

Use `array_map` instead of a `foreach` that builds a result array — it drops the temp variable and guarantees output count equals input count. Prefer a short arrow closure `fn()`; a string function name or first-class callable (PHP 8.1) works when no wrapping is needed.

```php
$upperCasedNames = array_map(fn (string $name) => strtoupper($name), $names);
$upperCasedNames = array_map('strtoupper', $names);      // string name
$upperCasedNames = array_map(strtoupper(...), $names);   // first-class callable (8.1)
```

## Use `array_filter` to exclude

Use `array_filter` instead of a `foreach` with an `if` to drop items — the result has equal-or-fewer items. Callable returns truthy to keep the item; omit the callable to strip all falsy values.

```php
$names = array_filter($namesAndEmptyValues, fn (string $name) => ! empty($name));
$names = array_filter($namesAndEmptyValues); // no closure: removes empty values
```

## Replace repeated `if` blocks with `match`

Collapse repeated equality `if`/return chains into a `match` expression (one line per path; group cases with commas; `default` for the fallback).

```php
return match ($status) {
    'ok' => 'bg-green-100',
    'failed', 'crashed' => 'bg-red-100',
    default => 'bg-white',
};
```

## The value of `void`

Add `: void` to functions that return nothing. It documents that no value should be returned or captured, resolving ambiguity for callers.

```php
function setName(User $user, string $name): void
{
    $user->name = $name;
}

setName($user, 'John Doe'); // no return value to capture
```

## Formatting numbers

Use `_` digit separators in numeric literals (the compiler ignores them). Express derived constants as math with the unit in the variable name rather than a magic number. For currency, store cents and use `_` as a decimal separator. Use scientific notation (`E`) for scientific magnitudes.

```php
$largeNumber = 45_697_512;
$timeoutInSeconds = 60 * 60 * 24;   // clearer than 86_400
$dollarPriceInCents = 5_30;         // $5.30
$avogadrosNumber = 6.022E23;
```
