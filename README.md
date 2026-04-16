# Noibu iOS SDK Guide (SwiftUI)

## Table of Contents

- [1. Requirements](#1-requirements)
- [2. Installation](#2-installation)
- [3. Configuration](#3-configuration)
- [4. Initialization](#4-initialization)
- [5. Session Replay & User Interactions](#5-session-replay--user-interactions)
- [6. Page Navigation](#6-page-navigation)
- [7. Error Reporting](#7-error-reporting)
- [8. Network Monitoring](#8-network-monitoring)
- [9. WebView Support](#9-webview-support)
- [10. Custom Attributes](#10-custom-attributes)
- [11. Privacy & Security](#11-privacy--security)
- [12. Lifecycle Management](#12-lifecycle-management)

---

## 1. Requirements

- **Minimum iOS**: 16.0
- **Xcode**: 15.0+
- **Swift**: 5.9+

---

## 2. Installation

### 2.1 Adding the SDK via Swift Package Manager (Xcode UI)

1. Open your project in Xcode.
2. In the menu bar, go to **File → Add Package Dependencies…**
3. In the search field, paste the Noibu SDK URL:
   ```
   https://github.com/Noibu/session-replay-ios.git
   ```
4. Click **Add**. Xcode will resolve the package and show available versions.
5. Under **Dependency Rule**, choose one of:
   - **Up to Next Major Version** (recommended)
   - **Exact Version** (if you need strict reproducibility)
6. Select the latest stable version of the SDK.
7. In **Add to Project**, select your app target.
8. Click **Add Package**.

### 2.2 Package.swift Integration (Manual)

Add the Noibu SDK to the `dependencies` section:

```swift
dependencies: [
    .package(
        url: "https://github.com/Noibu/session-replay-ios.git",
        from: "<latest-stable-version>"
    )
]
```

Reference the Noibu product inside your target:

```swift
.target(
    name: "MyApp",
    dependencies: [
        .product(name: "NoibuSessionReplay", package: "session-replay-ios")
    ]
)
```

Then run:

```bash
swift package update
swift package resolve
```

### 2.3 Updating the SDK

**Via Xcode:**
1. Select your project in the Project Navigator.
2. Go to the **Package Dependencies** tab.
3. Locate `NoibuSessionReplay` and update the version.

**Via Package.swift:**

```swift
.package(
    url: "https://github.com/Noibu/session-replay-ios.git",
    from: "<latest-stable-version>"
)
```

Then run:

```bash
swift package update
swift package resolve
```

### 2.4 Removing the SDK

**Via Xcode:**
1. Select your project in the Project Navigator.
2. Open the **Package Dependencies** tab.
3. Right-click `NoibuSessionReplay` and select **Remove**.
4. Delete any `import NoibuSessionReplay` statements from your code.
5. Clean the build folder via **Product → Clean Build Folder**.

**Via Package.swift:**

Remove the dependency entry and the product from your target, then run:

```bash
swift package update
```

---

## 3. Configuration

### NoibuConfig

The SDK is configured via `NoibuConfig`. All parameters:

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `domain` | `String` | **Yes** | - | Your Noibu domain endpoint (provided by Noibu) |
| `privacyMode` | `NoibuPrivacy` | No | `.maskSensitive` | Privacy level for session recording |

### Privacy Modes

| Mode | Description |
|------|-------------|
| `.allowAll` | All content is visible in recordings |
| `.maskSensitive` | Masks passwords and other sensitive inputs (recommended) |
| `.maskAll` | Masks all text content |

---

## 4. Initialization

Initialize the SDK as early as possible in your app's lifecycle to ensure full session capture.

### Basic Setup

```swift
import NoibuSessionReplay

let config = NoibuConfig(
    domain: "<your-domain.noibu.com>",
    privacyMode: .maskSensitive
)

Noibu.shared.initialize(configuration: config)
```

### SwiftUI App

For SwiftUI apps, initialize inside the `init()` of your `@main` App struct. This ensures the SDK is running before your first view appears:

```swift
import SwiftUI
import NoibuSessionReplay

@main
struct MyApp: App {

    init() {
        let config = NoibuConfig(
            domain: "<your-domain.noibu.com>",
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

### Checking Initialization Status

```swift
if Noibu.shared.isInitialized {
    print("Noibu SDK is running")
}
```

---

## 5. Session Replay & User Interactions

Session Replay is enabled automatically when `Noibu.shared.initialize()` is called. No additional configuration is required.

### 5.1 Automatically Captured Data

The following data is captured automatically without any additional instrumentation:

- Screen transitions (SwiftUI view changes)
- Button taps and touch interactions
- Gestures and scroll events
- Slider changes
- Navigation triggers (NavigationLink / NavigationStack)
- View appearance and disappearance events
- Layout and UI updates
- Error events originating from the UI layer

### 5.2 Tracking Screens

Label important screens using the `.trackView(name:)` modifier:

```swift
var body: some View {
    VStack {
        Text("Hello World")
    }
    .trackView(name: "Main ContentView")
}
```

This gives the replay viewer a clear, human-readable screen name in the session timeline.

### 5.3 Tracking User Actions

Explicitly annotate meaningful user actions using `.trackTapAction(name:)`:

```swift
Button(action: {
    withAnimation { showContent.toggle() }
}) {
    Text("Toggle content")
}
.trackTapAction(name: "Toggle content button")
```

This is useful for:
- Primary call-to-action buttons
- Navigation triggers
- Feature toggles
- Sliders or configuration changes

### 5.4 Performance Considerations

The Noibu iOS SDK is optimized to minimize impact on app performance:

- **Delta-based snapshots** — only visual differences are recorded, reducing CPU and memory usage
- **Event batching** — UI interactions are grouped efficiently
- **Background uploads** — replay data is synced when the device is idle
- **Low memory footprint** — thanks to native replay engine optimizations

---

## 6. Page Navigation

### Manual Page Tracking

Call `didNavigate()` when the user navigates to a new screen. This splits the session replay into distinct pages and ensures events are associated with the correct page visit:

```swift
// With a page name
Noibu.shared.didNavigate(pageName: "ProductDetails")

// Without a page name (uses default)
Noibu.shared.didNavigate()
```

### Tab Navigation

For tab-based navigation, call `didNavigate` when the selected tab changes:

```swift
TabView(selection: $selectedTab) {
    // ...
}
.onChange(of: selectedTab) { _, newTab in
    Noibu.shared.didNavigate(pageName: pageName(for: newTab))
}

private func pageName(for tab: Tab) -> String {
    switch tab {
    case .home: return "Home"
    case .products: return "Products"
    case .cart: return "Cart"
    case .settings: return "Settings"
    }
}
```

### NavigationLink Tracking

For NavigationLink transitions, call `didNavigate` in `.onAppear` of the destination view:

```swift
NavigationLink {
    ProductDetailView(product: product)
        .onAppear {
            Noibu.shared.didNavigate(pageName: "ProductDetail")
        }
} label: {
    Text("View Details")
}
```

### When to Call `didNavigate()`

- Navigation to a new screen
- Tab switches that represent distinct pages
- Modal or bottom sheet presentations
- Deep link handling

> **Important**: Always call `didNavigate()` when switching screens so that errors and custom attributes are associated with the correct page.

---

## 7. Error Reporting

Report errors to Noibu for tracking and analysis. Errors are associated with the current page visit.

### Reporting a Custom Error

```swift
// With a message only
Noibu.shared.addError(message: "Payment processing failed")

// With a message and stack trace
Noibu.shared.addError(
    message: "Network timeout",
    stack: Thread.callStackSymbols.joined(separator: "\n")
)

// With attributes for additional context
Noibu.shared.addError(
    message: "Checkout API returned 500",
    stack: Thread.callStackSymbols.joined(separator: "\n"),
    attributes: [
        "screen": "Checkout",
        "request_type": "POST",
        "retry_count": "1"
    ]
)
```

### Reporting a Swift Error

```swift
do {
    try riskyOperation()
} catch {
    Noibu.shared.addError(
        error,
        attributes: [
            "screen": "Home",
            "operation": "FetchProducts"
        ]
    )
}
```

The SDK automatically extracts the localized description and attaches the current call stack.

### Reporting an NSError

```swift
let error = NSError(
    domain: "com.myapp.payment",
    code: 1001,
    userInfo: [NSLocalizedDescriptionKey: "Payment gateway timeout"]
)

Noibu.shared.addError(
    error,
    attributes: [
        "screen": "Checkout",
        "payment_provider": "Stripe"
    ]
)
```

### API Reference

| Method | Parameters | Description |
|--------|-----------|-------------|
| `addError(message:stack:attributes:)` | `message: String`, `stack: String?`, `attributes: [String: String]` | Report a custom error message |
| `addError(_:attributes:)` | `error: Error`, `attributes: [String: String]` | Report a Swift Error |
| `addError(_:attributes:)` | `error: NSError`, `attributes: [String: String]` | Report an NSError |

### Best Practices

- Always call `didNavigate(pageName:)` before reporting errors so they attach to the correct page.
- Keep error messages consistent and descriptive.
- Avoid logging sensitive data (emails, payment details, personal identifiers).
- Use `attributes` for structured debugging context rather than long messages.
- Do not report errors inside tight loops or rapidly repeating UI events.

---

## 8. Network Monitoring

The Noibu iOS SDK automatically captures HTTP request and response data via a custom `URLProtocol` interceptor. No additional setup is required — the interceptor is installed automatically during `initialize()`.

### What Is Captured

| Data | Details |
|------|---------|
| Request metadata | HTTP method, URL, request size |
| Response metadata | Status code, response size, duration |
| Request/response headers | All headers (sensitive headers are automatically redacted) |
| Request/response bodies | Text-based content types only (JSON, XML, form data) |
| Errors | Network failures and exceptions |

### Privacy

The following headers are automatically redacted:

`authorization`, `cookie`, `set-cookie`, `x-auth-token`, `x-api-key`, `proxy-authorization`, `x-forwarded-for`

---

## 9. WebView Support

The Noibu SDK can capture session replay data from `WKWebView`, rendering WebView content as part of the same mobile session recording.

### Prerequisites

- JavaScript must be enabled on the WebView.
- Call `enable()` **before** loading any URL.
- Call `enable()` **after** `Noibu.shared.initialize()`.

### Setup

```swift
import WebKit
import NoibuSessionReplay

let webView = WKWebView(frame: .zero)
webView.configuration.preferences.javaScriptEnabled = true

NoibuWebViewTracking.enable(webView)

webView.load(URLRequest(url: URL(string: "https://example.com")!))
```

### SwiftUI

For SwiftUI apps, use `UIViewRepresentable` to host the WebView:

```swift
import SwiftUI
import WebKit
import NoibuSessionReplay

struct NoibuWebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.configuration.preferences.javaScriptEnabled = true
        NoibuWebViewTracking.enable(webView)
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
```

### How It Works

1. The SDK injects a DOM recorder into every page loaded in the WebView.
2. DOM snapshots and mutations are captured and routed through a native bridge.
3. Records are written directly to the replay outbox and sent alongside native snapshots.
4. WebView replay data is associated with the current native page view.

> **Note**: Call `didNavigate()` before presenting a new screen containing a WebView to ensure replay data is associated with the correct page.

---

## 10. Custom Attributes

Add metadata to sessions for filtering and analysis in the Noibu dashboard.

### Adding Attributes

```swift
Noibu.shared.addCustomAttribute(name: "customerId", value: "12345")
Noibu.shared.addCustomAttribute(name: "orderId", value: "ORD-98765")
Noibu.shared.addCustomAttribute(name: "appVersion", value: "2.1.0")
```

### Recommended Usage Patterns

**When a screen appears:**

```swift
.onAppear {
    Noibu.shared.addCustomAttribute(name: "screen.name", value: "ContentView")
    Noibu.shared.addCustomAttribute(name: "screen.variant", value: "main")
}
```

**When application state changes:**

```swift
Toggle(isOn: $isSwitchOn) {
    Text("Debug mode")
}
.onChange(of: isSwitchOn) { value in
    Noibu.shared.addCustomAttribute(
        name: "debug.enabled",
        value: value ? "true" : "false"
    )
}
```

**Before a meaningful user action:**

```swift
Button(action: {
    Noibu.shared.addCustomAttribute(
        name: "ui.toggle_content",
        value: showContent ? "hide" : "show"
    )
    withAnimation { showContent.toggle() }
}) {
    Text("Toggle content")
}
.trackTapAction(name: "Toggle content button")
```

**Pairing with Page Splitting:**

```swift
.onAppear {
    Noibu.shared.didNavigate(pageName: "Checkout")
    Noibu.shared.addCustomAttribute(name: "checkout.step", value: "shipping")
}
```

### Validation Rules

| Rule | Limit |
|------|-------|
| Maximum attributes per session | 10 |
| Attribute name length | 1–50 characters |
| Attribute value length | 1–50 characters |
| Duplicate names | Not allowed |

### Return Values

`addCustomAttribute` returns a `Bool`:

| Result | Description |
|--------|-------------|
| `true` | Attribute added successfully |
| `false` | Attribute was rejected (SDK not initialized or validation failed) |

### Naming Best Practices

- Use clear, descriptive names (e.g. `"screen.name"`, `"checkout.step"`)
- Focus on session context, not individual events
- Keep names consistent across similar screens
- Avoid including personal or sensitive data in attribute names or values

---

## 11. Privacy & Security

### Privacy Mode Selection

Choose the appropriate privacy mode based on your app's requirements:

```swift
// For general apps — masks only sensitive fields (default)
privacyMode: .maskSensitive

// For apps handling highly sensitive data
privacyMode: .maskAll

// For internal/debug builds only
privacyMode: .allowAll
```

### Data Storage

- Session data is streamed to Noibu's servers
- Local data is stored temporarily in the app's cache directory
- Data is automatically cleared after successful upload

---

## 12. Lifecycle Management

### Automatic Background Handling

The SDK automatically handles app lifecycle:
- **App goes to background**: Pending data is flushed
- **App returns after 30+ seconds**: A new page view is started automatically

### Shutdown

To completely stop the SDK (e.g., user revokes consent):

```swift
Noibu.shared.shutdown()
```

This will:
- Stop all recording
- Flush pending data
- Clear custom attributes
- Reset the initialized state

---

## Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| No recordings appearing | Verify `domain` is correct and `initialize()` is called before the first view appears |
| Events not associated with a page | Ensure `didNavigate()` is called on every screen transition |
| Custom attributes not appearing | Check the 10-attribute limit and verify no duplicate names |
| WebView content not in replay | Ensure `NoibuWebViewTracking.enable()` is called before loading the URL |
| Network requests not captured | The interceptor is installed automatically — verify `initialize()` completed successfully |
| Errors not appearing in dashboard | Verify `addError()` is called after `initialize()` and after `didNavigate()` |

### Verify Initialization

```swift
if Noibu.shared.isInitialized {
    print("Noibu SDK is running")
} else {
    print("Noibu SDK is not initialized")
}
```

---

## Support

Need help? Contact your Noibu solutions engineer with:
- SDK version
- iOS version and device type
- Xcode version
- Initialization code snippet
- Relevant console output

