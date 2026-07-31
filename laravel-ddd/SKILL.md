---
name: laravel-ddd
description: "Apply this skill when structuring a Laravel application around domain-driven design — organizing code into src/Domain/<Domain> with Actions, Payloads, Models, Enums, and Batches, wiring invokable versioned controllers, or deciding where business logic should live. Use when creating a new domain/module, adding a business operation, refactoring fat controllers or models, introducing DTOs/value objects, designing state machines with enums, structuring queued batch jobs that process large datasets, or reviewing Laravel code for domain boundaries and layering. This is a fuller architectural methodology than laravel-best-practices' architecture rule — use this skill when the whole request/response flow needs to be structured, not just a single pattern fixed."
license: MIT
metadata:
  author: robmellett
  source: https://robmellett.com/blog/laravel-domain-driven-design-agent
---

# Laravel Domain-Driven Design

A pragmatic DDD architecture for Laravel apps built with AI agents in mind. Core principle: **the folder tree should read like the product owner's vocabulary, and a new engineer should find any business operation in under 10 seconds.**

This is a stricter, fuller methodology than [`laravel-best-practices`](../laravel-best-practices/SKILL.md)'s `architecture.md` rule. Reach for this skill when structuring a whole domain or request/response flow; reach for `laravel-best-practices` for everything else (queries, caching, validation details, etc.) — the two are complementary and should not contradict each other.

## Directory structure

```
src/Domain/<DomainName>/
├── Actions/          (business operations)
├── Payloads/         (typed DTOs)
├── Models/           (Eloquent models)
├── Enums/            (status/type values)
├── Batches/          (queued jobs that walk large datasets, optional)
├── Events/           (domain events, optional)
└── Exceptions/       (domain exceptions, optional)

src/Support/<VendorName>/   (third-party SDK adapters, one folder per vendor)

app/Http/
├── Controllers/<Domain>/V1/    (invokable, versioned)
├── Requests/<Domain>/V1/       (validation + payload())
└── Responses/                  (Responsable classes)
```

`composer.json` autoload:
```json
"autoload": {
    "psr-4": {
        "App\\": "app/",
        "Domain\\": "src/Domain/",
        "Shared\\": "src/Shared/",
        "Support\\": "src/Support/"
    }
}
```

## The eight core rules

### 1. Business-first naming
Replace technical defaults with the product owner's vocabulary (`User` → `Customer`, `Job` → `Broadcast`, `Task` → `AutomationStep`). If the folder name wouldn't make sense to a non-engineer, rename it.

### 2. Invokable controllers
One controller per operation, one `__invoke()` method, versioned under `V1/`, `V2/` for safe breaking changes. Controllers exclusively wire request → action → response — no business logic, no direct model writes.

### 3. Form Requests as DTO carriers
Validation stays in the `FormRequest`; the same class produces a typed payload via `payload()`. Controllers never touch `$request->all()` or `$request->validated()` directly.

```php
final class StoreTaskRequest extends FormRequest
{
    public function rules(): array { /* validation */ }

    public function payload(): StoreTaskPayload
    {
        return new StoreTaskPayload(
            title: $this->validated('title'),
            dueAt: $this->date('due_at'),
            priority: Priority::from($this->validated('priority')),
        );
    }
}
```

### 4. Payloads (DTOs)
`final readonly class` with promoted constructor properties — strong typing and immutability, no external package needed. Include `toArray()`.

```php
final readonly class StoreTaskPayload
{
    public function __construct(
        public string $title,
        public ?CarbonImmutable $dueAt,
        public Priority $priority,
    ) {}

    public function toArray(): array { /* conversion */ }
}
```

**All communication between layers happens through Payloads. Never pass a bare `array $data` across a boundary.**

### 5. Actions
One business operation per invokable class, named `{Verb}{Domain}Action`. Dependencies come from constructor injection (never `app()`/`resolve()` internally); actions return models or values, never arrays. Wrap multi-write operations in a transaction; throw domain exceptions for precondition failures.

```php
final readonly class CreateTaskAction
{
    public function __construct(
        private RecordTaskCreatedAction $recordAuditTrail,
    ) {}

    public function __invoke(StoreTaskPayload $payload): Task
    {
        return DB::transaction(function () use ($payload) {
            $task = Task::create($payload->toArray());
            ($this->recordAuditTrail)($task);
            return $task;
        });
    }
}
```

**One action = one user story.**

