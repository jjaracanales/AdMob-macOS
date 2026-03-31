import SwiftUI
import AppKit

/// Settings panel accessible from the earnings view
struct SettingsView: View {
    @ObservedObject var auth: GoogleAuthService
    @ObservedObject var localization: LocalizationService
    @ObservedObject var launchAtLogin: LaunchAtLoginService
    @ObservedObject var notchService: NotchService
    @AppStorage("refresh_interval_minutes") var refreshInterval: Int = 60
    @AppStorage("onboarding_completed") var onboardingCompleted: Bool = true
    @Binding var showSettings: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Button {
                    showSettings = false
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.subheadline.bold())
                }
                .buttonStyle(.borderless)

                Text(L10n.settings)
                    .font(.headline)
                Spacer()

                Text("v1.0.0")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Divider()

            // Settings list
            VStack(spacing: 2) {
                // Launch at Login
                settingsToggle(
                    icon: "power.circle.fill",
                    color: .green,
                    label: L10n.launchAtLogin,
                    isOn: $launchAtLogin.isEnabled
                )

                Divider().padding(.horizontal, 16)

                // Notch mode
                settingsToggle(
                    icon: "rectangle.topthird.inset.filled",
                    color: .purple,
                    label: L10n.notchMode,
                    isOn: $notchService.isEnabled
                )

                Divider().padding(.horizontal, 16)

                // Refresh interval
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(.blue)
                        .frame(width: 20)
                    Text(L10n.refreshInterval)
                        .font(.subheadline)
                    Spacer()
                    Picker("", selection: $refreshInterval) {
                        Text("15 min").tag(15)
                        Text("30 min").tag(30)
                        Text("1 hr").tag(60)
                        Text("2 hr").tag(120)
                    }
                    .labelsHidden()
                    .frame(width: 80)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                Divider().padding(.horizontal, 16)

                // Language
                HStack {
                    Image(systemName: "globe")
                        .foregroundColor(.purple)
                        .frame(width: 20)
                    Text(L10n.language)
                        .font(.subheadline)
                    Spacer()
                    Picker("", selection: $localization.currentLanguage) {
                        ForEach(AppLanguage.allCases) { lang in
                            Text(lang.displayName).tag(lang)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 110)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                Divider().padding(.horizontal, 16)

                // Replay onboarding
                Button {
                    onboardingCompleted = false
                    showSettings = false
                } label: {
                    HStack {
                        Image(systemName: "questionmark.circle.fill")
                            .foregroundColor(.orange)
                            .frame(width: 20)
                        Text(L10n.replayOnboarding)
                            .font(.subheadline)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.borderless)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }

            Divider()

            // Buy Me a Coffee
            Button {
                if let url = URL(string: "https://buymeacoffee.com/jjaracanales") {
                    NSWorkspace.shared.open(url)
                }
            } label: {
                HStack(spacing: 8) {
                    Image("BMCIcon")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .clipShape(Circle())
                    Text(L10n.buyCoffee)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.borderless)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            // GitHub
            Button {
                if let url = URL(string: "https://github.com/jjaracanales/AdMob-macOS") {
                    NSWorkspace.shared.open(url)
                }
            } label: {
                HStack {
                    Image(systemName: "curlybraces")
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                    Text("GitHub")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.borderless)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            Divider()

            // Sign Out
            Button {
                auth.signOut()
                showSettings = false
            } label: {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .foregroundColor(.red)
                        .frame(width: 20)
                    Text(L10n.signOut)
                        .font(.subheadline)
                        .foregroundColor(.red)
                }
            }
            .buttonStyle(.borderless)
            .padding(.horizontal, 16)
            .padding(.vertical, 6)

            // Quit
            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                HStack {
                    Image(systemName: "xmark.circle")
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                    Text(L10n.quit)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.borderless)
            .padding(.horizontal, 16)
            .padding(.vertical, 6)

            Divider()

            // Powered by Plutonia
            Button {
                if let url = URL(string: "https://www.plutonia.cl") {
                    NSWorkspace.shared.open(url)
                }
            } label: {
                HStack {
                    Spacer()
                    Text(L10n.poweredBy)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("Plutonia")
                        .font(.caption2.bold())
                        .foregroundColor(.accentColor)
                    Spacer()
                }
            }
            .buttonStyle(.borderless)
            .padding(.vertical, 8)
            .padding(.bottom, 4)
        }
        .frame(width: 280)
    }

    private func settingsToggle(icon: String, color: Color, label: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            Text(label)
                .font(.subheadline)
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.small)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}
