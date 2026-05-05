import SwiftUI
import SankofaIOS

@main
struct SankofaExampleApp: App {

    init() {
        // ─── SDK [v2] Initialization ──────────────────────────────────────────
        // This mirrors exactly how an enterprise customer would set up the SDK.
        Sankofa.shared.initialize(
            apiKey: "sk_test_b25f965d194d55bd071fb23921401e7c",
            config: SankofaConfig(
                // Point to your local Sankofa engine or staging URL
                endpoint: "http://172.20.10.6:8080", // "http://192.168.1:8080", //"http://172.20.10.6:8080", //
                debug: true,
                trackLifecycleEvents:  true,
                flushIntervalSeconds: 10,
                batchSize: 5,
                recordSessions: true,
                maskAllInputs:true,
                captureScale:  0.35,

            )
        )

        // Seed Switch + Config defaults so the Lab view has something
        // to render before the first handshake lands (offline first-
        // launch, slow network, etc.). Both modules self-register with
        // the Traffic Cop on first access — the .shared touch here is
        // what wires handshake payloads into them.
        _ = SankofaSwitch.shared.withDefaults(DemoFlag.defaults)
        _ = SankofaRemoteConfig.shared.withDefaults(DemoConfig.defaults)

        // ─── Catch (error tracking) ──────────────────────────────────────────
        // Install the uncaught-exception + native-signal handlers early
        // so any crash that happens later in the app lifecycle lands
        // in the dashboard. Idempotent — safe to call more than once.
        _ = SankofaCatch.shared.start(
            environment: "dev",
            release: "example-ios@1.0.0",
            appVersion: "1.0.0"
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