### 6. Models are dumb
Models hold relationships, casts, and accessors only — no saving, validation, or orchestration. Logic touching more than one model belongs in an Action. Prefer ULIDs over auto-increment IDs.

```php
final class Task extends Model
{
    protected $casts = [
        'priority' => Priority::class,
        'status'   => TaskStatus::class,
        'due_at'   => 'immutable_datetime',
    ];

    public function owner(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
```

### 7. Responses via Responsable
Return `Responsable` classes for a consistent JSON shape instead of ViewModels or ad-hoc arrays.

```php
final readonly class JsonDataResponse implements Responsable
{
    public function __construct(
        private mixed $data,
        private int $status = 200,
    ) {}

    public function toResponse($request): JsonResponse
    {
        return new JsonResponse(['data' => $this->data], $this->status);
    }
}
```

### 8. State via enums and guards
Backed enums carry transition logic. Only reach for `spatie/laravel-model-states` once the transition graph outgrows a `match`.

```php
enum TaskStatus: string
{
    case Draft     = 'draft';
    case Active    = 'active';
    case Completed = 'completed';

    public function canTransitionTo(self $next): bool
    {
        return match ($this) {
            self::Draft     => $next === self::Active,
            self::Active    => $next === self::Completed,
            self::Completed => false,
        };
    }
}

final readonly class CompleteTaskAction
{
    public function __invoke(Task $task): Task
    {
        throw_unless(
            $task->status->canTransitionTo(TaskStatus::Completed),
            new InvalidStateTransition("cannot be completed from {$task->status->value}"),
        );
        $task->update(['status' => TaskStatus::Completed]);
        return $task;
    }
}
```

## Lightweight CQRS

Split at the controller level: `IndexController`/`ShowController` for reads, `StoreController`/`UpdateController`/`DestroyController` for writes. Reads query models directly; writes go through Actions.

**A controller either reads or writes. Never both.**

## Batches for large datasets

Long-running work over a large table belongs in `src/Domain/<Domain>/Batches/`, not in a console command, an Action, or an ad-hoc job. Name the class `{Verb}{Domain}Batch` (e.g. `RecalculateCustomerScoresBatch`) so it reads in the domain's vocabulary alongside its Actions.

A Batch is a single `Batchable` job that processes one keyset page and appends the next page back into the running batch — it drains the table one page at a time and stops when a page comes back empty. Use `forPageAfterId` (keyset pagination), never `OFFSET`.

```php
namespace Domain\Customer\Batches;

use Domain\Customer\Models\Customer;
use Illuminate\Bus\Batchable;
use Illuminate\Contracts\Queue\ShouldQueue;

final class RecalculateCustomerScoresBatch implements ShouldQueue
{
    use Batchable;

    public function __construct(
        public readonly int $lastId = 0,
    ) {}

    public function handle(): void
    {
        if ($this->batch()?->cancelled()) {
            return;
        }

        $customers = Customer::forPageAfterId(perPage: 100, lastId: $this->lastId)->get();

        $customers->each(function (Customer $customer) {
            // delegate real work to an Action — the Batch only walks the data
        });

        if ($customers->isNotEmpty()) {
            $this->batch()->add(new self($customers->last()->id));
        }
    }
}
```

- The Batch **walks** the dataset; per-record business logic still lives in an Action the Batch invokes. Keep the loop body thin.
- Console commands and scheduled tasks dispatch the Batch and return immediately — they never run the query themselves:

```php
Bus::batch([new RecalculateCustomerScoresBatch])
    ->name('recalculate-customer-scores')
    ->dispatch();
```

See [`laravel-best-practices`](../laravel-best-practices/rules/queue-jobs.md) for the queue-level details (batch callbacks, cancellation, `retry_after` vs `timeout`).

## PHP style enforcement

- `declare(strict_types=1);` in every file
- `final readonly class` by default (drop `readonly` only when mutation is required)
- Constructor property promotion, always
- Return and parameter types on every method
- PSR-12 formatting
- `match` over nested ternaries
- Never call `app()`, `resolve()`, or facades inside Domain classes — inject dependencies
- Models use ULIDs

## Cross-domain boundaries

- Cross-domain calls go through Actions only
- Avoid foreign keys across important domain boundaries — use IDs with an explicit lookup instead
- An Action may call another domain's Action, but never touch another domain's Models directly
- Keep private helpers and internal models inside their own namespace

## Vendor integrations

