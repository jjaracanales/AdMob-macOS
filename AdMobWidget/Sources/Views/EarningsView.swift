import SwiftUI
import AppKit

/// Main earnings display shown in the menu bar dropdown
struct EarningsView: View {
    @ObservedObject var api: AdMobAPIService
    @ObservedObject var auth: GoogleAuthService
    @ObservedObject var localization: LocalizationService
    @ObservedObject var launchAtLogin: LaunchAtLoginService
    @ObservedObject var notchService: NotchService
    let onRefresh: () -> Void

    @State private var showSettings = false
    @State private var showApps = false

    var body: some View {
        if showSettings {
            SettingsView(
                auth: auth,
                localization: localization,
                launchAtLogin: launchAtLogin,
                notchService: notchService,
                showSettings: $showSettings
            )
        } else if showApps {
            AppsView(
                api: api,
                localization: localization,
                showApps: $showApps
            )
        } else {
            earningsContent
        }
    }

    private var earningsContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            headerView

            Divider()

            // Today highlight card
            todayCard

            Divider()

            // Other earnings
            VStack(spacing: 0) {
                earningsRow(
                    label: L10n.yesterday,
                    value: api.earnings.formatted(api.earnings.yesterday),
                    icon: "moon.fill",
                    color: .indigo
                )
                Divider().padding(.horizontal, 16)
                earningsRow(
                    label: L10n.last7Days,
                    value: api.earnings.formatted(api.earnings.last7Days),
                    icon: "calendar",
                    color: .blue
                )
                Divider().padding(.horizontal, 16)
                earningsRow(
                    label: L10n.thisMonth,
                    value: api.earnings.formatted(api.earnings.thisMonth),
                    icon: "calendar.circle.fill",
                    color: .green
                )
            }

            Divider()

            // Quick actions
            HStack(spacing: 12) {
                // Per-app breakdown
                actionButton(icon: "square.grid.2x2.fill", label: L10n.apps) {
                    showApps = true
                }

                // Open AdMob
                actionButton(icon: "safari.fill", label: L10n.openAdMob) {
                    if let url = URL(string: "https://admob.google.com/v2/home") {
                        NSWorkspace.shared.open(url)
                    }
                }

                // Refresh
                actionButton(icon: "arrow.clockwise", label: L10n.refresh) {
                    onRefresh()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider()

            // Footer
            footerView
        }
        .frame(width: 300)
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Image(systemName: "dollarsign.circle.fill")
                .font(.title3)
                .foregroundColor(.green)
            Text(L10n.earningsTitle)
                .font(.headline)
            Spacer()
            if api.isLoading {
                ProgressView()
                    .scaleEffect(0.6)
            }
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.borderless)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    // MARK: - Today highlight

    private var todayCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "sun.max.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    Text(L10n.today)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Text(api.earnings.formatted(api.earnings.today))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .monospacedDigit()
            }
            Spacer()
            // Trend indicator
            if api.earnings.yesterday > 0 {
                let diff = api.earnings.today - api.earnings.yesterday
                let pct = (diff / api.earnings.yesterday) * 100
                VStack(alignment: .trailing, spacing: 2) {
                    Image(systemName: diff >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.title3)
                        .foregroundColor(diff >= 0 ? .green : .red)
                    Text(String(format: "%+.1f%%", pct))
                        .font(.caption.monospacedDigit())
                        .foregroundColor(diff >= 0 ? .green : .red)
                    Text(L10n.vsYesterday)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.accentColor.opacity(0.05))
                .padding(.horizontal, 8)
        )
    }

    // MARK: - Earnings row

    private func earningsRow(label: String, value: String, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.monospacedDigit().bold())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - Action buttons

    private func actionButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.subheadline)
                Text(label)
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
        .buttonStyle(.borderless)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.secondary.opacity(0.1))
        )
    }

    // MARK: - Footer

    private var footerView: some View {
        VStack(spacing: 4) {
            HStack {
                if let error = api.error {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.yellow)
                        .font(.caption2)
                    Text(error)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                } else {
                    Text("\(L10n.updated): \(api.earnings.lastUpdated.formatted(date: .omitted, time: .shortened))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }

            // Powered by Plutonia
            Button {
                if let url = URL(string: "https://www.plutonia.cl") {
                    NSWorkspace.shared.open(url)
                }
            } label: {
                HStack(spacing: 3) {
                    Text(L10n.poweredBy)
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.6))
                    Text("Plutonia")
                        .font(.caption2.bold())
                        .foregroundColor(.accentColor.opacity(0.7))
                }
            }
            .buttonStyle(.borderless)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}
