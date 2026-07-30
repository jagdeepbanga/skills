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

The React starter kit already ships `larastan/larastan`, `laravel/sail`, and
`laravel/pint` as dev dependencies — check `composer.json` before adding anything, and
don't re-require them. Normally you only need the two spatie packages:

```bash
composer require spatie/laravel-data
composer require spatie/laravel-ray --dev
```

`laravel-data` gives you typed DTOs; `laravel-ray` is dev-only debugging (needs the
desktop Ray app). `larastan` powers the static analysis below and `sail` is the
Dockerised dev environment — both come with the kit.

### 3 — Bring up Sail + Postgres

**Start Docker Desktop first** — `sail up` needs the daemon running (`open -a Docker` on
macOS, then wait for it to report ready). The first `sail:install` builds a
multi-gigabyte PHP runtime image, so expect it to run for a few minutes.

```bash
php artisan sail:install --with=pgsql --devcontainer   # writes compose.yaml + rewrites .env
./vendor/bin/sail up -d
./vendor/bin/sail artisan migrate                       # wait for the pgsql container to be healthy
```

Modern Sail writes **`compose.yaml`** (not `docker-compose.yml`) and rewrites `.env` to
the Sail defaults (`DB_HOST=pgsql`, user `sail`). Give the `pgsql` container a moment to
report healthy before migrating.

**Fix the URL/port mismatch.** The installer ships `APP_URL=http://localhost:8000` but
sets no `APP_PORT`, so Sail actually serves on **port 80** — the app is at
`http://localhost`, and hitting `localhost:8000` gives a "connection refused" that looks
like a broken build. Align them (a stale `APP_URL` also breaks generated links and Vite
asset URLs): either set `APP_URL=http://localhost` in `.env` **and** `.env.example`, or
add `APP_PORT=8000` and `sail up -d` to serve on 8000 to match. Run
`sail artisan config:clear` after editing.

From here on, prefix artisan/composer/pnpm with
`./vendor/bin/sail` to run them inside the containers. An `alias sail='./vendor/bin/sail'`
saves a lot of typing.

### 4 — Drop in the tooling config

**`pint.json`** — the kit ships a bare `{ "preset": "laravel" }`. Extend it, then run
Pint **once** to apply the new rules across the scaffold. Skip that run and CI's
`pint --test` fails on every file that predates `declare_strict_types`:

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

```bash
./vendor/bin/sail bin pint        # applies declare(strict_types=1) etc. repo-wide
```

**`phpstan.neon`** — the kit **already ships a level-7 config** that includes the
Larastan and Carbon extensions and scans `app/`, `bootstrap/`, `config/`, `database/`,
and `routes/`. Keep it — don't overwrite it with a narrower `app/`-only version. The
current scaffold passes level 7 clean, so **no baseline is needed**; just confirm:

```bash
./vendor/bin/sail bin phpstan analyse
```

Only reach for `--generate-baseline` if a future starter-kit version regresses and you
can't fix the findings immediately.

### 5 — pnpm lockfile, native builds & CI

The installer leaves `node_modules` in place but **doesn't emit `pnpm-lock.yaml`**, and
pnpm 11 aborts with `ERR_PNPM_IGNORED_BUILDS` on the `unrs-resolver` native build that
the kit's `.npmrc` (`ignore-scripts=true`) blocks — which breaks both local `pnpm run`
and CI. Fix both, and pin the pnpm version so CI's `cache: pnpm` is deterministic:

```bash
pnpm install --lockfile-only      # generate the missing pnpm-lock.yaml
```

- Add `"packageManager": "pnpm@<version>"` to `package.json`.
- Acknowledge the skipped build in `pnpm-workspace.yaml` (pnpm 11 keeps build settings
  here, not in `package.json`; `pnpm approve-builds` writes the same block):

  ```yaml
  allowBuilds:
    unrs-resolver: false        # prebuilt bindings ship in the tree; the build is a fallback
  ```

Run `pnpm install` again to sync, then confirm the JS checks pass:
`pnpm run types:check && pnpm run lint:check && pnpm run format:check && pnpm build`.

**CI** — the React kit already ships `.github/workflows/tests.yml`, which runs
`composer setup` then `composer ci:check` (Pint, ESLint, Prettier, PHPStan, tests). Don't
add a second workflow; patch that file to close two gaps for this stack:

- Add a `postgres:16-alpine` **service** plus job-level `DB_*` env (`DB_HOST=127.0.0.1`
  with matching creds) — otherwise the pgsql `migrate` inside `composer setup` fails.
  Laravel loads `.env` immutably, so job-level env vars win over the copied `.env.example`.
- Add a **`pnpm/action-setup`** step and `cache: pnpm` on `setup-node` — the kit's default
  workflow never installs pnpm, so `composer setup`'s `pnpm install` would fail on a runner.

Commit both `composer.lock` and `pnpm-lock.yaml`.

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
