# Sankofa Catch — iOS Crash Gallery

A hands-on catalogue of error + crash scenarios wired into
`CrashGalleryView` (Tab 5 — "Catch"). Every scenario exercises a
different entry point in `SankofaCatch` so the dashboard shows a
realistic spread of event types, mechanisms, and levels.

The SDK is started once in `SankofaExampleApp.init()`:

```swift
_ = SankofaCatch.shared.start(
    environment: "dev",
    release: "example-ios@1.0.0",
    appVersion: "1.0.0"
)
```

When the gallery view appears it attaches a demo user + tags and
drops a navigation breadcrumb:

```swift
SankofaCatch.shared.setUser(CatchUserContext(id: "user_42", ...))
SankofaCatch.shared.setTags(["surface": "ios_example", ...])
SankofaCatch.shared.addBreadcrumb(CatchBreadcrumb(type: "navigation", ...))
```

Manual captures land on the next 5-second flush tick. Fatal scenarios
persist via `UserDefaults` and drain on the next launch — so after a
hard crash, relaunch the app and watch the dashboard receive the
event within ~5s.

All scenarios that deliberately tear the process down are gated behind
`#if DEBUG` so they cannot ship to TestFlight / App Store.

## Scenarios

| # | Scenario | Mechanism | Level | DEBUG-only |
|---|---|---|---|---|
| 1 | `NSInvalidArgumentException` | `NSSetUncaughtExceptionHandler` | fatal | yes |
| 2 | Force-unwrap `nil` | Swift runtime trap (SIGILL / SIGABRT) | fatal | yes |
| 3 | Array out of range | Swift runtime trap | fatal | yes |
| 4 | Dictionary force-unwrap miss | Swift runtime trap | fatal | yes |
| 5 | Force cast `as!` failure | Swift runtime trap | fatal | yes |
| 6 | Integer division by zero | Swift runtime trap | fatal | yes |
| 7 | `precondition(false, ...)` | Swift runtime trap | fatal | yes |
| 8 | `fatalError(...)` | Swift runtime trap | fatal | yes |
| 9 | Stack overflow (recursion) | SIGSEGV via guard page | fatal | yes |
| 10 | `PaymentDeclinedError` | Manual `captureException` | error | — |
| 11 | Background-thread `NSException` | `NSSetUncaughtExceptionHandler` (off-main) | fatal | yes |
| 12 | `captureMessage` warning | Manual `captureMessage` | warning | — |
| 13 | SIGSEGV via bad pointer | `CatchSignalHandler` tombstone | fatal | yes |

### Notes on signal-based scenarios

Scenarios 9 and 13 land in `CatchSignalHandler.install()` — the async-
signal-safe dump writer. The current process cannot POST the event
inline (it is being torn down), so the handler writes a crash dump
file. On the next app launch `SankofaCatch.start(...)` calls
`drainPendingNativeCrashes()` which hydrates the dumps into the event
buffer. Symbolication happens server-side using the `debug_meta`
captured with each event (LC_UUID + text vmaddr for every loaded
image).

### Custom business error

Scenario 10 uses a realistic `PaymentDeclinedError` modeled on the
same shape the Node + Web example galleries use, so filters like
`gateway_code:stripe_card_declined` work uniformly across every
Sankofa example SDK:

```swift
struct PaymentDeclinedError: LocalizedError {
    let orderId: String
    let gatewayCode: String
    let amountCents: Int
    let reason: String
}
```

The capture call attaches tags (`feature`, `gateway`), extra
metadata (`order_id`, `amount_cents`), and a fingerprint so repeat
declines group into a single Catch issue.

## SDK surface used

- `SankofaCatch.shared.start(environment:release:appVersion:)`
- `SankofaCatch.shared.setUser(CatchUserContext)`
- `SankofaCatch.shared.setTags([String: String])`
- `SankofaCatch.shared.addBreadcrumb(CatchBreadcrumb)`
- `SankofaCatch.shared.captureException(Error, options: CaptureOptions)`
- `SankofaCatch.shared.captureMessage(String, options: CaptureOptions)`
- `SankofaCatch.shared.flush()`

Auto-hooks (no call required):

- `NSSetUncaughtExceptionHandler` — Obj-C `NSException` on any thread.
- `CatchSignalHandler` — `SIGSEGV / SIGABRT / SIGBUS / SIGILL / SIGFPE / SIGTRAP / SIGSYS`.
