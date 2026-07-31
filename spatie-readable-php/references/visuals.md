# Visuals

How code looks on the page. Formatting and layout have zero runtime cost — spend them entirely on the human reader. (Mechanical PSR-12 style is owned by the sibling `spatie-laravel-php` skill; this file covers the readability judgment on top of it.)

## Optimize code for human readers

Code is read far more often than it is written, by teammates and by your future self. Every layout decision below serves the reader, not the compiler.

## Auto-format to PSR-12

Follow PSR-12 for all mechanical style (brackets, spacing, newlines) so no brainpower is spent on formatting. Enforce it automatically with PHP CS Fixer (config in `.php-cs-fixer.php`), ideally wired into CI. The rules below cover what PSR-12 does not.

## Add breathing space

Separate a function's logical steps with blank lines so it reads as paragraphs — group related statements (setup, guard clauses, side effects, return) and isolate distinct ones.

```php
$page = $this->pages()->where('slug', $url)->first();

if (! $page) {
    return null;
}

return $page;
```

## Optimize for the happy path

Handle every edge case first as a guard clause, then place the core "happy path" as the final step. Once the edge cases are handled, the happy path no longer needs a wrapping condition.

```php
// ❌ happy path first, buried among conditions
public function sendMail(User $user, Mail $mail)
{
    if ($user->hasSubscription() && $mail->isValid()) {
        $mail->send();
    }

    if (! $user->hasSubscription()) {
        // throw exception
    }

    if (! $mail->isValid()) {
        // throw exception
    }
}

// ✅ edge cases first, happy path last and unwrapped
public function sendMail(User $user, Mail $mail)
{
    if (! $user->hasSubscription()) {
        // throw exception
    }

    if (! $mail->isValid()) {
        // throw exception
    }

    $mail->send();
}
```

## Remove dead code

Never keep commented-out blocks or unreachable code (`if (false) { ... }`) around "just in case" — it hurts readability, and version history already preserves it. If code is conditionally needed, put it behind a real feature flag; otherwise delete it. Treat comments as first-class code: keep only those that add non-obvious value.

```php
// ❌ never reachable
if (false) {
    $price = $price - $discountAmount;
}

// ✅ real feature flag
if ($discountIsActive ?? false) {
    $price = $price - $discountAmount;
}
```

## Group related class properties

Order properties logically (not arbitrarily) and separate logical groups with a single blank line. Don't over-group — one property per "group" defeats the purpose.

```php
class Period
{
    protected int $startYear;
    protected int $startMonth;
    protected int $startDay;

    protected int $endYear;
    protected int $endMonth;
    protected int $endDay;
}
```

## Configure the IDE and repo for readability

Increase editor line height (~1.6) for breathing room. Commit an `.editorconfig` so the whole team shares invisible-character conventions: `charset = utf-8`, `end_of_line = lf`, `insert_final_newline = true`, `indent_style = space`, `indent_size = 4`, `trim_trailing_whitespace = true` (with per-filetype overrides, e.g. `indent_size = 2` for YAML).
