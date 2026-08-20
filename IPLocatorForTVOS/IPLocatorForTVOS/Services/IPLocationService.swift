import Foundation

enum IPLocationError: LocalizedError {
    case invalidResponse
    case server(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "The location service returned an unexpected response."
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
/// Uses ipapi.co — a keyless, HTTPS JSON API — as the data source. No account or
/// API key is required. (MaxMind's GeoIP2 web service was tried first, but it
/// requires at least a MaxMind account plus a paid subscription to use as a
/// hosted API, unlike this.)
struct IPLocationService: IPLocationFetching {
    private let endpoint = URL(string: "https://ipapi.co/json/")!
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchCurrentLocation() async throws -> IPLocationInfo {
        var request = URLRequest(url: endpoint)
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw IPLocationError.invalidResponse
        }

        let decoder = JSONDecoder()

        if let errorPayload = try? decoder.decode(IPAPIErrorPayload.self, from: data),
           errorPayload.error == true {
            throw IPLocationError.server(errorPayload.reason ?? "Unable to determine your location.")
        }

        do {
            let decoded = try decoder.decode(IPAPIResponse.self, from: data)
            return IPLocationInfo(
                ip: decoded.ip,
                city: decoded.city,
                region: decoded.region,
                countryName: decoded.countryName,
                countryCode: decoded.countryCode,
                org: decoded.org,
                timezone: decoded.timezone
            )
        } catch {
            throw IPLocationError.invalidResponse
        }
    }
}

// MARK: - ipapi.co response shape

private struct IPAPIErrorPayload: Decodable {
    let error: Bool?
    let reason: String?
}

private struct IPAPIResponse: Decodable {
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
}
