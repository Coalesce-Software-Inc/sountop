class Sountop < Formula
  desc "Command-line audio process monitor for macOS, like htop for audio"
  homepage "https://github.com/Coalesce-Software-Inc/sountop"
  url "https://github.com/Coalesce-Software-Inc/sountop/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "PLACEHOLDER_SHA256"
  license "MIT"
  head "https://github.com/Coalesce-Software-Inc/sountop.git", branch: "develop"

  depends_on :macos
  depends_on xcode: ["12.0", :build]

  def install
    system "swiftc", "-O", "-o", "sountop", "sountop.swift"
    bin.install "sountop"
  end

  test do
    assert_match "sountop - Monitor audio output", shell_output("#{bin}/sountop --help")
  end
end
