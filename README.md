# Sankofa iOS example

A runnable native SwiftUI app that exercises every product the iOS SDK ships — Analytics, Catch (Crashlytics + Sentry merged), Switch, Config, Pulse, Replay — against a local or remote Sankofa engine.

## 🏗 Setup

This is a full native iOS app. You can open it in Xcode two ways:

### Choice A — Traditional Xcode project (recommended)

Open **`SankofaExampleIOS.xcodeproj`**. This is pre-configured to link the local `SankofaIOS` SDK and runs on simulator + device out of the box.

### Choice B — Swift Package project

Open the folder `/example/sankofa_example_ios/` in Xcode. Xcode 15+ recognizes the `Package.swift` and treats the folder as a project.

## 🚀 Build & Run

1. Open the project (Choice A or B above).
2. Select an iOS Simulator (e.g. iPhone 15).
3. Hit **Run** (⌘ R).

## Point at your engine

Edit `Sources/SankofaExampleIOS/SankofaExampleApp.swift`:

```swift
let config = SankofaConfig(
    endpoint: "http://172.20.10.6:8080",  // or your local IP / staging URL
    // ...
)
Sankofa.shared.initialize(apiKey: "sk_test_...", config: config)
```

## 🔍 What it demonstrates

### Crash Gallery (`CrashGalleryView.swift`)

Sections covering the full Catch API surface:

- **Manual captures (safe)** — `captureException` business error, `captureMessage` warning, caught Swift throw.
- **Swift runtime traps (fatal, DEBUG only)** — force-unwrap nil, array out-of-range, dict key miss, type-cast force, division by zero, precondition failure, `fatalError`, stack overflow.
- **Obj-C + native (fatal, DEBUG only)** — `NSInvalidArgumentException`, background-thread crash, SIGSEGV tombstone.
- **Breadcrumbs + flush** — manual breadcrumb push + force-flush queue.
- **Phase B — withScope + beforeSend**
  - "withScope — temporary overlay" — tags + level + extras on ONE capture only.
  - "withScope — nested scopes" — inner scope inherits + extends the outer.
  - "beforeSend — see SankofaExampleApp" — fires events the hook should drop or scrub.
  - "Trigger main-queue stall" — sleeps the main thread 3s; the stall detector fires an `anr` event.

### Phase B `beforeSend` (`SankofaExampleApp.swift`)

`config.beforeSend = { event in ... }` is wired at init:

- Drops events whose message contains `"[noise]"`.
- Scrubs `user_email` from `extra`.

### Main-queue stall detector

`SankofaConfig(catchStallThresholdSeconds: 2.0)` (the default) installs a background timer that pings a sentinel block onto the main queue. If the sentinel doesn't fire within 2s, an `anr` event is emitted. The crash gallery's "Trigger main-queue stall" button blocks the main thread 3s to exercise this.

### Flags Lab (`FlagsLabView.swift`)

Live decision tables for every demo `SankofaSwitch` + `SankofaRemoteConfig` key, with onChange listeners. Demonstrates `Sankofa.shared.tagScrollContainer { ... }` for SwiftUI scroll-offset tagging.

### Pulse Lab (`PulseLabView.swift`)

Triggers + previews the in-app survey runtime.

## Sticky context

`bootstrapContext()` in `CrashGalleryView` calls `SankofaCatch.shared.setUser` / `setTags` / `addBreadcrumb` once so every captured event inherits the same identity. Compare against `withScope` overlays to see how Sentry-style temporary context layers on top.

## Documentation

Full iOS SDK reference: [docs.sankofa.dev/sdks/ios](https://docs.sankofa.dev/sdks/ios/overview).
