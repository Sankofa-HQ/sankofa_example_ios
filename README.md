## 🏗 Setup & Running

This is a full native iOS app. You can open it in Xcode in two ways:

### Choice A: Traditional Xcode Project (Recommended)
Simply open **`SankofaExampleIOS.xcodeproj`** in Xcode.
- This is a pre-configured project that links the local `SankofaIOS` SDK.
- Works out-of-the-box on iOS Simulators and Devices.

### Choice B: Swift Package Project
Open the **folder** `/example/sankofa_example_ios/` in Xcode.
- Xcode 15+ will recognize the `Package.swift` and treat the folder as a project.

---

## 🚀 Build & Run
1. Open the project via one of the methods above.
2. Select an **iOS Simulator** (e.g., iPhone 15).
3. Hit **Run** (Command + R).

---

## 🔍 Features Demonstrated

- **Event Tracking**: Fire preset or custom events.
- **Identity**: Manage user IDs and profile attributes.
- **Session Replay**: Hardened Ghost Masking and Escalation triggers.
- **Offline First**: All events are queued via GRDB/SQLite (WAL mode).
