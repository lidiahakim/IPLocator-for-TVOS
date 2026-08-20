import Foundation

enum IPLocationError: LocalizedError {
    case missingCredentials
    case invalidResponse
    case server(String)

    var errorDescription: String? {
        switch self {
        case .missingCredentials:
            return "Add your MaxMind account ID and license key in MaxMindCredentials.swift."
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

/// Looks up the device's public IP address and geolocation using MaxMind's
/// GeoIP2 web service (a paid, account-based API — see MaxMindCredentials.swift
/// for where to add your credentials).
///
/// Requesting the special IP value "me" tells MaxMind to look up whatever
/// address the request itself came from, so no separate "what's my IP" call
/// is needed first.
struct IPLocationService: IPLocationFetching {
    private let endpoint = URL(string: "https://geoip.maxmind.com/geoip/v2.1/city/me")!
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchCurrentLocation() async throws -> IPLocationInfo {
        guard !MaxMindCredentials.accountID.isEmpty, !MaxMindCredentials.licenseKey.isEmpty else {
            throw IPLocationError.missingCredentials
        }

        var request = URLRequest(url: endpoint)
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let credentials = "\(MaxMindCredentials.accountID):\(MaxMindCredentials.licenseKey)"
        let credentialsData = Data(credentials.utf8)
        request.setValue("Basic \(credentialsData.base64EncodedString())", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw IPLocationError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorPayload = try? JSONDecoder().decode(MaxMindErrorPayload.self, from: data) {
                throw IPLocationError.server(errorPayload.error)
            }
            throw IPLocationError.invalidResponse
        }

        do {
            let decoded = try JSONDecoder().decode(MaxMindCityResponse.self, from: data)
            return IPLocationInfo(
                ip: decoded.traits?.ipAddress ?? "Unknown",
                city: decoded.city?.names?.en,
                region: decoded.subdivisions?.first?.names?.en,
                countryName: decoded.country?.names?.en,
                countryCode: decoded.country?.isoCode,
                org: nil,
                timezone: decoded.location?.timeZone
            )
        } catch {
            throw IPLocationError.invalidResponse
        }
    }
}

// MARK: - MaxMind GeoIP2 City response shape

private struct MaxMindErrorPayload: Decodable {
    let code: String
    let error: String
}

private struct MaxMindLocalizedNames: Decodable {
    let en: String?
}

private struct MaxMindCityResponse: Decodable {
    struct City: Decodable {
        let names: MaxMindLocalizedNames?
    }

    struct Country: Decodable {
        let isoCode: String?
        let names: MaxMindLocalizedNames?

        enum CodingKeys: String, CodingKey {
            case isoCode = "iso_code"
            case names
        }
    }

    struct Subdivision: Decodable {
        let names: MaxMindLocalizedNames?
    }

    struct Location: Decodable {
        let timeZone: String?

        enum CodingKeys: String, CodingKey {
            case timeZone = "time_zone"
        }
    }

    struct Traits: Decodable {
        let ipAddress: String?

        enum CodingKeys: String, CodingKey {
            case ipAddress = "ip_address"
        }
    }

    let city: City?
    let country: Country?
    let subdivisions: [Subdivision]?
    let location: Location?
    let traits: Traits?
}
