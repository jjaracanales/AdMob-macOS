import SwiftUI

@main
struct AdMobWidgetApp: App {
    @StateObject private var auth: GoogleAuthService
    @StateObject private var api: AdMobAPIService
    @ObservedObject private var localization = LocalizationService.shared
    @ObservedObject private var launchAtLogin = LaunchAtLoginService.shared
    @ObservedObject private var notchService = NotchService.shared
    @AppStorage("onboarding_completed") private var onboardingCompleted = false
    @AppStorage("refresh_interval_minutes") private var refreshIntervalMinutes = 60

    @State private var refreshTimer: Timer?

    init() {
        let authService = GoogleAuthService()
        _auth = StateObject(wrappedValue: authService)
        _api = StateObject(wrappedValue: AdMobAPIService(auth: authService))
    }

    var body: some Scene {
        MenuBarExtra {
            menuContent
        } label: {
            menuBarLabel
        }
        .menuBarExtraStyle(.window)
    }

    // MARK: - Menu bar icon + text

    private var menuBarLabel: some View {
        HStack(spacing: 4) {
            Image(systemName: "dollarsign.circle.fill")
            if auth.isAuthenticated && !api.isLoading {
                Text(api.earnings.formatted(api.earnings.today))
                    .monospacedDigit()
            }
        }
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
                // Update notch panel when earnings change
                notchService.updateEarnings(api.earnings)
            }
        } else {
            SetupView(auth: auth, localization: localization)
        }
    }

    // MARK: - Refresh logic

    private func refresh() {
        Task {
            await api.fetchEarnings()
            // Update notch with latest data
            notchService.updateEarnings(api.earnings)
        }
    }

    private func startPeriodicRefresh() {
        refreshTimer?.invalidate()
        let interval = TimeInterval(refreshIntervalMinutes * 60)
        refreshTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            refresh()
        }
    }
}
