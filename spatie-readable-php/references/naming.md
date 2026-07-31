# Naming

A good name lets code speak for itself. Choose names for the reader, not the writer — step outside yourself and imagine how someone else will interpret the name.

## Write code in English

Use English for all identifiers — it's the de facto standard and aligns with framework/domain nomenclature. Exception: business terms with no good English translation (e.g. `bonusMalus`) — keep the term the business already uses.

```php
// ❌
if ($zouEenMailMoetenVersturen) {
    $this->verstuurMail();
}

// ✅
if ($shouldSendMail) {
    $this->sendMail();
}
```

## Avoid abbreviations

Spell names out — typing isn't the bottleneck, and abbreviations lose meaning for future readers. Exceptions: well-known conventions (loop `$i`) and established domain vocabulary (`$vat`).

```php
// ❌ $pwt = $p + $t;
$priceWithTax = $basePrice + $tax;
```

## Be expressive

### Extract commented steps into named functions

When a block has comments describing each step, extract each step into a method named after its comment. Bonus: the new methods are natural unit-test targets.

```php
$data = $this->getSanitizedPdfData();
$pathToPdf = $this->createPdf($data, $user);
$this->mailPdf($user, $mail);
```

### Prefix boolean-returning methods with `is`/`has`

An `is`/`has` prefix signals a boolean return and reads naturally at the call site.

```php
// ❌ $status = $user->pending();
$userIsPending = $user->isPending();
$user->hasReplied();
```

### Put units in names for measurable values

Append the unit to any measured value so the expected magnitude is unambiguous; for richer cases use a value object with named static constructors.

```php
// ❌ $averageTime = 100;
$averageTimeInMs = 100;

$percentage = Percentage::fromInt(50); // vs ambiguous 0.5 / 50
```

### Name exactly what is returned

Disambiguate overloaded terms (e.g. "class" = name? path? reflection?) by naming the concrete thing returned. Don't fear longer names.

```php
// ❌ return $factory->getTargetClass();
return $factory->getTargetClassName();
return $factory->getTargetClassFile();
return $factory->getTargetClassReflection();
```

## Be consistent

### Use verb prefixes with agreed meaning

Reserve verb prefixes for specific semantics so a call site is understandable without reading the implementation. Define your own set, but apply it consistently. A common set:

- `make` — build object in memory, not persisted
- `create` — build and persist to the database
- `get` — retrieve from local DB/disk (fast)
- `fetch` — retrieve over the network (potentially slow)

### Name many-to-many tables for meaning

Instead of concatenating the two model names, name the pivot for what the relationship represents.

```php
// ❌ user_video, product_user
watched_videos
purchased_products
```

### Be consistent with file names

Use the same suffix for the same kind of file so structure and search stay predictable.

```php
// ❌ Actions/ImportYouTubeVideos.php + Actions/GetTwitchStreamsAction.php
Actions/ImportYouTubeStreamsAction.php
Actions/ImportTwitchStreamsAction.php
```

## Replace model booleans with nullable timestamps

Prefer a nullable `<event>_at` timestamp over a boolean flag: it answers both *if* and *when* at no extra cost, and never needs a companion column. Default to this even when you don't yet need the "when".

```php
// column: shipped (bool)  →  shipped_at (nullable timestamp; null = not shipped)
if ($product->shipped_at) {
    // ...
}
```

## Create a team style guide

Agree naming/style conventions as a team and write them down — consistency within the team matters more than which specific choices you make.
