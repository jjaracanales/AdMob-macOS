import SwiftUI

@main
struct AdMobWidgetApp: App {
    @StateObject private var auth: GoogleAuthService
    @StateObject private var api: AdMobAPIService
    @StateObject private var localization = LocalizationService.shared
    @StateObject private var launchAtLogin = LaunchAtLoginService.shared
    @StateObject private var notchService = NotchService.shared
    @AppStorage("onboarding_completed") private var onboardingCompleted = false
    @AppStorage("refresh_interval_minutes") private var refreshIntervalMinutes = 60

    /// Refresh timer managed outside @State to avoid fragility in App struct redraws.
    /// Using a nonisolated(unsafe) static so the timer reference is stable.
    nonisolated(unsafe) private static var refreshTimer: Timer?

    init() {
        let authService = GoogleAuthService()
        _auth = StateObject(wrappedValue: authService)
        _api = StateObject(wrappedValue: AdMobAPIService(auth: authService))
    }

    var body: some Scene {
        MenuBarExtra {
            menuContent
        } label: {
            HStack(spacing: 4) {
                Image("MenuBarIcon")
                if auth.isAuthenticated && !api.isLoading {
                    Text(api.earnings.formatted(api.earnings.today))
                        .monospacedDigit()
                }
            }
        }
        .menuBarExtraStyle(.window)
    }

    // MARK: - Dropdown content

    @ViewBuilder
    private var menuContent: some View {
        if !onboardingCompleted {
            OnboardingView(
                localization: localization,
                onboardingCompleted: $onboardingCompleted
            )
        } else if auth.isAuthenticated {
            EarningsView(
                api: api,
                auth: auth,
                localization: localization,
                launchAtLogin: launchAtLogin,
                notchService: notchService,
                onRefresh: refresh
            )
            .onAppear {
                startPeriodicRefresh()
                if api.earnings.lastUpdated == AdMobEarnings.empty.lastUpdated {
                    refresh()
                }
            }
            .onChange(of: refreshIntervalMinutes) {
                startPeriodicRefresh()
            }
            .onChange(of: api.earnings.today) {
                notchService.updateEarnings(api.earnings)
            }
        } else {
            SetupView(auth: auth, localization: localization)
        }
    }

    // MARK: - Refresh logic

    private func refresh() {
        Task { @MainActor [api, notchService] in
            await api.fetchEarnings()
            notchService.updateEarnings(api.earnings)
        }
    }

    private func startPeriodicRefresh() {
        Self.refreshTimer?.invalidate()
        let interval = TimeInterval(refreshIntervalMinutes * 60)
        Self.refreshTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak api, weak notchService] _ in
            Task { @MainActor in
                guard let api, let notchService else { return }
                await api.fetchEarnings()
                notchService.updateEarnings(api.earnings)
            }
        }
    }
}
