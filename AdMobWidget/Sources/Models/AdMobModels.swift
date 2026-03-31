import Foundation

/// OAuth token pair stored in Keychain
struct OAuthTokens: Codable {
    var accessToken: String
    var refreshToken: String
    var expiresAt: Date

    var isExpired: Bool {
        Date() >= expiresAt
    }
}

/// OAuth client credentials from the user's Google API Console JSON
struct OAuthClientConfig: Codable {
    var clientId: String
    var clientSecret: String

    struct GoogleJSON: Codable {
        struct Installed: Codable {
            let client_id: String
            let client_secret: String
        }
        let installed: Installed
    }

    /// Parse from Google's downloaded client_secret JSON
    static func fromGoogleJSON(data: Data) throws -> OAuthClientConfig {
        let decoded = try JSONDecoder().decode(GoogleJSON.self, from: data)
        return OAuthClientConfig(
            clientId: decoded.installed.client_id,
            clientSecret: decoded.installed.client_secret
        )
    }
}

/// Revenue data from AdMob API
struct AdMobEarnings {
    var today: Double
    var yesterday: Double
    var thisMonth: Double
    var last7Days: Double
    var lastUpdated: Date
    var currency: String

    static let empty = AdMobEarnings(
        today: 0, yesterday: 0, thisMonth: 0,
        last7Days: 0, lastUpdated: Date(), currency: "USD"
    )

    func formatted(_ value: Double) -> String {
        String(format: "%@%.2f", currency == "USD" ? "USD" : currency + " ", value)
    }
}

/// Per-app earnings breakdown
struct AppEarnings: Identifiable {
    let id: String  // app ID (e.g. "ca-app-pub-XXX~XXX")
    var name: String
    var platform: String  // "Android" or "iOS"
    var today: Double
    var yesterday: Double
    var thisMonth: Double
    var last7Days: Double
}

/// AdMob API response structures
struct AdMobAccountResponse: Codable {
    let account: [AdMobAccount]?

    struct AdMobAccount: Codable {
        let name: String
        let publisherId: String?
        let currencyCode: String?
    }
}

struct AdMobReportResponse: Codable {
    let rows: [ReportRow]?

    struct ReportRow: Codable {
        let dimensionValues: [String: DimensionValue]?
        let metricValues: [String: MetricValue]?
    }

    struct DimensionValue: Codable {
        let value: String?
    }

    struct MetricValue: Codable {
        let microsValue: String?
        let integerValue: String?
    }
}
