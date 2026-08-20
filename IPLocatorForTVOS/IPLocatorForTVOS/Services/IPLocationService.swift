import Foundation

enum IPLocationError: LocalizedError {
    case invalidResponse(status: Int, body: String)
    case server(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse(let status, let body):
            let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
            let snippet = trimmed.isEmpty ? "empty body" : String(trimmed.prefix(300))
            return "Unexpected response (HTTP \(status)): \(snippet)"
        case .server(let reason):
            return reason
        }
    }
}

protocol IPLocationFetching {
    func fetchCurrentLocation() async throws -> IPLocationInfo
}

/// Looks up the device's public IP address and geolocation.
///
/// Uses GeoJS — a free, keyless, HTTPS JSON API — as the data source. No
/// account or API key is required. GeoJS's own geolocation data is sourced
/// from MaxMind's GeoLite2 database, which is the closest free, accountless
/// approximation of using MaxMind directly.
///
/// (DB-IP's free API was tried before this, but flags frequent/VPN-like
/// callers as abuse and pushes a paid plan. ipwho.is was tried before that.
/// MaxMind's GeoIP2 web service was tried before that, but it requires at
/// least a MaxMind account plus a paid subscription to use as a hosted API.
/// ipapi.co was tried before that, but returns HTTP 403 on VPN exit IPs.
///
/// None of these -- MaxMind included -- can be guaranteed correct for every
/// VPN exit IP: geolocation databases are independently maintained per
/// provider and can be stale or wrong for a specific IP block regardless of
/// source.)
struct IPLocationService: IPLocationFetching {
    private let endpoint = URL(string: "https://get.geojs.io/v1/ip/geo.json")!
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchCurrentLocation() async throws -> IPLocationInfo {
        var request = URLRequest(url: endpoint)
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)
        let decoder = JSONDecoder()
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw IPLocationError.invalidResponse(status: statusCode, body: String(decoding: data, as: UTF8.self))
        }

        do {
            let decoded = try decoder.decode(GeoJSResponse.self, from: data)
            return IPLocationInfo(
                ip: decoded.ip,
                city: decoded.city,
                region: decoded.region,
                countryName: decoded.country,
                countryCode: decoded.countryCode,
                org: decoded.organizationName,
                timezone: decoded.timezone
            )
        } catch {
            throw IPLocationError.invalidResponse(status: statusCode, body: String(decoding: data, as: UTF8.self))
        }
    }
}

// MARK: - GeoJS response shape

private struct GeoJSResponse: Decodable {
    let ip: String
    let city: String?
    let region: String?
    let country: String?
    let countryCode: String?
    let timezone: String?
    let organizationName: String?

    enum CodingKeys: String, CodingKey {
        case ip
        case city
        case region
        case country
        case countryCode = "country_code"
        case timezone
        case organizationName = "organization_name"
    }
}
