---
name: laravel-new
description: Preferred tech stack and conventions for new Laravel projects. Use when the user wants to start, bootstrap, scaffold, or set up a new Laravel app/project/backend.
---

# Starting a Laravel Project

Every new app starts from the same locked-in stack. Treat the choices below as fixed —
don't propose swaps unless the user explicitly asks for one.

## The stack

| Layer | Choice | Notes |
|-------|--------|-------|
| Framework | Laravel 13+ | No Lumen, Symfony, or raw PHP |
| Database | PostgreSQL | Run locally through Laravel Sail |
| Dev environment | Laravel Sail | Docker; `./vendor/bin/sail …` |
| Tests | PHPUnit | Installer default (`--pest` only on request) |
| Bundler | Vite | Config lives in `vite.config.ts` |
| Styling | Tailwind CSS 4+ | CSS-first — no `tailwind.config.js` |
| Frontend language | TypeScript 5+ | Strict mode, as the starter kit ships it |
| JS package manager | pnpm | Never npm or yarn |
| DTOs | spatie/laravel-data | Typed request/response objects |
| Debugging | spatie/laravel-ray | Dev-only; needs the desktop Ray app |
| Formatting | Laravel Pint | `declare(strict_types=1)` everywhere |
| Static analysis | Larastan (PHPStan) | Level 7 |

## Bootstrapping

### 1 — Create the app

```bash
laravel new my-app --react --database=pgsql --phpunit --pnpm
```

This pulls the React + Inertia starter kit (TypeScript, Tailwind 4, Vite) and installs
JS deps with pnpm. Reach for `--vue` or `--livewire` instead only when the user names it.

### 2 — Pull in the packages

```bash
composer require spatie/laravel-data
composer require spatie/laravel-ray --dev
composer require larastan/larastan --dev
composer require laravel/sail --dev
```

`laravel-data` gives you typed DTOs; `laravel-ray` is dev-only debugging; `larastan`
powers the static analysis below; `sail` is the Dockerised dev environment.

### 3 — Bring up Sail + Postgres

```bash
php artisan sail:install --with=pgsql --devcontainer   # writes docker-compose.yml + .env
./vendor/bin/sail up -d
./vendor/bin/sail artisan migrate
```

From here on, prefix artisan/composer/pnpm with `./vendor/bin/sail` to run them inside
the containers. An `alias sail='./vendor/bin/sail'` saves a lot of typing.

### 4 — Drop in the tooling config

**`pint.json`** (project root):

```json
{
    "preset": "laravel",
    "rules": {
        "declare_strict_types": true,
        "single_line_empty_body": false,
        "multiline_promoted_properties": true
    }
}
```

**`phpstan.neon`** (project root):

```neon
includes:
    - vendor/larastan/larastan/extension.neon

parameters:
    paths:
        - app/

    level: 7
```

A brand-new scaffold won't clear level 7 on the first pass — Larastan is strict about
relation generics and the like in the default code. Snapshot what's there, then chip
away at it:

```bash
./vendor/bin/phpstan analyse --generate-baseline
```

### 5 — Wire up CI

Commit both `pnpm-lock.yaml` and `composer.lock`, then add `.github/workflows/ci.yml`.
It spins up a Postgres service and runs formatting, analysis, and tests on every push/PR:

```yaml
name: CI
on:
  push:
    branches: [main, master]
  pull_request:

jobs:
  test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:16-alpine
        env:
          POSTGRES_DB: laravel
          POSTGRES_USER: laravel
          POSTGRES_PASSWORD: secret
        ports: ["5432:5432"]
        options: >-
          --health-cmd="pg_isready -U laravel" --health-interval=5s
          --health-timeout=5s --health-retries=10
    env:
      DB_CONNECTION: pgsql
      DB_HOST: 127.0.0.1
      DB_PORT: 5432
      DB_DATABASE: laravel
      DB_USERNAME: laravel
      DB_PASSWORD: secret
    steps:
      - uses: actions/checkout@v4
      - uses: shivammathur/setup-php@v2
        with:
          php-version: "8.4"
          coverage: none
      - uses: pnpm/action-setup@v4
      - uses: actions/setup-node@v4
        with:
          node-version: "22"
          cache: pnpm
      - run: composer install --no-interaction --prefer-dist --no-progress
      - run: pnpm install --frozen-lockfile && pnpm build
      - run: cp .env.example .env && php artisan key:generate && php artisan migrate --force
      - run: ./vendor/bin/pint --test
      - run: ./vendor/bin/phpstan analyse --no-progress
      - run: php artisan test
```

## Writing code here

**PHP / Laravel**
- Every file opens with `declare(strict_types=1)` (Pint enforces it).
- Reach for Eloquent before dropping to raw SQL.
- Model incoming/outgoing payloads as `spatie/laravel-data` objects rather than loose arrays.
- Keep Larastan green — add to the baseline only when you can't fix it now.

**TypeScript / frontend**
- `.ts` / `.tsx` throughout; no plain `.js` when TypeScript is an option.
- `tsconfig` stays in strict mode, targeting ESNext.
- Favour `type` aliases over `interface` unless you actually need declaration merging.
- Style with Tailwind 4 utilities (`@import "tailwindcss"`); write custom CSS only as a last resort.

## Day-to-day commands

```bash
# Frontend (pnpm only)
pnpm dev                        # Vite dev server
pnpm build                      # production build
pnpm tsc --noEmit               # type check

# Backend (through Sail)
./vendor/bin/sail up -d         # start the environment
./vendor/bin/sail artisan test  # run the suite
./vendor/bin/sail bin pint      # format
./vendor/bin/sail bin phpstan analyse
```

## Off-limits
- npm, yarn, or any package manager that isn't pnpm
- webpack or other bundlers in place of Vite
- Tailwind 3-era syntax and `tailwind.config.js`
- Non-Laravel PHP frameworks (Lumen, Symfony, plain PHP)
- Untyped `.js` where a typed `.ts`/`.tsx` would do
