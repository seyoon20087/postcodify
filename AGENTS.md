# AGENTS.md

Postcodify: a search server and jQuery client for Korean road-name addresses and postcodes. LGPLv3.
The user-facing docs (in Korean) are in [docs/](docs/README.md).

## Layout

- `lib/indexer.php`: CLI entry point. `php indexer.php <command>` maps `foo-bar` to the class `Postcodify_Indexer_Foo_Bar`.
- `lib/search.php`: HTTP/JSONP search endpoint. Also works from the CLI: `php search.php "세종대로 110"`.
- `lib/autoload.php`: defines `POSTCODIFY_VERSION` and loads `lib/config.php`. Class `Postcodify_X_Y` lives in `lib/classes/x/y.php`.
- `lib/classes/indexer/`: one class per indexer command (`download`, `createdb`, `verifydb`, `set-postcode`, `download-updates`, `update`, `sqlite-convert`). `checkenv.php` checks the environment before `createdb` runs.
- `lib/classes/parser/`: readers for the source data files (juso.go.kr, epost.go.kr).
- `lib/classes/server/`: the search engine (query parsing, DB access, cache, result formatting). See [docs/server.md](docs/server.md).
- `lib/resources/schema.php`: the 11 `postcodify_*` tables and their indexes. `createdb`, `verifydb` and `sqlite-convert` all read it.
- `lib/emulators/`: endpoints that emulate other postcode APIs.
- `api/`: the jQuery client (`search.js`, `popup.js` and their `.min.js` builds).
- `data/` (gitignored): downloaded source zips. The indexer reads them without unzipping.

## Environment

- The dev container (`.devcontainer/`) has PHP 8.5, MariaDB, and the extensions the indexer needs (`pdo_mysql`, `zip`, `mbstring`, `pcntl`, `shmop`). On startup it creates the DB `postcodify` with user `postcodify` and password `yourpassword`.
- `lib/config.php` is gitignored. To create it, copy `lib/config.example.php` and fill in the DB credentials. Never commit it.
- The indexer runs only on the CLI, on Linux, against MySQL/MariaDB. The search server can use MySQL or SQLite.

## Working on the code

- The code targets very old PHP versions (5.x style: `array()`, no namespaces or type hints) and must also run on PHP 8.5. Match the surrounding style: Allman braces, 4-space indent, Korean comments and user-facing messages.
- There is no test suite. To check changes:
  - `php -l <file>` for syntax.
  - `php indexer.php verifydb` after DB changes.
  - `php search.php "<query>"` to try searches.
- A full `download` + `createdb` takes from 20 minutes to several hours and needs a few GB of disk. Don't start one unless the task requires it.
- `createdb` overwrites the existing tables. `sqlite-convert <file>` overwrites the target file.
- Download URLs are constants at the top of `download.php` and `download_updates.php`. The upstream sites change them from time to time (see the git log).
- When you change a schema, update `resources/schema.php`. The verifier and the SQLite converter both depend on it.
- The `postcodify_settings` table stores the data date (`updated`) and the `oldpostcodes` flag. `update` and `download-updates` read both.
- The `.min.js` files in `api/` are build outputs. If you edit `search.js` or `popup.js`, regenerate the matching `.min.js` or say that it needs regenerating.
