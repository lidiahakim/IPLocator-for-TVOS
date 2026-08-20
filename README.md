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

`Assets.xcassets/Brand Assets.brandassets` contains a custom icon: a translucent
glass location pin with photographed-glass-sphere shading, a glowing "landing"
ellipse, sitting above a pinpointed location. Structure:

- `App Icon.imagestack` (400×240, home screen) — the artwork is on the **Back**
  layer; **Front** and **Middle** are present but empty, so it currently renders
  flat rather than with true parallax depth.
- `App Icon - App Store.imageset` (1280×768) — a plain flat image, no layering.

An earlier attempt at this (naming the catalog `App Icon & Top Shelf Image` and
wrapping the App Store icon in its own layered image-stack) failed Xcode's asset
validation. This version corrects both: the catalog is named `Brand Assets` to match
what Xcode's own icon generator actually names it, and the App Store icon is a plain
image set rather than a layered stack. It has **not been confirmed working in a real
Xcode build yet** — if you hit any asset-catalog errors, tell me the exact error text
and I'll fix it, or fall back to letting Xcode generate the icon slots itself
(**Assets.xcassets → right-click → New tvOS App Icon**) and dragging in the PNGs from
the `IconSource/` folder at the repo root.

A Top Shelf Image (shown when the app is focused on the home screen) isn't included
yet — not required to build/run, only for App Store submission.

## Notes

- Deployment target: tvOS 16.0.
