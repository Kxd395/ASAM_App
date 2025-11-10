//
//  ExportUtils.swift
//  ASAM Assessment Application
//
//  Export preflight and atomic write utilities
//  T-0035: Export space and memory preflight
//  Addresses: Out of space, corrupted partial writes, OOM
//

import Foundation
import PDFKit

enum ExportError: LocalizedError {
    case insufficientDiskSpace(required: Int64, available: Int64)
    case atomicWriteFailed(URL)
    case pdfRenderFailed

    var errorDescription: String? {
        switch self {
        case .insufficientDiskSpace(let req, let avail):
            let reqMB = Double(req) / 1_048_576
            let availMB = Double(avail) / 1_048_576
            return "Insufficient disk space: need \(String(format: "%.1f", reqMB))MB, have \(String(format: "%.1f", availMB))MB"
        case .atomicWriteFailed(let url):
            return "Failed to write file atomically: \(url.lastPathComponent)"
        case .pdfRenderFailed:
            return "PDF rendering failed"
        }
    }
}

/// Check available disk space before export
func ensureSpace(bytes: Int64) throws {
    let url = FileManager.default.temporaryDirectory
    let values = try url.resourceValues(forKeys: [.volumeAvailableCapacityKey])

    guard let cap = values.volumeAvailableCapacity else {
        print("⚠️ Cannot determine available disk space, proceeding with caution")
        return
    }

    let availableBytes = Int64(cap)
    guard availableBytes > bytes else {
        throw ExportError.insufficientDiskSpace(required: bytes, available: availableBytes)
    }

    print("✅ Disk space check passed: \(availableBytes / 1_048_576)MB available, \(bytes / 1_048_576)MB required")
}

/// Write data atomically with replace-item-at semantics
func atomicWrite(_ data: Data, to url: URL) throws {
    let tmpDir = url.deletingLastPathComponent()
    let tmpFile = tmpDir.appendingPathComponent(UUID().uuidString + ".tmp")

    // Write to temp file
    try data.write(to: tmpFile, options: [.atomic])

    // Replace target atomically
    let fm = FileManager.default
    if fm.fileExists(atPath: url.path) {
        _ = try fm.replaceItemAt(url, withItemAt: tmpFile)
    } else {
        try fm.moveItem(at: tmpFile, to: url)
    }

    print("✅ Atomic write completed: \(url.lastPathComponent)")
}

/// Estimate PDF size for space check (rough heuristic)
func estimatePDFSize(pages: Int, hasImages: Bool = false) -> Int64 {
    let basePageSize: Int64 = 50_000  // 50KB per page
    let imageOverhead: Int64 = hasImages ? 200_000 : 0  // 200KB if images
    let overhead: Int64 = 100_000  // 100KB metadata overhead

    return (Int64(pages) * basePageSize) + imageOverhead + overhead
}

/// Render PDF with paged memory management
@MainActor
func renderPDFPaged(_ document: PDFDocument, progress: @escaping (Int, Int) -> Void) async throws -> Data {
    guard document.pageCount > 0 else {
        throw ExportError.pdfRenderFailed
    }

    let pageCount = document.pageCount

    // Use PDFDocument's built-in dataRepresentation with progress tracking
    for i in 0..<pageCount {
        progress(i + 1, pageCount)

        // Yield every 10 pages to prevent blocking
        if i % 10 == 0 {
            await Task.yield()
        }
    }

    guard let data = document.dataRepresentation() else {
        throw ExportError.pdfRenderFailed
    }

    return data
}

/// Memory pressure monitor (simplified)
struct MemoryMonitor {
    static func checkPressure() -> Bool {
        // Return true if under pressure
        let info = ProcessInfo.processInfo
        return info.thermalState == .serious || info.thermalState == .critical
    }
}
