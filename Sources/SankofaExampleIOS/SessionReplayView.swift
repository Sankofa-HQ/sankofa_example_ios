import SwiftUI
import SankofaIOS

struct SessionReplayView: View {

    @State private var password = ""
    @State private var creditCard = ""
    @State private var normalText = ""

    var body: some View {
        NavigationView {
            Form {
                Section {
                    SecureField("Password (auto-masked)", text: $password)
                    TextField("Credit card (auto-masked)", text: $creditCard)
                        .keyboardType(.numberPad)
                } header: {
                    Label("Privacy Masking", systemImage: "eye.slash")
                } footer: {
                    Text("Fields are automatically redacted in screenshots via Ghost Masking.")
                }

                Section {
                    TextField("Visible field", text: $normalText)
                } header: {
                    Label("Unmasked", systemImage: "eye")
                }

                Section {
                    Button("🔥 Trigger Escalation (40s)") {
                        Sankofa.shared.track("checkout_started")
                    }
                    .foregroundColor(.orange)

                    Button("📤 Force Flush") {
                        Sankofa.shared.flush()
                    }
                } header: {
                    Label("Engine Controls", systemImage: "slider.horizontal.3")
                }
            }
            .navigationTitle("Session Replay")
        }
    }
}
