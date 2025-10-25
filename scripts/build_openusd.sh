#!/usr/bin/env bash
set -euo pipefail

USD_REPO="${USD_REPO:-https://github.com/PixarAnimationStudios/OpenUSD.git}"
USD_TAG="${USD_TAG:-release}"
USD_VERSION="${USD_VERSION:-${USD_TAG#v}}"
PACKAGE_VERSION="${PACKAGE_VERSION:-$USD_VERSION}"
BUILD_ROOT="${BUILD_ROOT:-$PWD/.build}"
INSTALL_PREFIX="${INSTALL_PREFIX:-$PWD/dist/prefix}"
ARTIFACT_NAME="${ARTIFACT_NAME:-usd-toolset-${PACKAGE_VERSION}-${RUNNER_OS:-$(uname -s | tr '[:upper:]' '[:lower:]')}-${RUNNER_ARCH:-$(uname -m)}}"
DIST_DIR="$PWD/dist"
BUILD_USD_ARGS="${BUILD_USD_ARGS:---no-tests --no-tutorials --python --materialx}"
PYPROJECT_PATH="${PYPROJECT_PATH:-$PWD/pyproject.toml}"

mkdir -p "$BUILD_ROOT" "$INSTALL_PREFIX" "$DIST_DIR"

# Clone the specified OpenUSD tag if it is not already available.
if [[ ! -d "$BUILD_ROOT/OpenUSD" ]]; then
  git clone --branch "$USD_TAG" --depth 1 "$USD_REPO" "$BUILD_ROOT/OpenUSD"
else
  pushd "$BUILD_ROOT/OpenUSD" >/dev/null
  git fetch --depth 1 origin "$USD_TAG"
  git checkout --force "$USD_TAG"
  popd >/dev/null
fi

python3 -m venv "$BUILD_ROOT/.venv"
source "$BUILD_ROOT/.venv/bin/activate"
pip install --upgrade pip

if [[ -f "$PYPROJECT_PATH" ]]; then
  if ! "$BUILD_ROOT/.venv/bin/python" -c "import tomllib" >/dev/null 2>&1; then
    pip install tomli
  fi

  if ! command -v uv >/dev/null 2>&1; then
    echo "uv CLI is required to sync Python dependencies. Install from https://docs.astral.sh/uv/ and re-run." >&2
    exit 1
  fi

  mapfile -t PY_DEPS < <("$BUILD_ROOT/.venv/bin/python" - "$PYPROJECT_PATH" <<'PY'
import sys
import pathlib

try:
    import tomllib
except ModuleNotFoundError:  # Python <3.11 fallback
    import tomli as tomllib

path = pathlib.Path(sys.argv[1])
data = tomllib.loads(path.read_text())
for dep in data.get("project", {}).get("dependencies", []):
    dep = dep.strip()
    if dep:
        print(dep)
PY
)

  if ((${#PY_DEPS[@]})); then
    echo "Installing Python build dependencies via uv: ${PY_DEPS[*]}"
    uv pip install --python "$BUILD_ROOT/.venv/bin/python" "${PY_DEPS[@]}"
  fi
fi

pushd "$BUILD_ROOT/OpenUSD" >/dev/null
python3 build_scripts/build_usd.py $BUILD_USD_ARGS "$INSTALL_PREFIX"
popd >/dev/null

deactivate

TARBALL_PATH="$DIST_DIR/${ARTIFACT_NAME}.tar.gz"
tar -C "$INSTALL_PREFIX" -czf "$TARBALL_PATH" .

SHA256=$(shasum -a 256 "$TARBALL_PATH" | awk '{print $1}')
cat <<JSON > "$TARBALL_PATH.json"
{
  "artifact": "${ARTIFACT_NAME}.tar.gz",
  "package_version": "$PACKAGE_VERSION",
  "usd_tag": "$USD_TAG",
  "usd_repo": "$USD_REPO",
  "sha256": "$SHA256"
}
JSON

cat <<INFO | tee "$DIST_DIR/${ARTIFACT_NAME}.sha256"
$SHA256  ${ARTIFACT_NAME}.tar.gz
INFO
