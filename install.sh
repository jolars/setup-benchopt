#!/usr/bin/env bash
# Install benchopt according to the SETUP_BENCHOPT_* environment variables
# and expose the installed version as a step output.
set -euo pipefail

case "$SETUP_BENCHOPT_VERSION" in
  git)
    user="${SETUP_BENCHOPT_BRANCH%@*}"
    branch="${SETUP_BENCHOPT_BRANCH##*@}"
    python -m pip install --upgrade \
      "benchopt @ git+https://github.com/${user}/benchopt@${branch}"
    ;;
  latest)
    python -m pip install --upgrade benchopt
    ;;
  *)
    python -m pip install "benchopt==${SETUP_BENCHOPT_VERSION}"
    ;;
esac

# Persist the conda environment for later steps, so that they can use plain
# (non-login) shells: put the environment's executables on PATH and export the
# variables that benchopt reads. Full activation (activate.d hooks) still
# requires a login shell, but nothing in this environment needs it.
if [ -n "${CONDA_PREFIX:-}" ]; then
  {
    echo "CONDA_PREFIX=${CONDA_PREFIX}"
    echo "CONDA_DEFAULT_ENV=${CONDA_DEFAULT_ENV:-}"
  } >> "$GITHUB_ENV"
  for dir in "$CONDA_PREFIX" "$CONDA_PREFIX/bin" "$CONDA_PREFIX/Scripts" \
    "$CONDA_PREFIX/Library/bin"; do
    if [ -d "$dir" ]; then
      echo "$dir" >> "$GITHUB_PATH"
    fi
  done
fi

version="$(benchopt --version)"
echo "version=${version}" >> "$GITHUB_OUTPUT"
echo "Installed benchopt ${version}"
