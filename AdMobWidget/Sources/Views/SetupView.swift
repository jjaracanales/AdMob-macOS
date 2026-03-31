import SwiftUI
import AppKit
import UniformTypeIdentifiers

/// First-time setup: import Google OAuth credentials and authenticate
struct SetupView: View {
    @ObservedObject var auth: GoogleAuthService
    @ObservedObject var localization: LocalizationService
    @State private var authCode = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(L10n.setupTitle)
                    .font(.headline)
                Spacer()
                languagePicker
            }

            if !auth.hasClientConfig {
                step1ConfigView
            } else if !auth.isAuthenticated {
                step2AuthView
            }

            if let error = auth.error {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .lineLimit(3)
            }
        }
        .padding(20)
        .frame(width: 420)
    }

    // MARK: - Language picker

    private var languagePicker: some View {
        Menu {
            ForEach(AppLanguage.allCases) { lang in
                Button {
                    localization.currentLanguage = lang
                } label: {
                    HStack {
                        Text(lang.displayName)
                        if localization.currentLanguage == lang {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "globe")
                .font(.subheadline)
        }
        .menuStyle(.borderlessButton)
        .frame(width: 30)
    }

    // MARK: - Step 1: Import client_secret.json

    private var step1ConfigView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(L10n.step1Title, systemImage: "1.circle.fill")
                .font(.subheadline.bold())

            Text(L10n.step1Description)
                .font(.caption)
                .foregroundColor(.secondary)

            Button(L10n.selectFile) {
                openFilePicker()
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private func openFilePicker() {
        // Ensure we run on the main thread (NSOpenPanel requires it)
        DispatchQueue.main.async {
            let panel = NSOpenPanel()
            panel.allowedContentTypes = [UTType.json, UTType.data, UTType.plainText]
            panel.allowsMultipleSelection = false
            panel.canChooseDirectories = false
            panel.title = L10n.selectFile
            panel.level = .floating
            panel.treatsFilePackagesAsDirectories = true

            guard panel.runModal() == .OK, let url = panel.url else { return }

            // Security-scoped resource access for sandboxed apps
            let didAccess = url.startAccessingSecurityScopedResource()
            defer {
                if didAccess { url.stopAccessingSecurityScopedResource() }
            }

            do {
                try auth.importClientSecret(from: url)
            } catch {
                print("[SetupView] Failed to import client_secret.json: \(error)")
                auth.error = "\(L10n.invalidJSON): \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Step 2: OAuth login

    private var step2AuthView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(L10n.step2Title, systemImage: "2.circle.fill")
                .font(.subheadline.bold())

            Text(L10n.step2Description)
                .font(.caption)
                .foregroundColor(.secondary)

            Button(auth.isAuthenticating ? L10n.reopenSignIn : L10n.signIn) {
                auth.startAuthFlow()
            }
            .buttonStyle(.bordered)

            HStack {
                TextField(L10n.pasteCode, text: $authCode)
                    .textFieldStyle(.roundedBorder)

                Button(L10n.submit) {
                    let code = authCode.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !code.isEmpty else { return }
                    Task {
                        await auth.exchangeCode(code)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(authCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
}
