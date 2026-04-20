import SwiftUI
import SankofaIOS

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            TrackingView()
                .sankofaScreen("Event Tracking")
                .tabItem { Label("Track", systemImage: "chart.bar.xaxis") }
                .tag(0)

            IdentityView()
                .sankofaScreen("Identity")
                .tabItem { Label("Identity", systemImage: "person.fill") }
                .tag(1)

            SessionReplayView()
                .sankofaScreen("Session Replay")
                .tabItem { Label("Replay", systemImage: "record.circle") }
                .tag(2)

            FlagsLabView()
                .sankofaScreen("Flags Lab")
                .tabItem { Label("Lab", systemImage: "flask") }
                .tag(3)

            SettingsView()
                .sankofaScreen("Settings")
                .tabItem { Label("Settings", systemImage: "gear") }
                .tag(4)
        }
        .accentColor(.purple)
    }
}
