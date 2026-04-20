import SwiftUI
import SankofaIOS

struct TrackingView: View {

    struct LogEntry: Identifiable {
        let id = UUID()
        let text: String
    }

    @State private var log: [LogEntry] = []
    @State private var customEvent = ""
    @State private var customKey   = "screen"
    @State private var customValue = "home"

    // Flag-driven CTA at the top of the list. Reading the variant
    // records an exposure row — useful for demonstrating how the
    // experiment pipeline sees real reads, not just handshake rows.
    private var ctaVariant: String {
        SankofaSwitch.shared.getVariant(DemoFlag.checkoutCtaVariant, default: "control")
    }
    private var maintenanceEnabled: Bool {
        SankofaRemoteConfig.shared.get(DemoConfig.maintenanceBannerEnabled, default: false)
    }

    var body: some View {
        NavigationView {
            List {
                if maintenanceEnabled {
                    Section {
                        Text("⚠️ Maintenance in progress — see Lab tab for details.")
                            .font(.footnote.weight(.semibold))
                            .foregroundColor(.orange)
                    }
                }

                // Variant-driven CTA — the label and color flip with
                // the checkout_cta_variant A/B/C flag.
                Section {
                    Button {
                        fire("cta_showcase_pressed", props: ["variant": ctaVariant])
                    } label: {
                        HStack {
                            Image(systemName: "sparkles")
                            Text(ctaLabel(for: ctaVariant))
                                .fontWeight(.bold)
                            Spacer()
                            Text(ctaVariant).font(.caption).opacity(0.7)
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(ctaBackground(for: ctaVariant))
                    .foregroundColor(.white)
                }

                // ─── Quick Events ────────────────────────────────────────
                Section("Quick Events") {
                    ForEach(quickEvents, id: \.name) { ev in
                        Button {
                            fire(ev.name, props: ev.props)
                        } label: {
                            HStack {
                                Image(systemName: ev.icon)
                                    .frame(width: 28)
                                    .foregroundColor(.purple)
                                VStack(alignment: .leading) {
                                    Text(ev.name).font(.subheadline.bold())
                                    if let props = ev.props {
                                        Text(props.map { "\($0.key): \($0.value)" }.joined(separator: ", "))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }

                // ─── Custom Event ─────────────────────────────────────────
                Section("Custom Event") {
                    TextField("Event name", text: $customEvent)
                    HStack {
                        TextField("Key", text: $customKey)
                        Text(":")
                        TextField("Value", text: $customValue)
                    }
                    Button("Send Custom Event") {
                        guard !customEvent.isEmpty else { return }
                        fire(customEvent, props: [customKey: customValue])
                    }
                    .disabled(customEvent.isEmpty)
                }

                // ─── Log ──────────────────────────────────────────────────
                if !log.isEmpty {
                    Section("Log") {
                        ForEach(log.reversed()) { entry in
                            Text(entry.text)
                                .font(.caption.monospaced())
                                .foregroundColor(.secondary)
                        }
                        Button("Clear") { log.removeAll() }
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Event Tracking")
        }
    }

    // MARK: - Helpers

    private func fire(_ event: String, props: [String: Any]? = nil) {
        Sankofa.shared.track(event, properties: props ?? [:])
        let entryText = "[\(timestamp())] \(event)"
        log.append(LogEntry(text: entryText))
    }

    private func timestamp() -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f.string(from: Date())
    }

    private func ctaLabel(for variant: String) -> String {
        switch variant {
        case "blue": return "Try it free"
        case "red":  return "Upgrade now"
        default:     return "Fire showcase event"
        }
    }

    private func ctaBackground(for variant: String) -> Color {
        switch variant {
        case "blue": return .blue
        case "red":  return .red
        default:     return .purple
        }
    }

    private struct QuickEvent {
        let name: String
        let icon: String
        let props: [String: Any]?
    }

    private let quickEvents: [QuickEvent] = [
        QuickEvent(name: "app_opened",           icon: "app",             props: nil),
        QuickEvent(name: "onboarding_completed", icon: "checkmark.circle",props: ["step": "3"]),
        QuickEvent(name: "purchase_completed",   icon: "cart",            props: ["item": "cam_001", "price": 120.50]),
        QuickEvent(name: "checkout_started",     icon: "creditcard",      props: ["cart_value": 249.99]),
        QuickEvent(name: "premium_clicked",      icon: "star",            props: ["source": "paywall"]),
        QuickEvent(name: "video_played",         icon: "play.circle",     props: ["duration": 42]),
    ]
}
