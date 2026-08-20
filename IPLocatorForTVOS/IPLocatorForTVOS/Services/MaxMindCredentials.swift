import Foundation

/// Your MaxMind GeoIP2 web service credentials.
///
/// 1. Sign up at https://www.maxmind.com and subscribe to a GeoIP2 Precision
///    web service (City or above — the free GeoLite2 databases are download-only
///    and don't offer a hosted web service).
/// 2. Under your account, open "Manage License Keys" and generate a key.
/// 3. Fill in your account ID (a number, shown on your account page) and that
///    license key below.
///
/// These are secrets. If this repository is ever made public, replace them
/// with placeholders and pass real values another way (e.g. an untracked
/// config file, environment-specific build settings, or a secrets manager) —
/// don't leave a real license key in version control.
enum MaxMindCredentials {
    static let accountID = ""
    static let licenseKey = ""
}
