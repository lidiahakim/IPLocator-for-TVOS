import Foundation

/// The device's public IP address and geolocation, mapped from whichever
/// provider `IPLocationFetching` is backed by.
struct IPLocationInfo: Equatable {
    let ip: String
    let city: String?
    let region: String?
    let countryName: String?
    let countryCode: String?
    let org: String?
    let timezone: String?

    /// A human-readable "City, Region, Country" label, skipping any missing parts.
    var locationName: String {
        [city, region, countryName]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }
}
