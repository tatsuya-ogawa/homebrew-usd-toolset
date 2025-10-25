# homebrew-usd-toolset

Homebrew tap template for distributing prebuilt OpenUSD binaries produced by GitHub Actions. Run the workflow to compile Pixar's OpenUSD with `build_usd.py`, upload the resulting tarball to a GitHub Release, and point the Formula at that asset so end users can `brew install` the toolset.

## 背景と前提
- OpenUSD は公式リポジトリが提供する `build_usd.py` スクリプトで依存関係を含めたフルビルドが可能です。このスクリプトは必要なサードパーティをダウンロードし、指定したインストールディレクトリに USD コアや Imaging を配置します。
- macOS では Xcode Command Line Tools と CMake さえあれば `python OpenUSD/build_scripts/build_usd.py <install-dir>` でビルドできます。
- このリポジトリはそのビルド手順を GitHub Actions で自動化し、成果物を Homebrew tap として配布する雛形です。

## リポジトリ構成
- `Formula/usd-toolset.rb` — Homebrew formula テンプレート。GitHub Release の tarball URL と `sha256` を埋めれば `brew install tatsuya-ogawa/usd-toolset/usd-toolset` で配布できます。
- `scripts/build_openusd.sh` — OpenUSD を指定タグでクローンし `build_usd.py` を実行、`dist/` 以下に tarball / SHA256 / JSON manifest を生成します。`pyproject.toml` があれば `uv pip install` で依存関係を同期します。
- `scripts/update_formula.sh` — リリース URL と SHA256 を手早く Formula に反映する小さなヘルパー。
- `.github/workflows/build.yml` — macOS runner 上で上記スクリプトを実行し、Artifacts / Releases に成果物をアップロードするワークフロー。
- `pyproject.toml` — `uv` で解決する Python 依存関係 (ここでは PyOpenGL / PySide6) を定義。

## GitHub Actions でのビルド
1. **トリガー**
   - タグ `v*` を push すると自動実行し、同名タグを Release 名に使います。
   - もしくは `workflow_dispatch` から `package_version` (例: `0.1.0`), `usd_tag` (例: `release` や `v25.08`) を入力して手動実行。
2. **依存関係** — ランナーで `brew install cmake ninja` と `uv` インストールを行い、`scripts/build_openusd.sh` が仮想環境を作成して `pyproject.toml` の依存関係 (PyOpenGL / PySide6) を `uv pip install --python <venv>` で同期します。必要なら `build_usd_args` 入力で上書きできます。
3. **成果物** — `dist/usd-toolset-<version>-<os>-<arch>.tar.gz` と `.sha256`, `.json` を artifact として保存し、タグ実行時は GitHub Release に添付します。

## リリース〜Formula 更新手順
1. ワークフロー完了後、`dist/*.sha256` のハッシュとリリース URL を確認。
2. ローカルで `./scripts/update_formula.sh --version <semver> --url <release-tarball-url> --sha256 <hash>` を実行。
3. `Formula/usd-toolset.rb` をコミット・プッシュ。Homebrew 利用者は `brew update` 後にインストールできます。

## ローカルで試す
```bash
USD_TAG=release PACKAGE_VERSION=0.1.0 scripts/build_openusd.sh
```
- 生成される tarball は `dist/` に配置されます。
- `BUILD_USD_ARGS` 環境変数で `build_usd.py` へ任意のフラグを渡せます (例: `--no-usdview --build-variant release`).
- 事前に [uv](https://docs.astral.sh/uv/) をインストールし、`pyproject.toml` の依存関係が同期できるようにしてください。

## Homebrew での利用例
```bash
brew tap tatsuya-ogawa/usd-toolset https://github.com/tatsuya-ogawa/homebrew-usd-toolset.git
brew install usd-toolset
usdcat --help
```
※ 初回は Formula の `sha256` と `url` を実際のリリースに合わせて更新してから。

## 今後の拡張アイデア
1. Linux / Windows 用の追加ジョブやユニバーサルバイナリの結合。
2. 成果物のサイニングと SBOM 生成。
3. Formula の自動更新 (GitHub Actions で `update_formula.sh` を実行し PR 作成)。
