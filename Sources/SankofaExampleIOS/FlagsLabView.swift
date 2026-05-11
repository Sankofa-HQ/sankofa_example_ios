import SwiftUI
import SankofaIOS

/// Lab view — shows the live preview surface that consumes flag +
/// config values, then tables every canonical demo key with its
/// current decision, reason, and version.
///
/// All state lives in @State dictionaries keyed by the canonical
/// demo-key strings. onChange subscribers bump a `rev` counter so the
/// view re-renders whenever a new handshake payload lands.
struct FlagsLabView: View {
    @State private var flags: [String: FlagDecision] = [:]
    @State private var config: [String: ItemDecision] = [:]
    @State private var cancellations: [Cancellation] = []
    @State private var scrollOffset: CGFloat = 0
    @State private var scrollHandle: SankofaScrollContainerHandle?

    var body: some View {
        // Sankofa.shared.tagScrollContainer — registers a scroll-offset
        // provider so heatmap touch attribution + replay frames carry
        // the right Y coordinate for below-the-fold taps. On iOS 16+
        // SwiftUI's ScrollView bridges to UIScrollView and the UIKit
        // walker handles this automatically, so this provider is the
        // belt-and-braces fallback for older OS versions + custom hosts.
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Maintenance banner
                if maintenanceEnabled {
                    maintenanceBanner
                }

                heroCard
                aiAndUploadsRow
                pricingCard
                supportCard

                sectionLabel("SANKOFA SWITCH — LIVE DECISIONS")
                ForEach(DemoFlag.all, id: \.self) { key in
                    flagRow(key)
                }

                sectionLabel("SANKOFA CONFIG — TYPED REMOTE VALUES")
                ForEach(DemoConfig.all, id: \.self) { key in
                    configRow(key)
                }
            }
            .padding()
            .background(GeometryReader { geo in
                Color.clear.preference(
                    key: ScrollOffsetKey.self,
                    value: -geo.frame(in: .named("flagsLabScroll")).minY
                )
            })
        }
        .coordinateSpace(name: "flagsLabScroll")
        .onPreferenceChange(ScrollOffsetKey.self) { scrollOffset = $0 }
        .background(Color(red: 0.06, green: 0.06, blue: 0.10))
        .onAppear {
            subscribe()
            scrollHandle = Sankofa.shared.tagScrollContainer { scrollOffset }
        }
        .onDisappear {
            scrollHandle?.remove()
            scrollHandle = nil
            for c in cancellations { c.cancel() }
            cancellations.removeAll()
        }
    }

    /// PreferenceKey used to plumb the SwiftUI `ScrollView`'s content
    /// offset out to a parent's `@State`. The negative sign on the
    /// background flips "content scrolled up by N" to "Y offset is N",
    /// matching what `Sankofa.shared.tagScrollContainer { ... }` expects.
    private struct ScrollOffsetKey: PreferenceKey {
        static var defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = nextValue()
        }
    }

    // MARK: - Subscriptions

    private func subscribe() {
        refreshSnapshot()
        cancellations.removeAll()
        for key in DemoFlag.all {
            let c = SankofaSwitch.shared.onChange(key) { _ in refreshSnapshot() }
            cancellations.append(c)
        }
        for key in DemoConfig.all {
            let c = SankofaRemoteConfig.shared.onChange(key) { _ in refreshSnapshot() }
            cancellations.append(c)
        }
    }

    private func refreshSnapshot() {
        var f: [String: FlagDecision] = [:]
        for key in DemoFlag.all {
            f[key] = SankofaSwitch.shared.getDecision(key) ?? DemoFlag.defaults[key]
        }
        var c: [String: ItemDecision] = [:]
        for key in DemoConfig.all {
            c[key] = SankofaRemoteConfig.shared.getDecision(key) ?? DemoConfig.defaults[key]
        }
        DispatchQueue.main.async {
            flags = f
            config = c
        }
    }

    // MARK: - Derived values

    private var themePrimary: Color {
        stringValue(DemoConfig.themeColors, nested: "primary").flatMap(Color.init(hex:)) ?? .purple
    }
    private var themeAccent: Color {
        stringValue(DemoConfig.themeColors, nested: "accent").flatMap(Color.init(hex:)) ?? .pink
    }
    private var supportURL: String {
        stringValue(DemoConfig.supportURL) ?? "https://support.sankofa.dev"
    }
    private var maxUploads: Int {
        intValue(DemoConfig.maxUploadsPerDay) ?? 25
    }
    private var discountPct: Double {
        doubleValue(DemoConfig.trialDiscountPct) ?? 0
    }
    private var maintenanceEnabled: Bool {
        boolValue(DemoConfig.maintenanceBannerEnabled) ?? false
    }
    private var newHomeLayout: Bool {
        flags[DemoFlag.newHomeLayout]?.value ?? false
    }
    private var ctaVariant: String {
        flags[DemoFlag.checkoutCtaVariant]?.variant ?? "control"
    }
    private var onboardingV2: Bool {
        flags[DemoFlag.onboardingV2Rollout]?.value ?? false
    }
    private var aiHalted: Bool {
        flags[DemoFlag.aiSummaryKillSwitch]?.value ?? false
    }
    private var pricingArm: String {
        flags[DemoFlag.abPricingPage]?.variant ?? "A"
    }
    private var premiumBadgeVisible: Bool {
        flags[DemoFlag.premiumBadgeVisible]?.value ?? true
    }
    private var pricingTiers: [DemoPricingTier] {
        let decision = config[DemoConfig.pricingTable] ?? DemoConfig.defaults[DemoConfig.pricingTable]!
        let parsed = DemoPricingTier.parse(decision.value)
        return pricingArm == "B" ? Array(parsed.reversed()) : parsed
    }

    // MARK: - UI building blocks

    private var maintenanceBanner: some View {
        Text("⚠️ Maintenance in progress — some features may be slow.")
            .font(.footnote.weight(.semibold))
            .foregroundColor(Color(red: 0.99, green: 0.76, blue: 0.25))
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(red: 0.96, green: 0.62, blue: 0.12).opacity(0.15))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(red: 0.96, green: 0.62, blue: 0.12), lineWidth: 1)
            )
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(newHomeLayout ? "HERO LAYOUT: V2" : "HERO LAYOUT: CLASSIC")
                .font(.caption2.weight(.bold))
                .tracking(1.4)
                .foregroundColor(.gray)
            Text(newHomeLayout ? "Analytics for modern teams" : "Ship analytics in minutes")
                .font(.title2.bold())
                .foregroundColor(.white)
            Text("Driven by `new_home_layout` and `theme_colors`.")
                .font(.caption)
                .foregroundColor(.gray)

            Button {
                // Reading the variant records an exposure row.
                _ = SankofaSwitch.shared.getVariant(DemoFlag.checkoutCtaVariant, default: "control")
            } label: {
                Text(ctaLabel)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(ctaBg)
                    .foregroundColor(.white)
                    .font(.subheadline.bold())
                    .cornerRadius(10)
            }
            .padding(.top, 4)

            Text("CTA variant: \(ctaVariant)")
                .font(.caption2).foregroundColor(.gray)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    newHomeLayout
                    ? themePrimary.opacity(0.12)
                    : Color(red: 0.10, green: 0.10, blue: 0.18)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(themeAccent.opacity(0.3), lineWidth: 1)
        )
    }

    private var ctaLabel: String {
        switch ctaVariant {
        case "blue": return "Try it free"
        case "red":  return "Upgrade now"
        default:     return "Get started"
        }
    }
    private var ctaBg: Color {
        switch ctaVariant {
        case "blue": return Color.blue
        case "red":  return Color.red
        default:     return themePrimary
        }
    }

    private var aiAndUploadsRow: some View {
        HStack(spacing: 10) {
            card(eyebrow: "AI SUMMARY") {
                if aiHalted {
                    Text("🛑 Paused").font(.subheadline.bold()).foregroundColor(.red.opacity(0.8))
                    Text("`ai_summary_kill_switch` halted. Halt webhooks flip this live.")
                        .font(.caption2).foregroundColor(.gray)
                } else {
                    Text("Ready for queries").font(.subheadline.bold()).foregroundColor(.white)
                    Text("Kill switch clear.").font(.caption2).foregroundColor(.gray)
                }
            }
            card(eyebrow: "UPLOADS") {
                Text("\(maxUploads) / day").font(.subheadline.bold()).foregroundColor(.white)
                Button {
                    _ = SankofaSwitch.shared.getFlag(DemoFlag.onboardingV2Rollout, default: false)
                } label: {
                    Text(onboardingV2 ? "Open uploader (v2)" : "Uploader coming soon")
                        .font(.caption.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(onboardingV2 ? themeAccent : Color.gray.opacity(0.5))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(!onboardingV2)
            }
        }
    }

    private var pricingCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("PRICING — ARM \(pricingArm)")
                        .font(.caption2.weight(.bold)).tracking(1.4).foregroundColor(.gray)
                    Text(pricingArm == "B" ? "Enterprise-first pricing" : "Simple pricing, scales with you")
                        .font(.subheadline.bold()).foregroundColor(.white)
                }
                Spacer()
                if premiumBadgeVisible {
                    Text("✨ Premium")
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(themePrimary.opacity(0.2))
                        .foregroundColor(themePrimary)
                        .overlay(
                            Capsule().stroke(themePrimary.opacity(0.5), lineWidth: 1)
                        )
                        .clipShape(Capsule())
                }
            }

            ForEach(pricingTiers, id: \.name) { tier in
                pricingTileRow(tier)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(red: 0.10, green: 0.10, blue: 0.18))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(themePrimary.opacity(0.3), lineWidth: 1)
        )
    }

    private func pricingTileRow(_ tier: DemoPricingTier) -> some View {
        let discounted = max(0, tier.price * (1 - discountPct))
        return HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(tier.name).font(.subheadline.bold()).foregroundColor(.white)
                Text("$\(Int(discounted))/mo")
                    .font(.title3.bold()).foregroundColor(themePrimary)
                if discountPct > 0, tier.price > 0 {
                    Text("\(Int(discountPct * 100))% off trial")
                        .font(.caption2).foregroundColor(.yellow)
                }
            }
            Spacer()
            VStack(alignment: .leading, spacing: 2) {
                ForEach(tier.features, id: \.self) { f in
                    Text("• \(f)").font(.caption2).foregroundColor(.gray)
                }
            }
        }
        .padding(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var supportCard: some View {
        card(eyebrow: "SUPPORT") {
            if let url = URL(string: supportURL) {
                Link(supportURL, destination: url)
                    .font(.subheadline.bold())
                    .foregroundColor(themeAccent)
            } else {
                Text(supportURL).font(.subheadline.bold()).foregroundColor(themeAccent)
            }
            Text("From `support_url`.").font(.caption2).foregroundColor(.gray)
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption2.weight(.bold))
            .tracking(1.4)
            .foregroundColor(.gray)
            .padding(.top, 8)
    }

    private func flagRow(_ key: String) -> some View {
        let d = flags[key] ?? DemoFlag.defaults[key]!
        let value = !d.variant.isEmpty ? d.variant : String(d.value)
        return HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text(key).font(.caption.bold()).foregroundColor(.white)
                Text(DemoFlag.descriptions[key] ?? "")
                    .font(.caption2).foregroundColor(.gray)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text(value).font(.caption.bold()).foregroundColor(Color(red: 0.98, green: 0.64, blue: 0.68))
                Text("\(d.reason.rawValue) · v\(d.version)")
                    .font(.caption2).foregroundColor(.gray)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(red: 0.10, green: 0.10, blue: 0.18))
        )
    }

    private func configRow(_ key: String) -> some View {
        let d = config[key] ?? DemoConfig.defaults[key]!
        let rendered: String = {
            switch d.value {
            case .null: return "null"
            case .bool(let b): return String(b)
            case .int(let i): return String(i)
            case .double(let f): return String(f)
            case .string(let s): return "\"\(s)\""
            case .array, .object:
                if let data = try? JSONEncoder().encode(d.value),
                   let text = String(data: data, encoding: .utf8) {
                    return text
                }
                return "json"
            }
        }()
        return HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text(key).font(.caption.bold()).foregroundColor(.white)
                Text(DemoConfig.descriptions[key] ?? "")
                    .font(.caption2).foregroundColor(.gray)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text(rendered).font(.caption2.bold())
                    .foregroundColor(Color(red: 0.98, green: 0.64, blue: 0.68))
                    .lineLimit(3)
                    .multilineTextAlignment(.trailing)
                Text("\(d.type.rawValue) · \(d.reason.rawValue) · v\(d.version)")
                    .font(.caption2).foregroundColor(.gray)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(red: 0.10, green: 0.10, blue: 0.18))
        )
    }

    private func card<Content: View>(
        eyebrow: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(eyebrow)
                .font(.caption2.weight(.bold))
                .tracking(1.4)
                .foregroundColor(.gray)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.10, green: 0.10, blue: 0.18))
        )
    }

    // MARK: - Typed value helpers

    private func stringValue(_ key: String, nested: String? = nil) -> String? {
        guard let d = config[key] else { return nil }
        if let nested = nested {
            if case .object(let obj) = d.value,
               case .string(let s)? = obj[nested] {
                return s
            }
            return nil
        }
        if case .string(let s) = d.value { return s }
        return nil
    }

    private func intValue(_ key: String) -> Int? {
        guard let d = config[key] else { return nil }
        if case .int(let i) = d.value { return Int(i) }
        if case .double(let f) = d.value { return Int(f) }
        return nil
    }

    private func doubleValue(_ key: String) -> Double? {
        guard let d = config[key] else { return nil }
        if case .double(let f) = d.value { return f }
        if case .int(let i) = d.value { return Double(i) }
        return nil
    }

    private func boolValue(_ key: String) -> Bool? {
        guard let d = config[key] else { return nil }
        if case .bool(let b) = d.value { return b }
        return nil
    }
}

// Small hex Color init helper for theme tokens.
private extension Color {
    init?(hex: String) {
        var h = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if h.hasPrefix("#") { h.removeFirst() }
        guard h.count == 6 || h.count == 8 else { return nil }
        var rgb: UInt64 = 0
        guard Scanner(string: h).scanHexInt64(&rgb) else { return nil }
        let (r, g, b, a): (Double, Double, Double, Double)
        if h.count == 6 {
            r = Double((rgb & 0xFF0000) >> 16) / 255
            g = Double((rgb & 0x00FF00) >> 8) / 255
            b = Double(rgb & 0x0000FF) / 255
            a = 1
        } else {
            r = Double((rgb & 0xFF000000) >> 24) / 255
            g = Double((rgb & 0x00FF0000) >> 16) / 255
            b = Double((rgb & 0x0000FF00) >> 8) / 255
            a = Double(rgb & 0x000000FF) / 255
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}
