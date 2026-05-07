cask "dockdock" do
  version "0.2.0"
  sha256 "5cae1f1f7d830dab454f6bdd4fc0a156088a2639ea228b4e4d2dfe455fc8ca9c"

  url "https://github.com/CodeOneLabs/DockDock/releases/download/v#{version}/DockDock-#{version}.zip"
  name "DockDock"
  desc "Open the auto-hidden macOS Dock before the pointer reaches the last screen pixel"
  homepage "https://github.com/CodeOneLabs/DockDock"

  app "DockDock.app"

  zap trash: [
    "~/Library/Preferences/com.local.DockDock.plist",
  ]
end
