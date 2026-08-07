# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

`setup-benchopt` is a **composite GitHub Action** that installs
[benchopt](https://benchopt.github.io) onto a CI runner, optionally alongside
the conda toolchain (miniforge and mamba) that benchopt uses to manage
benchmark environments. It is not an application; there is no build step. The
"code" is `action.yml` plus a single install script.

## Architecture

Two files carry all the logic:

- **`action.yml`** — the composite action definition. It declares the inputs
  (`version`, `branch`, `python-version`, `conda`, `environment-name`,
  `cache-dir`, `shorten-windows-path`) and orchestrates steps: set up miniforge
  *or* plain Python (mutually exclusive on `inputs.conda`), optionally cache
  directories, set `BENCHOPT_CONDA_CMD=mamba`, then run `install.sh`. The
  `install.sh` step is duplicated with two different shells and step ids
  (`install-conda` uses `bash -el {0}` login shell; `install` uses plain
  `bash`); the `benchopt-version` output falls back between the two step ids.
  A final Windows-only step rebuilds `PATH` from an allowlist, because
  benchopt's `cmd`-based conda calls inline `PATH` and overflow cmd's
  8191-character limit. It runs last so that installing benchopt itself still
  sees the full runner `PATH`; directories added via `GITHUB_PATH` (including
  the conda environment that `install.sh` exports) are prepended by the runner
  afterwards and so survive the rewrite.

- **`install.sh`** — reads `SETUP_BENCHOPT_VERSION` and `SETUP_BENCHOPT_BRANCH`
  (passed in as `env:` by `action.yml`) and pip-installs benchopt accordingly:
  `git` installs from a `user@branch` fork, `latest` upgrades from PyPI,
  anything else pins an exact version. It then persists the conda environment
  to `$GITHUB_ENV`/`$GITHUB_PATH` so later plain-`bash` steps see benchopt,
  conda, and mamba on PATH without needing a login shell, and writes the
  installed version to `$GITHUB_OUTPUT`.

Key design point: the action puts the conda environment on PATH itself, so
downstream workflow steps do **not** need `shell: bash -el {0}` unless they
require full conda activation (`activate.d` hooks). Keep this invariant intact
when editing `install.sh`.

## Commands

Local checks (dependencies provided via devenv/`devenv.nix`):

```bash
actionlint            # lint the GitHub workflow/action YAML
shellcheck install.sh # lint the install script
npx versionary verify # validate versionary release config
```

`actionlint` and `shellcheck` also run automatically as git hooks (configured
in `devenv.nix`). There is no test suite; behavior is verified by the CI
workflow, which exercises the action against
[`benchopt/template_benchmark`](https://github.com/benchopt/template_benchmark)
across conda, pip-only, and git-install matrices.

## Releasing

- Version lives in **`version.txt`** and is managed by
  [versionary](https://github.com/jolars/versionary) (config in
  `versionary.jsonc`), which runs in CI on pushes to `main` and opens/merges
  release PRs.
- When a `v*.*.*` tag is pushed, `.github/workflows/update-major-minor-tags.yml`
  force-moves the floating major and minor tags (e.g. `v1`, `v1.2`) so users
  pinning `@v1` get updates. Do not hand-edit these tags.

## Conventions

- The action must keep working on Linux, macOS, and Windows runners; account
  for all three when touching PATH handling or shell invocation in
  `install.sh` (note the Windows-specific `Scripts` and `Library/bin` dirs).
- `.pre-commit-config.yaml` is a symlink into the Nix store and is gitignored;
  do not commit or edit it directly.
