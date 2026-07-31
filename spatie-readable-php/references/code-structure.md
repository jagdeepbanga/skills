# Code structure

Optimize code for logical interpretation, not just appearance. Reduce nesting, simplify conditions, and eliminate redundant paths so a method reads top-to-bottom as a sequence of clear steps.

## Avoid `else`

Rewrite `if`/`else` as early returns so paths stay linear instead of nested. Invert the condition and `return` early.

```php
// ❌
if ($conditionA) {
    if ($conditionB) { /* A and B */ }
    else { /* A passed, B failed */ }
} else { /* A failed */ }

// ✅
if (! $conditionA) {
    return;
}

if (! $conditionB) {
    return;
}

// A and B passed
```

## Group boolean return values

When a function returns booleans across multiple paths, order all `false` returns first and `true` last (reverse conditions as needed) so the false/true boundary is visible at a glance.

```php
if ($this->someCondition()) {
    return false;
}

if ($user->hasSubscription()) {
    return false;
}

if (! $this->anotherCondition()) { // reversed to keep false grouped
    return false;
}

return true;
```

## Order functions logically

Order methods by call order (a caller appears before the methods it calls) or, for objects with a lifecycle, by that lifecycle.

```php
public function create();
public function update();
public function delete();
```

## Refactor complex conditionals

Split combined/negated `&&`/`||` conditions into separate early-return `if`s. Extract a hard-to-read comparison into a named boolean method.

```php
// ❌ combined and negated — hard to parse
if (! $this->shipping_country === 'GB' || $this->status !== 'Valid') {
    return true;
}
return false;

// ✅ one guard per condition
if ($this->shipping_country === 'GB') {
    return false;
}

if ($this->status !== 'Valid') {
    return false;
}

return true;
```

```php
// ❌  if (! in_array($this->item->address->country, $listOfCountries)) { ... }
// ✅
if ($this->isItemCountryOutsideOfEurope()) { ... }
```

For deeply nested `if` blocks: extract to a function with early returns, one guard per condition. Keep a high-level feature test suite to confirm the paths survive the refactor.

## Put variables close to where they are used

Declare a variable immediately before its use and group related lines together — easier to refactor and produces cleaner diffs.

```php
$owners = $this->getOwners();
$this->process($owners);

$admins = $this->getAdmins();
$this->process($admins);
```

## Make boolean parameters readable

Bare boolean arguments hide intent at the call site. Use PHP 8 named arguments, or better, expose dedicated methods.

```php
$this->getPrice(true);                    // ❌ unclear
$this->getPrice(includingTaxes: true);    // ✅ named arg
$this->getPriceIncludingTax();            // ✅ better: dedicated method
```

## Use `ensure` and `guard` methods

Extract precondition/preparation checks out of a function into a helper so the core logic stands alone. Prefix with `ensure` (may fix the problem) or `guard` (throws when something is wrong) by convention.

```php
public function writeToDisk(Disk $disk, string $path, string $content): void
{
    $this->ensureWritable($disk, $path);

    $disk->write($path, $content);
}
```

Flatten a guard by inverting its check and returning early rather than wrapping the body in an `if`.

```php
if (in_array($mimeType, $allowedMimeTypes)) {
    return;
}

// build message and throw
```

## Use custom exceptions

Replace generic `Exception` with a named custom exception class, and build the message in a static `make()` factory to keep the throwing method clean. Named classes can be caught higher up for friendly handling.

```php
class MimeTypeNotAllowed extends Exception
{
    public static function make(string $file, array $allowedMimeTypes): self
    {
        $mimeType = mime_content_type($file);
        $allowedMimeTypes = implode(', ', $allowedMimeTypes);

        return new self("File has a mime type of {$mimeType}, while only {$allowedMimeTypes} are allowed");
    }
}

// throw MimeTypeNotAllowed::make($file, $allowedMimeTypes);
```

## Consider single-use traits

Extract a cohesive group of methods (often the ones already separated by a comment banner) from a large class into a trait, even if only one class uses it — the host class becomes smaller and scannable. Add `@mixin` so IDEs resolve `$this` to the host class.

```php
class User
{
    use HasSubscription;
}

/** @mixin User */
trait HasSubscription
{
    public function hasSubscription(): bool { /* ... */ }
    public function subscribe(): self { /* ... */ }
}
```

## Assign a variable in a small check

When a call's result is needed both in the condition and afterward, assign inside the `if`. Use sparingly — in large function bodies it obscures where the variable is introduced.

```php
if (! $invoice = $this->getInvoice()) {
    return;
}

$this->mailInvoice($invoice);
```
