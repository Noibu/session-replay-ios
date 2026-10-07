# Noibu iOS SDK Guide

## Table of Contents

- [1. Requirements](#1-requirements)
- [2. Installation](#2-installation)
- [3. Configuration](#3-configuration)
- [4. Initialization](#4-initialization)
- [5. Page Navigation](#5-page-navigation)
- [6. Error Reporting](#6-error-reporting)
- [7. Network Monitoring](#7-network-monitoring)
- [8. WebView Support](#8-webview-support)
- [9. View Tagging](#9-view-tagging)
- [10. Custom Attributes](#10-custom-attributes)
- [11. Privacy & Security](#11-privacy--security)
- [12. Lifecycle Management](#12-lifecycle-management)
- [13. Background Sync](#13-background-sync)

---

## 1. Requirements

- **Minimum iOS**: 14.0
- **Swift**: 5.9+
- **Xcode**: 26.0+
- **Dependency manager**: Swift Package Manager **or** CocoaPods

---

## 2. Installation

The current release is **1.1.2**. The SDK is distributed as prebuilt binary XCFrameworks (`NoibuSessionReplay` and its `coreKit` runtime). It declares one dependency, [Kronos](https://github.com/lyft/Kronos) (NTP clock sync), which Swift Package Manager and CocoaPods resolve for you — nothing to add by hand.

### Swift Package Manager (Xcode UI)

1. In Xcode, go to **File → Add Package Dependencies…**
2. Enter the package URL: `https://github.com/Noibu/session-replay-ios.git`
3. Choose **Up to Next Major Version** from `1.1.2` (or **Exact Version** `1.1.2` to pin).
4. Add the package to your app target.

### Swift Package Manager (`Package.swift`)

```swift
dependencies: [
    .package(
        url: "https://github.com/Noibu/session-replay-ios.git",
        from: "1.1.2"
    )
]
```

Then reference the product in your target:

```swift
.target(
    name: "MyApp",
    dependencies: [
        .product(name: "NoibuSessionReplay", package: "session-replay-ios")
    ]
)
```

### CocoaPods

Add to your `Podfile`:

```ruby
platform :ios, '14.0'

target 'YourApp' do
  pod 'NoibuSessionReplay', '~> 1.1.2'
end

# Xcode 15+ defaults ENABLE_USER_SCRIPT_SANDBOXING = YES, which blocks CocoaPods'
# "[CP] Embed Pods Frameworks" script (it copies coreKit.framework into your app) with
# "Sandbox: rsync ... Operation not permitted". Disable script sandboxing on your app target:
post_install do |installer|
  installer.aggregate_targets.each do |aggregate_target|
    aggregate_target.user_project.native_targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['ENABLE_USER_SCRIPT_SANDBOXING'] = 'NO'
      end
    end
    aggregate_target.user_project.save
  end
end
```

Then install and open the generated workspace:

```bash
pod install --repo-update
open YourApp.xcworkspace
```

> **The pod is a binary.** CocoaPods downloads the prebuilt xcframework bundle from the matching
> GitHub release and pulls in the `Kronos` pod as a dependency; nothing is compiled from source.
>
> **Any linkage mode works.** The SDK vendors a dynamic `coreKit.xcframework`, and CocoaPods adds
> the `[CP] Embed Pods Frameworks` phase for a vendored dynamic xcframework whether or not you use
> `use_frameworks!` — verified against this pod under `use_frameworks! :linkage => :static` and with
> no `use_frameworks!` at all. Use whichever mode your app already uses; React Native apps must
> keep `:linkage => :static` (Hermes does not support dynamic frameworks).
>
> You can also set `ENABLE_USER_SCRIPT_SANDBOXING` to `No` in your app target's Build Settings
> instead of the `post_install` hook.
>
> Always open `.xcworkspace`, not `.xcodeproj`, when using CocoaPods.

---

## 3. Configuration

### NoibuConfig

The SDK is configured via `NoibuConfig`. Parameters:

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `domain` | `String` | **Yes** | - | Your Noibu domain endpoint (provided by Noibu) |
| `privacyMode` | `NoibuPrivacyMode` | No | `.maskSensitive` | How much displayed text reaches the replay. See [Privacy Modes](#privacy-modes). |
| `logLevel` | `NoibuLogLevel?` | No | `nil` | Diagnostic log verbosity. Leave unset for the default (silent in release builds). See [Diagnostic Logging](#diagnostic-logging). |
| `trackTouches` | `Bool` | No | `true` | Capture taps and scrolls (with DXA selectors) |
| `trackKeyboard` | `Bool` | No | `true` | Capture keyboard-focus events (which field was typed in — never the text) |
| `trackNetwork` | `Bool` | No | `true` | Capture HTTP requests/responses |
| `trackWebViews` | `Bool` | No | `true` | Allow webview hybrid capture — off makes `NoibuWebViewTracking.enable` a no-op |
| `autoTrackNavigation` | `Bool` | No | `false` | Derive page boundaries from `UIViewController.viewDidAppear` instead of explicit `didNavigate` calls. See [Page Navigation](#5-page-navigation). |
| `trackErrors` | `Bool` | No | `true` | Report uncaught `NSException`s as errors (chains to the existing handler). See [Error Reporting](#6-error-reporting). |

The field list mirrors Android's `SessionReplayConfig`, so the React Native and Flutter shims map one
config surface onto both platforms.

### Privacy

The mode controls how much **displayed** text (labels, button titles, field placeholders) reaches the
replay. What the user **types** is never captured in any mode — a field surfaces its placeholder, or `***`.

| Mode | Description |
|------|-------------|
| `.allowAll` | Displayed text is captured verbatim — nothing is redacted |
| `.maskSensitive` | Default. Displayed text is captured, with card / SSN / email / phone spans redacted in place — including PII rendered as a plain label, which input masking never sees |
| `.maskAll` | No readable text at all: every string becomes `xxxx`, keeping only its word/length shape |

The mode applies to the UIKit walker (which also covers React Native's text views) and to SwiftUI text
read structurally from the render tree. It is shared with the Android and Flutter SDKs
(`com.noibu.mobile.core.privacy.TextMasking` in the KMP core owns the policy).

> **SwiftUI caveat:** where the structural reader can't reach a SwiftUI view, its layer is rasterized
> into an image — text baked into those pixels is not redacted by any mode. Prefer `.maskAll` together
> with a screen-level review for SwiftUI apps handling regulated data.

The mode you initialized with can be read back from `Noibu.shared.privacyMode`.

### Per-view privacy (UIKit)

The global mode sets the floor for the whole app. To tighten one region without masking everything,
set `noibuPrivacy` on a `UIView`; the level applies to that view and its whole subtree, and a nested
mark wins over an outer one. A mark can only make a region stricter than the global mode, never looser.

| Level | Effect on the subtree |
|-------|-----------------------|
| `.mask` | Every readable text is masked, keeping its shape — layout replays, words do not |
| `.maskInputs` | Typed values are masked; surrounding labels stay readable |
| `.hidden` | Dropped from the replay entirely — no node, no tap target, nothing |

```swift
cardNumberField.noibuPrivacy = .mask       // this field's content never leaves the device
paymentForm.noibuPrivacy = .maskInputs     // the form's labels stay readable, the values do not
secretBanner.noibuPrivacy = .hidden        // not captured at all
```

There is no SwiftUI equivalent: a SwiftUI screen is governed by the global `privacyMode` (see the
caveat above), or by marking a `UIViewRepresentable`'s backing `UIView`.

### Diagnostic Logging

The SDK can print diagnostic logs (via `NSLog`, prefixed `NB>`, visible in the Xcode console and Console.app) to help debug an integration. Control verbosity with `logLevel`:

| Level | What it logs |
|-------|--------------|
| `.none` | Nothing |
| `.error` | Failures (send / connect / persist) |
| `.warning` | Recoverable issues (discarded data, missing assets) plus errors |
| `.info` | **Recommended for debugging** — lifecycle milestones (init, page recording, data sends, background sync) plus warnings and errors |
| `.debug` / `.verbose` | Internal Noibu diagnostics; high volume, intended for Noibu support |

```swift
let config = NoibuConfig(
    domain: "your-domain.noibu.com",
    logLevel: .info
)
```

Logging is **off by default** — leave `logLevel` unset and the SDK logs nothing. Set a level to opt in.

---

## 4. Initialization

### SwiftUI

Initialize inside the `init()` of your `@main App`:

```swift
import SwiftUI
import NoibuSessionReplay

@main
struct MyApp: App {

    init() {
        let config = NoibuConfig(
            domain: "[your domain]",
            privacyMode: .maskSensitive
        )
        Noibu.shared.initialize(configuration: config)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### UIKit

Initialize in `AppDelegate`'s `application(_:didFinishLaunchingWithOptions:)`, before the window and root view controller are set up:

```swift
import UIKit
import NoibuSessionReplay

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let config = NoibuConfig(
            domain: "[your domain]",
            privacyMode: .maskSensitive
        )
        Noibu.shared.initialize(configuration: config)
        return true
    }
}
```

> **UIKit note**: Do not initialize in `SceneDelegate.scene(_:willConnectTo:)` — that method is called after `didFinishLaunchingWithOptions` and may miss early network requests.

### Checking Initialization Status

```swift
if Noibu.shared.isInitialized {
    print("Noibu SDK is running")
}
```

---

## 5. Page Navigation

A page visit starts at each page boundary. There are two ways to produce boundaries — **choose one**:

| Mode | How | Fits |
|------|-----|------|
| Explicit (default) | Call `Noibu.shared.didNavigate(pageName:)` (or `.trackView(name:)` in SwiftUI) at each screen | SwiftUI apps, custom routers, apps that want their own page names |
| Automatic | `autoTrackNavigation: true` in `NoibuConfig` | UIKit apps with one `UIViewController` per screen |

Nothing is detected automatically in SwiftUI: a SwiftUI screen only becomes a page when you call
`didNavigate` or attach `.trackView(name:)`.

### Automatic Tracking (UIKit)

With `autoTrackNavigation: true`, the SDK hooks `UIViewController.viewDidAppear` and opens a page for
each content controller that appears:

- Container controllers (`UINavigationController`, `UITabBarController`, `UISplitViewController`,
  `UIPageViewController`, and any controller with child controllers) host a screen and are not pages.
- `UIAlertController` and system-internal controllers are not pages; only controllers defined in your
  app bundle count.
- The page name is the class name with a trailing `ViewController`, `Controller` or `VC` removed
  (`CartViewController` → `Cart`).
- A consecutive re-appearance of the same controller instance (e.g. dismissing a sheet over it) does
  not open a new page.

**Do not mix the modes.** The first explicit `didNavigate` call permanently silences automatic
tracking for the rest of the process, so a single stray call turns a fully auto-tracked app into one
with a single page. If you need custom names for some screens, use explicit tracking everywhere.

### Manual Page Tracking

Call `didNavigate()` when the user moves to a new page:

```swift
Noibu.shared.didNavigate(pageName: "ProductDetails")
Noibu.shared.didNavigate()   // boundary without a name
```

#### SwiftUI — Tab switches

```swift
// In your root view, observe tab changes
.onChange(of: selectedTab) { _, newTab in
    Noibu.shared.didNavigate(pageName: newTab.title)
}
```

#### UIKit — Tab switches

Call `didNavigate()` in the tab bar delegate, whenever the active tab changes:

```swift
func tabBar(_ tabBar: CustomTabBarView, didSelect tab: AppTab) {
    Noibu.shared.didNavigate(pageName: tab.title)
    showTab(tab)
}
```

#### UIKit — Screen pushes

Call `didNavigate()` in `viewDidLoad` or `viewWillAppear` for each view controller:

```swift
override func viewDidLoad() {
    super.viewDidLoad()
    Noibu.shared.didNavigate(pageName: "Cart")
}
```

**When to call `didNavigate(pageName:)`:**
- Tab switches that represent distinct pages
- Modal or sheet presentations
- Custom routing flows outside the standard navigation stack
- Deep link handling

**What happens:**
1. Pending replay data is flushed for the current page
2. A new full snapshot is captured
3. Replay state is reset for fresh transformation
4. A new page visit is created in analytics

---

## 6. Error Reporting

Report errors to correlate them with the current session and page visit.

### Custom Error Message

```swift
Noibu.shared.addError(message: "Payment processing failed")

Noibu.shared.addError(
    message: "Network timeout",
    stack: Thread.callStackSymbols.joined(separator: "\n")
)
```

When `stack` is omitted, the current call stack is captured. An empty `message` is ignored.

### Swift `Error`

```swift
do {
    try riskyOperation()
} catch {
    Noibu.shared.addError(error)
}
```

### `NSError`

```swift
let error = NSError(
    domain: "com.myapp.payment",
    code: 1001,
    userInfo: [NSLocalizedDescriptionKey: "Payment gateway timeout"]
)
Noibu.shared.addError(error)
```

### API Reference

| Method | Description |
|--------|-------------|
| `addError(message:stack:attributes:)` | Report a custom error message with optional stack trace |
| `addError(_:attributes:)` (Swift `Error`) | Report a caught Swift error (`localizedDescription` + current call stack) |
| `addError(_:attributes:)` (`NSError`) | Report an `NSError` (`localizedDescription` + current call stack) |

The `attributes` parameter is accepted for source compatibility but is reserved: its contents are not
sent. To attach context to a session, use [Custom Attributes](#10-custom-attributes).

> **Note**: Up to 500 errors are reported per page visit; the count resets on the next page visit.

### Uncaught Exceptions

With `trackErrors` on (the default), the SDK installs an uncaught-exception handler at `initialize`.
It reports `NSException`-based crashes (reason and call stack) and always chains to the handler that
was installed before it, so another crash reporter keeps working. Low-level signals (`SIGSEGV`,
`SIGABRT`, Swift runtime traps) are not captured.

---

## 7. Network Monitoring

The SDK captures HTTP requests and responses automatically — calling `Noibu.shared.initialize(configuration:)` registers the necessary `URLProtocol` (the same thing `NoibuHTTPInterceptor.shared.install()` does), which covers `URLSession.shared`. Sessions you build yourself need one extra line (below).

### What Is Captured

| Data | Details |
|------|---------|
| Request | HTTP method, URL, headers (sensitive ones redacted — see [Privacy & Security](#11-privacy--security)), body |
| Response | Status code, duration, headers (redacted likewise), body |
| Bodies | Captured for JSON, `text/*`, form-urlencoded and XML content types, up to 64 KB (a larger body is recorded as `[Body too large]`). Values under sensitive JSON keys (`password`, `cardNumber`, …) and card / email / SSN / phone patterns are scrubbed before the body leaves the device. |
| Errors | Transport failures, HTTP error statuses, and GraphQL errors — a `200 OK` whose JSON body carries an `errors` array is reported as an error too |

### Custom `URLSession` Instances

Requests made through `URLSession.shared` are observed automatically. A `URLSession` created from its own configuration consults only that configuration's `protocolClasses`, so instrument it explicitly:

```swift
import NoibuSessionReplay

let config = URLSessionConfiguration.default
NoibuHTTPInterceptor.shared.installNetworkInstrumentation(on: config)
let session = URLSession(configuration: config)
```

Order doesn't matter — a session built before `Noibu.shared.initialize(configuration:)` is still
captured once init lands, and nothing is captured when `trackNetwork` is off.

---

## 8. WebView Support

The SDK captures session replay data from `WKWebView` instances, rendering web content as part of the same mobile session recording. No setup is required on the web page itself.

### Setup

Call `NoibuWebViewTracking.enable(_:)` **after** creating the `WKWebView` and **before** loading any URL.

### SwiftUI

Wrap the `WKWebView` in a `UIViewRepresentable`. Call `enable` inside `makeUIView`, before returning the view — never in `updateUIView`, which is called on every re-render:

```swift
import SwiftUI
import WebKit
import NoibuSessionReplay

struct NoibuWebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        NoibuWebViewTracking.enable(webView)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        webView.load(URLRequest(url: url))
    }
}
```

### UIKit

Create the `WKWebView`, call `enable`, then load the URL. The order matters — loading before calling `enable` will miss the initial page:

```swift
import WebKit
import NoibuSessionReplay

class WebViewController: UIViewController, WKNavigationDelegate {

    private var webView: WKWebView!

    override func viewDidLoad() {
        super.viewDidLoad()

        webView = WKWebView()
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false

        // Enable tracking BEFORE loading any URL
        NoibuWebViewTracking.enable(webView)

        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        // Load AFTER enable
        if let url = URL(string: "https://example.com") {
            webView.load(URLRequest(url: url))
        }
    }
}
```

### Disabling

```swift
NoibuWebViewTracking.disable(webView)
```

### Important Notes

- Call `enable(_:)` **before** loading any URL — late attachment will miss the initial page load.
- Initialize the SDK at launch (see [Initialization](#4-initialization)) so it is running by the time a webview is created; with `trackWebViews: false`, `enable` is a no-op.
- **UIKit**: do not call `enable` in `viewWillAppear` or `viewDidAppear` — by that point the WebView may have already started loading. Always call it in `viewDidLoad` right after creating the `WKWebView`.
- Each `WKWebView` instance is tracked independently.
- The page follows the configured `privacyMode`: under `.maskSensitive` (default) every input value is masked and a click on a field reports its label rather than its contents; `.maskAll` masks all page text as well; `.allowAll` records the page verbatim, typed values included.

---

## 9. View Tagging

View tagging names the screens that appear in the replay timeline.

### SwiftUI

`.trackView(name:)` calls `didNavigate(pageName:)` when the view appears — attach it to each screen's
root view:

```swift
var body: some View {
    VStack { ... }
        .trackView(name: "ProductDetails")
}
```

### UIKit

`trackView` is a SwiftUI modifier. In UIKit, either enable `autoTrackNavigation` or call
`didNavigate(pageName:)` in `viewDidLoad` (see [Page Navigation](#5-page-navigation)):

```swift
override func viewDidLoad() {
    super.viewDidLoad()
    Noibu.shared.didNavigate(pageName: "ProductDetails")
}
```

### Taps

Taps and scrolls are captured natively for every element when `trackTouches` is on — nothing to tag.
`.trackTapAction(name:)` (SwiftUI), `Noibu.shared.trackTapAction(name:)` and
`UIControl.noibuTrackTapAction(name:)` (UIKit) still compile for source compatibility but do nothing;
remove them from your code at your convenience.

### Naming Best Practices

- Use clear, descriptive names focused on user intent (`"ProductDetails"`, not `"VC2"`).
- Stay consistent across platforms — use the same names in UIKit as you would in SwiftUI.
- Avoid including personal or sensitive data in page names.

---

## 10. Custom Attributes

Add metadata to sessions for filtering and analysis in the Noibu dashboard. Attributes are session-scoped and describe context that changes infrequently (feature flags, A/B variants, environment, build metadata, etc.).

### Adding Attributes

```swift
Noibu.shared.addCustomAttribute(name: "customerId", value: "12345")
Noibu.shared.addCustomAttribute(name: "orderId", value: "ORD-98765")
Noibu.shared.addCustomAttribute(name: "appVersion", value: "2.1.0")
```

### Validation Rules

| Rule | Limit |
|------|-------|
| Maximum attributes per session | 10 |
| Attribute name length | 1–50 characters |
| Attribute value length | 1–50 characters |
| Duplicate names | Not allowed |

The limits are enforced silently: an attribute that breaks a rule is dropped without feedback, so
keep names and values within the table above.

### Return Value

`addCustomAttribute` returns `false` only when the SDK is not initialized yet; a `true` means the
attribute was accepted for validation, not that it passed.

```swift
if !Noibu.shared.addCustomAttribute(name: "customerId", value: customerId) {
    print("Noibu is not initialized — call initialize(configuration:) first")
}
```

---

## 10b. Tracking Events

`track(name:data:)` reports ecommerce and custom events — the counterpart of NoibuJS's
`track(name, payload)`. Events appear on the session's timeline and in Explorations.

```swift
// A standard ecommerce event: the payload follows the shared ecommerce schema.
Noibu.shared.track(name: "product_added_to_cart", data: [
    "cartLine": [
        "quantity": 1,
        "merchandise": ["id": "sku-42", "title": "Running Shoes",
                        "price": ["amount": 89.99, "currencyCode": "USD"]],
    ],
])

// A custom event: any name, any JSON object.
let result = Noibu.shared.track(name: "promo_banner_dismissed", data: ["campaign": "summer"])
if !result.success { print(result.errors) }

// Already-serialized JSON goes through track(name:dataJson:).
Noibu.shared.track(name: "cart_viewed", dataJson: cartJsonString)
```

| Rule | Limit |
|------|-------|
| Event name length | ≤ 500 characters |
| Payload | a JSON object (`JSONSerialization.isValidJSONObject`) or `nil`, ≤ 10,000 characters serialized |
| Standard payloads | checked against the ecommerce schema; unknown properties dropped, wrong types rejected |
| Events per page visit | 500 |

Nothing is thrown. `NoibuTrackResult.success` is `false` when the event was rejected and `errors`
lists why, in the same words as the web SDK. Two messages have constants: a payload
`JSONSerialization` cannot encode answers `NoibuTrackResult.notSerializable`, and a `track` before
`initialize` answers `NoibuTrackResult.notInitialized`.

`track` can be called from any thread. An event tracked as a screen appears — for example right
after `didNavigate` — is ordered behind that boundary and lands on the new screen's page visit.

### Standard ecommerce events

A standard event's payload is validated against the shared ecommerce schema: every field is
optional, unknown properties are dropped, and a type mismatch is reported in `errors` and the event
is not sent. Any other event name is a custom event and only has to be a JSON object.

Shared shapes: `Money` is `["amount": 89.99, "currencyCode": "USD"]`. A `productVariant` is
`[id, sku, title, price: Money, product: [id, title, type, url, vendor]]`. A `cartLine` is
`[quantity, merchandise: productVariant, cost: [totalAmount: Money]]`.

| Event name | Payload key | Payload |
|---|---|---|
| `product_viewed` | `productVariant` | a product variant |
| `product_added_to_cart`, `product_removed_from_cart` | `cartLine` | a cart line |
| `cart_viewed` | `cart` | `[id, totalQuantity, lines: [cartLine], cost: [totalAmount: Money]]` |
| `collection_viewed` | `collection` | `[id, title, productVariants: [productVariant]]` |
| `search_submitted` | `searchResult` | `[query, productVariants: [productVariant]]` |
| `checkout_started`, `checkout_address_info_submitted`, `checkout_contact_info_submitted`, `checkout_shipping_info_submitted`, `payment_info_submitted`, `checkout_completed` | `checkout` | `[token, currencyCode, subtotalPrice, totalTax, totalPrice, lineItems: [[id, title, quantity, variant: productVariant, finalLinePrice]], shippingLine: [price], discountApplications, order: [id, customer: [id, isFirstOrder]], transactions]` |

---

## 11. Privacy & Security

### Privacy Mode Selection

```swift
privacyMode: .maskSensitive  // card / SSN / email / phone spans redacted in displayed text — default
privacyMode: .maskAll        // no readable text at all — only word/length shape survives
privacyMode: .allowAll       // displayed text verbatim
```

Independent of the mode: secure text fields record `***`, captured HTTP bodies are PII-scrubbed (see
[Network Monitoring](#7-network-monitoring)), and these request/response headers are recorded as
`[REDACTED]` (matched case-insensitively):

`authorization`, `proxy-authorization`, `cookie`, `set-cookie`, `x-auth-token`, `x-api-key`,
`x-forwarded-for`, `forwarded`, `x-real-ip`, `from`, `content-md5`, `x-device-id`, `x-request-id`,
`x-user-id`, `x-uidh`.

### Data Storage

- Session data is streamed to Noibu's servers.
- Local data is buffered temporarily in the app's caches directory.
- Data is cleared automatically after successful upload.

---

## 12. Lifecycle Management

The SDK is intended to run for the lifetime of the app process. Call `Noibu.shared.initialize(configuration:)` exactly once during app launch — subsequent calls are no-ops. The SDK persists across foreground/background transitions.

### Sessions

A session starts when the SDK initializes. If the app stays in the background for 15 minutes or
more, a new session starts when it returns to the foreground; a shorter background stay continues
the same session.

### Shutdown

To completely stop the SDK (e.g. the user revokes consent):

```swift
Noibu.shared.shutdown()
```

This will:
- Stop all capture (replay, taps, keyboard, network, webviews)
- Flush pending data
- Stop the lifecycle, session and clock monitors

The tap and auto-navigation hooks and the uncaught-exception handler stay installed (they cannot be
removed safely once in place) but go inert: everything they observe is dropped while the SDK is not
initialized.

`initialize(configuration:)` is accepted again afterwards, so consent can be granted later in the same app run.

---

## 13. Background Sync

The SDK sends captured data continuously while the app is in the foreground and flushes any pending data when the app moves to the background. To let the system deliver the **last events captured at the moment of backgrounding** after the app is suspended or terminated, enable a background processing task.

This is optional. Without it, data still flushes during the short window iOS grants on backgrounding, and any remainder is sent on the next launch. Enabling it lets the remainder be delivered sooner, while the app is suspended.

### Required `Info.plist` keys

```xml
<key>UIBackgroundModes</key>
<array>
    <string>processing</string>
</array>
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>com.noibu.sessionreplay.process</string>
</array>
```

The identifier must be exactly `com.noibu.sessionreplay.process` — the SDK registers and schedules the task for you. No extra code is needed beyond calling `Noibu.shared.initialize(configuration:)` at launch (see [Initialization](#4-initialization)); the SDK registers the task during initialization, which must complete before launch finishes.

> **Note**: iOS runs background processing tasks opportunistically — typically when the device is idle and on power — so delivery after suspension can be delayed by the system. Foreground sending and the on-background flush are unaffected.

### Verifying

Background tasks don't fire on demand. To force a run while debugging on a **physical device**, background the app, pause in Xcode, and run in the LLDB console:

```
e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.noibu.sessionreplay.process"]
```

Resume the app — the SDK drains and sends any pending data. (The Simulator does not reliably run background tasks; test on a device.)

---

## SwiftUI vs UIKit — Quick Reference

| Feature | SwiftUI | UIKit |
|---------|---------|-------|
| Initialization | `App.init()` | `AppDelegate.application(_:didFinishLaunchingWithOptions:)` |
| Screen tracking | `.trackView(name:)` modifier | `Noibu.shared.didNavigate(pageName:)` in `viewDidLoad`, or `autoTrackNavigation: true` |
| Tap tracking | Automatic (`trackTouches`) | Automatic (`trackTouches`) |
| Tab switches | `.onChange(of: selectedTab)` → `didNavigate` | Tab bar delegate → `didNavigate` (or automatic) |
| WebView tracking | `NoibuWebViewTracking.enable` in `makeUIView` | `NoibuWebViewTracking.enable` in `viewDidLoad`, before `load` |
| Per-view privacy | Global `privacyMode` only | `view.noibuPrivacy = .mask / .maskInputs / .hidden` |
| Automatic screen detection | — (use `.trackView`) | `autoTrackNavigation: true`; never mix with explicit `didNavigate` |

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| No recordings appearing | Verify `domain` is correct and reachable from the device |
| Need detail when debugging an integration | Set `logLevel: .info` in `NoibuConfig`, then filter the Xcode console / Console.app for `NB>` (see [Diagnostic Logging](#diagnostic-logging)) |
| WebView content not in replay | Ensure `NoibuWebViewTracking.enable(_:)` is called **before** loading any URL. In UIKit, call it in `viewDidLoad` right after creating the `WKWebView`. |
| Taps not tracked | Check `trackTouches` is not `false`. `trackTapAction` calls are no-ops; taps are captured natively. |
| UIKit: screen names missing | Call `didNavigate(pageName:)` in `viewDidLoad` for each `UIViewController`, or set `autoTrackNavigation: true`. |
| `autoTrackNavigation` stopped splitting pages | An explicit `didNavigate` (including `.trackView`) silences automatic tracking for the rest of the process — remove the explicit calls or track every screen explicitly. |
| `pod install` can't find spec | Run `pod install --repo-update` |
| Build error after CocoaPods | Open `.xcworkspace`, not `.xcodeproj` |
| Network requests not captured | Call `NoibuHTTPInterceptor.shared.installNetworkInstrumentation(on:)` on custom `URLSession` configurations |
| Errors not appearing | Verify `addError(...)` is called after `initialize(configuration:)` |
| Last events before backgrounding delayed/missing | Add the [Background Sync](#13-background-sync) `Info.plist` keys, and ensure `initialize` runs at launch so the task can register in time |
| SPM does not offer the version | Rules like **Up to Next Major** skip pre-release tags; use **Exact Version** for a `-rc` build. Stable releases such as `1.1.2` resolve with any rule. |
| Link error mentioning `Kronos` | Let SPM / CocoaPods resolve the SDK's `Kronos` dependency (`pod install --repo-update`, or File → Packages → Resolve Package Versions) |

---

## Support

Need help? Contact your Noibu solutions engineer with:
- SDK version
- iOS version and device type
- SwiftUI or UIKit
- Xcode version
- Initialization code snippet
- Console log output