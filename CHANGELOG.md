# Changelog

All notable changes to the **Noibu Session Replay iOS SDK** are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.1] - 2026-10-28

### Fixed
- **SwiftUI tab bars are pinned in page analysis on real devices.** SwiftUI only exposes a bar's
  `.isTabBar` trait while an accessibility client is running, so on most devices a custom bar (for
  example one placed with `.safeAreaInset(edge: .bottom)`) was not recognised, and page analysis scrolled
  it away with the page instead of pinning it to the bottom of the snapshot. The SDK now also recognises
  the bar by its shape. Nothing to configure.

## [2.0.0] - 2026-10-26

### BREAKING
- **Pages now come exclusively from `trackNavigation` calls.** Automatic screen and WebView route
  detection is removed: no view controller, SwiftUI view or webview navigation opens a page.
- **One navigation API: `Noibu.shared.trackNavigation(screenName:attributes:)`.** Call it from every
  screen (`viewDidAppear`, SwiftUI `.onAppear`), including when Back reveals it.
- **Automatic page reporting removed.** The SDK no longer opens a page per appearing view controller
  (`NoibuConfig.autoTrackNavigation` is gone). Apps that relied on automatic tracking must now call
  `trackNavigation` on every page.
- **WebViews open no pages.** A navigation inside a tracked webview no longer opens a page visit named
  after its URL; its replay, clicks, errors and requests land on the current page. Report web steps with
  `trackNavigation` (see [Web steps as pages](README.md#web-steps-as-pages)).
- **Deprecated APIs removed:** `didNavigate(pageName:)`, SwiftUI `.trackView(name:)` and the no-op
  tap annotations (SwiftUI `.trackTapAction(name:)`, UIKit `trackTapAction(name:)` /
  `noibuTrackTapAction(name:)`).
- **Unnamed or blank calls report nothing.** A blank `screenName` opens no page.
- **Pages without a `trackNavigation` call.** On a fresh start (no previous screen), events land on a
  `view/<uuid>` placeholder that the first screen takes over (within 2 s, or before any replay frame);
  on a return from background, a relaunch or a new session, the next page copies the previous screen's
  name, group and attributes; an app that never calls it gets `view/<uuid>` pages. See
  [What happens without a call](README.md#what-happens-without-a-call).

See [Migrating from 1.x](README.md#migrating-from-1x).

### Added
- **Screen names and attributes.** `trackNavigation(screenName:attributes:)` reports a page by its
  template name (`Product Detail`, `Cart`), which is also its page group, with per-visit `attributes`
  (`productId`); the same name with different attributes is a new visit.
- **`pageType` attribute.** A standard type (`NoibuPageType` constants, any case) is the page group
  instead of the screen name. Reserved names (`None`, `Page Check`, `Exit`…) are never sent as a group.
- **Page groups** in page analysis: every page is grouped by its screen name or `pageType`.
- **`onRouteChange` on `NoibuWebViewTracking.enable`.** Called with the route's `path?query` each time the
  page inside a tracked WebView moves to a different route, so the app can report web steps with
  `trackNavigation` (see [Web steps as pages](README.md#web-steps-as-pages)). The document the webview
  loads first is not passed to it: the hosting screen reports that one with its own `path`.

### Changed
- `beginNavigationTransition()` is internal to the React Native bridge and no longer public API.

### Removed
- `NoibuConfig.autoTrackNavigation` and the automatic page per appearing view controller.
- `didNavigate(pageName:)`, `.trackView(name:)`, `trackTapAction(name:)` (SwiftUI and UIKit),
  `noibuTrackTapAction(name:)`.

### Fixed
- **UIKit views inside SwiftUI replay.** A `UIViewRepresentable` (a label, a Lottie view, a frame
  animation) and a `TabView`'s tab bar were never walked; they now are, in paint order.
- **A SwiftUI screen sliding over another stays opaque.** Its background, and the other screen's
  content outside any scroll view, kept their paint order; a scroll view's content is only what is
  inside it, and a moving fill keeps one node instead of a new one per frame.
- **Animated splash content replays.** A `UIImageView` frame animation (`animationImages`) shows its
  current frame, and a view drawn only by its layers (a `CAShapeLayer`, Lottie) is rasterized while it
  animates, within the existing per-view cap.
- **A screen sliding over another replays as a slide, not a scroll.** Children moving together under a
  node that cannot scroll (an inner navigation the app does not report, a pager) were read as that node
  scrolling: the screen sliding out was kept as an off-screen ghost and the move replayed as a scroll.
  Only a node the walker marks scrollable scrolls now, and rows a pixel apart from float rounding no
  longer make a list's scroll frame read as none.
- **Sessions end after 29 minutes without input.** A page visit stayed open for as long as the process
  lived when the app was never told it went to the background (launched straight into it, or
  suspended before the lifecycle callback ran), so a visit hours later continued it. Now, as on the
  web, 29 minutes with no tap, scroll, keystroke or navigation ends the session and seals its pages;
  the next input starts a new session on a new page visit. Animations and network traffic don't count
  as activity.
- **Replay survives a crash or a kill.** The server stores a screen's replay only when its
  connection closes; a long screen's connection is now checkpointed every 2 minutes, so a process that
  dies with it open loses at most the last 2 minutes instead of the whole screen.
- **The first replay frame of a screen is always its snapshot**, also when a tap opens the screen.
- **Visits stay in order after a quick background.** A request begun on one screen and answered after
  the app left it was filed to the next visit with its start time, so that visit started before the
  one it followed and the two traded places (and referrers) in the timeline.
- **Changes that don't move anything now reach the replay.** A label whose text or colour changes in
  place (an auto-advancing banner), an image swap, or a fade or hide was skipped until the next tap,
  because capture only re-walked the screen when a frame or scroll offset moved.
- **iOS 27 scene-based apps seal the page on background.** Core now observes UIScene as well as
  UIApplication lifecycle notifications, and treats a launch straight into the background as one.

## [1.2.1]

### Fixed
- **Image-heavy screens no longer freeze while Noibu records.** Every image the capture had not seen was
  redrawn at its full size, PNG-encoded and hashed on the main thread, and a recycled list cell counted as
  unseen — so a grid of product photos (a FlashList of `expo-image` cards, a `UICollectionView`) stopped
  drawing for close to a second on landing and after every fling. Images are now drawn and encoded off the
  main thread, at the size they are shown (at most 2x), photos as JPEG; the same photo is captured once
  however often a cell shows it again. Nothing to configure.

## [1.2.0]

### Added
- **Custom tab bars in page analysis.** A view carrying the `.tabBar` accessibility trait (a
  `UITabBar`, a React Native `accessibilityRole="tablist"`, or your own bar with
  `accessibilityTraits.insert(.tabBar)`) is the page's bottom bar. In SwiftUI, put
  `.accessibilityElement(children: .contain).accessibilityAddTraits(.isTabBar)` on a hand-rolled bar;
  a `TabView` needs nothing. Scroll views are marked by intent (`alwaysBounceVertical`, tables) as
  well as by content size.

### Fixed
- **React Native text replays on the old architecture.** An old-architecture `RCTTextView` keeps its
  string only in a private text storage, with no `attributedText` to read, so every `<Text>` of such an
  app replayed as an empty box: labels, prices, buttons and tab titles. It is now read, with its font,
  colour, line height and decoration.
- **React Native borders replay in their own style on the old architecture.** The border style was read
  one step off React Native's enum, so every solid border replayed dotted, and a dotted one dashed.
- **No crash on a screen with a view whose frame isn't finite.** A view laid out with `CGRect.infinite`
  or a NaN size — OneTrust's Preference Center has one — stopped the app as soon as the screen opened,
  in the capture's change check. Such a value now reads as 0 there and in every other geometry the
  SDK records, and a finite one too large to convert (a text box, corner radius or line height past
  the integer range, a gradient stop that is NaN) is clamped instead of crashing.
- **Page analysis: each visit names the screen it came from.** The referrer is recorded when the page
  opens, so a visit whose predecessor had already been sent no longer arrives without one.
- **Page analysis: a tap on empty space no longer lights up the whole page.** A tap between rows, on a
  large unlabelled container, keys to the nearest content-sized element instead of a page-sized one.
- **No blank page visit at launch.** Work that runs before the first screen names itself (a network
  call at startup) no longer opens a visit of its own; the first screen adopts it.
- **Page analysis: taps land on the element under the finger after a scroll.** A reused accessibility
  read follows the scroll, and elements scrolled into view are added.
- **No junk page visit on backgrounding.** The app-switcher snapshot no longer opens a one-frame visit.
- **Grayscale and dark-mode backgrounds replay.** `.white`, `.black` and `.gray` fills and a dark
  page's black background are kept, and UIKit text uses its resolved dynamic colour.
- **Page analysis: click selectors are resolved at the tap.** The tapped element is looked up when the finger lifts, against what is on screen then, instead of when the pipeline drains seconds later — a tap followed by a scroll was attributed to whatever had moved under that point.
- **Page analysis: scroll and tab-bar markers follow the screen.** A list that only becomes scrollable once its content loads, or a bar that settles into place after a transition, is re-marked instead of keeping the state of the first frame; nested Material bars pin once. A node's
  selector class follows its key as siblings come and go, so a click always finds its element.

## [1.1.3]

### Fixed
- **App Store uploads no longer fail with ITMS-90208 on Swift Package Manager installs.** Xcode
  copied an empty `NoibuSessionReplay.framework` into the app, built for the app's own minimum iOS
  version, so any app with a minimum other than iOS 14.0 was rejected at upload ("does not support
  the minimum OS Version specified in the Info.plist"). The SDK is now linked straight into the app;
  only `coreKit.framework` is embedded. A build phase you added to delete the empty framework can be
  removed. CocoaPods installs were not affected.
- **Replay processing stays light however much of a screen changes.** Its per-capture work is now
  proportional to the screen; a large part of a screen disappearing and coming back used to cost
  time that grew with the square of its size. Nothing to configure.
- **SwiftUI colours replay at their real shade.** Resolved SwiftUI colours were read as linear light,
  so every mid-tone replayed noticeably darker than the app drew it.
- **Bundled fonts replay in the right face and weight.** SwiftUI text now uploads its bundled font as
  UIKit text does; each bundled weight is its own face, so Medium and Bold no longer replay as one
  file; text set in a bundled font keeps the position it has on screen instead of sitting a few points
  low; and the weight sent is the face's own (Medium was replayed as Regular or Bold).
- **Shadows and letter spacing replay.** A layer's `shadow*` on a UIKit view, and kerning and tracking
  on UIKit, SwiftUI and React Native text, were dropped.
- **React Native views on the new architecture keep their borders, corners, shadows and gradients.**
  Fabric draws a border, a `boxShadow` and a `backgroundImage` gradient into its own sublayers; they
  replayed as plain square boxes. `opacity` on a layout `View` that paints nothing now fades the views
  under it, as it does on screen.
- **Views inside a bordered view sit where they are drawn.** Every child of a view with a border was
  replayed shifted in by the border's width.
- **Fonts are on the first frame of a screen.** A screen whose font finished uploading after its first
  capture replayed in a fallback font for the whole visit.
- **Webview HTTP calls are reported with absolute URLs.** A page's fetch or XHR to a relative URL
  was reported as written, and the backend dropped the whole session it could not parse.

## [1.1.2]

### Fixed
- **Builds again with Xcode 26.** `1.1.1` was built with Xcode 27, so Xcode 26 could not read its
  Swift interface (`expected type` / `expected '{' in extension`) and it required iOS 15. This
  release is the same code as `1.1.1` built with Xcode 26.0.1: it builds with Xcode 26 and supports
  iOS 14 again.

## [1.1.1]

### Fixed
- **No more 100% CPU, crash or crash loop on SwiftUI screens that nest a background in a same-size
  background.** Layer ids came from geometry alone, so a view filling a same-size view with a
  background (a card and its content) took its parent's id and became its own parent. The replay
  differ then looped forever on a background thread — a core pinned at 100%, the device heating up
  until iOS killed the app — or, with that view on a screen's first frame, overflowed its stack and
  crashed the app, again on every launch while that frame waited on disk. Ids are now unique within
  each capture, and the replay core repairs any tree with a repeated id or a parent cycle before
  diffing it, so an app already caught in that loop recovers on update, with its data intact.
- **SwiftUI replays no longer come out blank or missing layers** where repeated ids confused the
  player, such as a home screen whose sections nest backgrounds.

## [1.1.0]

### Added
- **`track(name:data:)` — ecommerce and custom events.** The counterpart of NoibuJS's
  `track(name, payload)`: report a standard ecommerce event (`product_viewed`,
  `product_added_to_cart`, `cart_viewed`, `checkout_started`, `checkout_completed`, …) or any custom
  event with a JSON payload, and it appears on the session's timeline and in Explorations exactly as
  the web event does. Standard payloads are checked against the shared ecommerce schema (unknown
  properties are dropped, type mismatches rejected); a custom payload only has to be a JSON object.
  Event names are capped at 500 characters and payloads at 10,000 characters serialized — the
  payload cap also applies to standard events, which web leaves to its schema — and up to 500 events
  are kept per page visit. Nothing is thrown: the call answers a `NoibuTrackResult` with `success`
  and the validation `errors`, in the same words as web. `track(name:dataJson:)` takes an
  already-encoded payload.
  Called off the main thread, `track` is ordered behind a `didNavigate` already on its way there,
  so an event tracked as a screen appears lands on that screen's page visit.
  Events tracked between `sealCurrentPageReplay` and the boundary that follows it are held by the
  core and attributed to the page the boundary opens (the Android Compose add-on's transition
  pattern); no iOS caller uses that pattern today.

### Fixed
- **Capture no longer crashes on iOS 26 when a screen shows a tab bar.** The Liquid Glass tab bar
  reports an infinite corner radius for its capsule layers, and the replay walkers converted layer
  geometry to integers with Swift's checked `Int32(_:)`, which traps on a non-finite value — the app
  died on the first capture of any `UITabBar` or SwiftUI `TabView` screen. Every layer-derived
  conversion now treats a non-finite radius or frame as zero and clamps the rest. Nothing changes in
  an app and there is nothing to configure.

## [1.0.1]

### Fixed
- **Sessions are now attributed to the SDK that recorded them.** Every session reported an internal
  build number rather than the SDK and version installed in your app, so a session recorded by this
  SDK could not be told apart from one recorded by another Noibu mobile SDK, or by an earlier release
  of this one. A session now reports this SDK and its version. Nothing changes in an app and there is
  nothing to configure; what is captured is unchanged.

## [1.0.0]

### Fixed
- **Web content inside a wrapped webview now appears in replay.** A `WKWebView` you add to a screen
  yourself was always captured, but one nested inside a container view — the shape React Native's
  WebView component uses — replayed as an empty area. Everything else about those screens was
  recorded normally: the page visit, the native UI around the webview, and its network requests. You
  enable tracking exactly as before; nothing to change in an app.

## [1.0.0-rc.3]

Everything since `1.0.0-alpha06`, including what first shipped in the `1.0.0-rc.1` and `1.0.0-rc.2`
prereleases — published without release notes of their own, so their contents are folded in here.

### Fixed
- **The published XCFramework now exposes its API to Objective-C.** The framework shipped a stub
  umbrella header and no generated `NoibuSessionReplay-Swift.h`, so an Objective-C consumer could
  `@import NoibuSessionReplay;` and see nothing at all — any `.m`/`.mm` file referencing, say,
  `NoibuHTTPInterceptor` failed to compile against the released pod. Swift consumers were unaffected.
  The header now ships per slice, declared as the `NoibuSessionReplay.Swift` submodule.
- The framework's module map no longer declares `DatadogCore`, `DatadogInternal`, `DatadogRUM` or
  `DatadogSessionReplay`. There is no Datadog dependency in this build; the declarations were left
  over from the fork era.

### Added
- `addError` is capped at 500 errors per page visit. A component stuck in an error loop, or a
  tracked webview whose page throws on every interaction, wrote one event per throw for the whole
  life of the screen. The cap resets on every page visit — including the ones the SDK opens itself
  after a background return, a relaunch or a session rotation.
- GraphQL errors are now detected on successful responses. A GraphQL server answers a failed
  operation with `200 OK` and an `errors` array, so a declined payment looked like a successful
  request. Core parses the captured response body of a 2xx GraphQL request (JSON at a `graphql`
  URL, or `application/graphql`) and reports one `gql` error event per entry, with the message,
  locations, path and extensions.
- `NoibuHTTPInterceptor.installNetworkInstrumentation(on:)` — adds Noibu's HTTP capture to a
  `URLSessionConfiguration` you build yourself. `URLProtocol.registerClass` (what `initialize`
  does) only reaches `URLSession.shared`, so any session with its own configuration — React
  Native's networking, Alamofire, … — was silently uncaptured. Callable before `initialize` (a
  session is built once and cached, and React Native builds its own on the app's first request):
  the protocol goes in unconditionally and `NoibuURLProtocol` stays inert until capture is up.
  Android analog: `installNetworkInstrumentation()` on an OkHttp builder.
- Capture switches on `NoibuConfig` — `trackTouches`, `trackKeyboard`, `trackNetwork`,
  `trackWebViews`, `trackErrors` (all default `true`). The config surface now mirrors Android's
  `SessionReplayConfig` field for field, so the React Native and Flutter shims map one config onto
  both platforms. `trackWebViews: false` makes `NoibuWebViewTracking.enable` a no-op.
- Configurable diagnostic logging via `NoibuConfig.logLevel`. Logging is **off by default**;
  set `.info` to surface integration-debugging diagnostics in the Xcode console / Console.app
  (filter `NB>`). See [Diagnostic Logging](README.md#diagnostic-logging).
- Background sync: with the `BGProcessingTask` `Info.plist` keys, data captured right before
  the app is suspended/terminated is delivered while the app is in the background. See
  [Background Sync](README.md#13-background-sync).

### Removed
- `NoibuConfig.environment`, `NoibuConfig.sampleRate` and `NoibuConfig.firstPartyHosts`. They were
  accepted and read nowhere — a `sampleRate` of `0.0` still captured every session. Drop them from
  your `NoibuConfig(...)` call; no behaviour changes.
- `NoibuConfig.ingestHost`. Where sends go is not an integration setting — a customer build always
  delivers to Noibu production — and a public field made it a supported knob that could be pointed
  anywhere. Noibu-side development redirects it in the app's debug wiring instead
  (`NOIBU_DEV_INGEST_HOST` env var or a `NoibuDevIngestHost` Info.plist key), which only a debug SDK
  build reads.

### Fixed
- The CocoaPods integration docs no longer require `use_frameworks!`. CocoaPods embeds a vendored
  dynamic xcframework under any linkage mode — measured against this pod with `:linkage => :static`
  and with no `use_frameworks!` — so the stated requirement was wrong, and following it breaks
  React Native hosts, where Hermes rules out dynamic frameworks. The `Podfile` sample also pinned a
  long-superseded `~> 0.1.0-rc.1`.
- `NoibuConfig.privacyMode` now takes effect. It was declared, defaulted and documented while being
  read by no line of the SDK, so a customer who set `.maskAll` got `.maskSensitive` behaviour and no
  error. The mode is forwarded into the KMP core and applied by the UIKit walker (React Native's text
  views included), the SwiftUI structural text reader and the SwiftUI accessibility walker, using the
  same `TextMasking` policy Android and Flutter use. `.maskSensitive` also gained PII scrubbing of
  DISPLAY text — a card number, SSN, email or phone rendered in a plain label was shipping verbatim.
  Typed input content is still never captured in any mode, `.maskAll` included. Note that SwiftUI
  views the structural reader can't read are rasterized, and text in those pixels is not redacted.
- Line height is captured. UIKit and React Native both carry it on the attributed string's
  `NSParagraphStyle`, which the walk never read and `NodeStyle` has no field for, so replay fell back
  to CSS `normal` (roughly 1.2x the font size): a paragraph styled looser replayed cramped and one
  styled tighter lost its last line to the box's clip. It now ships as a `line-height` CSS override,
  on both React Native architectures.
- Underlined and struck-through text is captured. UIKit and React Native both carry
  `textDecorationLine` as an `NSAttributedString` attribute, which the walk never read and
  `NodeStyle` has no field for, so a struck-out original price beside a sale price replayed as a
  second live price and an underlined link replayed as plain text. The decoration now ships as a
  `text-decoration` CSS override, on both React Native architectures.
- React Native borders are captured in replay. `RCTView` writes `CALayer.borderWidth` only when the
  border is uniform, solid AND the view clips — otherwise it renders the border into a layer image,
  so the layer reports none at all. The walk read only the layer, so an outlined card, a list
  separator's `borderBottomWidth`, an input underline or a tab indicator replayed with no border
  whatsoever. React Native's own props are now read (a logical `start`/`end` edge wins over the
  physical one, swapped under RTL, then the `borderWidth`/`borderColor` shorthand) and a per-edge or
  dashed border ships as `border-width`/`border-color`/`border-style` CSS. A sub-point width
  (`StyleSheet.hairlineWidth`) floors at 1px rather than rounding away. Old architecture only — under
  Fabric the props live in C++ and are unreadable from the walk.
- A `UISlider` is captured in replay. Its track and thumb are drawn by private UIKit subviews
  carrying no text, image or background, so the walk elided the whole control as a structural
  wrapper and reparented its internals to the window — a slider (React Native's
  `@react-native-community/slider`) replayed as loose fragments with no node to resolve as a click
  target. It is now rasterized like a `UISwitch`, so the replayed slider follows its value.
- A `UIActivityIndicatorView` is captured in replay. Its spinner is drawn by private UIKit subviews
  carrying no text, image or background, so the walk elided the whole control as a structural
  wrapper and a loading screen (React Native's `<ActivityIndicator>`) showed no sign the app was
  waiting. It is now rasterized like a `UISwitch`, and frozen at its first raster — its rotation
  carries no information, and every accepted change stages and uploads a separate asset.
- A `UISwitch` is captured in replay. Its track and thumb are drawn by private UIKit subviews that
  carry no text, image or background, so the walk elided the whole control as a structural wrapper
  and every toggle (React Native's `<Switch>`) was missing from the session. It is now rasterized
  the way a react-native-svg root already is — the ref follows the drawn content, so the replayed
  toggle shows its on/off state — and its internals are no longer walked over the image.
- Alerts and other overlay windows are captured, and no longer replace the screen behind them.
  Capture walked the key window only, so a `UIAlertController` in its own window (React Native's
  `Alert`, and most toast/banner libraries) either replaced the whole app screen in replay once it
  became key, or was missing entirely. The active scene's visible windows are now walked
  lowest-level first, with the overlays nested under the app window's node, and the capturer's
  change-detection fingerprint covers them so an alert opening over a static screen isn't skipped.
- A react-native-svg view is rasterized only when what it draws changes. Every capture walk rendered
  each `RNSVGSvgView` on screen at full resolution and PNG-encoded it on the main thread, then
  re-staged identical bytes as an asset. A 64px fingerprint raster now gates the full render, and
  accepted changes are bounded at 30 per view (matching Android) so an animating vector can't ship
  one asset per capture.
- `didNavigate` is now safe to call from any thread. The page rotation reads the snapshot capturer's
  main-thread state and runs `evaluateJavaScript` on every tracked webview, so calling it off the
  main thread — which the React Native bridge does, since RN dispatches module methods on its own
  serial queue — raced the replay capture and touched WebKit off-main. It hops to the main thread
  first, the way Android's `navigateTo` already did.
- HTTP redirects follow the app's policy again, and each hop is captured. `NoibuURLProtocol`
  forwards intercepted requests on its own session, which followed every 3xx silently — so a
  session delegate's `willPerformHTTPRedirection` never ran (React Native rebuilds the next
  request's headers from the cookie jar on every hop, which means the original request's headers
  were carried to the redirect target instead of being dropped), and the whole chain collapsed into
  one `Network` event carrying the first URL with the last status. The redirect is now handed to
  the URL Loading System, which re-issues the new request under the app's policy — captured on its
  own, since the re-issued request no longer carries capture's already-handled marker.
- WebView capture no longer records what the user types in the page. The injected rrweb recorder ran
  with the library's default input masking, which covers `<input type="password">` only, so a webview
  checkout shipped the card number, email and address into replay — while the native walkers have
  always masked a text field (they ship its placeholder, never its content). Every input value is now
  masked, and a click on a text field no longer reports that field's value as the click label (it fell
  back to `.value`, which is a custom control's visible caption but a field's typed text — wrappers
  such as `ion-input` nest a real `<input>` and leaked the same way). Buttons keep their caption.
- HTTP responses are streamed to the app instead of being buffered whole. `NoibuURLProtocol`
  forwarded each request on a task with a completion handler, which accumulates the entire response
  in memory and hands the app every byte at once at the end — so a large download (a file, an image,
  a paginated API response) was held in memory in full by capture, `URLSession` progress and
  incremental delivery arrived only on completion, and a `downloadTask` lost its stream-to-disk
  behaviour. Capture now forwards response, data and completion as they arrive and keeps only a
  64 KB-capped copy of the body, while still reporting the response's true size.
- Cancelled HTTP requests are now cancelled. `NoibuURLProtocol` forwards each intercepted request
  on its own `URLSession` task but never cancelled it in `stopLoading()`, so a request the app
  aborted (`AbortController`, a task cancelled on screen dismissal) kept downloading its response
  into memory for the rest of its life, and the completion handler then messaged a client the URL
  Loading System had already torn down — which it forbids. The forwarded task is cancelled on stop
  and nothing is forwarded to the client afterwards.
- Oversized HTTP responses are no longer silently dropped, and the capture cap is now 64 KB
  (was 256 KB, matching Android). A body over the cap used to be cut at a byte offset, which
  splits a multi-byte codepoint whenever one straddles the boundary — the UTF-8 decode then failed
  and the whole payload vanished from the event. An oversized body is now reported as
  `[Body too large: N bytes]`, the same marker the request path already used. Response capture also
  honours the `Content-Type` allowlist Android has always applied, so binary responses are no
  longer read as text.
- Stack frames are parsed more accurately. The frame parser now uses the pattern the JavaScript SDKs
  use; Swift crash frames are unchanged, and a leading message line is no longer turned into a bogus
  frame when it happens to contain a parenthesis. JavaScript stacks — those a `WKWebView` or a
  cross-platform shim reports — were the ones actually broken before, losing the file and line of
  every anonymous frame.
- Captured HTTP payloads and header values are now PII-redacted before they are cached or uploaded.
  `NoibuURLProtocol` captures request/response bodies verbatim, so a login or checkout POST carried
  the plaintext password and card number. Core scrubs values under sensitive keys and card / email
  / SSN / SIN / phone patterns at the raw-cache boundary.
- Opening a page visit is now atomic. Events arrive on whatever thread produced them (the URL
  protocol's delegate queue for network, the main thread for replay and taps, a shim's JS/platform
  thread for custom errors), and the page open below was a read-modify-write spanning two lock
  acquisitions — so concurrent callers could each mint a page for the same screen.
- Returning from the background no longer records into a closed page visit. Backgrounding finalizes
  every open page so it can flush, and a relaunch finds the previous run's page in the same state,
  but that page stayed *current* — so everything captured after the app resumed was filed under a
  page visit that had already been processed and sent, and after a session rotation the new
  session's events landed in the previous session's page. A finalized page now yields to a
  successor, which keeps the screen's name.
- The first `didNavigate(pageName:)` no longer leaves an extra `view/<uuid>` page visit behind.
  Capture opens a nameless page as soon as the first event lands; a host that names its opening
  screen a moment later (React Native and Flutter do, once their async init resolves) split off it,
  shipping that placeholder as its own page visit. The first page name now adopts it instead.
- A React Native `<TextInput>` no longer leaks what the user typed. On the old architecture RN wraps
  the field in a plain `UIView` that re-exposes the typed value as its own `attributedText`, which
  the walker read as display text — past the `UITextField` masking. Such a wrapper now defers to the
  field it wraps (placeholder, or `***`). An editable `UITextView` and an unlabelled filled field
  likewise emit `***` instead of their content (previously the text view emitted nothing at all, so
  the box vanished from the replay as the user typed).
- Replay now captures a view's border (uniform `layer.borderWidth` / `layer.borderColor`), and a
  view whose only paint IS that border — an outlined card, a divider, a bordered text field — is no
  longer dropped from the replay as an empty layout wrapper.
- Custom attributes are no longer lost after a session rotation. The 10-attribute budget and the
  no-duplicate-names rule are documented as per session, but they only reset on SDK shutdown — so
  once the SDK rotated to a new session (a background stay of 15+ minutes), an app re-sending its
  customer id had it dropped as a duplicate and the new session carried no attributes at all.
- Session replay video now aligns with the session timeline — taps, keyboard input, and
  navigation appear at the same moment in the replay as on the timeline.
- Replay video is attributed to the correct screen during rapid navigation between pages.
- Single-page sessions (no navigation) now reliably deliver session replay and events.

## [1.0.0-alpha06]

Initial public alpha.

- Session replay capture.
- RUM events: taps, navigation, and errors.
- Network monitoring.
- WebView capture.
- Custom attributes and custom errors.
- Privacy modes: `.maskAll`, `.maskSensitive`, `.allowAll`.
