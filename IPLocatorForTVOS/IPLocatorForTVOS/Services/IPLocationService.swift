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
        let decoder = JSONDecoder()
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1

        // Check for ipapi.co's own error payload before the HTTP status code:
        // rate-limit and quota errors can come back as a non-2xx status (e.g. 429)
        // *with* a helpful reason in the body, and checking the status first would
        // discard that reason in favor of a generic, undiagnosable message.
        if let errorPayload = try? decoder.decode(IPAPIErrorPayload.self, from: data),
           errorPayload.error == true {
            throw IPLocationError.server(errorPayload.reason ?? "Unable to determine your location.")
        }

        // Neither a 2xx status nor ipapi.co's known error shape — surface the raw
        // status and body (e.g. an HTML block page, or an unrecognized JSON error
        // shape) instead of a generic, undiagnosable message.
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw IPLocationError.invalidResponse(status: statusCode, body: String(decoding: data, as: UTF8.self))
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
            throw IPLocationError.invalidResponse(status: statusCode, body: String(decoding: data, as: UTF8.self))
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
