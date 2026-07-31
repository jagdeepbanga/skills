---
name: laravel-new
description: Preferred tech stack and conventions for new Laravel projects. Use when the user wants to start, bootstrap, scaffold, or set up a new Laravel app/project/backend.
---

# Starting a Laravel Project

Every new app starts from the same locked-in stack — treat the choices below as fixed unless
the user asks for a swap. Deep setup gotchas live in [REFERENCE.md](REFERENCE.md).

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

### 1 — Create the app & add packages

```bash
laravel new my-app --react --database=pgsql --phpunit --pnpm
```

Pulls the React + Inertia starter kit (TypeScript, Tailwind 4, Vite); use `--vue`/`--livewire`
only when the user names it. It already bundles `larastan`, `laravel/sail`, and `laravel/pint`
— check `composer.json` first, then add only the two spatie packages:

```bash
composer require spatie/laravel-data
composer require spatie/laravel-ray --dev   # dev-only; needs the desktop Ray app
```

### 2 — Bring up Sail + Postgres

```bash
# Start Docker Desktop first, then:
php artisan sail:install --with=pgsql --devcontainer   # writes compose.yaml + rewrites .env
./vendor/bin/sail up -d
./vendor/bin/sail artisan migrate                       # wait for pgsql to be healthy
```

The installer ships a mismatched `APP_URL`/port — align it (see [REFERENCE.md](REFERENCE.md))
before the app looks broken. From here on, prefix artisan/composer/pnpm with
`./vendor/bin/sail` (alias it to `sail`).

### 3 — Drop in the tooling config

Extend the kit's bare `pint.json` (add `declare_strict_types`, `multiline_promoted_properties`;
disable `single_line_empty_body` — full config in [REFERENCE.md](REFERENCE.md)), then:

```bash
./vendor/bin/sail bin pint            # applies declare(strict_types=1) etc. repo-wide
./vendor/bin/sail bin phpstan analyse # keep the kit's level-7 config; run inside Sail
```

Run Pint once up front (else CI's `pint --test` fails on pre-`declare_strict_types` files).
Run PHPStan inside Sail; it won't be clean out of the box — baseline upstream kit findings
rather than editing kit code (workflow in [REFERENCE.md](REFERENCE.md)).

### 4 — pnpm lockfile, native builds & CI

`--pnpm` already produced `node_modules` and `pnpm-lock.yaml`, but pnpm 11 aborts on the
`unrs-resolver` native build and the kit's CI needs a Postgres service + pnpm setup — fixes
(pin `packageManager`, `allowBuilds`, workflow patches) in [REFERENCE.md](REFERENCE.md).
Commit both lockfiles.

## Writing code here

**PHP / Laravel** — `declare(strict_types=1)` in every file (Pint enforces it); Eloquent
before raw SQL; model payloads as `spatie/laravel-data` objects, not loose arrays; keep
Larastan green, baselining only what you can't fix now.

**TypeScript / frontend** — `.ts`/`.tsx` throughout, no plain `.js`; strict mode targeting
ESNext; prefer `type` over `interface` unless you need declaration merging; style with
Tailwind 4 utilities (`@import "tailwindcss"`), custom CSS only as a last resort.

## Day-to-day commands

Frontend (pnpm only): `pnpm dev` · `pnpm build` · `pnpm tsc --noEmit`. Backend through Sail:
`sail up -d` · `sail artisan test` · `sail bin pint` · `sail bin phpstan analyse`.

## Off-limits

npm/yarn (pnpm only) · webpack or non-Vite bundlers · Tailwind 3 syntax and
`tailwind.config.js` · non-Laravel PHP frameworks (Lumen, Symfony, plain PHP) · untyped
`.js` where a typed `.ts`/`.tsx` would do.
