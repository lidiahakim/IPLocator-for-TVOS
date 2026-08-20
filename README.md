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

`IPLocationService.swift` calls **[ipapi.co](https://ipapi.co)** — a free, keyless,
HTTPS JSON API. No account or API key needed.

(MaxMind's GeoIP2 web service was tried first, since it's a well-known,
accuracy-focused provider, but it requires at least a MaxMind account plus a paid
subscription to use as a hosted API — there's no keyless or fully-free way to query
it as a web service. Their free GeoLite2 databases are download-only files, not
something you can call over HTTP, and using one would mean bundling a large binary
database in the app plus a third-party parser. ipapi.co avoids all of that.)

The networking layer is isolated behind the `IPLocationFetching` protocol
(`Services/IPLocationService.swift`), so switching providers later — MaxMind
included, if you get an account — is a matter of adding a new type conforming to
that protocol and passing it into `IPLocatorViewModel(service:)` in
`ContentView.swift`, without touching any UI code.

## Project structure

```
IPLocatorForTVOS/
  IPLocatorForTVOSApp.swift      App entry point
  ContentView.swift              Screen states + view model
  Models/IPLocationInfo.swift    Provider-agnostic location model
  Services/IPLocationService.swift    Network call (ipapi.co)
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
