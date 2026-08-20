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
  font, timezone, and network/ISP name.
- A focusable "Refresh" button (tvOS `.card` button style) re-queries on demand.
- Handles loading and error states with a dedicated screen for each.

## About the data source

`IPLocationService.swift` calls **[MaxMind's GeoIP2 web service](https://www.maxmind.com)**
(the hosted, pay-per-query City API — not a local database file). It requests the
special IP value `"me"`, which tells MaxMind to look up whatever address the
request itself came from, so no separate "what's my IP" call is needed first.

**Setup required:** this is an account-based API, not a keyless one.
1. Sign up at maxmind.com and subscribe to a GeoIP2 Precision web service (City or
   above — the free GeoLite2 databases are download-only and don't offer a hosted
   web service).
2. Generate a license key under your account's "Manage License Keys" page.
3. Open `Services/MaxMindCredentials.swift` and fill in your account ID and license
   key. Until you do, the app shows a clear "add your credentials" error instead of
   crashing.

These are secrets. If this repository is ever made public, replace them with
placeholders and pass real values another way (an untracked config file,
environment-specific build settings, a secrets manager) — don't leave a real
license key in version control.

The networking layer is isolated behind the `IPLocationFetching` protocol
(`Services/IPLocationService.swift`), so swapping in a different provider later is
a matter of adding a new type conforming to that protocol and passing it into
`IPLocatorViewModel(service:)` in `ContentView.swift`, without touching any UI code.

## Project structure

```
IPLocatorForTVOS/
  IPLocatorForTVOSApp.swift      App entry point
  ContentView.swift              Screen states + view model
  Models/IPLocationInfo.swift    Provider-agnostic location model
  Services/IPLocationService.swift    Network call (MaxMind GeoIP2 web service)
  Services/MaxMindCredentials.swift   Your MaxMind account ID + license key
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
