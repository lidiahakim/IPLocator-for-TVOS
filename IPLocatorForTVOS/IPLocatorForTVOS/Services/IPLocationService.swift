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
/// Uses ipwho.is — a keyless, HTTPS JSON API — as the data source. No account or
/// API key is required. (ipapi.co was tried first, but returns HTTP 403 on VPN
/// exit IPs — either from its free-tier daily quota being shared across everyone
/// using that same exit IP, or from it deliberately blocking known VPN/proxy IP
/// ranges. MaxMind's GeoIP2 web service was tried before that, but it requires at
/// least a MaxMind account plus a paid subscription to use as a hosted API.)
struct IPLocationService: IPLocationFetching {
    private let endpoint = URL(string: "https://ipwho.is/")!
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

        do {
            let decoded = try decoder.decode(IPWhoIsResponse.self, from: data)

            // ipwho.is always answers with HTTP 200, even on failure — the real
            // success/failure signal is the "success" field in the body, with the
            // reason in "message".
            guard decoded.success else {
                throw IPLocationError.server(decoded.message ?? "Unable to determine your location.")
            }

            return IPLocationInfo(
                ip: decoded.ip ?? "Unknown",
                city: decoded.city,
                region: decoded.region,
                countryName: decoded.country,
                countryCode: decoded.countryCode,
                org: decoded.connection?.isp ?? decoded.connection?.org,
                timezone: decoded.timezone?.id
            )
        } catch let error as IPLocationError {
            throw error
        } catch {
            throw IPLocationError.invalidResponse(status: statusCode, body: String(decoding: data, as: UTF8.self))
        }
    }
}

// MARK: - ipwho.is response shape

private struct IPWhoIsResponse: Decodable {
    let ip: String?
    let success: Bool
    let message: String?
    let city: String?
    let region: String?
    let country: String?
    let countryCode: String?
    let connection: Connection?
    let timezone: Timezone?

    enum CodingKeys: String, CodingKey {
        case ip
        case success
        case message
        case city
        case region
        case country
        case countryCode = "country_code"
        case connection
        case timezone
    }

    struct Connection: Decodable {
        let isp: String?
        let org: String?
    }

    struct Timezone: Decodable {
        let id: String?
    }
}
