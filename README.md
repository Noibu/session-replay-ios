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

---

## 1. Requirements

- **Minimum iOS**: 14.0
- **Swift**: 5.9+
- **Xcode**: 15.0+
- **Dependency manager**: Swift Package Manager **or** CocoaPods

---

## 2. Installation

The SDK is distributed as a self-contained binary XCFramework that statically bundles all of its internal dependencies — no additional packages or pods are required.

### Swift Package Manager (Xcode UI)

1. In Xcode, go to **File → Add Package Dependencies…**
2. Enter the package URL: `https://github.com/Noibu/session-replay-ios.git`
3. Choose **Exact Version** and select `[last version]` (pre-release versions require `Exact Version`).
4. Add the package to your app target.

### Swift Package Manager (`Package.swift`)

```swift
dependencies: [
    .package(
        url: "https://github.com/Noibu/session-replay-ios.git",
        exact: "[last sdk version]"
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
use_frameworks!

target 'YourApp' do
  pod 'NoibuSessionReplay', '[last version]'
end
```

Then install and open the generated workspace:

```bash
pod install --repo-update
open YourApp.xcworkspace
```

> Always open `.xcworkspace`, not `.xcodeproj`, when using CocoaPods.

---

## 3. Configuration

### NoibuConfig

The SDK is configured via `NoibuConfig`. Parameters:

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `domain` | `String` | **Yes** | - | Your Noibu domain endpoint (provided by Noibu) |
| `environment` | `String` | No | `"test"` | Label to separate environments. _Reserved — not yet applied to the recording pipeline._ |
| `sampleRate` | `Double` | No | `100.0` | Percentage of sessions to capture (0–100). _Reserved — current builds capture every session regardless of value._ |
| `privacyMode` | `NoibuPrivacyMode` | No | `.maskSensitive` | Privacy level for session recording. _Reserved — current builds use `.maskSensitive` regardless of value._ |
| `firstPartyHosts` | `[String]` | No | `[]` | Hostnames intended for first-party network classification. _Reserved — currently unused._ |

> **Note**: Only `domain` affects current behavior. The other parameters are part of the API surface for forward compatibility and will become functional in upcoming releases.

### Privacy Modes

| Mode | Description |
|------|-------------|
| `.allowAll` | All content is visible in recordings |
| `.maskSensitive` | Masks passwords, credit card fields, and other sensitive inputs (default) |
| `.maskAll` | Masks all text content |

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
            sampleRate: 100.0,
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

---

## 7. Network Monitoring

The SDK captures HTTP request and response metadata automatically — calling `Noibu.shared.initialize(configuration:)` registers the necessary `URLProtocol` with no additional setup.

### What Is Captured

| Data | Details |
|------|---------|
| Request metadata | HTTP method, URL |
| Response metadata | Status code, duration |
| Errors | Network failures and exceptions |

### Custom `URLSession` Instances

Requests made through `URLSession.shared` are observed automatically. For custom `URLSession` instances that override `protocolClasses`:

```swift
import NoibuSessionReplay

let config = URLSessionConfiguration.default
config.protocolClasses = [NoibuURLProtocol.self] + (config.protocolClasses ?? [])
let session = URLSession(configuration: config)
```

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
privacyMode: .maskSensitive  // General apps (default)
privacyMode: .maskAll        // Highly sensitive data
privacyMode: .allowAll       // Internal/debug builds only
```

### Data Storage

- Session data is streamed to Noibu's servers.
- Local data is buffered temporarily in the app's caches directory.
- Data is cleared automatically after successful upload.

---

## 12. Lifecycle Management

The SDK is intended to run for the lifetime of the app process. Call `Noibu.shared.initialize(configuration:)` exactly once during app launch — subsequent calls are no-ops. The SDK persists across foreground/background transitions and stops only when the app process terminates.

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
| WebView content not in replay | Ensure `NoibuWebViewTracking.enable(_:)` is called **before** loading any URL. In UIKit, call it in `viewDidLoad` right after creating the `WKWebView`. |
| UIKit: tap actions not tracked | `trackTapAction` is SwiftUI-only. Use `addCustomAttribute(name: "tap.action", value:)` instead. |
| UIKit: screen names missing | Call `didNavigate(pageName:)` in `viewDidLoad` for each `UIViewController`. |
| `pod install` can't find spec | Run `pod install --repo-update` |
| Build error after CocoaPods | Open `.xcworkspace`, not `.xcodeproj` |
| Network requests not captured | Ensure custom `URLSession` instances include `NoibuURLProtocol` in `protocolClasses` |
| Errors not appearing | Verify `addError(...)` is called after `initialize(configuration:)` |
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
