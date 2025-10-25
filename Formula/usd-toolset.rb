class UsdToolset < Formula
  desc "Prebuilt OpenUSD command-line utilities"
  homepage "https://github.com/PixarAnimationStudios/OpenUSD"
  version "0.1.0"
  url "https://github.com/tatsuya-ogawa/homebrew-usd-toolset/releases/download/v0.1.0/usd-toolset-0.1.0-macos-universal.tar.gz"
  sha256 "REPLACE_WITH_SHA256"
  license "Apache-2.0"
  depends_on "python@3.11"

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
