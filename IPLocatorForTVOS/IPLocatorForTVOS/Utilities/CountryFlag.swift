import Foundation

enum CountryFlag {
    /// Renders an ISO 3166-1 alpha-2 country code (e.g. "US") as its flag emoji
    /// by combining Unicode regional indicator symbols. Falls back to a plain
    /// white flag when the code is missing or malformed.
    static func emoji(for countryCode: String?) -> String {
        guard let code = countryCode?.uppercased(), code.count == 2,
              code.unicodeScalars.allSatisfy({ $0.isASCII && $0.properties.isAlphabetic }) else {
            return "🏳️"
        }

        let base: UInt32 = 127397
        var scalarView = String.UnicodeScalarView()
        for scalar in code.unicodeScalars {
            guard let flagScalar = Unicode.Scalar(base + scalar.value) else {
                return "🏳️"
            }
            scalarView.append(flagScalar)
        }
        return String(scalarView)
    }
}
