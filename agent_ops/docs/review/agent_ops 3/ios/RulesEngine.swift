import Foundation

public struct WMOutcome: Codable, Equatable {
    public let indicated: Bool
    public let candidateLevels: [String]
    public let rationale: [String]
    public let ruleId: String?
}

public struct LOCOutcome: Codable, Equatable {
    public let indicated: String
    public let why: [String]
    public let ruleId: String?
}

public final class RulesEngine {
    private let wm: [[String: Any]]
    private let loc: [[String: Any]]
    private let operators: [String: Any]

    public init(wmRulesURL: URL, locRulesURL: URL, operatorsURL: URL) throws {
        self.wm = try JSONSerialization.jsonObject(with: Data(contentsOf: wmRulesURL)) as? [[String: Any]] ??
                  (try (JSONSerialization.jsonObject(with: Data(contentsOf: wmRulesURL)) as? [String: Any])?["rules"] as? [[String: Any]] ?? [])
        let locObj = try JSONSerialization.jsonObject(with: Data(contentsOf: locRulesURL))
        if let dict = locObj as? [String: Any], let rules = dict["rules"] as? [[String: Any]] {
            self.loc = rules
        } else {
            self.loc = locObj as? [[String: Any]] ?? []
        }
        self.operators = (try JSONSerialization.jsonObject(with: Data(contentsOf: operatorsURL)) as? [String: Any]) ?? [:]
    }

    // MARK: - Public API

    public func evaluateWM(state: [String: Any]) -> WMOutcome {
        var best: (prio: Int, rule: [String: Any])? = nil
        for anyRule in wm {
            guard let prio = anyRule["priority"] as? Int else { continue }
            if conditionsMet(anyRule["if"], state: state) {
                if best == nil || prio > best!.prio {
                    best = (prio, anyRule)
                }
            }
        }
        guard let chosen = best?.rule else {
            return WMOutcome(indicated: false, candidateLevels: [], rationale: [], ruleId: nil)
        }
        let then = chosen["then"] as? [String: Any] ?? [:]
        let indicated = (then["wm_indicated"] as? Bool) ?? false
        let levels = (then["candidate_levels"] as? [String]) ?? []
        let rationale = (then["rationale"] as? [String]) ?? []
        let ruleId = chosen["rule_id"] as? String
        return WMOutcome(indicated: indicated, candidateLevels: levels, rationale: rationale, ruleId: ruleId)
    }

    public func evaluateLOC(state: [String: Any], wmOutcome: WMOutcome) -> LOCOutcome {
        var best: (prec: Int, rule: [String: Any])? = nil
        var statePlus = state
        if wmOutcome.indicated {
            statePlus["wm_candidate"] = wmOutcome.candidateLevels
        }
        for anyRule in loc {
            guard let prec = anyRule["precedence"] as? Int else { continue }
            if conditionsMet(anyRule["if"], state: statePlus) {
                if best == nil || prec > best!.prec {
                    best = (prec, anyRule)
                }
            }
        }
        guard let chosen = best?.rule else {
            // fallback: 2.1 if nothing matches
            return LOCOutcome(indicated: "2.1", why: ["fallback_default"], ruleId: nil)
        }
        let then = chosen["then"] as? [String: Any] ?? [:]
        let loc = (then["indicated_loc"] as? String) ?? "2.1"
        let why = (then["why"] as? [String]) ?? []
        let ruleId = chosen["rule_id"] as? String
        return LOCOutcome(indicated: loc, why: why, ruleId: ruleId)
    }

    // MARK: - Condition Evaluator

    private func conditionsMet(_ condAny: Any?, state: [String: Any]) -> Bool {
        guard let cond = condAny as? [String: Any] else { return false }
        for (key, val) in cond {
            if key == "wm_candidate", let req = val as? [Any] {
                // support negated entries starting with "!"
                let have = (state["wm_candidate"] as? [Any]) ?? []
                var ok = false
                for r in req {
                    if let s = r as? String, s.hasPrefix("!") {
                        let needle = String(s.dropFirst())
                        if have.contains(where: { "\($0)" == needle }) { return false }
                        ok = true // negated requirement satisfied if not present
                    } else {
                        if have.contains(where: { "\($0)" == "\(r)" }) { ok = true }
                    }
                }
                if !ok { return false }
                continue
            }
            // Severity letters or numeric comparisons
            if let predicate = val as? String, isComparatorString(predicate) {
                guard let subjectNum = coerceNumber(state[key]) else { return false }
                if !compare(subjectNum, predicate: predicate) { return false }
                continue
            }
            // Bool equality
            if let wantBool = val as? Bool {
                guard let haveBool = state[key] as? Bool else { return false }
                if haveBool != wantBool { return false }
                continue
            }
            // String equality
            if let wantStr = val as? String {
                guard let haveStr = state[key] as? String else { return false }
                if haveStr != wantStr { return false }
                continue
            }
            // Unknown type: fail safe
            return false
        }
        return True
    }

    private func isComparatorString(_ s: String) -> Bool {
        return s.hasPrefix("<=") || s.hasPrefix(">=") || s.hasPrefix("<") || s.hasPrefix(">") || s.hasPrefix("==")
    }

    private func coerceNumber(_ any: Any?) -> Double? {
        if let n = any as? NSNumber { return n.doubleValue }
        if let s = any as? String { return Double(s) }
        return nil
    }

    private func compare(_ subject: Double, predicate: String) -> Bool {
        if predicate.hasPrefix("<=") {
            return subject <= (Double(predicate.dropFirst(2)) ?? .infinity)
        } else if predicate.hasPrefix(">=") {
            return subject >= (Double(predicate.dropFirst(2)) ?? -.infinity)
        } else if predicate.hasPrefix("<") {
            return subject < (Double(predicate.dropFirst(1)) ?? .infinity)
        } else if predicate.hasPrefix(">") {
            return subject > (Double(predicate.dropFirst(1)) ?? -.infinity)
        } else if predicate.hasPrefix("==") {
            return subject == (Double(predicate.dropFirst(2)) ?? subject)
        }
        return false
    }
}
