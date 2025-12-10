class Soundmon < Formula
  desc "Command-line audio process monitor for macOS, like htop for audio"
  homepage "https://github.com/mmccune/soundmon"
  url "https://github.com/mmccune/soundmon/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "PLACEHOLDER_SHA256"
  license "MIT"
  head "https://github.com/mmccune/soundmon.git", branch: "main"

  depends_on :macos
  depends_on xcode: ["12.0", :build]

  def install
    system "swiftc", "-O", "-o", "soundmon", "soundmon.swift"
    bin.install "soundmon"
  end

  test do
    assert_match "soundmon - Monitor audio output", shell_output("#{bin}/soundmon --help")
  end
end
