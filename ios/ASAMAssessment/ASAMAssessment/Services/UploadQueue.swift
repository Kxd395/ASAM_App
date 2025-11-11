//
//  UploadJob.swift
//  ASAM Assessment Application
//
//  Idempotent upload with retry and full jitter backoff
//  T-0034: Idempotent uploads with jitter backoff
//  Addresses: Network flakiness, duplicate submissions, safe resume
//

import Foundation
import Combine

/// Upload job with idempotency key and backoff state
struct UploadJob: Codable, Identifiable {
    let id: UUID
    let documentId: UUID          // Which document to upload
    let idemKey: String           // Idempotency key (persisted across retries)
    let attempt: Int              // Current attempt number (0-indexed)
    let nextAt: Date              // When to retry next
    let endpoint: URL             // Upload endpoint
    let createdAt: Date           // Job creation time
    let lastError: String?        // Last failure reason

    /// Create new upload job with fresh idempotency key
    init(documentId: UUID, endpoint: URL) {
        self.id = UUID()
        self.documentId = documentId
        self.idemKey = UUID().uuidString
        self.attempt = 0
        self.nextAt = Date()
        self.endpoint = endpoint
        self.createdAt = Date()
        self.lastError = nil
    }

    /// Create retry attempt with incremented counter and backoff
    func retry(error: String) -> UploadJob {
        let backoff = nextBackoff(attempt: self.attempt + 1)
        let nextAttempt = Date().addingTimeInterval(backoff)
        return UploadJob(
            id: self.id,
            documentId: self.documentId,
            idemKey: self.idemKey,  // SAME key for idempotency
            attempt: self.attempt + 1,
            nextAt: nextAttempt,
            endpoint: self.endpoint,
            createdAt: self.createdAt,
            lastError: error
        )
    }

    private init(id: UUID, documentId: UUID, idemKey: String, attempt: Int, nextAt: Date, endpoint: URL, createdAt: Date, lastError: String?) {
        self.id = id
        self.documentId = documentId
        self.idemKey = idemKey
        self.attempt = attempt
        self.nextAt = nextAt
        self.endpoint = endpoint
        self.createdAt = createdAt
        self.lastError = lastError
    }
}

/// Calculate full jitter exponential backoff with 5 minute cap
func nextBackoff(attempt: Int) -> TimeInterval {
    let cap: Double = 300  // 5 minutes max
    let base: Double = 2
    let raw = min(cap, pow(base, Double(attempt)))
    return Double.random(in: 0...raw)
}

/// Queue for managing upload jobs with persistence
@MainActor
final class UploadQueue: ObservableObject {
    @Published private(set) var jobs: [UploadJob] = []

    private let storageKey = "upload_jobs"

    init() {
        load()
    }

    /// Add new job to queue
    func enqueue(documentId: UUID, endpoint: URL) {
        let job = UploadJob(documentId: documentId, endpoint: endpoint)
        jobs.append(job)
        save()
        print("📤 Enqueued upload job: \(job.id) for document: \(documentId)")
    }

    /// Mark job as failed and schedule retry
    func retry(jobId: UUID, error: String) {
        guard let index = jobs.firstIndex(where: { $0.id == jobId }) else { return }
        let old = jobs[index]

        // Max 10 attempts
        if old.attempt >= 10 {
            print("❌ Upload job \(jobId) exceeded max attempts, removing")
            jobs.remove(at: index)
            save()
            return
        }

        let new = old.retry(error: error)
        jobs[index] = new
        save()

        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime]
        let nextAtStr = iso.string(from: new.nextAt)
        print("🔄 Retrying upload job \(jobId), attempt \(new.attempt), next at \(nextAtStr)")
    }

    /// Remove completed job
    func complete(jobId: UUID) {
        jobs.removeAll { $0.id == jobId }
        save()
        print("✅ Completed upload job: \(jobId)")
    }

    /// Get jobs ready to run now
    func ready() -> [UploadJob] {
        jobs.filter { $0.nextAt <= Date() }
    }

    /// Persist jobs to UserDefaults
    private func save() {
        if let data = try? JSONEncoder().encode(jobs) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    /// Load jobs from UserDefaults
    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let loaded = try? JSONDecoder().decode([UploadJob].self, from: data) else {
            return
        }
        jobs = loaded
        print("📥 Loaded \(jobs.count) upload jobs from storage")
    }
}

extension URLRequest {
    /// Add idempotency key header
    mutating func setIdempotencyKey(_ key: String) {
        setValue(key, forHTTPHeaderField: "Idempotency-Key")
    }
}
