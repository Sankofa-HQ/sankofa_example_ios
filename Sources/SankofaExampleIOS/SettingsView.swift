import SwiftUI
import SankofaIOS

struct SettingsView: View {
    var body: some View {
        NavigationView {
            List {
                Section("SDK Details") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0").foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Environment")
                        Spacer()
                        Text("Development").foregroundColor(.secondary)
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
        }
    }
}
