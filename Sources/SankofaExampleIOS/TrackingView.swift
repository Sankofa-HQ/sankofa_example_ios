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

    var body: some View {
        NavigationView {
            List {
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
