//
//  NetworkSanityChecker.swift
//  ASAM Assessment Application
//
//  Captive portal detection and network validation
//  T-0040: Captive portal detection
//  Addresses: Hospital wifi, TLS intercept, false positives
//

import Foundation
import Network
import Combine

enum NetworkStatus {
    case online
    case captivePortal
    case offline
    case tlsIntercepted
    case clockSkewed
}

/// Network sanity checker with active probing
@MainActor
final class NetworkSanityChecker: ObservableObject {
    @Published private(set) var status: NetworkStatus = .offline
    @Published private(set) var lastCheck: Date?

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.asam.network")

    // Probe endpoints
    private let tlsPinnedURL = URL(string: "https://example.com/health")!  // TODO: Replace with actual pinned endpoint
    private let plainTextURL = URL(string: "http://example.com/health")!   // TODO: Replace with actual endpoint

    init() {
        startMonitoring()
    }

    deinit {
        monitor.cancel()
    }

    /// Start network path monitoring
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            if path.status == .satisfied {
                Task { @MainActor in
                    await self?.performActiveProbe()
                }
            } else {
                Task { @MainActor in
                    guard let strongSelf = self else { return }
                    strongSelf.status = .offline
                }
            }
        }

        monitor.start(queue: queue)
    }

    /// Perform active probe to detect captive portals and TLS intercept
    func performActiveProbe() async {
        lastCheck = Date()

        // Probe 1: TLS pinned endpoint
        let tlsResult = await probeTLS()

        // Probe 2: Plain text endpoint
        let plainResult = await probePlain()

        // Analyze results
        if tlsResult.success && plainResult.success {
            // Both succeeded, check clock skew
            if let tlsSkew = tlsResult.skew,
               let plainSkew = plainResult.skew,
               abs(tlsSkew) > 1.0 || abs(plainSkew) > 1.0 {
                status = .clockSkewed
                print("⚠️ Network: Clock skew detected (TLS: \(tlsSkew)s, Plain: \(plainSkew)s)")
            } else {
                status = .online
                print("✅ Network: Online and validated")
            }
        } else if !tlsResult.success && plainResult.success {
            // Plain succeeded but TLS failed = likely TLS intercept or captive portal
            status = .tlsIntercepted
            print("⚠️ Network: TLS intercept or captive portal detected")
        } else if !tlsResult.success && !plainResult.success {
            // Both failed = likely captive portal or offline
            status = .captivePortal
            print("⚠️ Network: Captive portal detected")
        } else {
            // Plain failed but TLS succeeded = unusual, mark as captive portal
            status = .captivePortal
            print("⚠️ Network: Unusual condition, assuming captive portal")
        }
    }

    /// Probe TLS endpoint
    private func probeTLS() async -> (success: Bool, skew: TimeInterval?) {
        do {
            let start = Date()
            let request = URLRequest(url: tlsPinnedURL, timeoutInterval: 5)
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                return (false, nil)
            }

            // Check for expected content (should return timestamp)
            if let json = try? JSONDecoder().decode([String: String].self, from: data),
               let serverTime = json["timestamp"],
               let serverDate = ISO8601DateFormatter().date(from: serverTime) {
                let skew = serverDate.timeIntervalSince(start)
                return (true, skew)
            }

            return (true, nil)
        } catch {
            return (false, nil)
        }
    }

    /// Probe plain text endpoint
    private func probePlain() async -> (success: Bool, skew: TimeInterval?) {
        do {
            let start = Date()
            let request = URLRequest(url: plainTextURL, timeoutInterval: 5)
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                return (false, nil)
            }

            // Check for expected content
            if let json = try? JSONDecoder().decode([String: String].self, from: data),
               let serverTime = json["timestamp"],
               let serverDate = ISO8601DateFormatter().date(from: serverTime) {
                let skew = serverDate.timeIntervalSince(start)
                return (true, skew)
            }

            return (true, nil)
        } catch {
            return (false, nil)
        }
    }

    /// Check if network is safe for uploads
    var isSafeForUpload: Bool {
        status == .online
    }

    /// Get human-readable status
    var statusMessage: String {
        switch status {
        case .online:
            return "Network validated and online"
        case .captivePortal:
            return "Captive portal detected - please sign in to wifi"
        case .offline:
            return "No network connection"
        case .tlsIntercepted:
            return "TLS interception detected - uploads blocked for security"
        case .clockSkewed:
            return "Device clock out of sync - please check time settings"
        }
    }
}
