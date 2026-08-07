# Setup Benchopt

[![CI](https://github.com/jolars/setup-benchopt/actions/workflows/ci.yml/badge.svg)](https://github.com/jolars/setup-benchopt/actions/workflows/ci.yml)

A GitHub action that installs [benchopt](https://benchopt.github.io) and,
optionally, the conda toolchain (miniforge and mamba) that benchopt uses to
manage benchmark environments.

The action does one thing: it gets a working `benchopt` onto the runner. What
you do with it, such as testing a benchmark, running it on a schedule, or
publishing results, is up to your workflow.

## Usage

```yaml
jobs:
  test-benchmark:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
      - uses: jolars/setup-benchopt@v1
      - run: benchopt test . --env-name bench_test_env -vl
```

### Testing against the development version of benchopt

```yaml
- uses: jolars/setup-benchopt@v1
  with:
    version: git
    branch: benchopt@main
```

### Without conda

If you do not need benchopt to manage conda environments, for instance when
running with `--no-env`, you can skip the miniforge setup entirely:

```yaml
- uses: jolars/setup-benchopt@v1
  with:
    conda: false
```

### Caching benchmark data

```yaml
- uses: jolars/setup-benchopt@v1
  with:
    cache-dir: data/
```

## Inputs

| Input              | Default         | Description                                                                                                              |
| ------------------ | --------------- | ------------------------------------------------------------------------------------------------------------------------ |
| `version`          | `latest`        | Version of benchopt to install: `latest` (newest PyPI release), `git` (install from GitHub), or an exact version number. |
| `branch`           | `benchopt@main` | Fork and branch to install from when `version` is `git`, in the form `user@branch`.                                      |
| `python-version`   | `3.12`          | Python version used to install benchopt.                                                                                 |
| `conda`            | `true`          | Whether to set up miniforge and mamba for benchopt's environment management.                                             |
| `environment-name` | `benchopt`      | Name of the conda environment benchopt is installed into.                                                                |
| `cache-dir`        | `""`            | Directories to cache between runs, for instance benchmark data.                                                          |
| `shorten-windows-path` | `true`      | On Windows, replace `PATH` with a minimal set of directories for the rest of the job. See the note below.                 |

## Outputs

| Output             | Description                            |
| ------------------ | -------------------------------------- |
| `benchopt-version` | The version of benchopt that was installed. |

## Notes

- The action puts `benchopt`, `conda`, and `mamba` on `PATH` for subsequent
  steps, so plain `bash` steps work; no login shell is required. The one
  exception: if you install packages into the same conda environment that
  need full conda activation (`activate.d` hooks), run those steps with
  `shell: bash -el {0}`. See the [setup-miniconda
  documentation](https://github.com/conda-incubator/setup-miniconda#important)
  for details.
- With `conda: true`, the action sets `BENCHOPT_CONDA_CMD=mamba` so that
  benchopt uses mamba to create environments.
- The action works on Linux, macOS, and Windows runners.
- On Windows, benchopt drives conda through `cmd`, which inlines the whole
  `PATH` into the batch scripts it generates. The stock runner `PATH` is long
  enough that installing a `pip::` requirement overflows cmd's 8191-character
  command-line limit and fails with `The input line is too long`. The action
  therefore rebuilds `PATH` from the conda toolchain, git, and the Windows
  system directories, for the remainder of the job. If later steps need other
  tools from the runner image, set `shorten-windows-path: false` and keep
  `PATH` short some other way.

## Relation to `template_benchmark`

Benchmark repositories generated from
[benchopt/template_benchmark](https://github.com/benchopt/template_benchmark)
call a reusable workflow that owns the whole test job: the OS matrix, the
conda setup, and the `benchopt test` invocation. That works well until you
need to add a step of your own, such as installing a system dependency,
caching data, or running the benchmark instead of testing it.

This action inverts that relationship: your workflow owns the job, and
benchopt setup becomes a single composable step.
