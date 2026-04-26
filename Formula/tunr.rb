class Tunr < Formula
  desc "Screen & audio context provider for Claude Code via MCP"
  homepage "https://github.com/moeki0/tunr"
  url "https://github.com/moeki0/tunr/archive/refs/tags/v1.16.0.tar.gz"
  sha256 "6c1a5182e4672746e1e4e0d662b478206f3bd2242a5bebdfed860a341d58a04e"
  license "MIT"

  resource "bun" do
    on_arm do
      url "https://github.com/oven-sh/bun/releases/download/bun-v1.3.12/bun-darwin-aarch64.zip"
      sha256 "6c4bb87dd013ed1a8d6a16e357a3d094959fd5530b4d7061f7f3680c3c7cea1c"
    end
    on_intel do
      url "https://github.com/oven-sh/bun/releases/download/bun-v1.3.12/bun-darwin-x64.zip"
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
