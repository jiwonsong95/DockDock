# DockDock

DockDock is a small macOS helper for people who use an auto-hidden Dock but hate
having to hit the exact last screen pixel to open it.

The name is literal: a Dock that acts a little smarter.

It creates a configurable trigger band near the Dock edge. When your pointer
enters that band from outside, DockDock nudges the pointer to the real Dock
trigger pixel once, so the Dock opens earlier without trapping the mouse at the
screen edge.

## Demo

<video src="https://github.com/user-attachments/assets/74ff290f-b053-40c8-ad2d-7dd001ebec32" controls width="720"></video>

If the video does not render in your browser, open the
[release demo asset](https://github.com/CodeOneLabs/DockDock/releases/download/v0.1.0/demo.mp4).

## Status

DockDock is an early open-source macOS utility. It is built with SwiftPM and
uses only public macOS APIs.

What works now:

- Expand the Dock trigger area for bottom, left, or right Dock positions.
- Runs as a menu bar background app instead of opening a window at launch.
- Pause automatically for exception apps you add.
- Optionally start DockDock at login. The app asks once on first launch and can
  be changed later in Settings.
- Adjust the trigger band from 1 to 50 px, with 15 px as the recommended value
  and 5-25 px highlighted as the normal range.
- Show a translucent blue overlay while adjusting the trigger band.
- Open settings from the menu bar when needed.
- Create a stable local code-signing identity for development builds, so
  Accessibility permission survives rebuilds.

## Why This Works This Way

macOS does not expose a public API to directly tell the Dock to show itself.
DockDock therefore does not patch, inject into, or replace the Dock.

Instead it uses:

- `CGEvent` to observe global mouse movement.
- `CGWarpMouseCursorPosition` to move the pointer to the real Dock trigger pixel.
- `AXIsProcessTrustedWithOptions` to request Accessibility permission.

DockDock only snaps on entry into the configured trigger band. It should not keep
the pointer stuck to the edge.

## Requirements

- macOS 14 or newer.
- Xcode Command Line Tools.
- Swift toolchain available from Terminal.

Install Command Line Tools if needed:

```bash
xcode-select --install
```

## Build And Run

Clone the repository, then run:

```bash
./script/build_and_run.sh
```

The script will:

1. Build the SwiftPM app.
2. Stage `dist/DockDock.app`.
3. Create a local development code-signing identity if needed.
4. Sign the app with the stable bundle identifier `com.local.DockDock`.
5. Launch the app.

You can also verify the app launches:

```bash
./script/build_and_run.sh --verify
```

## Grant Accessibility Permission

DockDock needs Accessibility permission because it monitors global mouse
movement.

1. Launch DockDock.
2. Choose whether DockDock should start at login.
3. Open DockDock from the menu bar.
4. Click `Request Permission` or `Open System Settings`.
5. Open `System Settings -> Privacy & Security -> Accessibility`.
6. Enable `DockDock.app`.
7. In DockDock, turn on `Enable expanded Dock trigger zone`.

DockDock does not request Accessibility permission on every launch. It only
opens the permission prompt when you click `Request Permission`.

If the app still says `Stopped`, press `Recheck`.

If it still does not work, remove the old `DockDock.app` entry from
Accessibility with the minus button, then add this exact app with the plus
button:

```text
dist/DockDock.app
```

## Troubleshooting

### DockDock Says Stopped Even Though Accessibility Is Enabled

This usually means macOS has an old permission record for a previous build.

Try:

```bash
tccutil reset Accessibility com.local.DockDock
./script/build_and_run.sh
```

Then enable `DockDock.app` again in Accessibility settings.

### The Permission Prompt Keeps Coming Back

Make sure you are running the app from:

```text
dist/DockDock.app
```

Do not run the raw SwiftPM executable directly. The raw executable has different
app identity behavior and may not match the Accessibility entry.

### The Mouse Feels Stuck

DockDock should only snap once when entering the trigger band. If the pointer
keeps sticking to the edge, open an issue with:

- macOS version.
- Dock position.
- Trigger band value.
- Whether you use multiple displays.

### The Blue Band Overlay Appears In The Wrong Place

Open an issue with:

- A screenshot.
- Display arrangement.
- Dock position.
- Trigger band value.

### DockDock Should Not Run In A Specific App

Open DockDock from the menu bar, then use `Add Frontmost to Exceptions` or open
`Settings` and add the app's bundle identifier manually. DockDock pauses while an
exception app is frontmost.

### Start At Login

DockDock asks once on first launch whether it should start at login. You can
change this later from the menu bar or Settings. Internally, DockDock uses
Apple's `SMAppService.mainApp` login item API.

## Development

Run the geometry checks:

```bash
swift run GeometryChecks
```

Build without launching:

```bash
swift build
```

Build and launch:

```bash
./script/build_and_run.sh
```

Useful script modes:

```bash
./script/build_and_run.sh --build-only
./script/build_and_run.sh --verify
./script/build_and_run.sh --logs
./script/build_and_run.sh --debug
```

## Homebrew Distribution

DockDock can be distributed through a Homebrew Cask once the GitHub repository
and release URL are final.

Package a release zip:

```bash
./script/package_release.sh 0.1.0
```

The script prints the SHA-256 value needed by the cask template at:

```text
packaging/homebrew/Casks/dockdock.rb
```

After replacing `version` and `sha256` in that template and publishing a
Homebrew tap, users can install and update with:

```bash
brew tap CodeOneLabs/dockdock
brew install --cask dockdock
brew upgrade --cask dockdock
```

For a broad public binary release, use an Apple Developer ID certificate and
notarize the app before attaching the zip to GitHub Releases.

## Project Layout

```text
Sources/DockDock/        macOS app, services, and SwiftUI views
Sources/DockDockCore/    pure trigger geometry logic
Sources/GeometryChecks/  executable smoke checks for geometry behavior
script/                  build, launch, and local signing scripts
packaging/homebrew/      Homebrew Cask template
```

## Distribution Notes

This repository is set up for source builds. For a polished public binary
release, a maintainer should use an Apple Developer ID certificate and notarize
the app. The local development certificate created by this repo is only for
people building the app themselves.

## License

MIT. See [LICENSE](LICENSE).
