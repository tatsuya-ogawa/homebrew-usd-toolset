class UsdToolset < Formula
  desc "Prebuilt OpenUSD command-line utilities"
  homepage "https://github.com/PixarAnimationStudios/OpenUSD"
  version "0.1.0"
  license "Apache-2.0"
  depends_on "python@3.11"

  on_macos do
    on_intel do
      url "https://github.com/tatsuya-ogawa/homebrew-usd-toolset/releases/download/v0.1.0/usd-toolset-0.1.0-macOS-X64.tar.gz"
      sha256 "REPLACE_WITH_INTEL_SHA256"
    end

    on_arm do
      url "https://github.com/tatsuya-ogawa/homebrew-usd-toolset/releases/download/v0.1.0/usd-toolset-0.1.0-macOS-ARM64.tar.gz"
      sha256 "REPLACE_WITH_ARM_SHA256"
    end
  end

  livecheck do
    url "https://github.com/tatsuya-ogawa/homebrew-usd-toolset/releases/latest"
    strategy :github_latest
  end

  def install
    prefix.install Dir["*"]
  end

  test do
    system "#{bin}/usdcat", "--help"
  end
end