Third-party SDK wrappers (Stripe, Twilio, Mailgun, S3, ...) live in `src/Support/<VendorName>/` — one folder per vendor, e.g. `src/Support/Stripe/`, `src/Support/Twilio/`. Never a catch-all `src/Support/Integrations/`, and never inside `src/Domain` — a vendor has no business vocabulary of its own.

- A Domain owns the contract (interface); the vendor folder owns the implementation. Actions type-hint the contract, never the vendor SDK class directly.
- `src/Support/<VendorName>` classes hold no business logic — only translation between the vendor's shape and the app's Payloads/DTOs.
- Bind the concrete adapter to the contract in a service provider so the vendor can be swapped (e.g. Stripe → Braintree) without touching Domain code.
- Vendor config (API keys, webhook secrets) stays in `config/services.php`, injected via the constructor — never read with `env()` inside `src/Support`.

```php
// src/Domain/Billing/Contracts/PaymentGateway.php
interface PaymentGateway
{
    public function charge(int $amountInCents, string $customerId): PaymentResult;
}

// src/Support/Stripe/StripePaymentGateway.php
final readonly class StripePaymentGateway implements PaymentGateway
{
    public function __construct(private StripeClient $client) {}

    public function charge(int $amountInCents, string $customerId): PaymentResult
    {
        $charge = $this->client->charges->create([
            'amount'   => $amountInCents,
            'customer' => $customerId,
            'currency' => 'usd',
        ]);

        return new PaymentResult(
            successful: $charge->status === 'succeeded',
            reference: $charge->id,
        );
    }
}
```

```php
// AppServiceProvider::register()
$this->app->bind(PaymentGateway::class, StripePaymentGateway::class);
```

```
src/Support/Stripe/
├── StripePaymentGateway.php
└── StripeWebhookVerifier.php

src/Support/Twilio/
└── TwilioSmsGateway.php
```

## Naming reference

| Type | Pattern | Example |
|------|---------|---------|
| Action | `{Verb}{Domain}Action` | `CreateTaskAction` |
| Batch | `{Verb}{Domain}Batch` | `RecalculateTaskScoresBatch` |
| Controller | `{Verb}{Domain}Controller` | `StoreTaskController` |
| Request | `{Verb}{Domain}Request` | `StoreTaskRequest` |
| Payload | `{Verb}{Domain}Payload` | `StoreTaskPayload` |
| Response | `{Shape}Response` | `JsonDataResponse` |
| Enum | `{Concept}{Suffix}` | `TaskStatus`, `Priority` |
| Exception | `{Problem}Exception` | `InvalidStateTransition` |
| Vendor adapter | `{Vendor}{Contract}` | `StripePaymentGateway` |

## Example domain layout

```
src/Domain/Task/
├── Actions/
│   ├── CreateTaskAction.php
│   ├── CompleteTaskAction.php
│   └── RecordTaskCreatedAction.php
├── Payloads/
│   └── StoreTaskPayload.php
├── Models/
│   └── Task.php
├── Enums/
│   ├── TaskStatus.php
│   └── Priority.php
├── Batches/
│   └── RecalculateTaskScoresBatch.php
└── Exceptions/
    └── InvalidStateTransition.php

app/Http/
├── Controllers/Task/V1/
│   ├── IndexTaskController.php
│   ├── ShowTaskController.php
│   └── StoreTaskController.php
├── Requests/Task/V1/
│   └── StoreTaskRequest.php
└── Responses/
    ├── JsonDataResponse.php
    └── JsonErrorResponse.php
```

Namespaces: `Domain\Task\Actions\CreateTaskAction`, `Domain\Task\Payloads\StoreTaskPayload`, `App\Http\Controllers\Task\V1\StoreTaskController`.

## Pre-ship checklist

- [ ] Every business operation lives in an Action
- [ ] Controllers wire Request → Action → Response only
- [ ] No bare arrays cross a boundary — Payloads everywhere
- [ ] Form Requests handle validation and `payload()` generation
- [ ] Models contain no business logic
- [ ] `declare(strict_types=1)` on every file
- [ ] All classes `final` (drop `readonly` only when mutation is required)
- [ ] No `app()` / `resolve()` calls — dependency injection always
- [ ] State transitions gated by enum guards or explicit Actions
- [ ] Large-dataset walks live in `Batches/` (self-appending Batchable jobs), never in console commands
- [ ] Tests target Actions and HTTP endpoints, not models
- [ ] Vendor SDKs are wrapped in `src/Support/<VendorName>/`, never called directly from a Domain
