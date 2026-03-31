import Foundation

/// Fetches earnings data from the Google AdMob API
@MainActor
class AdMobAPIService: ObservableObject {
    @Published var earnings: AdMobEarnings = .empty
    @Published var apps: [AppEarnings] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var accountId: String?

    private let auth: GoogleAuthService
    private let baseURL = "https://admob.googleapis.com/v1"

    init(auth: GoogleAuthService) {
        self.auth = auth
    }

    /// Fetch the AdMob account ID (needed for reports)
    func fetchAccountId() async throws -> String {
        if let existing = accountId { return existing }

        let token = try await auth.getAccessToken()
        var request = URLRequest(url: URL(string: "\(baseURL)/accounts")!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200
        else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw APIError.requestFailed("Account fetch failed: \(body)")
        }

        // Parse: { "account": [{ "name": "accounts/pub-XXXX", ... }] }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let accounts = json["account"] as? [[String: Any]],
              let first = accounts.first,
              let name = first["name"] as? String
        else {
            throw APIError.noAccount
        }

        accountId = name
        return name
    }

    /// Fetch all earnings data
    func fetchEarnings() async {
        isLoading = true
        error = nil

        do {
            let account = try await fetchAccountId()
            let calendar = Calendar.current
            let today = Date()
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
            let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: today)!
            let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

            // Fetch today's earnings
            let todayEarnings = try await fetchReport(
                account: account,
                startDate: today,
                endDate: today
            )

            // Fetch yesterday's earnings
            let yesterdayEarnings = try await fetchReport(
                account: account,
                startDate: yesterday,
                endDate: yesterday
            )

            // Fetch this month's earnings
            let monthEarnings = try await fetchReport(
                account: account,
                startDate: startOfMonth,
                endDate: today
            )

            // Fetch last 7 days earnings
            let weekEarnings = try await fetchReport(
                account: account,
                startDate: sevenDaysAgo,
                endDate: today
            )

            earnings = AdMobEarnings(
                today: todayEarnings,
                yesterday: yesterdayEarnings,
                thisMonth: monthEarnings,
                last7Days: weekEarnings,
                lastUpdated: Date(),
                currency: "USD"
            )

            // Fetch per-app breakdown
            let appsList = try await fetchApps(account: account)
            let perAppEarnings = try await fetchPerAppEarnings(
                account: account,
                appsList: appsList,
                today: today,
                yesterday: yesterday,
                startOfMonth: startOfMonth,
                sevenDaysAgo: sevenDaysAgo
            )
            apps = perAppEarnings

        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Per-App Data

    /// Fetches the list of apps registered in the AdMob account
    private func fetchApps(account: String) async throws -> [(appId: String, name: String, platform: String)] {
        let token = try await auth.getAccessToken()
        var request = URLRequest(url: URL(string: "\(baseURL)/\(account)/apps")!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200
        else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw APIError.requestFailed("Apps fetch failed: \(body)")
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let appsArray = json["apps"] as? [[String: Any]]
        else {
            return []
        }

        return appsArray.compactMap { app -> (appId: String, name: String, platform: String)? in
            guard let appId = app["appId"] as? String else { return nil }

            let platformRaw = app["platform"] as? String ?? "UNKNOWN"
            let platform: String
            switch platformRaw {
            case "ANDROID": platform = "Android"
            case "IOS": platform = "iOS"
            default: platform = platformRaw
            }

            var displayName = appId
            if let manualInfo = app["manualAppInfo"] as? [String: Any],
               let name = manualInfo["displayName"] as? String {
                displayName = name
            }

            return (appId: appId, name: displayName, platform: platform)
        }
    }

    /// Fetches per-app earnings for today, yesterday, this month, and last 7 days
    private func fetchPerAppEarnings(
        account: String,
        appsList: [(appId: String, name: String, platform: String)],
        today: Date,
        yesterday: Date,
        startOfMonth: Date,
        sevenDaysAgo: Date
    ) async throws -> [AppEarnings] {
        // Fetch per-app reports for each date range
        let todayByApp = try await fetchPerAppReport(account: account, startDate: today, endDate: today)
        let yesterdayByApp = try await fetchPerAppReport(account: account, startDate: yesterday, endDate: yesterday)
        let monthByApp = try await fetchPerAppReport(account: account, startDate: startOfMonth, endDate: today)
        let weekByApp = try await fetchPerAppReport(account: account, startDate: sevenDaysAgo, endDate: today)

        // Build AppEarnings for each known app
        return appsList.map { app in
            AppEarnings(
                id: app.appId,
                name: app.name,
                platform: app.platform,
                today: todayByApp[app.appId] ?? 0,
                yesterday: yesterdayByApp[app.appId] ?? 0,
                thisMonth: monthByApp[app.appId] ?? 0,
                last7Days: weekByApp[app.appId] ?? 0
            )
        }
    }

    /// Generate a network report with APP dimension and return a dictionary of appId -> earnings
    private func fetchPerAppReport(
        account: String,
        startDate: Date,
        endDate: Date
    ) async throws -> [String: Double] {
        let token = try await auth.getAccessToken()
        let url = URL(string: "\(baseURL)/\(account)/networkReport:generate")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.year, .month, .day], from: startDate)
        let endComponents = calendar.dateComponents([.year, .month, .day], from: endDate)

        let body: [String: Any] = [
            "report_spec": [
                "date_range": [
                    "start_date": [
                        "year": startComponents.year!,
                        "month": startComponents.month!,
                        "day": startComponents.day!,
                    ],
                    "end_date": [
                        "year": endComponents.year!,
                        "month": endComponents.month!,
                        "day": endComponents.day!,
                    ],
                ],
                "dimensions": ["APP"],
                "metrics": ["ESTIMATED_EARNINGS"],
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200
        else {
            let responseBody = String(data: data, encoding: .utf8) ?? ""
            throw APIError.requestFailed("Per-app report failed: \(responseBody)")
        }

        return parsePerAppEarnings(data: data)
    }

    /// Parse the per-app report response into a dictionary of appId -> earnings in dollars
    private func parsePerAppEarnings(data: Data) -> [String: Double] {
        let text = String(data: data, encoding: .utf8) ?? ""
        var result: [String: Double] = [:]

        func processRow(_ item: [String: Any]) {
            guard let row = item["row"] as? [String: Any],
                  let dimensionValues = row["dimensionValues"] as? [String: Any],
                  let appDim = dimensionValues["APP"] as? [String: Any],
                  let appId = appDim["value"] as? String,
                  let metricValues = row["metricValues"] as? [String: Any],
                  let earnings = metricValues["ESTIMATED_EARNINGS"] as? [String: Any],
                  let microsStr = earnings["microsValue"] as? String,
                  let micros = Int64(microsStr)
            else { return }

            let dollars = Double(micros) / 1_000_000.0
            result[appId, default: 0] += dollars
        }

        // Try parsing as JSON array first
        if let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            for item in jsonArray {
                processRow(item)
            }
        } else {
            // Try line-by-line parsing
            for line in text.components(separatedBy: "\n") {
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty,
                      let lineData = trimmed.data(using: .utf8),
                      let json = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any]
                else { continue }
                processRow(json)
            }
        }

        return result
    }

