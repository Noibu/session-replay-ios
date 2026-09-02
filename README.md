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

- **Minimum iOS**: 16.0
- **Swift**: 5.9+
- **Xcode**: 15.0+
- **Dependency manager**: Swift Package Manager **or** CocoaPods

---

## 2. Installation

The SDK is distributed as a self-contained binary XCFramework that statically bundles all of its internal dependencies — no additional packages or pods are required.

### Swift Package Manager (Xcode UI)

1. In Xcode, go to **File → Add Package Dependencies…**
2. Enter the package URL: `https://github.com/Noibu/session-replay-ios.git`
3. Choose **Exact Version** and select `0.1.0-rc.1` (pre-release versions require `Exact Version`).
4. Add the package to your app target.

### Swift Package Manager (`Package.swift`)

```swift
dependencies: [
    .package(
        url: "https://github.com/Noibu/session-replay-ios.git",
        exact: "0.1.0-rc.1"
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
platform :ios, '16.0'

target 'YourApp' do
  pod 'NoibuSessionReplay', '~> 1.0.0-rc.2'
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
| `autoTrackNavigation` | `Bool` | No | `false` | Derive page boundaries from `viewDidAppear` instead of explicit `didNavigate` calls |
| `trackErrors` | `Bool` | No | `true` | Capture uncaught exceptions (chains to existing handlers) |

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

### Automatic Tracking

- **SwiftUI**: screen transitions and navigation events are captured automatically.
- **UIKit**: `UIViewController` lifecycle events are also tracked automatically. However, for tab switches, modals, and custom navigation flows, you should call `didNavigate()` manually to ensure clean page splits in the session replay.

### Manual Page Tracking

Call `didNavigate()` when the user moves to a new page:

```swift
Noibu.shared.didNavigate(pageName: "ProductDetails")
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
    stack: Thread.callStackSymbols.joined(separator: "\n"),
    attributes: ["screen": "Checkout", "request_type": "POST"]
)
```

### Swift `Error`

```swift
do {
    try riskyOperation()
} catch {
    Noibu.shared.addError(error, attributes: ["screen": "Home"])
}
```

### `NSError`

```swift
let error = NSError(
    domain: "com.myapp.payment",
    code: 1001,
    userInfo: [NSLocalizedDescriptionKey: "Payment gateway timeout"]
)
Noibu.shared.addError(error, attributes: ["screen": "Checkout"])
```

### API Reference

| Method | Description |
|--------|-------------|
| `addError(message:stack:attributes:)` | Report a custom error message with optional stack trace |
| `addError(_:attributes:)` (Swift `Error`) | Report a caught Swift error |
| `addError(_:attributes:)` (`NSError`) | Report an `NSError` |

> **Note**: Up to 500 errors are reported per page visit; the count resets on the next page visit.

---

## 7. Network Monitoring

The SDK captures HTTP request and response metadata automatically — calling `Noibu.shared.initialize(configuration:)` registers the necessary `URLProtocol`, which covers `URLSession.shared`. Sessions you build yourself need one extra line (below).

### What Is Captured

| Data | Details |
|------|---------|
| Request metadata | HTTP method, URL |
| Response metadata | Status code, duration |
| Errors | Network failures and exceptions |

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
- Call `enable(_:)` **after** `Noibu.shared.initialize(...)` — the SDK must already be running.
- **UIKit**: do not call `enable` in `viewWillAppear` or `viewDidAppear` — by that point the WebView may have already started loading. Always call it in `viewDidLoad` right after creating the `WKWebView`.
- Each `WKWebView` instance is tracked independently.
- Input values in the page are masked in replay, and a click on a field reports its label rather than its contents — the same rule the native view walker applies to a text field.

---

## 9. View Tagging

View tagging lets you label screens and user actions in the replay timeline.

### SwiftUI

Two view modifiers are available:

```swift
// Tag a screen
var body: some View {
    VStack { ... }
        .trackView(name: "ProductDetails")
}

