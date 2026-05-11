import SwiftUI
import SankofaIOS

// MARK: - Custom business error

/// Realistic domain error used by scenario #10. Modeled on the same
/// `PaymentDeclinedError` the Node + Web galleries use so dashboard
/// filters line up across every example SDK.
struct PaymentDeclinedError: LocalizedError {
    let orderId: String
    let gatewayCode: String
    let amountCents: Int
    let reason: String

    var errorDescription: String? {
        "Payment declined for order \(orderId): \(reason) (gateway=\(gatewayCode))"
    }
}

// MARK: - CrashGalleryView

/// A SwiftUI gallery of crash + error scenarios that exercise every
/// entry point the Catch SDK exposes: manual `captureException`,
/// `captureMessage`, Swift traps, Obj-C `NSException`, and native
/// signals (SIGSEGV).
///
/// Buttons that deliberately tear the process down are gated behind
/// `#if DEBUG` so they cannot ship to TestFlight / App Store review.
struct CrashGalleryView: View {

    @State private var status: String = "Tap any scenario to see Catch in action."
    @State private var lastEventLevel: CatchLevel? = nil
    @State private var triggerCount: Int = 0

    var body: some View {
        NavigationView {
            List {
                Section {
                    Text("Sankofa Catch — Crash Gallery")
                        .font(.headline)
                        .foregroundColor(.purple)
                    Text("Every button below exercises a different error path. Manual captures land in the dashboard in ~5s; fatal scenarios land on the next app launch via the persisted queue.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section("Manual captures (safe)") {
                    row(
                        title: "captureException — business error",
                        detail: "PaymentDeclinedError with tags + extra",
                        symbol: "creditcard.trianglebadge.exclamationmark",
                        tint: .orange,
                        action: triggerCustomBusinessError
                    )
                    row(
                        title: "captureMessage — warning",
                        detail: "Non-fatal signal with extra context",
                        symbol: "exclamationmark.bubble",
                        tint: .yellow,
                        action: triggerCaptureMessage
                    )
                    row(
                        title: "Caught Swift throw",
                        detail: "do/try/catch — manually reported",
                        symbol: "arrow.triangle.2.circlepath.circle",
                        tint: .blue,
                        action: triggerCaughtThrow
                    )
                }

                Section("Swift runtime traps (fatal)") {
                    #if DEBUG
                    row(
                        title: "Force-unwrap nil",
                        detail: "let x: String? = nil; x!.count",
                        symbol: "bolt.slash.fill",
                        tint: .red,
                        action: triggerForceUnwrapNil
                    )
                    row(
                        title: "Array out of range",
                        detail: "arr[99] on a 3-element array",
                        symbol: "square.stack.3d.up.slash",
                        tint: .red,
                        action: triggerArrayOutOfRange
                    )
                    row(
                        title: "Dictionary key miss with force",
                        detail: "dict[\"missing\"]!",
                        symbol: "key.slash",
                        tint: .red,
                        action: triggerDictForceUnwrap
                    )
                    row(
                        title: "Type cast force (as!)",
                        detail: "Int value cast to String",
                        symbol: "arrow.left.arrow.right.square",
                        tint: .red,
                        action: triggerTypeCastForce
                    )
                    row(
                        title: "Division by zero",
                        detail: "Int.max / 0 — arithmetic trap",
                        symbol: "divide.circle",
                        tint: .red,
                        action: triggerDivisionByZero
                    )
                    row(
                        title: "Precondition failure",
                        detail: "precondition(false, ...)",
                        symbol: "xmark.octagon",
                        tint: .red,
                        action: triggerPreconditionFailure
                    )
                    row(
                        title: "Fatal error",
                        detail: "fatalError(\"message\")",
                        symbol: "flame",
                        tint: .red,
                        action: triggerFatalError
                    )
                    row(
                        title: "Stack overflow",
                        detail: "Infinite recursive func",
                        symbol: "square.stack.3d.down.forward",
                        tint: .red,
                        action: triggerStackOverflow
                    )
                    #else
                    Text("Fatal scenarios are DEBUG-only and are disabled in this build.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    #endif
                }

                Section("Obj-C + native (fatal)") {
                    #if DEBUG
                    row(
                        title: "NSInvalidArgumentException",
                        detail: "NSArray out-of-range via Obj-C bridge",
                        symbol: "exclamationmark.triangle.fill",
                        tint: .red,
                        action: triggerNSInvalidArgument
                    )
                    row(
                        title: "Background-thread crash",
                        detail: "NSException on DispatchQueue.global()",
                        symbol: "cpu",
                        tint: .red,
                        action: triggerBackgroundThreadCrash
                    )
                    row(
                        title: "SIGSEGV (tombstone)",
                        detail: "UnsafePointer → invalid memory write",
                        symbol: "memorychip",
                        tint: .red,
                        action: triggerSIGSEGV
                    )
                    #else
                    Text("Native-signal scenarios are DEBUG-only.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    #endif
                }

                Section("Breadcrumbs + flush") {
                    row(
                        title: "Drop a breadcrumb",
                        detail: "Navigation crumb with extra data",
                        symbol: "mappin.and.ellipse",
                        tint: .purple,
                        action: triggerBreadcrumb
                    )
                    row(
                        title: "Force flush",
                        detail: "POST queued events immediately",
                        symbol: "paperplane.fill",
                        tint: .green,
                        action: triggerFlush
                    )
                }

                Section("Phase B — withScope + beforeSend") {
                    row(
                        title: "withScope — temporary overlay",
                        detail: "Tags + level + extras on ONE capture only",
                        symbol: "scope",
                        tint: .green,
                        action: triggerWithScope
                    )
                    row(
                        title: "withScope — nested scopes",
                        detail: "Inner scope inherits + extends outer",
                        symbol: "square.on.square",
                        tint: .green,
                        action: triggerNestedScope
                    )
                    row(
                        title: "beforeSend — see SankofaExampleApp",
                        detail: "Fires events the hook should drop or scrub",
                        symbol: "lock.shield",
                        tint: .green,
                        action: triggerBeforeSendDemo
                    )
                    row(
                        title: "Trigger main-queue stall",
                        detail: "Sleep main 3s; detector fires an 'anr' event",
                        symbol: "tortoise",
                        tint: .yellow,
                        action: triggerMainQueueStall
                    )
                }

                Section("Status") {
                    HStack(alignment: .top, spacing: 8) {
                        if let level = lastEventLevel {
                            Image(systemName: icon(for: level))
                                .foregroundColor(color(for: level))
                        }
                        Text(status)
                            .font(.callout)
                            .foregroundColor(.primary)
                    }
                    if triggerCount > 0 {
                        Text("Events dispatched: \(triggerCount)")
                            .font(.caption.monospaced())
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Catch Gallery")
            .onAppear(perform: bootstrapContext)
        }
    }

    // MARK: - Scenario handlers

    /// #10 — Custom business error, manually reported. Demonstrates
    /// the `CaptureOptions` surface: tags, extra, level, and
    /// fingerprint all land together.
    private func triggerCustomBusinessError() {
        announce("Triggering custom business error…")
        let err = PaymentDeclinedError(
            orderId: "ord_\(Int.random(in: 10_000...99_999))",
            gatewayCode: "stripe_card_declined",
            amountCents: 4_999,
            reason: "insufficient_funds"
        )
        SankofaCatch.shared.addBreadcrumb(CatchBreadcrumb(
            type: "transaction",
            category: "checkout",
            message: "User attempted to pay",
            level: .info,
            data: [
                "amount_cents": AnyCodable(4_999),
                "currency": AnyCodable("USD"),
            ]
        ))
        _ = SankofaCatch.shared.captureException(
            err,
            options: SankofaCatch.CaptureOptions(
                level: .error,
                tags: [
                    "feature": "checkout",
                    "gateway": "stripe",
                    "gateway_code": err.gatewayCode,
                ],
                extra: [
                    "order_id": AnyCodable(err.orderId),
                    "amount_cents": AnyCodable(err.amountCents),
                    "reason": AnyCodable(err.reason),
                ],
                fingerprint: ["payment-declined", err.gatewayCode]
            )
        )
        dispatched(.error)
    }

    /// #12 — non-error signal with extra context.
    private func triggerCaptureMessage() {
        announce("Capturing warning message…")
        _ = SankofaCatch.shared.captureMessage(
            "Checkout retry threshold exceeded",
            options: SankofaCatch.CaptureOptions(
                level: .warning,
                tags: ["feature": "checkout", "phase": "retry"],
                extra: [
                    "retry_count": AnyCodable(3),
                    "last_error": AnyCodable("network_timeout"),
                ]
            )
        )
        dispatched(.warning)
    }

    private func triggerCaughtThrow() {
        announce("Simulating caught Swift throw…")
        do {
            throw NSError(
                domain: "dev.sankofa.example",
                code: 409,
                userInfo: [NSLocalizedDescriptionKey: "Inventory conflict for SKU-42"]
            )
        } catch {
            _ = SankofaCatch.shared.captureException(
                error,
                options: SankofaCatch.CaptureOptions(
                    level: .error,
                    tags: ["feature": "inventory"]
                )
            )
        }
        dispatched(.error)
    }

    private func triggerBreadcrumb() {
        announce("Added navigation breadcrumb.")
        SankofaCatch.shared.addBreadcrumb(CatchBreadcrumb(
            type: "navigation",
            category: "ui.lifecycle",
            message: "User pressed the breadcrumb button",
            level: .info,
            data: [
                "screen": AnyCodable("CrashGalleryView"),
                "trigger_count": AnyCodable(triggerCount),
            ]
        ))
        dispatched(.info)
    }

    private func triggerFlush() {
        announce("Flushing buffered events…")
        SankofaCatch.shared.flush()
        dispatched(.info)
    }

    #if DEBUG

    // MARK: - Fatal scenarios (DEBUG only)

    /// #2 — Force-unwrap nil.
    private func triggerForceUnwrapNil() {
        announce("Force-unwrapping nil in 100ms…")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let maybe: String? = nil
            _ = maybe!.count
        }
    }

    /// #3 — Array out of range.
    private func triggerArrayOutOfRange() {
        announce("Indexing past end of array…")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let arr = [1, 2, 3]
            _ = arr[99]
        }
    }

    /// #4 — Dictionary key miss with force.
    private func triggerDictForceUnwrap() {
        announce("Force-unwrapping missing key…")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let dict: [String: String] = ["present": "ok"]
            _ = dict["missing"]!
        }
    }

    /// #5 — Type cast force.
    private func triggerTypeCastForce() {
        announce("Force casting Int → String…")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let value: Any = 42
            _ = value as! String
        }
    }

    /// #6 — Division by zero (integer trap).
    private func triggerDivisionByZero() {
        announce("Triggering integer division-by-zero trap…")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let zero = Int.random(in: 0...0) // keep the optimizer honest
            _ = Int.max / zero
        }
    }

    /// #7 — Precondition failure.
    private func triggerPreconditionFailure() {
        announce("Hitting precondition(false)…")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            precondition(false, "demo: precondition intentionally failed")
        }
    }