    /// Generate a network report for a date range and return total estimated earnings
    private func fetchReport(
        account: String,
        startDate: Date,
        endDate: Date
    ) async throws -> Double {
        let token = try await auth.getAccessToken()
        let url = URL(string: "\(baseURL)/\(account)/networkReport:generate")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.year, .month, .day], from: startDate)
        let endComponents = calendar.dateComponents([.year, .month, .day], from: endDate)

        let body: [String: Any] = [
            "report_spec": [
                "date_range": [
                    "start_date": [
                        "year": startComponents.year!,
                        "month": startComponents.month!,
                        "day": startComponents.day!,
                    ],
                    "end_date": [
                        "year": endComponents.year!,
                        "month": endComponents.month!,
                        "day": endComponents.day!,
                    ],
                ],
                "metrics": ["ESTIMATED_EARNINGS", "IMPRESSIONS", "CLICKS"],
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200
        else {
            let responseBody = String(data: data, encoding: .utf8) ?? ""
            throw APIError.requestFailed("Report failed: \(responseBody)")
        }

        return parseEarningsFromReport(data: data)
    }

    /// Parse the streaming JSON response from AdMob network report
    private func parseEarningsFromReport(data: Data) -> Double {
        // AdMob returns newline-separated JSON objects
        let text = String(data: data, encoding: .utf8) ?? ""
        var totalMicros: Int64 = 0

        // Try parsing as JSON array first
        if let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            for item in jsonArray {
                if let row = item["row"] as? [String: Any],
                   let metricValues = row["metricValues"] as? [String: Any],
                   let earnings = metricValues["ESTIMATED_EARNINGS"] as? [String: Any],
                   let microsStr = earnings["microsValue"] as? String,
                   let micros = Int64(microsStr) {
                    totalMicros += micros
                }
            }
        } else {
            // Try line-by-line parsing
            for line in text.components(separatedBy: "\n") {
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty,
                      let lineData = trimmed.data(using: .utf8),
                      let json = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any]
                else { continue }

                if let row = json["row"] as? [String: Any],
                   let metricValues = row["metricValues"] as? [String: Any],
                   let earnings = metricValues["ESTIMATED_EARNINGS"] as? [String: Any],
                   let microsStr = earnings["microsValue"] as? String,
                   let micros = Int64(microsStr) {
                    totalMicros += micros
                }
            }
        }

        // Convert micros to dollars
        return Double(totalMicros) / 1_000_000.0
    }
}

enum APIError: LocalizedError {
    case requestFailed(String)
    case noAccount

    var errorDescription: String? {
        switch self {
        case .requestFailed(let msg): return msg
        case .noAccount: return "No AdMob account found"
        }
    }
}
