import Foundation

public enum RulesServiceError: Error {
    case notFound(URL)
    case loadFailure(String)
}

public final class RulesService {
    private let engine: RulesEngine

    public init(bundle: Bundle = .main,
                wmRulesPath: String = "agent_ops/rules/wm_ladder.json",
                locRulesPath: String = "agent_ops/rules/loc_indication.guard.json",
                operatorsPath: String = "agent_ops/rules/operators.json") throws {
        let wmURL = RulesService.resolveURL(bundle: bundle, path: wmRulesPath)
        let locURL = RulesService.resolveURL(bundle: bundle, path: locRulesPath)
        let opURL = RulesService.resolveURL(bundle: bundle, path: operatorsPath)
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

    // MARK: - Helpers
    private static func resolveURL(bundle: Bundle, path: String) -> URL {
        // Try absolute file first
        let abs = URL(fileURLWithPath: path)
        if FileManager.default.fileExists(atPath: abs.path) { return abs }
        // Fallback to bundle resource
        if let url = bundle.url(forResource: path, withExtension: nil) { return url }
        fatalError("Rules file not found: \(path)")
    }
}