    /// #8 — Fatal error.
    private func triggerFatalError() {
        announce("Calling fatalError()…")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            fatalError("demo: fatalError from CrashGalleryView")
        }
    }

    /// #9 — Stack overflow via runaway recursion.
    private func triggerStackOverflow() {
        announce("Recursing into stack overflow…")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            Self.runawayRecursion(0)
        }
    }

    private static func runawayRecursion(_ n: Int) -> Int {
        return runawayRecursion(n &+ 1) &+ 1
    }

    /// #1 — NSInvalidArgumentException via Obj-C bridging.
    private func triggerNSInvalidArgument() {
        announce("Throwing NSInvalidArgumentException…")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let arr = NSArray(array: ["a", "b"])
            _ = arr.object(at: 99)
        }
    }

    /// #11 — Background-thread crash. Confirms the uncaught-exception
    /// handler fires from a non-main queue.
    private func triggerBackgroundThreadCrash() {
        announce("Throwing on DispatchQueue.global()…")
        DispatchQueue.global(qos: .userInitiated).async {
            let arr = NSArray(array: [1, 2, 3])
            _ = arr.object(at: 50)
        }
    }

    /// #13 — SIGSEGV via unsafe pointer. Lands on the signal handler
    /// and writes a tombstone; drained into the queue on next launch.
    private func triggerSIGSEGV() {
        announce("Writing through invalid pointer → SIGSEGV…")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let ptr = UnsafeMutablePointer<Int>(bitPattern: 0xDEAD_BEEF)!
            ptr.pointee = 42
        }
    }

    #endif

    // MARK: - Phase B — withScope + beforeSend

    /// Sentry-style withScope: tags + level + extras attached to ONE
    /// capture only. The global scope set in `bootstrapContext()` is
    /// untouched.
    private func triggerWithScope() {
        announce("Triggering withScope (one-shot overlay)…")
        Sankofa.withScope { scope in
            scope.setTag("checkout_step", "payment")
            scope.setTag("payment_method", "stripe")
            scope.setExtra("cart_id", AnyCodable("cart_8x92Lq"))
            scope.setExtra("cart_value_cents", AnyCodable(4_900))
            scope.setLevel(.warning)
            scope.setFingerprint(["checkout", "payment", "manual"])
            _ = Sankofa.captureMessage("payment gateway timeout — retried 3x")
        }
        // Subsequent captures lose the scope.
        _ = Sankofa.captureMessage("post-scope event — no checkout_step tag")
        lastEventLevel = .warning
        status = "Fired scoped + global events"
        triggerCount += 1
    }

    /// Nested scopes: the inner closure inherits the outer's tags +
    /// extras at capture time, then layers its own on top.
    private func triggerNestedScope() {
        announce("Triggering nested withScope…")
        Sankofa.withScope { outer in
            outer.setTag("feature", "billing")
            outer.setExtra("checkout_session", AnyCodable("sess_12345"))
            Sankofa.withScope { inner in
                inner.setTag("substep", "card-validation")
                inner.setExtra("attempt", AnyCodable(2))
                // Carries BOTH feature=billing (outer) AND
                // substep=card-validation (inner).
                _ = Sankofa.captureMessage("invalid card number checksum")
            }
            // After inner scope pops, only outer's tags apply.
            _ = Sankofa.captureMessage("still in outer scope (no substep tag)")
        }
        lastEventLevel = .info
        status = "Fired nested-scope events"
        triggerCount += 1
    }

    /// Fires events the `beforeSend` hook configured in
    /// `SankofaExampleApp.swift` should drop or scrub.
    private func triggerBeforeSendDemo() {
        announce("Firing beforeSend demo events…")
        // 1. "[noise]" marker → beforeSend returns nil → dropped.
        _ = Sankofa.captureMessage("[noise] framework warning — drop me")
        // 2. PII scrubbed — beforeSend rewrites user_email before send.
        _ = Sankofa.captureMessage(
            "checkout failure — beforeSend should scrub user_email",
            options: SankofaCatch.CaptureOptions(
                level: .info,
                extra: [
                    "user_email": AnyCodable("ada@example.com"),
                    "note": AnyCodable("beforeSend should redact user_email"),
                ]
            )
        )
        lastEventLevel = .info
        status = "Fired drop + scrub events"
        triggerCount += 1
    }

    /// Block the main queue for 3 seconds. The Sankofa stall detector
    /// (2s default threshold) picks this up and emits an `anr` event
    /// without taking down the app.
    private func triggerMainQueueStall() {
        announce("Stalling main queue 3s — detector will fire an anr event…")
        Thread.sleep(forTimeInterval: 3.0)
        lastEventLevel = .warning
        status = "Main queue resumed; check dashboard for anr event"
        triggerCount += 1
    }

    // MARK: - Context bootstrap

    /// Attach demo user + tags the first time the view appears so every
    /// scenario ships with realistic identity + environment metadata.
    private func bootstrapContext() {
        SankofaCatch.shared.setUser(CatchUserContext(
            id: "user_42",
            email: "demo@sankofa.dev",
            username: "demo_user",
            segment: "beta"
        ))
        SankofaCatch.shared.setTags([
            "surface": "ios_example",
            "gallery": "catch",
            "build": "debug",
        ])
        SankofaCatch.shared.addBreadcrumb(CatchBreadcrumb(
            type: "navigation",
            category: "ui.lifecycle",
            message: "CrashGalleryView appeared",
            level: .info
        ))
    }

    // MARK: - UI helpers

    private func row(
        title: String,
        detail: String,
        symbol: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: symbol)
                    .foregroundColor(tint)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.subheadline.bold()).foregroundColor(.primary)
                    Text(detail).font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 2)
        }
    }

    private func announce(_ text: String) {
        status = "🚀 \(text)"
    }

    private func dispatched(_ level: CatchLevel) {
        triggerCount += 1
        lastEventLevel = level
        status = "✅ Dispatched — level=\(level.rawValue). Next flush in ~5s."
    }

    private func icon(for level: CatchLevel) -> String {
        switch level {
        case .fatal:   return "flame.fill"
        case .error:   return "exclamationmark.octagon.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info:    return "info.circle.fill"
        case .debug:   return "ant.fill"
        }
    }

    private func color(for level: CatchLevel) -> Color {
        switch level {
        case .fatal:   return .red
        case .error:   return .orange
        case .warning: return .yellow
        case .info:    return .blue
        case .debug:   return .gray
        }
    }
}
