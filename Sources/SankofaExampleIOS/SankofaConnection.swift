import Foundation
import Combine
import SankofaIOS

/// Holds the user-supplied endpoint + API key and persists them across
/// app launches via `UserDefaults`. Mirrors the web example's
/// `SankofaProvider` so the developer experience is identical: connect
/// once, the credentials survive a relaunch, and a "Disconnect" action
/// wipes them and returns to the connect screen.
///
/// The SDK is **only** initialised after the user connects. Pre-connect
/// the app shows `ConnectView`. This matches how a real app behaves —
/// you don't init analytics with an empty key just to satisfy a
/// hardcoded global.
@MainActor
final class SankofaConnection: ObservableObject {

    static let shared = SankofaConnection()

    @Published private(set) var endpoint: String
    @Published private(set) var apiKey: String
    @Published private(set) var isConnected: Bool

    private let endpointKey = "sankofa.example.endpoint"
    private let apiKeyKey = "sankofa.example.apiKey"
    private let defaultEndpoint = "http://localhost:8080"

    private init() {
        let storedEndpoint = UserDefaults.standard.string(forKey: "sankofa.example.endpoint")?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let storedKey = UserDefaults.standard.string(forKey: "sankofa.example.apiKey")?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        self.endpoint = storedEndpoint.isEmpty ? "http://localhost:8080" : storedEndpoint
        self.apiKey = storedKey
        self.isConnected = !storedKey.isEmpty

        // If we already have stored credentials, boot the SDK on the
        // first run-loop tick so screens that read snapshots in
        // `.onAppear` already see a ready client.
        if !storedKey.isEmpty {
            initialiseSDK(apiKey: storedKey, endpoint: self.endpoint)
        }
    }

    /// `sk_test_` / `sk_live_` prefix → "test" / "live". Same convention
    /// the dashboard and the rest of the SDK family use.
    var inferredEnvironment: String? {
        if apiKey.hasPrefix("sk_test_") { return "test" }
        if apiKey.hasPrefix("sk_live_") { return "live" }
        return nil
    }

    /// Persist the supplied credentials and initialise the SDK. Called
    /// from `ConnectView` once the user has typed a key.
    func connect(apiKey: String, endpoint: String) {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEndpoint = endpoint.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else { return }

        let resolvedEndpoint = trimmedEndpoint.isEmpty ? defaultEndpoint : trimmedEndpoint

        UserDefaults.standard.set(trimmedKey, forKey: apiKeyKey)
        UserDefaults.standard.set(resolvedEndpoint, forKey: endpointKey)

        self.apiKey = trimmedKey
        self.endpoint = resolvedEndpoint
        self.isConnected = true

        initialiseSDK(apiKey: trimmedKey, endpoint: resolvedEndpoint)
    }

    /// Clear stored credentials and return to the connect screen. The
    /// SDK keeps running in-memory (no shutdown API on iOS yet) but
    /// the next launch starts fresh.
    func disconnect() {
        UserDefaults.standard.removeObject(forKey: apiKeyKey)
        UserDefaults.standard.removeObject(forKey: endpointKey)
        self.apiKey = ""
        self.endpoint = defaultEndpoint
        self.isConnected = false
    }

    private func initialiseSDK(apiKey: String, endpoint: String) {
        // Switch + Config defaults registered BEFORE init so the
        // auto-discovered flag / config snapshots Catch attaches see
        // something useful on the very first crash.
        _ = SankofaSwitch.shared.withDefaults(DemoFlag.defaults)
        _ = SankofaRemoteConfig.shared.withDefaults(DemoConfig.defaults)

        let config = SankofaConfig(
            endpoint: endpoint,
            debug: true,
            trackLifecycleEvents: true,
            flushIntervalSeconds: 10,
            batchSize: 5,
            recordSessions: true,
            maskAllInputs: true,
            captureScale: 0.35,
            catchEnvironment: inferredEnvironment ?? "dev",
            release: "example-ios@1.0.0",
            appVersion: "1.0.0"
        )
        config.beforeSend = { event in
            if event.message?.contains("[noise]") == true {
                return nil
            }
            if let extra = event.extra, extra["user_email"] != nil {
                var scrubbed = event
                scrubbed.extra?["user_email"] = AnyCodable("[redacted]")
                return scrubbed
            }
            return event
        }

        Sankofa.shared.initialize(apiKey: apiKey, config: config)
        _ = SankofaPulse.shared.register()
    }
}
