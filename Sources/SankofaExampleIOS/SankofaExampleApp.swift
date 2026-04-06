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
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
    }
}
