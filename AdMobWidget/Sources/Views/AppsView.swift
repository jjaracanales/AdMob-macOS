import SwiftUI
import AppKit

/// Per-app earnings breakdown view with compact chart
struct AppsView: View {
    @ObservedObject var api: AdMobAPIService
    @ObservedObject var localization: LocalizationService
    @Binding var showApps: Bool

    private var sortedApps: [AppEarnings] {
        api.apps.sorted { $0.thisMonth > $1.thisMonth }
    }

    private var maxMonthEarnings: Double {
        sortedApps.map(\.thisMonth).max() ?? 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Button {
                    showApps = false
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.subheadline.bold())
                }
                .buttonStyle(.borderless)

                Text(L10n.appBreakdown)
                    .font(.headline)
                Spacer()

                if api.isLoading {
                    ProgressView()
                        .scaleEffect(0.6)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Divider()

            if sortedApps.isEmpty {
                emptyState
            } else {
                // Compact bar chart (top 3 only)
                compactChart
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)

                Divider()

                // Full app list
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(Array(sortedApps.enumerated()), id: \.element.id) { index, app in
                            appRow(app, rank: index + 1)
                            if index < sortedApps.count - 1 {
                                Divider().padding(.horizontal, 16)
                            }
                        }
                    }
                }
                .frame(maxHeight: 400)
            }

            Divider()

            // Open AdMob
            Button {
                if let url = URL(string: "https://admob.google.com/v2/home") {
                    NSWorkspace.shared.open(url)
                }
            } label: {
                HStack {
                    Image(systemName: "safari.fill")
                        .foregroundColor(.blue)
                        .frame(width: 20)
                    Text(L10n.openAdMob)
                        .font(.subheadline)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.borderless)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .frame(width: 320)
    }

    // MARK: - Compact Chart (3 bars max)

    private var compactChart: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(L10n.topApps)
                .font(.caption2.bold())
                .foregroundColor(.secondary)

            let top = Array(sortedApps.prefix(3))
            ForEach(top) { app in
                HStack(spacing: 6) {
                    platformIcon(app.platform)
                        .frame(width: 12)

                    Text(app.name)
                        .font(.caption2)
                        .lineLimit(1)
                        .frame(width: 70, alignment: .leading)

                    GeometryReader { geo in
                        let w = maxMonthEarnings > 0
                            ? CGFloat(app.thisMonth / maxMonthEarnings) * geo.size.width
                            : 0
                        RoundedRectangle(cornerRadius: 2)
                            .fill(barColor(for: app.platform))
                            .frame(width: max(w, 3), height: 10)
                    }
                    .frame(height: 10)

                    Text(String(format: "USD%.2f", app.thisMonth))
                        .font(.caption2.monospacedDigit())
                        .frame(width: 60, alignment: .trailing)
                }
                .frame(height: 16)
            }
        }
    }

    // MARK: - App Row

    private func appRow(_ app: AppEarnings, rank: Int) -> some View {
        HStack(spacing: 8) {
            Text("#\(rank)")
                .font(.caption2.bold())
                .foregroundColor(.secondary)
                .frame(width: 18)
            platformIcon(app.platform)
                .frame(width: 14)

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(app.name)
                        .font(.subheadline.bold())
                        .lineLimit(1)
                    Spacer()
                    platformBadge(app.platform)
                }
                HStack(spacing: 14) {
                    miniStat(L10n.today, app.today, bold: true)
                    miniStat(L10n.yesterday, app.yesterday, bold: false)
                    miniStat(L10n.thisMonth, app.thisMonth, bold: false)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - Helpers

    private func platformIcon(_ platform: String) -> some View {
        Group {
            if platform == "iOS" {
                Image(systemName: "apple.logo")
                    .foregroundColor(.gray)
            } else {
                Image(systemName: "play.rectangle.fill")
                    .foregroundColor(.green)
            }
        }
        .font(.caption2)
    }

    private func platformBadge(_ platform: String) -> some View {
        Text(platform)
            .font(.caption2.bold())
            .foregroundColor(platform == "iOS" ? .gray : .green)
            .padding(.horizontal, 5)
            .padding(.vertical, 1)
            .background(
                RoundedRectangle(cornerRadius: 3)
                    .fill((platform == "iOS" ? Color.gray : Color.green).opacity(0.12))
            )
    }

    private func barColor(for platform: String) -> LinearGradient {
        platform == "iOS"
            ? LinearGradient(colors: [.blue, .cyan], startPoint: .leading, endPoint: .trailing)
            : LinearGradient(colors: [.green, .mint], startPoint: .leading, endPoint: .trailing)
    }

    private func miniStat(_ label: String, _ value: Double, bold: Bool) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.secondary)
            Text(String(format: "USD%.2f", value))
                .font(.caption2.monospacedDigit())
                .fontWeight(bold ? .bold : .regular)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "app.dashed")
                .font(.system(size: 28))
                .foregroundColor(.secondary)
            Text(L10n.noAppsFound)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}
