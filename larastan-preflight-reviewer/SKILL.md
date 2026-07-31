---
name: larastan-preflight-reviewer
description: Review Laravel Eloquent model `casts()` methods, `Attribute` accessor/mutator methods, relationship methods, and Laravel `JsonResource` `@mixin` annotations before Larastan/PHPStan runs. Use when asked to audit or fix model casts, Larastan array-shape return PHPDocs, Attribute get/set generics, relationship generics, model attribute type precision, resource mixin tags, or static-analysis failures involving model casts, accessors/mutators, relationships, or `JsonResource` proxy typing in `app/Models/*`, `src/Models/*`, or `app/Http/Resources/*`.
---

# Larastan Preflight Reviewer

Catch `casts()`, `Attribute` accessor/mutator, relationship signature, and `JsonResource` `@mixin` PHPDoc mismatches **before** Larastan/PHPStan analyzes the project.

Scope of review:
- Eloquent models under `app/Models/*` and `src/Models/*`.
- Model traits those models use, when the trait defines relationships, `Attribute` accessors/mutators, `casts()`-style logic, or model-facing dynamic properties.
- `JsonResource` classes under `app/Http/Resources/*` that proxy model properties.

The canonical "correct shapes" are in [Patterns](#patterns) below. For the exhaustive per-concern verification rules, see [MATCHING-RULES.md](MATCHING-RULES.md).

## Workflow

1. **Inspect project context first.**
   - Read the project's agent instructions (e.g. `AGENTS.md` / `CLAUDE.md`) and follow local Laravel, PHP, and testing rules. Use any repo-required documentation/search tools before changing code.
   - List candidate files with `rg --files app/Models src/Models app/Http/Resources` (ignore missing directories).

2. **Identify model classes.** Include classes that extend `Illuminate\Database\Eloquent\Model` directly or through a project base model. Exclude traits, factories, resources, DTOs, enums, policies, and other support classes even if they live near models. Don't review models outside `app/Models/*` or `src/Models/*` unless the user expands scope.

3. **Identify model traits used by those models.** Find trait usage in the model bodies first:
   - `rg -n '^\s*use\s+[A-Z][A-Za-z0-9_]*(?:\s*\{.*)?;' app/Models src/Models`
   - `rg -n '^use App\\Traits\\|^use .*\\Traits\\' app/Models src/Models`

   Resolve only traits actually used by models, then include a trait if it defines relationship methods, `Attribute` methods, `casts()`-style logic, or model-facing dynamic properties (e.g. `Addressable`, `AsOrder`, `HasMedia`, `HasAddons`, `InteractsWithDiscounts`). Ignore generic utility traits.

4. **Identify `JsonResource` classes** under `app/Http/Resources/*` that extend `Illuminate\Http\Resources\Json\JsonResource` (directly or via a base resource) and proxy model members like `$this->id`, `$this->email`, `$this->orders`. Exclude transformers that don't actually extend `JsonResource`.

5. **Verify each concern** against the [Patterns](#patterns) and the detailed rules in [MATCHING-RULES.md](MATCHING-RULES.md):
   - **`casts()`** — `protected`, explicit `array` return type, PHPDoc array shape matching the returned keys/value types, class-string casts written as fully qualified strings (`'App\Casts\MoneyCast'`).
   - **`Attribute` methods** — `protected`, `Attribute` return type, `@return Attribute<TGet, TSet>` matching the `get:`/`set:` closures; use `never` for a missing side.
   - **Relationship methods** — `public`, explicit relation return type, `@return` relation generic with the related model FQCN and `$this` as the declaring side.
   - **`JsonResource`** — class-level `@mixin \App\Models\X` when it proxies model members; don't invent a mixin when it wraps a collection or non-model payload, and report ambiguity rather than guessing a target.

6. Find each concern **by return type, not by method name**. If a return value is computed, conditional, or delegated such that the shape isn't deterministic, **flag the uncertainty** instead of inventing a precise type.

7. For models, traits, and resources with no relevant `casts()`, `Attribute`, relationship, or resource-proxy concerns, report nothing unless the user asked for a full inventory.

## Patterns

### Casts

```php
/**
 * @return array{
 *     email_verified_at: 'datetime',
 *     settings: 'array',
 *     user_id: 'int',
 *     custom_value: 'App\Casts\CustomValue',
 * }
 */
protected function casts(): array
{
    return [
        'email_verified_at' => 'datetime',
        'settings' => 'array',
        'user_id' => 'int',
        'custom_value' => App\Casts\CustomValue::class,
    ];
}
```

### Attribute

```php
/** @return Attribute<string, never> */
protected function fullName(): Attribute
{
    return Attribute::make(
        get: fn (): string => "{$this->first_name} {$this->last_name}",
    );
}

/** @return Attribute<string, string> */
protected function slug(): Attribute
{
    return Attribute::make(
        get: fn (string $value): string => $value,
        set: fn (string $value): string => Str::slug($value),
    );
}

/** @return Attribute<never, array{name: string}> */
protected function profile(): Attribute
{
    return Attribute::make(
        set: fn (array $value): array => ['name' => $value['name']],
    );
}
```

### Relationship

```php
/** @return HasMany<\App\Models\Post, $this> */
public function posts(): HasMany
{
    return $this->hasMany(Post::class);
}

/** @return BelongsTo<\App\Models\User, $this> */
public function user(): BelongsTo
{
    return $this->belongsTo(User::class);
}

/** @return MorphTo<\Illuminate\Database\Eloquent\Model, $this> */
public function imageable(): MorphTo
{
    return $this->morphTo();
}
```

### Resource

```php
/**
 * @mixin \App\Models\User
 */
class UserResource extends JsonResource
{
    public function toArray($request): array
    {
        return [
            'id' => $this->id,
            'email' => $this->email,
        ];
    }
}
```

## Fix guidance

- Keep edits scoped to `casts()` methods, `Attribute` methods, relationship methods, `JsonResource` class PHPDocs, and their Larastan-facing annotations unless the user requested broader cleanup.
- Don't rewrite legacy `$casts` properties unless the task specifically asks for that migration.
- Preserve existing ordering and style. Use imported class names in the PHP return array if that matches the file's style, but write fully qualified class-name strings (no leading slash) in the PHPDoc array shape.
- After PHP edits, run the project's formatter and the smallest relevant static-analysis or test command required by local instructions.

## Review output

Lead with actionable issues. For each finding give:

- File and line reference for the `casts()`, `Attribute`, relationship method, or resource class PHPDoc.
- Which rule failed: visibility, missing shape, missing generic, key mismatch, type mismatch, non-FQCN class name, missing `never`, generic relation mismatch, missing `@mixin`, wrong `@mixin` target, or non-deterministic return.
- The expected PHPDoc shape or a concise patch summary.
- Verification commands run, or why verification could not run.
