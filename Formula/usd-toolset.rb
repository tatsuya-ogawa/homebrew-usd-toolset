class UsdToolset < Formula
  desc "Prebuilt OpenUSD command-line utilities"
  homepage "https://github.com/PixarAnimationStudios/OpenUSD"
  version "0.1.0"
  license "Apache-2.0"
  depends_on "python@3.11"

  on_macos do
    on_intel do
      url "https://github.com/tatsuya-ogawa/homebrew-usd-toolset/releases/download/v#{version}/usd-toolset-#{version}-macOS-X64.tar.gz"
      sha256 "3f2d12abc85324dffd7b4de8f6d6b5390e5ae4be050034c3d3eeda87e3aadfdc"
    end

    on_arm do
      url "https://github.com/tatsuya-ogawa/homebrew-usd-toolset/releases/download/v#{version}/usd-toolset-#{version}-macOS-ARM64.tar.gz"
      sha256 "30d86b2b3528678844da9de31571bf877fc92a24dfbc0790e121756493a03c96"
    end
  end

  livecheck do
    url "https://github.com/tatsuya-ogawa/homebrew-usd-toolset/releases/latest"
    strategy :github_latest
  end

  def install
    bin.install Dir["bin/*"]
  end

  test do
    system "#{bin}/usdcat", "--help"
  end
end
