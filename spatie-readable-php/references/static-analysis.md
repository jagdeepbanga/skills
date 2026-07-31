# Static analysis

Static analysis checks code without running it, catching problems tests miss: wrong return types, docblocks that don't match the code, dead code, unexpected type juggling. It complements a test suite rather than replacing it — static analysis catches whole categories of bugs without writing tests, but you still need tests to verify actual runtime results. Use both.

## Tool choice: PHPStan (Larastan on Laravel)

Use PHPStan (or Psalm — similar functionality). On Laravel projects use [Larastan](https://github.com/larastan/larastan), a PHPStan wrapper whose stubs teach PHPStan Laravel's magic — plain PHPStan gets confused by it.

## Strictness levels: start low, climb up

PHPStan has 10 levels (0–9). Level 0 reports only crash-level errors; level 9 is paranoid and reports everything. Introduce it at a low level, fix all errors, then raise the level. Level 2 catches int-string type juggling (`$int + $string`); level 4 catches unreachable/dead code.

```bash
vendor/bin/phpstan analyse src --level=2
```

## Avoid type juggling

Don't rely on PHP's automatic type coercion (e.g. adding an `int` and a `string`) — it's hard to read and PHP may handle edge cases unexpectedly. Fix the type hints instead of leaning on juggling.

## Config in `phpstan.neon` + composer script

PHPStan auto-reads `phpstan.neon` from the project root (NEON is YAML-like). Set level and paths there so you don't repeat CLI flags:

```neon
parameters:
    level: 4
    paths:
        - src
```

Add a composer shortcut so you run `composer analyse`:

```json
"scripts": {
    "analyse": "vendor/bin/phpstan analyse src --level=4"
}
```

## Docblocks are back — for expressive types

Native PHP type hints let you drop docblocks for simple cases (`function sum(int $a, int $b): int`). But PHPStan's docblock types are far more expressive than the native system, so docblocks return — now carrying types the language can't express (array shapes, generics, `class-string`, callable signatures). Team convention: if you add a docblock, document every parameter *and* the return value.

## Integer ranges: `positive-int`, `negative-int`, `int<min, max>`

Constrain integers beyond native `int`. `positive-int` accepts `int<1, max>`; `negative-int` accepts up to `-1`. Define custom ranges with literals or the `min`/`max` keywords.

```php
/**
 * @param positive-int $divideBy
 */
```

```
int<0, 100>    // 0 through 100
int<min, 200>  // lowest possible up to 200
int<50, max>   // 50 and up
```

## `class-string` for class-name arguments

When a `string` param is actually a class name, hint `class-string` so PHPStan rejects arbitrary strings. Parameterize it — `class-string<Type>` — to require a specific base class/interface.

```php
use App\Mailers\Mailer;

/**
 * @param class-string<Mailer> $mailer
 */
function createMailer(string $mailer): Mailer
{
    return new $mailer;
}
```

Passing a non-`Mailer` class name errors: `expects class-string<App\Mailers\Mailer>, string given`.

## Array value/key types

Native `array` can't describe its contents; PHPStan can. Prefer the two-argument form specifying both key and value type (course convention: always type both).

```
array<int, string>          // int keys, string values
array<string, int|string>   // string keys, values are int OR string
array<int, mixed>           // int keys, any value
```

## Array shapes (specific keys)

Describe an array with known keys and per-key types; IDEs then autocomplete keys and PHPStan flags unknown offsets. Use `?` after a key for optional keys. Nest a shape inside `array<...>` for a list of shaped arrays.

```
array{first_name: string, last_name: string}
array{optional?: string, required: int}
array<array{first_name: string, last_name: string}>   // many shaped items
```

For objects in arrays, hint `array<int, User>` (or `array<User>`) so IDEs autocomplete when looping over the objects.

## Callable signatures

Type the parameters and return of a `callable` param so a mismatched closure is caught.

```php
/**
 * @param callable(string): string $manipulator
 */
```

```
callable(string, string): int   // two strings -> int
callable(string?)               // one optional string arg
callable(...User): (int|null)   // variadic User args -> int|null
```

## Generics: `@template` on a class

When a class handles multiple types (e.g. a collection), declare a type variable with `@template T` above the class, then reference `T` in property/method docblocks. Passing a concrete type fills `T` in, so PHPStan tracks what the instance holds.

```php
/**
 * @template T
 */
class Collection
{
    /** @var array<int, T> */
    public array $items = [];

    /**
     * @param T $item
     * @return self<T>
     */
    public function add($item): self { /* ... */ }

    /**
     * @return T
     */
    public function first() { /* ... */ }
}
```

After `->add(User::find(1))`, `first()` returns a `User`; calling an undefined method on it errors.

## Generics: `@template` on a function/method

Declare `@template T` in a function's own docblock to express the relationship between input and output. Combined with `class-string<T>`, PHPStan infers the concrete return type from the argument.

```php
/**
 * @template T
 * @param class-string<T> $className
 * @return T
 */
function instantiate(string $className): object
{
    return new $className;
}
```

`instantiate(RedisCache::class)` is treated as returning `RedisCache`. `@template` also links a callable's return to the function's return:

```php
/**
 * @template T
 * @param (callable(): T) $callback
 * @return T
 */
function once(callable $callback): mixed
```

## Multiple templates + `array-key`

Declare several type variables with meaningful names. `array-key` is the constraint for anything usable as an array key (`int|string`). A method-level `@template` can combine with class-level ones.

```php
/**
 * @template TKey of array-key
 * @template TValue
 */
class Collection implements ArrayAccess
{
    /** @var array<TKey, TValue> */
    protected $items = [];

    /** @param callable(TValue, TKey): mixed $callback */
    public function each(callable $callback) { /* ... */ }

    /**
     * @template TMapValue
     * @param  callable(TValue, TKey): TMapValue  $callback
     * @return static<TKey, TMapValue>
     */
    public function map(callable $callback) { /* ... */ }
}
```

`map()` transforms `TValue`; PHPStan re-types the resulting collection to the callback's return type, catching a wrong param type in a chained call.

## Test your types with `assertType`

Docblock types are easy to get wrong. `PHPStan\Testing\assertType($expectedType, $expression)` verifies inferred types. Store these in a `/types` directory with a separate max-level config.

```php
use function PHPStan\Testing\assertType;

assertType('App\Collection<int, int>', new Collection([1]));
assertType('App\Collection<int, string>', $collection->map(fn (int $i) => "num $i"));
```

```neon
# phpstan.types.neon.dist
parameters:
    paths:
        - types
    level: max
```

Run with `vendor/bin/phpstan --configuration="phpstan.types.neon.dist"` (wrap in a `check-types` composer script). A wrong assertion fails: `Expected type App\Collection<int, string>, actual: App\Collection<int, int>`.

## Baseline for legacy projects

Introducing PHPStan (or raising a level) on an existing project can surface an avalanche of errors. Instead of giving up, generate a baseline — a file recording all current errors so only *new* ones get reported going forward.

```bash
vendor/bin/phpstan --generate-baseline
```

Then include the generated `phpstan-baseline.neon`:

```neon
includes:
    - phpstan-baseline.neon

parameters:
    # your usual options
```

## Ignoring a single error

For a one-off you don't have time to fix, use `@phpstan-ignore-next-line`. Use sparingly.

```php
/** @phpstan-ignore-next-line */
$result = 1 + 'string';
```

## Run on CI

Run PHPStan locally before committing and on CI to catch newly pushed issues. Use `--error-format=github` for inline GitHub annotations.

```yaml
      - name: Run PHPStan
        run: ./vendor/bin/phpstan --error-format=github
```
