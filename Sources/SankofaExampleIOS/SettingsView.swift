import SwiftUI
import SankofaIOS

struct SettingsView: View {
    @EnvironmentObject private var connection: SankofaConnection
    @State private var showingDisconnectConfirm = false

    var body: some View {
        NavigationView {
            List {
                Section("Connection") {
                    HStack {
                        Text("Endpoint")
                        Spacer()
                        Text(connection.endpoint)
                            .font(.footnote.monospaced())
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    if let env = connection.inferredEnvironment {
                        HStack {
                            Text("Environment")
                            Spacer()
                            Text(env.uppercased())
                                .font(.footnote.weight(.bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(env == "test" ? Color.yellow.opacity(0.2) : Color.green.opacity(0.2))
                                .foregroundStyle(env == "test" ? Color.orange : Color.green)
                                .clipShape(Capsule())
                        }
                    }
                    HStack {
                        Text("API key")
                        Spacer()
                        Text(maskedKey(connection.apiKey))
                            .font(.footnote.monospaced())
                            .foregroundColor(.secondary)
                    }
                    Button(role: .destructive) {
                        showingDisconnectConfirm = true
                    } label: {
                        Label("Disconnect & forget key", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }

                Section("SDK Details") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0").foregroundColor(.secondary)
                    }
                }

                Section("Device Info") {
                    HStack {
                        Text("OS")
                        Spacer()
                        Text(UIDevice.current.systemName + " " + UIDevice.current.systemVersion)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("Disconnect from Sankofa?", isPresented: $showingDisconnectConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Disconnect", role: .destructive) {
                    connection.disconnect()
                }
            } message: {
                Text("Your saved API key and endpoint will be removed from this device. You'll be returned to the connect screen.")
            }
        }
    }

    /// Show only the prefix + last 4 of the key so the user can verify
    /// which key is in use without exposing the full secret on-screen
    /// (it's still a developer machine, but consistency with the web
    /// gate's masked display).
    private func maskedKey(_ key: String) -> String {
        guard key.count > 12 else { return "•••" }
        let prefix = key.prefix(8)
        let suffix = key.suffix(4)
        return "\(prefix)…\(suffix)"
    }
}
