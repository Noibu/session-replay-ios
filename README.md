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
use_frameworks!

target 'YourApp' do
  pod 'NoibuSessionReplay', '~> 0.1.0-rc.1'
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

> **Note**: Only `domain` affects current behavior. The other parameters are part of the API surface for forward compatibility and will become functional in upcoming releases. Set them now if you'd like; they'll start being honored without a code change once support lands.

### Privacy Modes

| Mode | Description |
|------|-------------|
| `.allowAll` | All content is visible in recordings |
| `.maskSensitive` | Masks passwords, credit card fields, and other sensitive inputs (default) |
| `.maskAll` | Masks all text content |

---

## 4. Initialization

### Basic Setup

Initialize the SDK as early as possible in your app's lifecycle. For SwiftUI apps, do this inside the `init()` of your `@main App`:

```swift
import SwiftUI
import NoibuSessionReplay

@main
struct MyApp: App {

    init() {
        let config = NoibuConfig(
            domain: "https://mobile.native.noibu.com",
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

### UIKit Setup

For UIKit apps, initialize in your `AppDelegate`'s `application(_:didFinishLaunchingWithOptions:)`:

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
            domain: "https://mobile.native.noibu.com"
        )

        Noibu.shared.initialize(configuration: config)
        return true
    }
}
```

### Checking Initialization Status

```swift
if Noibu.shared.isInitialized {
    print("Noibu SDK is running")
}
```

---

## 5. Page Navigation

### Automatic Tracking

For SwiftUI apps, screen transitions and navigation events are captured automatically. UIKit screen transitions tied to `UIViewController` lifecycle are also tracked automatically.

### Manual Page Tracking

For custom navigation flows, modals, tab switches, or deep links, call `didNavigate()` when the user moves to a new page:

```swift
// With a page name
Noibu.shared.didNavigate(pageName: "ProductDetails")

// Without a page name (uses default)
Noibu.shared.didNavigate()
```

**When to call `didNavigate(pageName:)`:**
- Tab switches that represent distinct pages
- Modal or sheet presentations that should be treated as separate pages
- Custom routing flows that don't go through a standard navigation stack
- Deep link handling

**What happens:**
1. Pending replay data is flushed for the current page
2. A new full snapshot is captured
3. Replay state is reset for fresh transformation
4. A new page visit is created in analytics

---

## 6. Error Reporting

Report errors to Noibu to correlate them with the current session and page visit. Three overloads are supported.

### Custom Error Message

```swift
Noibu.shared.addError(
    message: "Payment processing failed"
)

Noibu.shared.addError(
    message: "Network timeout",
    stack: Thread.callStackSymbols.joined(separator: "\n"),
    attributes: [
        "screen": "Checkout",
        "request_type": "POST"
    ]
)
```

### Swift `Error`

```swift
do {
    try riskyOperation()
} catch {
    Noibu.shared.addError(
        error,
        attributes: ["screen": "Home"]
    )
}
```

### `NSError`

```swift
let error = NSError(
    domain: "com.myapp.payment",
    code: 1001,
    userInfo: [NSLocalizedDescriptionKey: "Payment gateway timeout"]
)

Noibu.shared.addError(
    error,
    attributes: ["screen": "Checkout"]
)
```

### API Reference

| Method | Description |
|--------|-------------|
| `addError(message:stack:attributes:)` | Report a custom error message with an optional stack trace |
| `addError(_:attributes:)` (Swift `Error`) | Report a caught Swift error |
| `addError(_:attributes:)` (`NSError`) | Report an `NSError` |

---

## 7. Network Monitoring

The SDK captures HTTP request and response metadata automatically. There is **no setup step** — calling `Noibu.shared.initialize(configuration:)` registers the necessary `URLProtocol` and enables Datadog's URLSession tracking for you.

### What Is Captured

| Data | Details |
|------|---------|
| Request metadata | HTTP method, URL |
| Response metadata | Status code, duration |
| Errors | Network failures and exceptions |

### Custom `URLSession` Instances

Requests made through `URLSession.shared` are observed automatically. For custom `URLSession` instances that override `protocolClasses`, you must include `NoibuURLProtocol` explicitly:

```swift
import NoibuSessionReplay

let config = URLSessionConfiguration.default
config.protocolClasses = [NoibuURLProtocol.self] + (config.protocolClasses ?? [])
let session = URLSession(configuration: config)
```

### Manually Re-installing

If you need to force re-registration of the URLProtocol (rare — typically only needed if another library deregisters it), call:

