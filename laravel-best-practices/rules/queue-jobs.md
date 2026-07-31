# Queue & Job Best Practices

## Set `retry_after` Greater Than `timeout`

If `retry_after` is shorter than the job's `timeout`, the queue worker re-dispatches the job while it's still running, causing duplicate execution.

Incorrect (`retry_after` ≤ `timeout`):
```php
class ProcessReport implements ShouldQueue
{
    public $timeout = 120;
}

// config/queue.php — retry_after: 90 ← job retried while still running!
```

Correct (`retry_after` > `timeout`):
```php
class ProcessReport implements ShouldQueue
{
    public $timeout = 120;
}

// config/queue.php — retry_after: 180 ← safely longer than any job timeout
```

## Use Exponential Backoff

Use progressively longer delays between retries to avoid hammering failing services.

Incorrect (fixed retry interval):
```php
class SyncWithStripe implements ShouldQueue
{
    public $tries = 3;
    // Default: retries immediately, overwhelming the API
}
```

Correct (exponential backoff):
```php
class SyncWithStripe implements ShouldQueue
{
    public $tries = 3;
    public $backoff = [1, 5, 10];
}
```

## Implement `ShouldBeUnique`

Prevent duplicate job processing.

```php
class GenerateInvoice implements ShouldQueue, ShouldBeUnique
{
    public function uniqueId(): string
    {
        return $this->order->id;
    }

    public $uniqueFor = 3600;
}
```

## Always Implement `failed()`

Handle errors explicitly — don't rely on silent failure.

```php
public function failed(?Throwable $exception): void
{
    $this->podcast->update(['status' => 'failed']);
    Log::error('Processing failed', ['id' => $this->podcast->id, 'error' => $exception->getMessage()]);
}
```

## Rate Limit External API Calls in Jobs

Use `RateLimited` middleware to throttle jobs calling third-party APIs.

```php
public function middleware(): array
{
    return [new RateLimited('external-api')];
}
```

## Batch Related Jobs

Use `Bus::batch()` when jobs should succeed or fail together.

```php
Bus::batch([
    new ImportCsvChunk($chunk1),
    new ImportCsvChunk($chunk2),
])
->then(fn (Batch $batch) => Notification::send($user, new ImportComplete))
->catch(fn (Batch $batch, Throwable $e) => Log::error('Batch failed'))
->dispatch();
```

## Self-Append Batchable Jobs to Walk Large Datasets

When a batch must process an unbounded table, don't queue one job per row up front (millions of jobs) or load every record into memory. Use a single `Batchable` job that processes one keyset page, then adds the *next* page back into the running batch. The batch drains itself one page at a time and finishes when a page comes back empty.

Use keyset pagination (`forPageAfterId`), never `OFFSET` — offset degrades on deep pages and skips or repeats rows when records change mid-run.

```php
use Illuminate\Bus\Batchable;
use Illuminate\Contracts\Queue\ShouldQueue;

class ProcessUsersBatch implements ShouldQueue
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

        $users = User::forPageAfterId(perPage: 100, lastId: $this->lastId)->get();

        $users->each(function (User $user) {
            // do something...
        });

        if ($users->isNotEmpty()) {
            $this->batch()->add(new self($users->last()->id));
        }
    }
}
```

Dispatch it as a batch so `then()` / `catch()` / `finally()` callbacks and progress tracking work:

```php
Bus::batch([new ProcessUsersBatch])
    ->name('process-users')
    ->then(fn (Batch $batch) => Log::info('All users processed'))
    ->dispatch();
```

Check `$this->batch()?->cancelled()` at the top of `handle()` so a cancelled batch stops walking instead of re-appending forever.

## Keep Long-Running Queries Out of Console Commands

A console command that iterates a large table runs in one process — a deploy, timeout, or crash loses all progress, and nothing retries. Keep the command thin: it dispatches a batch and returns. Put the walking logic in a `Batchable` job (see above) so work runs on queue workers with retries, backoff, and failure handling.

Incorrect (long-running work inside the command):
```php
class RecalculateScores extends Command
{
    public function handle(): void
    {
        User::where('active', true)->chunkById(200, function ($users) {
            $users->each->recalculateScore(); // hours of work, one fragile process
        });
    }
}
```

Correct (command dispatches a batch, workers do the work):
```php
class RecalculateScores extends Command
{
    public function handle(): void
    {
        Bus::batch([new RecalculateScoresBatch])
            ->name('recalculate-scores')
            ->dispatch();

        $this->info('Dispatched score recalculation.');
    }
}
```

## `retryUntil()` Needs `$tries = 0`

When using time-based retry limits, set `$tries = 0` to avoid premature failure.

```php
public $tries = 0;

public function retryUntil(): \DateTimeInterface
{
    return now()->addHours(4);
}
```

## Use `ShouldBeUniqueUntilProcessing` for Early Lock Release

`ShouldBeUnique` holds the lock until the job completes. `ShouldBeUniqueUntilProcessing` releases it when processing starts, allowing new instances to queue.

```php
class UpdateSearchIndex implements ShouldQueue, ShouldBeUniqueUntilProcessing
{
    // Lock releases when processing begins, not when it finishes
}
```

## Use Horizon for Complex Queue Scenarios

Use Laravel Horizon when you need monitoring, auto-scaling, failure tracking, or multiple queues with different priorities.

```php
// config/horizon.php
'environments' => [
    'production' => [
        'supervisor-1' => [
            'connection' => 'redis',
            'queue' => ['high', 'default', 'low'],
            'balance' => 'auto',
            'minProcesses' => 1,
            'maxProcesses' => 10,
            'tries' => 3,
        ],
    ],
],
```
