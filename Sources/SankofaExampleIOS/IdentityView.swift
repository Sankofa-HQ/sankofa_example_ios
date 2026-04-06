import SwiftUI
import SankofaIOS

struct IdentityView: View {

    @State private var userId    = ""
    @State private var userName  = ""
    @State private var userEmail = ""
    @State private var plan      = "free"
    @State private var isIdentified = false
    @State private var message: String? = nil

    private let plans = ["free", "starter", "growth", "enterprise"]

    var body: some View {
        NavigationView {
            Form {
                // ─── Identify ─────────────────────────────────────────────
                Section {
                    TextField("User ID (e.g. user_99)", text: $userId)
                        .autocorrectionDisabled()
                    Button("Identify User") {
                        guard !userId.isEmpty else { return }
                        Sankofa.shared.identify(userId: userId)
                        isIdentified = true
                        flash("✅ Identified as \(userId)")
                    }
                    .disabled(userId.isEmpty)
                } header: {
                    Text("1. Identify")
                }

                // ─── Set Person ───────────────────────────────────────────
                Section {
                    TextField("Full name", text: $userName)
                    TextField("Email", text: $userEmail)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                    Picker("Plan", selection: $plan) {
                        ForEach(plans, id: \.self) { Text($0.capitalized) }
                    }
                    Button("Set Profile") {
                        Sankofa.shared.setPerson(
                            name: userName.isEmpty ? nil : userName,
                            email: userEmail.isEmpty ? nil : userEmail,
                            properties: ["plan": plan]
                        )
                        flash("✅ Profile updated")
                    }
                } header: { Text("2. Profile Attributes") }

                // ─── Reset ────────────────────────────────────────────────
                Section {
                    Button("Reset (Logout)", role: .destructive) {
                        Sankofa.shared.reset()
                        isIdentified = false
                        userId = ""; userName = ""; userEmail = ""
                        flash("🔄 Identity reset")
                    }
                }
                
                if let msg = message {
                    Section {
                        Text(msg)
                            .foregroundColor(msg.hasPrefix("✅") ? .green : .orange)
                    }
                }
            }
            .navigationTitle("Identity")
        }
    }

    private func flash(_ msg: String) {
        message = msg
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { message = nil }
    }
}
