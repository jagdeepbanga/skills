# laravel-new — setup gotchas

Deep operational detail for the bootstrap steps in [SKILL.md](SKILL.md). These are the
sharp edges the starter kit leaves behind; the specifics may drift between kit versions, so
treat symptoms as the signal rather than exact file paths.

## Sail + Postgres

Modern Sail writes **`compose.yaml`** (not `docker-compose.yml`) and rewrites `.env` to the
Sail defaults (`DB_HOST=pgsql`, user `sail`). The first `sail:install` builds a
multi-gigabyte PHP image, so expect a few minutes. Give the `pgsql` container a moment to
report healthy before migrating.

### URL / port mismatch

The installer ships `APP_URL=http://localhost:8000` but sets no `APP_PORT`, so Sail actually
serves on **port 80** — the app is at `http://localhost`, and hitting `localhost:8000` gives
a "connection refused" that looks like a broken build. A stale `APP_URL` also breaks
generated links and Vite asset URLs. Align them one of two ways:

- set `APP_URL=http://localhost` in **both** `.env` and `.env.example`, or
- add `APP_PORT=8000` and `sail up -d` to serve on 8000.

Run `sail artisan config:clear` after editing.

## Pint

The kit ships a bare `{ "preset": "laravel" }`. Extend it, then run `sail bin pint` once so
the rules apply across the scaffold (otherwise CI's `pint --test` fails on every file that
predates `declare_strict_types`):

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

## PHPStan

The kit already ships a **level-7 config** that includes the Larastan and Carbon extensions
and scans `app/`, `bootstrap/`, `config/`, `database/`, and `routes/`. Keep it — don't
overwrite it with a narrower `app/`-only version.

Run it **inside Sail** so it uses the container's PHP; a stock Homebrew `php.ini` caps memory
at 128M and PHPStan can OOM-crash mid-analysis:

```bash
./vendor/bin/sail bin phpstan analyse
```

Don't expect it clean out of the box — the React kit can carry a few findings that are
upstream imprecision (e.g. validation-rule return types) rather than bugs in your code.
Snapshot those into a baseline and chip away later rather than editing kit code:

```bash
./vendor/bin/sail bin phpstan analyse --generate-baseline   # writes phpstan-baseline.neon
```

Add `- phpstan-baseline.neon` as the first entry under `includes:` in `phpstan.neon` and
re-run to confirm zero errors. If a future kit version is already clean, skip this.

## pnpm native builds

`--pnpm` runs `pnpm install`, so `node_modules` **and** `pnpm-lock.yaml` are already present.
But pnpm 11 aborts with `ERR_PNPM_IGNORED_BUILDS` on the `unrs-resolver` native build,
because the kit ships `pnpm-workspace.yaml` with the build neither approved nor denied. That
breaks every `pnpm run` locally and in CI. Fix it and pin the pnpm version so CI's
`cache: pnpm` is deterministic:

```bash
ls pnpm-lock.yaml || pnpm install --lockfile-only   # generate only if missing
```

- Add `"packageManager": "pnpm@<version>"` to `package.json`.
- Acknowledge the skipped build in `pnpm-workspace.yaml` (pnpm 11 keeps build settings here,
  not in `package.json`; `pnpm approve-builds` writes the same block):

  ```yaml
  allowBuilds:
    unrs-resolver: false        # prebuilt bindings ship in the tree; the build is a fallback
  ```

Run `pnpm install` again to sync, then confirm the JS checks pass:
`pnpm run types:check && pnpm run lint:check && pnpm run format:check && pnpm build`.

## CI

The React kit ships `.github/workflows/tests.yml`, which runs `composer setup` then
`composer ci:check` (Pint, ESLint, Prettier, PHPStan, tests). Don't add a second workflow;
patch that file to close two gaps for this stack:

- Add a **Postgres service** plus job-level `DB_*` env (`DB_HOST=127.0.0.1` with matching
  creds) — otherwise the pgsql `migrate` inside `composer setup` fails. Laravel loads `.env`
  immutably, so job-level env vars win over the copied `.env.example`.
- Add a **`pnpm/action-setup`** step and `cache: pnpm` on `setup-node` — the default workflow
  never installs pnpm, so `composer setup`'s `pnpm install` would fail on a runner.

Commit both `composer.lock` and `pnpm-lock.yaml`.
