# Runtime isolation

Git worktrees isolate tracked files, the index, and HEAD. They do not isolate
anything else. Everything below is shared by default and will make two sessions
feel like they are fighting even after the git problem is solved.

Work through this once per repo, write the answers into a hook script, and it
stops being a per-ticket concern.

## What collides

| Resource | Why it breaks | Fix |
|---|---|---|
| `vendor/`, `node_modules/` | gitignored, so a new worktree starts empty | install per worktree |
| `.env`, `.env.local` | gitignored, so not carried over | copy from main tree, then rewrite the per-worktree values |
| App / dev server ports | both sessions bind the same port | assign a port per worktree |
| Database | a migration or rollback in one session breaks the other's test run | separate database per worktree |
| Redis, cache, queue | key and job collisions across sessions | distinct prefix per worktree |
| Docker Compose | container and network name clashes | distinct `COMPOSE_PROJECT_NAME` |
| Build output caches (`.next`, `dist`, `.turbo`) | usually gitignored, so already per-tree | verify nothing points at an absolute shared path |
| Global tool state (nvm, pyenv, direnv) | version pinned per directory | check the version file is tracked |

The database row is the one that most often survives an otherwise correct
worktree setup. A rollback in a sibling session drops your schema mid-test-run
and produces exactly the ambiguous red result worktrees were supposed to
eliminate.

## Hook script

This skill's `scripts/worktree-start.sh` looks for `.iww-setup.sh` at the repo root and runs
it inside the new worktree with these variables exported:

- `IWW_TICKET` — the ticket id, e.g. `TICKET-101`
- `IWW_SLUG` — lowercased, underscore-safe form, e.g. `ticket_101`
- `IWW_DIR` — absolute path to the new worktree
- `IWW_MAIN` — absolute path to the main checkout
- `IWW_PORT` — the port assigned to this worktree

Commit `.iww-setup.sh` so every session gets the same environment. Keep it
idempotent; it may be rerun.

### Node / TypeScript

```bash
#!/usr/bin/env bash
set -euo pipefail

cp "$IWW_MAIN/.env" "$IWW_DIR/.env" 2>/dev/null || true

cd "$IWW_DIR"
npm ci --silent

{
  echo "PORT=$IWW_PORT"
  echo "DATABASE_URL=postgres://localhost:5432/app_$IWW_SLUG"
  echo "REDIS_PREFIX=$IWW_SLUG"
} >> .env

createdb "app_$IWW_SLUG" 2>/dev/null || true
npm run db:migrate
```

### Laravel / PHP

```bash
#!/usr/bin/env bash
set -euo pipefail

cp "$IWW_MAIN/.env" "$IWW_DIR/.env"

cd "$IWW_DIR"
composer install --quiet
npm ci --silent

DB="app_$IWW_SLUG"
mysql -e "CREATE DATABASE IF NOT EXISTS \`$DB\`;"

# GNU sed: drop the '' after -i
sed -i '' "s|^DB_DATABASE=.*|DB_DATABASE=$DB|"                    .env
sed -i '' "s|^APP_URL=.*|APP_URL=http://localhost:$IWW_PORT|"     .env
sed -i '' "s|^CACHE_PREFIX=.*|CACHE_PREFIX=$IWW_SLUG|"            .env
sed -i '' "s|^REDIS_PREFIX=.*|REDIS_PREFIX=$IWW_SLUG|"            .env

php artisan key:generate
php artisan migrate --seed
```

### Docker Compose

Set `COMPOSE_PROJECT_NAME` so containers, volumes, and networks are namespaced,
and map host ports off the assigned port:

```bash
{
  echo "COMPOSE_PROJECT_NAME=$IWW_SLUG"
  echo "APP_PORT=$IWW_PORT"
  echo "DB_PORT=$((IWW_PORT + 1000))"
} >> "$IWW_DIR/.env"
```

Then in `compose.yml` use `"${APP_PORT}:8000"` rather than a hardcoded host port.

## Verification hook

`scripts/worktree-finish.sh` looks for `.iww-verify.sh` at the repo root and runs
it on the integrated result. It is the project's typecheck and test commands, and
a non-zero exit blocks the finish. Without it the script attempts common npm
scripts (`typecheck`, `lint`, `test`) and `php artisan test`. Commit it alongside
`.iww-setup.sh`.

```bash
#!/usr/bin/env bash
set -euo pipefail

npm run typecheck
npm run test
```

## Port assignment

`worktree-start.sh` defaults to the first free port at or above 3100. Passing an
explicit port is better when you want stable, memorable URLs per ticket. Reserve
a block, for example 3101 through 3110, and keep a note in the repo README of
which ticket owns which.

## Disk cost

Each worktree carries its own `node_modules` or `vendor`. Three parallel tickets
on a large JS monorepo is not a trivial amount of disk. If that becomes a
problem, pnpm's content-addressable store or a shared Yarn PnP cache removes most
of the duplication. Do not attempt to symlink `node_modules` between worktrees:
different branches can want different dependency versions, and a shared symlink
reintroduces exactly the coupling you removed.
