import SwiftUI
import SankofaIOS

/// Pulse Lab — exercises every public surface of `SankofaPulse.shared`:
///
///   - `register()` (handled in SankofaExampleApp.init; status surfaced here)
///   - `show(surveyId:from:properties:flags:)` programmatic presentation
///   - `isEligible(surveyId:properties:flags:)` eligibility probe
///   - `on(event, listener)` lifecycle hooks (each event logged)
///
/// Toggle "Pro user" to swap the `userProperties.plan` value. The
/// `productResearch` survey's targeting rule requires `plan = pro`.
struct PulseLabView: View {
    @State private var proUser = true
    @State private var eventLog: [String] = []
    @State private var subscriptions: [SankofaPulseSubscription] = []

    private var registered: Bool {
        SankofaPulse.shared.isRegistered
    }

    private var properties: [String: SankofaPulseAnyJSON] {
        ["plan": proUser ? .string("pro") : .string("free")]
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    registrationCard
                    hostContextCard
                    surveysSection
                    eventLogSection
                }
                .padding()
            }
            .navigationTitle("Pulse Lab")
            .background(Color(.systemGroupedBackground))
        }
        .onAppear(perform: subscribeIfNeeded)
        .onDisappear(perform: cancelSubscriptions)
    }

    private var registrationCard: some View {
        let color: Color = registered ? .green : .orange
        return HStack(alignment: .top, spacing: 12) {
            Image(systemName: registered
                  ? "checkmark.circle.fill"
                  : "exclamationmark.triangle.fill")
                .font(.title3)
                .foregroundColor(color)
            VStack(alignment: .leading, spacing: 4) {
                Text(registered
                     ? "SankofaPulse registered"
                     : "SankofaPulse not registered")
                    .font(.headline)
                Text(registered
                     ? "Surveys will fetch their bundle and present locally."
                     : "register() returned false — check Sankofa.shared.initialize ran.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }

    private var hostContextCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Host context")
                .font(.headline)
            Text("Forwarded into both `show()` and `isEligible()`. The 'Product research' survey requires plan = pro.")
                .font(.caption)
                .foregroundColor(.secondary)
            Toggle("Pro user (plan = pro)", isOn: $proUser)
                .padding(.top, 4)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(10)
    }

    private var surveysSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Surveys")
                .font(.headline)
            ForEach(DemoSurvey.all, id: \.self) { id in
                surveyCard(id: id)
            }
        }
    }

    @ViewBuilder
    private func surveyCard(id: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(DemoSurvey.titles[id] ?? id)
                .font(.subheadline.bold())
            Text(id)
                .font(.system(.caption2, design: .monospaced))
                .foregroundColor(.secondary)
            Text(DemoSurvey.descriptions[id] ?? "")
                .font(.caption)
            HStack(spacing: 8) {
                Button {
                    showSurvey(id)
                } label: {
                    Label("Show", systemImage: "play.fill")
                        .font(.caption.bold())
                }
                .buttonStyle(.borderedProminent)
                .disabled(!registered)

                Button {
                    Task { await probeEligibility(id) }
                } label: {
                    Label("Check eligibility", systemImage: "checklist")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .disabled(!registered)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(10)
    }

    private var eventLogSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Lifecycle event log")
                    .font(.headline)
                Spacer()
                if !eventLog.isEmpty {
                    Button("Clear") { eventLog.removeAll() }
                        .font(.caption)
                }
            }
            Text("Subscribed via SankofaPulse.shared.on(event, listener).")
                .font(.caption)
                .foregroundColor(.secondary)
            if eventLog.isEmpty {
                Text("No events yet. Press Show on a survey above.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(eventLog.indices, id: \.self) { i in
                    Text(eventLog[i])
                        .font(.system(.caption2, design: .monospaced))
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(10)
    }

    // MARK: - Actions

    private func showSurvey(_ id: String) {
        guard registered else { return }
        // Walk the key window's root VC chain to find the topmost
        // presented controller. SankofaPulse.show needs a presenter
        // and SwiftUI doesn't hand one out directly.
        guard let root = topMostViewController() else { return }
        SankofaPulse.shared.show(
            surveyId: id,
            from: root,
            properties: properties,
            flags: [:]
        )
    }

    private func probeEligibility(_ id: String) async {
        let decision = await SankofaPulse.shared.isEligible(
            surveyId: id,
            properties: properties,
            flags: [:]
        )
        let summary = decision.eligible
            ? "eligible ✓"
            : "ineligible — \(decision.reason ?? "(no reason)")"
        let entry = "\(timestamp())  probe \(DemoSurvey.titles[id] ?? id) — \(summary)"
        await MainActor.run {
            eventLog.insert(entry, at: 0)
            if eventLog.count > 40 { eventLog.removeLast() }
        }
    }

    private func subscribeIfNeeded() {
        guard registered, subscriptions.isEmpty else { return }
        let events: [SankofaPulseEvent] = [
            .surveyShown, .surveyDismissed, .surveyCompleted, .surveyPartialSaved,
        ]
        for event in events {
            let sub = SankofaPulse.shared.on(event) { payload in
                let suffix = [
                    payload.responseId.map { "response=\($0)" } ?? "",
                    payload.reason.map { "reason=\($0)" } ?? "",
                ].filter { !$0.isEmpty }.joined(separator: " · ")
                let entry = "\(timestamp())  \(event.rawValue)" +
                    (suffix.isEmpty ? "" : " — \(suffix)")
                Task { @MainActor in
                    eventLog.insert(entry, at: 0)
                    if eventLog.count > 40 { eventLog.removeLast() }
                }
            }
            subscriptions.append(sub)
        }
    }

    private func cancelSubscriptions() {
        for sub in subscriptions { sub.cancel() }
        subscriptions.removeAll()
    }

    private func timestamp() -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f.string(from: Date())
    }

    private func topMostViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes
        for scene in scenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            for window in windowScene.windows where window.isKeyWindow {
                var top = window.rootViewController
                while let presented = top?.presentedViewController {
                    top = presented
                }
                return top
            }
        }
        return nil
    }
}

#Preview {
    PulseLabView()
}
