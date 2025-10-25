#!/usr/bin/env bash
set -euo pipefail

FORMULA_PATH="${FORMULA_PATH:-Formula/usd-toolset.rb}"

usage() {
  cat <<USAGE
Usage: $0 --version <semver> --url <tarball_url> --sha256 <sha>
Updates the formula metadata in $FORMULA_PATH.
USAGE
}

VERSION=""
URL=""
SHA256=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version)
      VERSION="$2"
      shift 2
      ;;
    --url)
      URL="$2"
      shift 2
      ;;
    --sha256)
      SHA256="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ -z "$VERSION" || -z "$URL" || -z "$SHA256" ]]; then
  echo "Missing required arguments" >&2
  usage >&2
  exit 1
fi

if [[ ! -f "$FORMULA_PATH" ]]; then
  echo "Formula file not found at $FORMULA_PATH" >&2
  exit 1
fi

perl -0pi -e "s/(  version \?)\".*\"/\${1}\"$VERSION\"/" "$FORMULA_PATH"
perl -0pi -e "s/(  url )\".*\"/\${1}\"$URL\"/" "$FORMULA_PATH"
perl -0pi -e "s/(  sha256 )\".*\"/\${1}\"$SHA256\"/" "$FORMULA_PATH"

echo "Updated $FORMULA_PATH" >&2
