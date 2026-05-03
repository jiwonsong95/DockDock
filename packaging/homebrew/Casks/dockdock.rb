cask "dockdock" do
  version "0.1.5"
  sha256 "87cbc0f6da4f66c9d0723bec877c6dcb3ca092c2c36104af4afe4b53a8013faf"

  url "https://github.com/CodeOneLabs/DockDock/releases/download/v#{version}/DockDock-#{version}.zip"
  name "DockDock"
  desc "Open the auto-hidden macOS Dock before the pointer reaches the last screen pixel"
  homepage "https://github.com/CodeOneLabs/DockDock"

  app "DockDock.app"

  zap trash: [
    "~/Library/Preferences/com.local.DockDock.plist",
  ]
end
