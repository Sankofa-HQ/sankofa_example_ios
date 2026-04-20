import Foundation
import SankofaIOS

// Canonical demo keys, defaults, and descriptions — identical to the
// other five Sankofa example projects (web, react-native, html, ios,
// android, flutter). One dashboard config drives every client.

enum DemoFlag {
    static let newHomeLayout       = "new_home_layout"
    static let checkoutCtaVariant  = "checkout_cta_variant"
    static let onboardingV2Rollout = "onboarding_v2_rollout"
    static let aiSummaryKillSwitch = "ai_summary_kill_switch"
    static let abPricingPage       = "ab_pricing_page"
    static let premiumBadgeVisible = "premium_badge_visible"

    static var all: [String] {
        [
            newHomeLayout,
            checkoutCtaVariant,
            onboardingV2Rollout,
            aiSummaryKillSwitch,
            abPricingPage,
            premiumBadgeVisible,
        ]
    }

    static let descriptions: [String: String] = [
        newHomeLayout:       "Swap hero between classic and v2.",
        checkoutCtaVariant:  "A/B/C variant — CTA copy + colour.",
        onboardingV2Rollout: "Progressive rollout gate.",
        aiSummaryKillSwitch: "Halt webhook pauses AI summary.",
        abPricingPage:       "Variant A/B on pricing copy.",
        premiumBadgeVisible: "Show/hide the premium badge.",
    ]

    static let defaults: [String: FlagDecision] = [
        newHomeLayout:       FlagDecision(value: false, reason: .unknown, version: 0),
        checkoutCtaVariant:  FlagDecision(value: true,  variant: "control", reason: .unknown, version: 0),
        onboardingV2Rollout: FlagDecision(value: false, reason: .unknown, version: 0),
        aiSummaryKillSwitch: FlagDecision(value: false, reason: .unknown, version: 0),
        abPricingPage:       FlagDecision(value: true,  variant: "A", reason: .unknown, version: 0),
        premiumBadgeVisible: FlagDecision(value: true,  reason: .unknown, version: 0),
    ]
}

enum DemoConfig {
    static let supportURL                 = "support_url"
    static let maxUploadsPerDay           = "max_uploads_per_day"
    static let trialDiscountPct           = "trial_discount_pct"
    static let maintenanceBannerEnabled   = "maintenance_banner_enabled"
    static let pricingTable               = "pricing_table"
    static let themeColors                = "theme_colors"

    static var all: [String] {
        [
            supportURL,
            maxUploadsPerDay,
            trialDiscountPct,
            maintenanceBannerEnabled,
            pricingTable,
            themeColors,
        ]
    }

    static let descriptions: [String: String] = [
        supportURL:               "String — support link target.",
        maxUploadsPerDay:         "Int — daily upload ceiling.",
        trialDiscountPct:         "Float 0–1 — trial discount.",
        maintenanceBannerEnabled: "Bool — amber maintenance banner.",
        pricingTable:             "JSON — array of pricing tiers.",
        themeColors:              "JSON {primary, accent} — theme tokens.",
    ]

    static let defaults: [String: ItemDecision] = [
        supportURL: ItemDecision(
            value: .string("https://support.sankofa.dev"),
            type: .string, reason: .unknown, version: 0
        ),
        maxUploadsPerDay: ItemDecision(
            value: .int(25),
            type: .int, reason: .unknown, version: 0
        ),
        trialDiscountPct: ItemDecision(
            value: .double(0.2),
            type: .float, reason: .unknown, version: 0
        ),
        maintenanceBannerEnabled: ItemDecision(
            value: .bool(false),
            type: .bool, reason: .unknown, version: 0
        ),
        pricingTable: ItemDecision(
            value: .array([
                .object([
                    "name": .string("Starter"),
                    "price": .int(0),
                    "features": .array([.string("1 project"), .string("1k events/mo")]),
                ]),
                .object([
                    "name": .string("Pro"),
                    "price": .int(49),
                    "features": .array([.string("Unlimited projects"), .string("1M events/mo"), .string("Replay")]),
                ]),
                .object([
                    "name": .string("Enterprise"),
                    "price": .int(199),
                    "features": .array([.string("SSO"), .string("Priority support"), .string("Audit log")]),
                ]),
            ]),
            type: .json, reason: .unknown, version: 0
        ),
        themeColors: ItemDecision(
            value: .object([
                "primary": .string("#8B5CF6"),
                "accent":  .string("#EC4899"),
            ]),
            type: .json, reason: .unknown, version: 0
        ),
    ]
}

/// Small struct bag around the typed pricing tier read from the
/// `pricing_table` JSON config. Mirrors the same shape every example
/// expects server-side.
struct DemoPricingTier {
    let name: String
    let price: Double
    let features: [String]

    /// Parse from the type-erased `ConfigValue` an `ItemDecision` hands back.
    static func parse(_ list: ConfigValue) -> [DemoPricingTier] {
        guard case .array(let items) = list else { return [] }
        return items.compactMap { item in
            guard case .object(let obj) = item,
                  case .string(let name)? = obj["name"]
            else { return nil }

            let price: Double = {
                switch obj["price"] {
                case .int(let n): return Double(n)
                case .double(let d): return d
                default: return 0
                }
            }()
            let features: [String] = {
                if case .array(let arr)? = obj["features"] {
                    return arr.compactMap { if case .string(let s) = $0 { return s } else { return nil } }
                }
                return []
            }()
            return DemoPricingTier(name: name, price: price, features: features)
        }
    }
}
