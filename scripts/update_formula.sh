#!/usr/bin/env bash
set -euo pipefail

FORMULA_PATH="${FORMULA_PATH:-Formula/usd-toolset.rb}"

usage() {
  cat <<USAGE
Usage: $0 --version <semver> --intel-sha <sha> --arm-sha <sha>
Updates the version and macOS-specific SHA256 values inside $FORMULA_PATH.
USAGE
}

VERSION=""
INTEL_SHA=""
ARM_SHA=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version)
      VERSION="$2"
      shift 2
      ;;
    --intel-sha)
      INTEL_SHA="$2"
      shift 2
      ;;
    --arm-sha)
      ARM_SHA="$2"
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

if [[ -z "$VERSION" || -z "$INTEL_SHA" || -z "$ARM_SHA" ]]; then
  echo "Missing required arguments" >&2
  usage >&2
  exit 1
fi

if [[ ! -f "$FORMULA_PATH" ]]; then
  echo "Formula file not found at $FORMULA_PATH" >&2
  exit 1
fi

python3 - "$FORMULA_PATH" "$VERSION" "$INTEL_SHA" "$ARM_SHA" <<'PY'
import sys
import pathlib
import re

path = pathlib.Path(sys.argv[1])
version, intel_sha, arm_sha = sys.argv[2:5]
text = path.read_text()

version_pattern = r'(  version ")([^"]+)(")'

def repl_version(match):
    return f"{match.group(1)}{version}{match.group(3)}"

if not re.search(version_pattern, text):
    raise SystemExit("Could not locate version line in formula")
text = re.sub(version_pattern, repl_version, text, count=1)

intel_pattern = r'(macOS-X64\.tar\.gz"\n\s+sha256 ")(.*?)(")'

def repl_intel(match):
    return f"{match.group(1)}{intel_sha}{match.group(3)}"

text, count = re.subn(intel_pattern, repl_intel, text, count=1)
if count != 1:
    raise SystemExit("Failed to update Intel sha256 block")

arm_pattern = r'(macOS-ARM64\.tar\.gz"\n\s+sha256 ")(.*?)(")'

def repl_arm(match):
    return f"{match.group(1)}{arm_sha}{match.group(3)}"

text, count = re.subn(arm_pattern, repl_arm, text, count=1)
if count != 1:
    raise SystemExit("Failed to update ARM sha256 block")

path.write_text(text)
PY

echo "Updated $FORMULA_PATH" >&2
