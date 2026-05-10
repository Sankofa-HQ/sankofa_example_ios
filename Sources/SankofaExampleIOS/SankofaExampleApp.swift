import SwiftUI
import SankofaIOS

@main
struct SankofaExampleApp: App {

    init() {
        // Seed Switch + Config defaults BEFORE Sankofa.initialize so
        // the auto-discovered flag/config snapshots Catch attaches to
        // its events on the very first crash already see something
        // useful. Both modules self-register with the Traffic Cop on
        // first access — the .shared touch here is what wires handshake
        // payloads into them.
        _ = SankofaSwitch.shared.withDefaults(DemoFlag.defaults)
        _ = SankofaRemoteConfig.shared.withDefaults(DemoConfig.defaults)

        // One-line init. enableCatch=true (default) auto-installs the
        // NSException + POSIX-signal handlers and wires Switch/Config
        // snapshots onto every captured event — no separate
        // `SankofaCatch.shared.start(...)` call needed.
        Sankofa.shared.initialize(
            apiKey: "sk_test_b25f965d194d55bd071fb23921401e7c",
            config: SankofaConfig(
                // Point to your local Sankofa engine or staging URL
                endpoint: "http://172.20.10.6:8080",
                debug: true,
                trackLifecycleEvents: true,
                flushIntervalSeconds: 10,
                batchSize: 5,
                recordSessions: true,
                maskAllInputs: true,
                captureScale: 0.35,
                catchEnvironment: "dev",
                release: "example-ios@1.0.0",
                appVersion: "1.0.0"
            )
        )

        // ─── Pulse (in-app surveys) ───────────────────────────────────────
        // Pulse needs init() to have completed first because register()
        // pulls the apiKey + endpoint at registration time. The Pulse
        // tab below surfaces a "not registered" message if this returns
        // false (typically only when the SDK init failed).
        _ = SankofaPulse.shared.register()
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
    }
}
