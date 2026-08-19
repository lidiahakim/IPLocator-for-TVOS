import Foundation

/// Decoded response from the IP geolocation service.
struct IPLocationInfo: Decodable, Equatable {
    let ip: String
    let city: String?
    let region: String?
    let countryName: String?
    let countryCode: String?
    let org: String?
    let timezone: String?

    enum CodingKeys: String, CodingKey {
        case ip
        case city
        case region
        case countryName = "country_name"
        case countryCode = "country_code"
        case org
        case timezone
    }

    /// A human-readable "City, Region, Country" label, skipping any missing parts.
    var locationName: String {
        [city, region, countryName]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }
}

/// Error payload the API returns instead of a location when it can't resolve the request.
struct IPLocationErrorPayload: Decodable {
    let error: Bool?
    let reason: String?
}
