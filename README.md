# homebrew-usd-toolset

Homebrew tap template for distributing prebuilt OpenUSD binaries generated via GitHub Actions. Run the workflow to compile Pixar's OpenUSD with `build_usd.py`, upload the resulting tarball to a GitHub Release, and point the formula at that asset so end users can `brew install` the toolset.

## Background
- OpenUSD ships with `build_usd.py`, a script that downloads required third-party libraries and installs the USD core/imaging stack into a prefix you specify.
- On macOS, Xcode Command Line Tools plus CMake are enough to run `python OpenUSD/build_scripts/build_usd.py <install-dir>`.
- This repository automates that process in CI and packages the result as a Homebrew tap.

## Repository Layout
- `Formula/usd-toolset.rb` — Homebrew formula template. Populate the tarball `url` and `sha256` with your GitHub Release asset, then users can install via `brew install tatsuya-ogawa/usd-toolset/usd-toolset`.
- `scripts/build_openusd.sh` — Clones OpenUSD at the requested tag, runs `build_usd.py`, and writes tarball/SHA256/JSON manifests under `dist/`. If `pyproject.toml` exists, it uses `uv sync` to materialize the Python environment before invoking the build.
- `scripts/update_formula.sh` — Small helper that rewrites the formula metadata with a new version, URL, and SHA.
- `.github/workflows/build.yml` — Dual-runner macOS workflow (macos-13 Intel + macos-14 Apple Silicon) that executes the build script, uploads artifacts, and publishes release assets.
- `pyproject.toml` — Declares Python dependencies (PyOpenGL, PySide6) resolved via `uv`.

## Building in GitHub Actions
1. **Triggers**
   - Pushing a tag matching `v*` runs the workflow automatically and names the release after that tag.
   - Manual dispatch (`workflow_dispatch`) accepts `package_version`, `usd_tag`, and optional `build_usd_args` inputs.
2. **Dependencies**
   - Each runner (`macos-13` x86_64 and `macos-14` arm64) installs CMake/Ninja via Homebrew, installs `uv`, and calls `scripts/build_openusd.sh`. The script syncs the `pyproject.toml` environment into `.build/.venv` with `uv sync` so PyOpenGL/PySide6 are present for the USD build.
3. **Artifacts**
   - Outputs land in `dist/usd-toolset-<version>-<os>-<arch>.tar.gz` plus accompanying `.sha256` and `.json` for every architecture. Tag-triggered runs also upload these files to the GitHub Release.

## Release & Formula Update Flow
1. After the workflow finishes, record the tarball URL and SHA256 from `dist/*.sha256`.
2. Run `./scripts/update_formula.sh --version <semver> --url <release-tarball-url> --sha256 <hash>` locally.
3. Commit and push `Formula/usd-toolset.rb` so tap users can `brew update` and install.

## Try Locally
```bash
USD_TAG=release PACKAGE_VERSION=0.1.0 scripts/build_openusd.sh
```
- Artifacts appear under `dist/`.
- Override `build_usd.py` flags by setting `BUILD_USD_ARGS` (for example, `--no-usdview --build-variant release`).
- Install [uv](https://docs.astral.sh/uv/) ahead of time so the `pyproject.toml` dependencies can sync successfully.

## Homebrew Usage Example
```bash
brew tap tatsuya-ogawa/usd-toolset https://github.com/tatsuya-ogawa/homebrew-usd-toolset.git
brew install usd-toolset
usdcat --help
```
Make sure the formula's `url` and `sha256` fields point to a published release before tapping.

## Future Enhancements
1. Add Linux/Windows jobs or merge multiple macOS architectures into a single universal binary.
2. Sign release artifacts and emit SBOMs.
3. Automate formula updates by having GitHub Actions run `update_formula.sh` and open pull requests.
