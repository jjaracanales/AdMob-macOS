import Foundation
import AppKit
import CryptoKit

/// Handles Google OAuth 2.0 flow for AdMob API access
@MainActor
class GoogleAuthService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isAuthenticating = false
    @Published var error: String?

    private let keychainTokenKey = "oauth_tokens"
    private let keychainConfigKey = "oauth_config"
    private let scope = "https://www.googleapis.com/auth/admob.readonly"
    private let redirectURI = "urn:ietf:wg:oauth:2.0:oob" // Manual copy/paste flow

    private var config: OAuthClientConfig?
    private var tokens: OAuthTokens?

    // PKCE
    private var codeVerifier: String?

    init() {
        loadStoredCredentials()
    }

    // MARK: - Public

    var hasClientConfig: Bool {
        config != nil
    }

    /// Import the client_secret JSON downloaded from Google API Console
    func importClientSecret(from url: URL) throws {
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            print("[GoogleAuth] Failed to read file at \(url.path): \(error)")
            throw error
        }

        guard !data.isEmpty else {
            let emptyError = AuthError.invalidResponse
            print("[GoogleAuth] File is empty at \(url.path)")
            throw emptyError
        }

        let parsed = try OAuthClientConfig.fromGoogleJSON(data: data)
        config = parsed
        let saved = KeychainService.saveCodable(parsed, forKey: keychainConfigKey)
        if !saved {
            print("[GoogleAuth] Warning: Failed to save config to secure storage")
        }
    }

    /// Start OAuth flow - opens browser for user to authorize
    func startAuthFlow() {
        guard let config else {
            error = "Import client_secret.json first"
            return
        }

        isAuthenticating = true
        error = nil

        // Generate PKCE code verifier and challenge
        let verifier = generateCodeVerifier()
        codeVerifier = verifier
        let challenge = generateCodeChallenge(from: verifier)

        var components = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: config.clientId),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: scope),
            URLQueryItem(name: "access_type", value: "offline"),
            URLQueryItem(name: "prompt", value: "consent"),
            URLQueryItem(name: "code_challenge", value: challenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
        ]

        if let url = components.url {
            NSWorkspace.shared.open(url)
        }
    }

    /// Exchange the authorization code for tokens
    func exchangeCode(_ code: String) async {
        guard let config, let verifier = codeVerifier else {
            error = "Missing config or PKCE verifier"
            isAuthenticating = false
            return
        }

        do {
            let tokens = try await requestTokens(
                grantType: "authorization_code",
                code: code,
                verifier: verifier,
                config: config
            )
            self.tokens = tokens
            _ = KeychainService.saveCodable(tokens, forKey: keychainTokenKey)
            isAuthenticated = true
            isAuthenticating = false
            self.error = nil
        } catch {
            self.error = "Token exchange failed: \(error.localizedDescription)"
            isAuthenticating = false
        }
    }

    /// Get a valid access token, refreshing if needed
    func getAccessToken() async throws -> String {
        guard let tokens else {
            throw AuthError.notAuthenticated
        }

        if tokens.isExpired {
            guard let config else { throw AuthError.noConfig }
            let refreshed = try await refreshAccessToken(
                refreshToken: tokens.refreshToken,
                config: config
            )
            self.tokens = refreshed
            _ = KeychainService.saveCodable(refreshed, forKey: keychainTokenKey)
            return refreshed.accessToken
        }

        return tokens.accessToken
    }

    /// Sign out and clear stored credentials
    func signOut() {
        tokens = nil
        KeychainService.delete(key: keychainTokenKey)
        isAuthenticated = false
    }

    func clearAll() {
        signOut()
        config = nil
        KeychainService.delete(key: keychainConfigKey)
    }

    // MARK: - Private

    private func loadStoredCredentials() {
        config = KeychainService.loadCodable(forKey: keychainConfigKey)
        tokens = KeychainService.loadCodable(forKey: keychainTokenKey)
        if let tokens, !tokens.refreshToken.isEmpty {
            isAuthenticated = true
        }
    }

    private func requestTokens(
        grantType: String,
        code: String,
        verifier: String,
        config: OAuthClientConfig
    ) async throws -> OAuthTokens {
        var request = URLRequest(url: URL(string: "https://oauth2.googleapis.com/token")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let params = [
            "client_id": config.clientId,
            "client_secret": config.clientSecret,
            "code": code,
            "code_verifier": verifier,
            "grant_type": grantType,
            "redirect_uri": redirectURI,
        ]
        request.httpBody = params
            .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200
        else {
            let body = String(data: data, encoding: .utf8) ?? "unknown error"
            throw AuthError.tokenRequestFailed(body)
        }

        return try parseTokenResponse(data: data)
    }

    private func refreshAccessToken(
        refreshToken: String,
        config: OAuthClientConfig
    ) async throws -> OAuthTokens {
        var request = URLRequest(url: URL(string: "https://oauth2.googleapis.com/token")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let params = [
            "client_id": config.clientId,
            "client_secret": config.clientSecret,
            "refresh_token": refreshToken,
            "grant_type": "refresh_token",
        ]
        request.httpBody = params
            .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200
        else {
            let body = String(data: data, encoding: .utf8) ?? "unknown error"
            // If refresh fails, user needs to re-authenticate
            tokens = nil
            KeychainService.delete(key: keychainTokenKey)
            isAuthenticated = false
            throw AuthError.tokenRequestFailed(body)
        }

        var newTokens = try parseTokenResponse(data: data)
        // Google doesn't always return a new refresh token
        if newTokens.refreshToken.isEmpty {
            newTokens.refreshToken = refreshToken
        }
        return newTokens
    }

    private func parseTokenResponse(data: Data) throws -> OAuthTokens {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let accessToken = json["access_token"] as? String
        else {
            throw AuthError.invalidResponse
        }

        let refreshToken = json["refresh_token"] as? String ?? tokens?.refreshToken ?? ""
        let expiresIn = json["expires_in"] as? Int ?? 3600

        return OAuthTokens(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresAt: Date().addingTimeInterval(TimeInterval(expiresIn - 60))
        )
    }

    // MARK: - PKCE helpers

    private func generateCodeVerifier() -> String {
        var buffer = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, buffer.count, &buffer)
        return Data(buffer)
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private func generateCodeChallenge(from verifier: String) -> String {
        let data = Data(verifier.utf8)
        let hash = SHA256.hash(data: data)
        return Data(hash)
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

enum AuthError: LocalizedError {
    case notAuthenticated
    case noConfig
    case tokenRequestFailed(String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "Not authenticated"
        case .noConfig: return "OAuth config not set"
        case .tokenRequestFailed(let msg): return "Token request failed: \(msg)"
        case .invalidResponse: return "Invalid response from Google"
        }
    }
}
