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
/// Uses ipapi.co — a keyless, HTTPS JSON API — as the data source. `iplocation.io` does not
/// publish a documented public API for third-party apps, so this service is written behind
/// the `IPLocationFetching` protocol: swap in a different implementation (e.g. one backed by
/// an iplocation.io API key) without touching the UI layer.
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

        if let errorPayload = try? decoder.decode(IPLocationErrorPayload.self, from: data),
           errorPayload.error == true {
            throw IPLocationError.server(errorPayload.reason ?? "Unable to determine your location.")
        }

        do {
            return try decoder.decode(IPLocationInfo.self, from: data)
        } catch {
            throw IPLocationError.invalidResponse
        }
    }
}
