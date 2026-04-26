class Tunr < Formula
  desc "Screen & audio context provider for Claude Code via MCP"
  homepage "https://github.com/moeki0/tunr"
  url "https://github.com/moeki0/tunr/archive/refs/tags/v1.15.1.tar.gz"
  sha256 "396715ecfde7d2950d411c91e0f4b2cd922f9c6bde27a57414068da0392f3aa2"
  license "MIT"

  resource "bun" do
    on_arm do
      url "https://github.com/oven-sh/bun/releases/download/bun-v1.3.13/bun-darwin-aarch64.zip"
      sha256 "5467e3f65dba526b9fea98f0cce04efafc0c63e169733ec27b876a3ad32da190"
    end
    on_intel do
      url "https://github.com/oven-sh/bun/releases/download/bun-v1.3.13/bun-darwin-x64.zip"
      sha256 :no_check
    end
  end

  def install
    resource("bun").stage do
      bun_bin = Dir["bun-*/bun"].first || "bun"
      buildpath.install bun_bin => "bun"
    end
    chmod 0755, buildpath/"bun"
    bun = (buildpath/"bun").to_s

    system bun, "install", "--frozen-lockfile"
    system bun, "build", "--compile", "src/cli.ts", "--outfile", "tunr"
    system "swiftc", "swift/ax_text.swift", "-o", "tunr-ax-text", "-O"
    system "swiftc", "swift/embed.swift", "-o", "tunr-embed", "-O"
    system "swiftc", "swift/audio_capture.swift", "-o", "tunr-audio-capture", "-O",
           "-framework", "AVFoundation", "-framework", "CoreAudio"
    bin.install "tunr"
    bin.install "tunr-ax-text"
    bin.install "tunr-embed"
    bin.install "tunr-audio-capture"
  end

  def caveats
    <<~EOS
      Grant Accessibility permission to your terminal app (System Settings > Privacy & Security).

      Register the MCP server with Claude Code:
        claude mcp add -s user tunr -- #{bin}/tunr mcp

      Start Claude Code with channels enabled:
        claude --dangerously-load-development-channels server:tunr

      Start the daemon:
        tunr start

      For Chrome web content capture:
        defaults write com.google.Chrome AllowJavaScriptAppleEvents -bool true

      For audio capture, install BlackHole and set up a multi-output device:
        brew install --cask blackhole-2ch
      Then configure a multi-output device in Audio MIDI Setup.
    EOS
  end

  test do
    assert_match "tunr", shell_output("#{bin}/tunr 2>&1", 0)
  end
end
