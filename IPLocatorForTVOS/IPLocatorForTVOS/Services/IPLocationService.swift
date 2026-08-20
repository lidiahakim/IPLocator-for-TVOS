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
/// Uses DB-IP's free API — a keyless, HTTPS JSON API backed by DB-IP's own
/// geolocation database — as the data source. No account or API key is
/// required (the literal path segment "free" stands in for an API key). It's
/// rate-limited for evaluation use rather than meant for high-volume traffic,
/// but that fits an app that only looks itself up on demand.
///
/// (ipwho.is was tried before this. MaxMind's GeoIP2 web service was tried
/// before that, but it requires at least a MaxMind account plus a paid
/// subscription to use as a hosted API. ipapi.co was tried before that, but
/// returns HTTP 403 on VPN exit IPs — either its free-tier daily quota being
/// exhausted by everyone sharing that same exit IP, or it deliberately
/// blocking known VPN/proxy IP ranges.)
struct IPLocationService: IPLocationFetching {
    private let endpoint = URL(string: "https://api.db-ip.com/v2/free/self")!
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

        // Check for DB-IP's own error payload before the HTTP status code:
        // rate-limit responses can come back with a helpful reason in the
        // body, and checking the status first would discard that reason in
        // favor of a generic, undiagnosable message.
        if let errorPayload = try? decoder.decode(DBIPErrorPayload.self, from: data),
           let reason = errorPayload.error {
            throw IPLocationError.server(reason)
        }

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw IPLocationError.invalidResponse(status: statusCode, body: String(decoding: data, as: UTF8.self))
        }

        do {
            let decoded = try decoder.decode(DBIPResponse.self, from: data)
            return IPLocationInfo(
                ip: decoded.ipAddress,
                city: decoded.city,
                region: decoded.stateProv,
                countryName: decoded.countryName,
                countryCode: decoded.countryCode,
                org: nil,
                timezone: decoded.timeZone
            )
        } catch {
            throw IPLocationError.invalidResponse(status: statusCode, body: String(decoding: data, as: UTF8.self))
        }
    }
}

// MARK: - DB-IP response shape

private struct DBIPErrorPayload: Decodable {
    let error: String?
}

private struct DBIPResponse: Decodable {
    let ipAddress: String
    let city: String?
    let stateProv: String?
    let countryName: String?
    let countryCode: String?
    let timeZone: String?
}