```swift
NoibuHTTPInterceptor.shared.install()
```

This is normally unnecessary because the SDK calls it during `initialize(configuration:)`.

---

## 8. WebView Support

The SDK can capture session replay data from WKWebViews, rendering web content as part of the same mobile session recording. The SDK injects a DOM recorder into the WebView — no setup is required on the web page itself.

### Setup

Call `NoibuWebViewTracking.enable(_:)` after creating your `WKWebView` and **before** loading any URL:

```swift
import WebKit
import NoibuSessionReplay

let webView = WKWebView()
NoibuWebViewTracking.enable(webView)
webView.load(URLRequest(url: URL(string: "https://example.com")!))
```

### SwiftUI

Wrap the WKWebView in a `UIViewRepresentable`:

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

### Disabling

To stop tracking a specific WebView:

```swift
NoibuWebViewTracking.disable(webView)
```

### Important Notes

- Call `enable(_:)` **before** loading any URL — late attachment will miss the initial page load.
- Call `enable(_:)` **after** `Noibu.shared.initialize(...)` — the SDK must already be running.
- Each WebView instance is tracked independently, so multiple WebViews on the same screen are recorded with distinct identities.

---

## 9. View Tagging

For SwiftUI apps, two view modifiers let you label important screens and actions in the replay timeline.

### Tracking Screens

```swift
import NoibuSessionReplay

var body: some View {
    VStack {
        Text("Hello World")
    }
    .trackView(name: "ContentView")
}
```

### Tracking User Actions

```swift
Button(action: {
    withAnimation { showContent.toggle() }
}) {
    Text(showContent ? "Hide content" : "Show content")
}
.trackTapAction(name: "ToggleContentButton")
```

### Naming Best Practices

- Use clear, descriptive names focused on user intent (`"AddToCart"`, not `"Button123"`).
- Stay consistent across similar interactions.
- Avoid including personal or sensitive data in tag names.

---

## 10. Custom Attributes

Add metadata to sessions for filtering and analysis in the Noibu dashboard. Attributes are session-scoped and should describe context that changes infrequently (feature flags, A/B variants, environment, build metadata, etc.).

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

The method returns `true` on success and `false` if the attribute was rejected (limit hit, invalid input, duplicate, SDK not initialized).

### Example with Result Check

```swift
if !Noibu.shared.addCustomAttribute(name: "customerId", value: customerId) {
    print("Failed to attach customerId attribute to session")
}
```

---

## 11. Privacy & Security

### Privacy Mode Selection

Choose the privacy mode based on your app's data sensitivity:

```swift
// General apps — masks only sensitive fields (default)
privacyMode: .maskSensitive

// Apps handling highly sensitive data
privacyMode: .maskAll

// Internal/debug builds only
privacyMode: .allowAll
```

### Data Storage

- Session data is streamed to Noibu's servers.
- Local data is buffered temporarily in the app's caches directory.
- Data is cleared automatically after successful upload.

---

## 12. Lifecycle Management

### One-Shot Initialization

The SDK is intended to run for the lifetime of the app process. Call `Noibu.shared.initialize(configuration:)` exactly once during app launch — subsequent calls are no-ops if the SDK is already configured. The SDK persists across foreground/background transitions and stops only when the app process terminates.

The current build does not expose a public `shutdown()` method.

---

## Troubleshooting

### Verify Installation

Check the Xcode console for SDK initialization log lines:

```
filter your device log by: "Noibu"
```

### Common Issues

| Issue | Solution |
|-------|----------|
| No recordings appearing | Verify `domain` is correct and reachable from the device |
| `pod install` can't find spec | Run `pod install --repo-update`, or clear cache with `rm -rf ~/Library/Caches/CocoaPods` |
| Build error after CocoaPods install | Open `.xcworkspace`, not `.xcodeproj` |
| Network requests not captured | Ensure `NoibuHTTPInterceptor.shared.install()` is called and the `URLSession` does not exclude default protocols |
| WebView content not in replay | Ensure `NoibuWebViewTracking.enable(_:)` is called **before** loading any URL |
| Errors not appearing | Verify `addError(...)` is called after `initialize(configuration:)` |
| Pre-release version not resolvable via SPM | SPM requires `exact:` for pre-release versions; `from:` won't match them |

---

## Support

Need help? Contact your Noibu solutions engineer with:
- SDK version
- iOS version
- Xcode version
- Initialization code snippet
- Console log output
