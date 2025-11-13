//
//  TokenProvider.swift
//  ASAM Assessment Application
//
//  Token lifecycle with fences and safe refresh
//  T-0037: Token fences and background session
//  Addresses: Token churn, race conditions, background uploads
//

import Foundation
import Combine

/// Thread-safe token provider with automatic refresh
actor TokenProvider {
    private var token: String?
    private var expiresAt: Date?
    private let refreshURL: URL
    private let clientID: String
    private let clientSecret: String

    init(refreshURL: URL, clientID: String, clientSecret: String) {
        self.refreshURL = refreshURL
        self.clientID = clientID
        self.clientSecret = clientSecret
    }

    /// Get valid token, refreshing if needed
    func get() async throws -> String {
        // Return cached token if still valid
        if let token = token,
           let expires = expiresAt,
           !isExpiringSoon(expires) {
            return token
        }

        // Refresh token
        let new = try await refresh()
        self.token = new.accessToken
        self.expiresAt = Date().addingTimeInterval(TimeInterval(new.expiresIn))

        print("🔑 Token refreshed, expires at: \(expiresAt?.description ?? "unknown")")

        return new.accessToken
    }

    /// Force token refresh
    func forceRefresh() async throws {
        token = nil
        expiresAt = nil
        _ = try await get()
    }

    /// Check if token is expiring soon (within 5 minutes)
    private func isExpiringSoon(_ date: Date) -> Bool {
        date.timeIntervalSinceNow < 300  // 5 minutes
    }

    /// Refresh token from OAuth endpoint
    nonisolated private func refresh() async throws -> TokenResponse {
        var request = URLRequest(url: refreshURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = [
            "grant_type": "client_credentials",
            "client_id": clientID,
            "client_secret": clientSecret
        ]

        request.httpBody = body.map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw TokenError.refreshFailed("HTTP \((response as? HTTPURLResponse)?.statusCode ?? -1)")
        }

        // Decode in detached task to avoid Swift 6 main actor isolation issues
        return try await Task.detached {
            let decoder = JSONDecoder()
            return try decoder.decode(TokenResponse.self, from: data)
        }.value
    }
}

// Sendable conformance ensures safe concurrent access
struct TokenResponse: Codable, Sendable {
    let accessToken: String
    let expiresIn: Int
    let tokenType: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
    }
}

enum TokenError: LocalizedError {
    case refreshFailed(String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .refreshFailed(let reason):
            return "Token refresh failed: \(reason)"
        case .invalidResponse:
            return "Invalid token response"
        }
    }
}

/// Background upload session with token fence
@MainActor
final class BackgroundUploadSession: NSObject, ObservableObject {
    private var session: URLSession!
    private let tokenProvider: TokenProvider
    private var activeTasks: [URLSessionTask] = []

    init(tokenProvider: TokenProvider) {
        self.tokenProvider = tokenProvider
        super.init()

        let config = URLSessionConfiguration.background(withIdentifier: "com.asam.upload")
        config.isDiscretionary = false
        config.sessionSendsLaunchEvents = true

        self.session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }

    /// Upload data with automatic token injection
    func upload(data: Data, to url: URL, idemKey: String) async throws {
        // Get fresh token
        let token = try await tokenProvider.get()

        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(idemKey, forHTTPHeaderField: "Idempotency-Key")
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")

        // Upload
        let task = session.uploadTask(with: request, from: data)
        activeTasks.append(task)
        task.resume()

        print("📤 Background upload started: \(url.lastPathComponent), idempotency: \(idemKey)")
    }
}

extension BackgroundUploadSession: URLSessionTaskDelegate {
    nonisolated func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        Task { @MainActor in
            activeTasks.removeAll { $0 == task }

            if let error = error {
                print("❌ Upload failed: \(error.localizedDescription)")
            } else if let response = task.response as? HTTPURLResponse {
                if (200...299).contains(response.statusCode) {
                    print("✅ Upload completed successfully")
                } else {
                    print("❌ Upload failed with status: \(response.statusCode)")
                }
            }
        }
    }
}
