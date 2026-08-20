# IPLocator for TVOS

A tvOS app that shows your public IP address, your approximate location, and your
country's flag in a modern, card-based UI.

## Opening the project

1. Open `IPLocatorForTVOS/IPLocatorForTVOS.xcodeproj` in Xcode (15 or newer).
2. Select the `IPLocatorForTVOS` scheme and an Apple TV simulator or device.
3. Build and run (⌘R).

No third-party dependencies, no API key, and no signing beyond your personal team
are required to run it.

## What it does

- On launch, fetches your public IP address and geolocation.
- Displays the country flag (rendered from the ISO country code — no image assets
  needed), the "City, Region, Country" name, the IP address in a large monospaced
  font, and timezone. (The network/ISP row only appears when the provider returns
  one — DB-IP's free tier doesn't include it, so it won't show currently.)
- A focusable "Refresh" button (tvOS `.card` button style) re-queries on demand.
- Handles loading and error states with a dedicated screen for each.

## About the data source

`IPLocationService.swift` calls **[DB-IP's free API](https://db-ip.com/api/)**
(`api.db-ip.com/v2/free/self`) — a keyless, HTTPS JSON API backed by DB-IP's own
geolocation database. No account or API key needed (the literal path segment
`free` stands in for one). It's rate-limited for evaluation-level use rather than
built for high-volume traffic, but that fits an app that only looks itself up on
demand. Its free tier doesn't include ISP/organization data, only city-level
geolocation.

(ipwho.is was tried before this. MaxMind's GeoIP2 web service was tried before
that, since it's a well-known, accuracy-focused provider, but it requires at least
a MaxMind account plus a paid subscription to use as a hosted API — there's no
keyless or fully-free way to query it as a web service. ipapi.co was tried before
that, but returns HTTP 403 on VPN exit IPs — either its free-tier daily quota being
exhausted by everyone sharing that same exit IP, or it deliberately blocking known
VPN/proxy IP ranges.

DB-IP also publishes **DB-IP Lite** — an actual downloadable database file, like
MaxMind's GeoLite2 but without needing an account — which would remove the network
call entirely and can't be blocked on a VPN. That's a bigger change than swapping
an API endpoint, though: it means bundling a large file in the app, adding a parser
for it since there's no built-in Swift support, showing DB-IP's required
attribution in the UI, and manually re-downloading it periodically since a bundled
copy goes stale. Ask if you'd like to go that route instead.)

The networking layer is isolated behind the `IPLocationFetching` protocol
(`Services/IPLocationService.swift`), so switching providers later is a matter of
adding a new type conforming to that protocol and passing it into
`IPLocatorViewModel(service:)` in `ContentView.swift`, without touching any UI code.

## Project structure

```
IPLocatorForTVOS/
  IPLocatorForTVOSApp.swift      App entry point
  ContentView.swift              Screen states + view model
  Models/IPLocationInfo.swift    Provider-agnostic location model
  Services/IPLocationService.swift    Network call (DB-IP free API)
  Utilities/CountryFlag.swift    Country code -> flag emoji
  Views/BackgroundView.swift     Gradient background
  Views/LocationCardView.swift   Glass card showing flag/IP/location
```

## App icon

`Assets.xcassets/Brand Assets.brandassets` contains a custom icon: a translucent
glass location pin with photographed-glass-sphere shading, a glowing "landing"
ellipse, sitting above a pinpointed location. Confirmed building and showing up
correctly in Xcode. Structure:

- `App Icon.imagestack` (400×240, home screen) and `App Icon - App Store.imagestack`
  (1280×768) — both layered image stacks (Front/Middle/Back, for the parallax effect
  on the home screen). The artwork is duplicated onto the **Back** and **Middle**
  layers (Xcode requires at least 2 of the 3 layers to have content); **Front** is
  empty. Since Back and Middle are identical, it currently renders as a flat icon
  rather than with true parallax depth — ask if you'd like the design actually split
  across distinct layers for a real depth effect.
- `Top Shelf Image` (1920×720) / `Top Shelf Image Wide` (2320×720) — the wide banner
  tvOS shows behind the app icon when it's focused/hovered on the home screen. Same
  glass-pin-and-glow motif, with the "IPLocator / FOR TVOS" wordmark set beside it
  (vertically centered — there's only 720px of height at 1x, not enough for a
  stacked layout like the icon uses), sized and margined conservatively to stay
  clear of TV overscan/safe-area cropping.

This structure was derived directly from what Xcode's own "New tvOS App Icon"
generator produced on the target machine (two earlier hand-authored attempts, closer
guesses based on the asset catalog documentation, failed Xcode's validation).

## Notes

- Deployment target: tvOS 16.0.
