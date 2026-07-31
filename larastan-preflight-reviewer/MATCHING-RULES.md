# Matching Rules

Detailed per-concern verification rules for the [Larastan Preflight Reviewer](SKILL.md). Consult the relevant section when verifying a specific concern.

## Cast matching rules

- Compare array shape keys exactly against the returned array keys.
- Treat `SomeClass::class` return values as the fully qualified class-name string that PHP resolves to in that namespace.
- Require PHPDoc class-string values to be fully qualified without a leading slash, such as `'App\Casts\MoneyCast'`, not `'MoneyCast'` or `MoneyCast::class`.
- Preserve literal Laravel cast strings in PHPDoc, such as `'int'`, `'integer'`, `'bool'`, `'boolean'`, `'array'`, `'json'`, `'object'`, `'collection'`, `'datetime'`, `'immutable_datetime'`, `'date'`, `'decimal:2'`, `'encrypted:array'`, and enum collection cast strings.
- If the returned value is computed or conditionally built, avoid inventing a precise shape. Flag it and recommend making the return value static where practical, or documenting the stable subset only if that matches existing project practice.
- If the method delegates to `array_merge()` or another helper, inspect enough context to determine the final shape. If that is not deterministic, report the uncertainty.

## Attribute matching rules

- Find attribute methods by return type, not by method name. A model attribute method normally has `protected function attributeName(): Attribute`.
- Treat `Attribute::make(...)` and `new Attribute(...)` as equivalent for this review.
- If only `get:` is present, require the set generic to be `never`.
- If only `set:` is present, require the get generic to be `never`.
- If both `get:` and `set:` are present, require both generics to match their respective closure types.
- If a getter closure has an explicit return type, use that as the get generic unless the body proves it wrong.
- If a setter closure has an explicit parameter type, use that as the set generic unless the body proves it wrong.
- If a setter returns an array of attributes, the set generic describes the accepted input value, not the returned storage array.
- If closures omit types, infer conservatively from the returned expression, model casts, database shape, and call sites. Flag uncertain cases instead of inventing overly precise generics.
- Prefer `never` over `null` for the missing generic side. Use nullable types only when the getter or setter actually accepts or returns null, such as `Attribute<?string, ?string>`.
- Preserve existing shorthand built-in types where valid: `string`, `int`, `float`, `bool`, `array`, `mixed`, `never`, and array shapes.

## Relation matching rules

- Find relationship methods by explicit return type from `Illuminate\Database\Eloquent\Relations`, not by method name.
- Relationship methods should be `public`; Laravel relationship methods are intended to be called for query chaining, eager-load constraints, and dynamic property access.
- Require a PHPDoc `@return` generic for every relationship return type.
- The PHPDoc relationship class must match the PHP return type.
- For direct relationships, require the first generic to match the related model class passed to the relationship builder.
- For inverse relationships such as `belongsTo(User::class)`, the first generic is the parent or related model, not the declaring model.
- For polymorphic inverse relationships using `morphTo()` with no explicit class argument, use the narrowest known related model union if the codebase establishes one; otherwise use `\Illuminate\Database\Eloquent\Model`.
- For through relationships, preserve the framework relation's generic arity expected by the installed Larastan version. If unsure, inspect existing project examples or run PHPStan after the change instead of guessing.
- Prefer `$this` for the declaring model generic unless local PHPStan feedback requires a concrete fully qualified model type.
- Use fully qualified model class names in PHPDoc generics, for example `HasMany<\App\Models\Post, $this>`, even when the PHP body uses imported class names.
- If a relationship delegates to another method, macro, or conditional relation builder, report uncertainty instead of inventing a generic.

## Resource matching rules

- Find resources by class inheritance from `Illuminate\Http\Resources\Json\JsonResource`, not by filename alone.
- Require an `@mixin` tag when the resource reads properties or methods that are expected to come from an underlying model instance.
- The `@mixin` target should be the wrapped model class, using a fully qualified class name with a leading slash in the PHPDoc, for example `@mixin \App\Models\Order`.
- If the resource uses `$this->resource` with an explicit model type and never proxies model members directly, an `@mixin` tag may be unnecessary; follow local project practice.
- If a resource wraps different model types depending on runtime context, report the ambiguity instead of inventing a single incorrect mixin.
