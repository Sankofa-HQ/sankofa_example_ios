import SwiftUI
import SankofaIOS

@main
struct SankofaExampleApp: App {

    /// The connection state owns the SDK lifecycle now — no more
    /// hardcoded `apiKey` + `endpoint` at app launch. If the user has
    /// previously connected (UserDefaults has stored values) the
    /// connection initialises the SDK in its constructor and we drop
    /// straight into `MainTabView`. Otherwise we show `ConnectView`
    /// which mirrors the web example's `ApiKeyGate` UX.
    @StateObject private var connection = SankofaConnection.shared

    var body: some Scene {
        WindowGroup {
            Group {
                if connection.isConnected {
                    MainTabView()
                } else {
                    ConnectView()
                }
            }
            .environmentObject(connection)
            .animation(.easeInOut(duration: 0.25), value: connection.isConnected)
        }
    }
}
