cask "dockdock" do
  version "0.1.4"
  sha256 "d1aeaf95a91d2a101f6d1850f1c0ba6a8d4dc0edc7f95ee2ed7aa6348026222c"

  url "https://github.com/CodeOneLabs/DockDock/releases/download/v#{version}/DockDock-#{version}.zip"
  name "DockDock"
  desc "Open the auto-hidden macOS Dock before the pointer reaches the last screen pixel"
  homepage "https://github.com/CodeOneLabs/DockDock"

  app "DockDock.app"

  zap trash: [
    "~/Library/Preferences/com.local.DockDock.plist",
  ]
end