// Tag a tap action
Button("Add to Cart") {
    cartStore.add(product)
}
.trackTapAction(name: "AddToCart")
```

### UIKit

`trackView` and `trackTapAction` are SwiftUI-only view modifiers and are **not available in UIKit**. Use the following alternatives:

**Screen tracking** — call `didNavigate(pageName:)` in `viewDidLoad`:

```swift
override func viewDidLoad() {
    super.viewDidLoad()
    Noibu.shared.didNavigate(pageName: "ProductDetails")
}
```

**Action tracking** — use `addCustomAttribute` to record meaningful tap events:

```swift
@objc private func addToCartTapped() {
    Noibu.shared.addCustomAttribute(name: "tap.action", value: "AddToCart")
    cartStore.add(product)
}
```

> The 10-attribute-per-session limit applies. Use `addCustomAttribute` for the most significant interactions rather than every tap.

### Naming Best Practices

- Use clear, descriptive names focused on user intent (`"AddToCart"`, not `"Button123"`).
- Stay consistent across platforms — use the same names in UIKit as you would in SwiftUI.
- Avoid including personal or sensitive data in tag names.

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

### Example with Result Check

```swift
if !Noibu.shared.addCustomAttribute(name: "customerId", value: customerId) {
    print("Failed to attach customerId attribute to session")
}
```

---

## 11. Privacy & Security

### Privacy Mode Selection

```swift
privacyMode: .maskSensitive  // card / SSN / email / phone spans redacted in displayed text — default
privacyMode: .maskAll        // no readable text at all — only word/length shape survives
privacyMode: .allowAll       // displayed text verbatim
```

Independent of the mode: secure text fields record `***`, and the sensitive HTTP headers
`authorization`, `cookie`, `set-cookie` and `x-api-key` are redacted to `***`.

### Data Storage

- Session data is streamed to Noibu's servers.
- Local data is buffered temporarily in the app's caches directory.
- Data is cleared automatically after successful upload.

---

## 12. Lifecycle Management

The SDK is intended to run for the lifetime of the app process. Call `Noibu.shared.initialize(configuration:)` exactly once during app launch — subsequent calls are no-ops. The SDK persists across foreground/background transitions.

### Shutdown

To completely stop the SDK (e.g. the user revokes consent):

```swift
Noibu.shared.shutdown()
```

This will:
- Stop all capture (replay, taps, keyboard, network, webviews)
- Flush pending data
- Remove lifecycle observers

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
| Screen tracking | `.trackView(name:)` modifier | `Noibu.shared.didNavigate(pageName:)` in `viewDidLoad` |
| Tap tracking | `.trackTapAction(name:)` modifier | `Noibu.shared.addCustomAttribute(name: "tap.action", value:)` |
| Tab switches | `.onChange(of: selectedTab)` | Tab bar delegate → `didNavigate` |
| WebView tracking | `NoibuWebViewTracking.enable` in `makeUIView` | `NoibuWebViewTracking.enable` in `viewDidLoad`, before `load` |
| Automatic VC tracking | ✅ | ✅ (partial — manual `didNavigate` recommended for tabs and modals) |

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| No recordings appearing | Verify `domain` is correct and reachable from the device |
| Need detail when debugging an integration | Set `logLevel: .info` in `NoibuConfig`, then filter the Xcode console / Console.app for `NB>` (see [Diagnostic Logging](#diagnostic-logging)) |
| WebView content not in replay | Ensure `NoibuWebViewTracking.enable(_:)` is called **before** loading any URL. In UIKit, call it in `viewDidLoad` right after creating the `WKWebView`. |
| UIKit: tap actions not tracked | `trackTapAction` is SwiftUI-only. Use `addCustomAttribute(name: "tap.action", value:)` instead. |
| UIKit: screen names missing | Call `didNavigate(pageName:)` in `viewDidLoad` for each `UIViewController`. |
| `pod install` can't find spec | Run `pod install --repo-update` |
| Build error after CocoaPods | Open `.xcworkspace`, not `.xcodeproj` |
| Network requests not captured | Call `NoibuHTTPInterceptor.shared.installNetworkInstrumentation(on:)` on custom `URLSession` configurations |
| Errors not appearing | Verify `addError(...)` is called after `initialize(configuration:)` |
| Last events before backgrounding delayed/missing | Add the [Background Sync](#13-background-sync) `Info.plist` keys, and ensure `initialize` runs at launch so the task can register in time |
| Pre-release version not resolvable | SPM requires `exact:` for pre-release versions |

---

## Support

Need help? Contact your Noibu solutions engineer with:
- SDK version
- iOS version and device type
- SwiftUI or UIKit
- Xcode version
- Initialization code snippet
- Console log output