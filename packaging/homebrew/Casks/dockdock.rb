cask "dockdock" do
  version "0.1.0"
  sha256 "99ab41f8dbb149a6d755ff506125d66d932896705d273f9997e4042f226f6c8f"

  url "https://github.com/CodeOneLabs/DockDock/releases/download/v#{version}/DockDock-#{version}.zip"
  name "DockDock"
  desc "Open the auto-hidden macOS Dock before the pointer reaches the last screen pixel"
  homepage "https://github.com/CodeOneLabs/DockDock"

  app "DockDock.app"

  zap trash: [
    "~/Library/Preferences/com.local.DockDock.plist",
  ]
end
