import SwiftUI

/// First-run "connect" screen — mirror of the web example's
/// `ApiKeyGate`. Collects an API key + optional endpoint, persists
/// them via `SankofaConnection`, then hands control to `MainTabView`.
struct ConnectView: View {
    @EnvironmentObject private var connection: SankofaConnection

    @State private var draftKey: String = ""
    @State private var draftEndpoint: String = ""
    @State private var touched: Bool = false

    private var inferredEnv: String? {
        if draftKey.hasPrefix("sk_test_") { return "TEST" }
        if draftKey.hasPrefix("sk_live_") { return "LIVE" }
        return nil
    }

    private var keyLooksValid: Bool { draftKey.trimmingCharacters(in: .whitespaces).count > 8 }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 40)

                // Logo / brand block
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color(red: 0.42, green: 0.36, blue: 0.91),
                                     Color(red: 0.64, green: 0.61, blue: 1.0)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 76, height: 76)
                        .shadow(color: Color(red: 0.42, green: 0.36, blue: 0.91).opacity(0.4),
                                radius: 20, x: 0, y: 6)
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(.white)
                }

                VStack(spacing: 6) {
                    Text("Sankofa Developer Sandbox")
                        .font(.caption)
                        .textCase(.uppercase)
                        .foregroundStyle(.secondary)
                    Text("Connect your project")
                        .font(.title2.weight(.bold))
                    Text("Paste your Sankofa API key to start tracking events, capturing errors, and exercising every SDK module from this app. Your key is stored on this device only.")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                }

                // Form
                VStack(alignment: .leading, spacing: 14) {
                    Label("API key", systemImage: "key.fill")
                        .font(.subheadline.weight(.semibold))

                    SecureField("sk_test_…", text: $draftKey)
                        .textContentType(.password)
                        .autocorrectionDisabled(true)
                        .textInputAutocapitalization(.never)
                        .padding(12)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    if let env = inferredEnv {
                        HStack(spacing: 6) {
                            Text("Detected")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            Text(env)
                                .font(.footnote.weight(.bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(env == "TEST" ? Color.yellow.opacity(0.2) : Color.green.opacity(0.2))
                                .foregroundStyle(env == "TEST" ? Color.orange : Color.green)
                                .clipShape(Capsule())
                            Text("environment")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    if touched && !keyLooksValid {
                        Text("That key looks too short — paste the full token.")
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }

                    DisclosureGroup("Advanced · server endpoint") {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Override only if you self-host. Leave blank for the hosted Sankofa cloud.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextField("http://localhost:8080", text: $draftEndpoint)
                                .keyboardType(.URL)
                                .autocorrectionDisabled(true)
                                .textInputAutocapitalization(.never)
                                .padding(10)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .padding(.top, 8)
                    }
                    .padding(.top, 4)

                    Button(action: submit) {
                        Text("Connect & initialize SDK")
                            .font(.body.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(red: 0.42, green: 0.36, blue: 0.91))
                    .disabled(!keyLooksValid)
                    .padding(.top, 8)
                }
                .padding(20)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(.separator).opacity(0.5), lineWidth: 1)
                )

                HStack(spacing: 4) {
                    Text("Don't have a key?")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Link("Get one in 30 seconds ↗",
                         destination: URL(string: "https://sankofa.dev")!)
                        .font(.footnote.weight(.medium))
                }

                Spacer(minLength: 20)
            }
            .padding(20)
            .frame(maxWidth: 480)
            .frame(maxWidth: .infinity)
        }
        .onAppear {
            // Pre-populate the endpoint field with the value last used.
            // Lets the developer flip back to ConnectView (after
            // Disconnect) without re-typing the URL every time.
            if draftEndpoint.isEmpty { draftEndpoint = connection.endpoint }
        }
    }

    private func submit() {
        touched = true
        guard keyLooksValid else { return }
        connection.connect(apiKey: draftKey, endpoint: draftEndpoint)
    }
}
