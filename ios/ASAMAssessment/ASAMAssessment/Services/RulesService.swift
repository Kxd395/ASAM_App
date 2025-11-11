import Foundation

/// Rules service errors with meaningful diagnostic messages
public enum RulesServiceError: LocalizedError {
    case missing(String)              // file not found in bundle
    case read(String)                 // file exists but can't read
    case decode(String, String)       // JSON decode failed with reason
    case notFound(URL)                // legacy: URL resolution failed
    case loadFailure(String)          // legacy: generic load failure
    
    public var errorDescription: String? {
        switch self {
        case .missing(let file):
            return "Missing rules file: \(file)"
        case .read(let file):
            return "Unable to read rules file: \(file)"
        case .decode(let file, let reason):
            return "JSON decode failed (\(file)): \(reason)"
        case .notFound(let url):
            return "Rules file not found: \(url.lastPathComponent)"
        case .loadFailure(let msg):
            return "Rules load failure: \(msg)"
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .missing:
            return "Ensure rules/ folder is a blue folder reference in Xcode with all required JSON files"
        case .read:
            return "Check file permissions and bundle structure"
        case .decode:
            return "Verify JSON syntax and schema match expected format"
        case .notFound:
            return "Verify bundle contains rules/ directory with required files"
        case .loadFailure:
            return "Check console logs for detailed error information"
        }
    }
}

public final class RulesService {
    private let engine: RulesEngine

    public init(bundle: Bundle = .main,
                wmRulesFile: String = "rules/wm_ladder.json",
                locRulesFile: String = "rules/loc_indication.guard.json",
                operatorsFile: String = "rules/operators.json") throws {
        // Load JSON files with subdirectory support
        let wmURL = try Self.resolveURL(bundle: bundle, path: wmRulesFile)
        let locURL = try Self.resolveURL(bundle: bundle, path: locRulesFile)
        let opURL = try Self.resolveURL(bundle: bundle, path: operatorsFile)
        self.engine = try RulesEngine(wmRulesURL: wmURL, locRulesURL: locURL, operatorsURL: opURL)
    }

    public func evaluate(severities: [String:Int],
                         d1Context: [String: Any],
                         flags: [String: Bool],
                         program: [String: Any] = [:]) -> (wm: WMOutcome, loc: LOCOutcome) {
        var state: [String: Any] = [:]
        for (k,v) in severities { state[k] = v }
        // flatten some common fields
        if let substances = d1Context["substances"] { state["substances"] = substances }
        if let cows = d1Context["cows"] { state["cows"] = cows }
        if let ciwa = d1Context["ciwa"] { state["ciwa"] = ciwa }
        for (k,v) in flags { state[k] = v }
        for (k,v) in program { state[k] = v }

        let wm = engine.evaluateWM(state: state)
        let loc = engine.evaluateLOC(state: state, wmOutcome: wm)
        return (wm, loc)
    }

    // MARK: - URL Resolution
    private static func resolveURL(bundle: Bundle, path: String) throws -> URL {
        // Try absolute path first (development/testing)
        let abs = URL(fileURLWithPath: path)
        if FileManager.default.fileExists(atPath: abs.path) { return abs }

        // Split into subdirectory + filename for bundle lookup
        let nsPath = path as NSString
        let filename = nsPath.lastPathComponent
        let subdir = nsPath.deletingLastPathComponent
        let subdirectory = subdir.isEmpty ? nil : subdir

        // Look in bundle with subdirectory support
        guard let url = bundle.url(
            forResource: (filename as NSString).deletingPathExtension,
            withExtension: (filename as NSString).pathExtension,
            subdirectory: subdirectory
        ) else {
            throw RulesServiceError.notFound(URL(fileURLWithPath: path))
        }

        return url
    }
}
