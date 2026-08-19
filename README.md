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

You asked for the app to use `iplocation.io`'s database. That site doesn't publish
a documented public API for third-party apps to call (no API-key signup, no
request/response schema), so it isn't something an app can safely integrate
against. Instead, `IPLocationService.swift` calls **[ipapi.co](https://ipapi.co)**
— a free, keyless, HTTPS JSON API with the exact fields this UI needs (IP, city,
region, country name/code, ISP, timezone).

The networking layer is isolated behind the `IPLocationFetching` protocol
(`Services/IPLocationService.swift`), so if you have an API key or a specific
documented endpoint for `iplocation.io` (or any other provider), you can add a new
type conforming to that protocol and pass it into `IPLocatorViewModel(service:)`
in `ContentView.swift` without touching any UI code.

## Project structure

```
IPLocatorForTVOS/
  IPLocatorForTVOSApp.swift      App entry point
  ContentView.swift              Screen states + view model
  Models/IPLocationInfo.swift    Decoded API response
  Services/IPLocationService.swift  Network call (ipapi.co)
  Utilities/CountryFlag.swift    Country code -> flag emoji
  Views/BackgroundView.swift     Gradient background
  Views/LocationCardView.swift   Glass card showing flag/IP/location
```

## App icon

`Assets.xcassets/AppIcon.appiconset` contains a custom icon: a location pin holding
a globe/latitude-longitude grid, with broadcasting signal arcs, on a navy-to-purple
gradient matching the in-app UI. It's provided as a flat (non-parallax) tvOS icon at
the two required sizes (400×240 and 1280×768, @1x/@2x).

For App Store submission, Apple additionally requires a **layered** icon (separate
front/middle/back images for the parallax effect) and a **Top Shelf Image** — neither
is included here since they need Xcode's icon composer / real design tooling. For
development and TestFlight-style local testing, the flat icon above is picked up
automatically (`ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon`).

## Notes

- Deployment target: tvOS 16.0.
