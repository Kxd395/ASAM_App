import Foundation
import PDFKit
import AppKit
import CryptoKit

struct Diagnosis: Codable { let system: String; let code: String }
struct Objective: Codable, Identifiable { let id: String; let text: String; let targetDate: String? }
struct Problem: Codable, Identifiable { let id: String; let statement: String; let goal: String; let objectives: [Objective] }
struct Sig: Codable { let signedAt: String?; let planHashAtSigning: String? }
struct Signatures: Codable { let patient: Sig; let clinician: Sig }
struct Plan: Codable, Identifiable {
    let id: String
    let patientFullName: String
    let mrn: String
    let levelOfCare: String
    let diagnoses: [Diagnosis]
    let problems: [Problem]
    let signatures: Signatures
    let version: Int
    let lastChanged: String
}

func shortSeal(_ plan: Plan) -> String {
    let enc = JSONEncoder()
    enc.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    let data = try! enc.encode(plan)
    let digest = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    return String(digest.prefix(12))
}

let fieldMap: [String:String] = [
    "patient_name": "patientFullName",
    "mrn": "mrn",
    "level_of_care": "levelOfCare",
    "initial_plan_date": "initialPlanDate",
    "problem1_statement": "problem1_statement",
    "problem1_goal": "problem1_goal",
    "problem2_statement": "problem2_statement",
    "problem2_goal": "problem2_goal",
    "problem3_statement": "problem3_statement",
    "problem3_goal": "problem3_goal",
    "problem4_statement": "problem4_statement",
    "problem4_goal": "problem4_goal"
]

func valueForKey(_ key: String, plan: Plan, planDate: Date) -> String {
    switch key {
    case "patientFullName": return plan.patientFullName
    case "mrn": return plan.mrn
    case "levelOfCare": return plan.levelOfCare
    case "initialPlanDate":
        let fmt = DateFormatter(); fmt.dateStyle = .short; fmt.timeStyle = .none
        return fmt.string(from: planDate)
    case "problem1_statement": return plan.problems.indices.contains(0) ? plan.problems[0].statement : ""
    case "problem1_goal": return plan.problems.indices.contains(0) ? plan.problems[0].goal : ""
    case "problem2_statement": return plan.problems.indices.contains(1) ? plan.problems[1].statement : ""
    case "problem2_goal": return plan.problems.indices.contains(1) ? plan.problems[1].goal : ""
    case "problem3_statement": return plan.problems.indices.contains(2) ? plan.problems[2].statement : ""
    case "problem3_goal": return plan.problems.indices.contains(2) ? plan.problems[2].goal : ""
    case "problem4_statement": return plan.problems.indices.contains(3) ? plan.problems[3].statement : ""
    case "problem4_goal": return plan.problems.indices.contains(3) ? plan.problems[3].goal : ""
    default: return ""
    }
}

func imageFromFile(_ path: String) -> NSImage? {
    guard !path.isEmpty else { return nil }
    return NSImage(contentsOfFile: path)
}

func addFooterSeal(doc: PDFDocument, text: String) {
    guard let last = doc.page(at: doc.pageCount - 1) else { return }
    let bounds = last.bounds(for: .cropBox)
    let ann = PDFAnnotation(bounds: CGRect(x: 36, y: 36, width: bounds.width - 72, height: 12),
                            forType: .freeText, withProperties: nil)
    ann.font = .systemFont(ofSize: 9); ann.fontColor = .gray; ann.alignment = .center
    ann.contents = text
    last.addAnnotation(ann)
}

// PRODUCTION HARDENING: Metadata scrubbing for PHI protection
func stripMetadata(doc: PDFDocument, planHash: String, rulesHash: String, version: String) {
    let attrs: [PDFDocumentAttribute: Any] = [
        .titleAttribute: "",
        .authorAttribute: "",
        .creatorAttribute: "ASAM Clinical Exporter",
        .producerAttribute: "ASAM Assessment v\(version)",
        .keywordsAttribute: "",
        .subjectAttribute: "ASAM Treatment Plan"
    ]
    doc.documentAttributes = attrs
}

func stampAllPages(doc: PDFDocument, rulesHash: String, timestamp: String) {
    let footer = "Generated: \(timestamp) | Rules: \(rulesHash.prefix(12))"
    for i in 0..<doc.pageCount {
        guard let page = doc.page(at: i) else { continue }
        let bounds = page.bounds(for: .cropBox)
        let ann = PDFAnnotation(bounds: CGRect(x: 36, y: 12, width: bounds.width - 72, height: 10),
                                forType: .freeText, withProperties: nil)
        ann.font = .systemFont(ofSize: 7); ann.fontColor = .lightGray; ann.alignment = .right
        ann.contents = footer
        page.addAnnotation(ann)
    }
}

struct Args {
    let pdf: String
    let plan: String
    let out: String
    let sig: String
}

func parseArgs() -> Args {
    var pdf = "", plan = "", out = "", sig = ""
    var it = CommandLine.arguments.dropFirst().makeIterator()
    while let a = it.next() {
        switch a {
        case "--pdf": pdf = it.next() ?? ""
        case "--plan": plan = it.next() ?? ""
        case "--out": out = it.next() ?? ""
        case "--sig": sig = it.next() ?? ""
        default: break
        }
    }
    guard !pdf.isEmpty, !plan.isEmpty, !out.isEmpty else {
        fputs("usage: pdf_export --pdf template.pdf --plan plan.json --out out.pdf [--sig signature.png]\n", stderr)
        exit(2)
    }
    return Args(pdf: pdf, plan: plan, out: out, sig: sig)
}

let args = parseArgs()
guard let planData = FileManager.default.contents(atPath: args.plan) else {
    fputs("plan json not found\n", stderr); exit(2)
}
let decoder = JSONDecoder()
let plan = try decoder.decode(Plan.self, from: planData)

guard let doc = PDFDocument(url: URL(fileURLWithPath: args.pdf)) else {
    fputs("template pdf not found\n", stderr); exit(2)
}
let planDate = Date()

// Fill AcroForms
for i in 0..<doc.pageCount {
    guard let page = doc.page(at: i) else { continue }
    for ann in page.annotations where ann.widgetFieldType != .undefined {
        if let name = ann.fieldName, let vk = fieldMap[name] {
            ann.widgetStringValue = valueForKey(vk, plan: plan, planDate: planDate)
        }
    }
}

// Signature image stamp if provided
if let sigImg = imageFromFile(args.sig),
   let page = doc.page(at: min(6, doc.pageCount - 1)) {
    // Default placement. Adjust as needed for your form.
    let rect = CGRect(x: 350, y: 140, width: 180, height: 60)
    let ann = PDFAnnotation(bounds: rect, forType: .stamp, withProperties: nil)
    ann.image = sigImg
    page.addAnnotation(ann)
}

// Footer seal
let seal = "[\(plan.signatures.clinician.signedAt != nil || plan.signatures.patient.signedAt != nil ? "SIGNED" : "DRAFT")] Plan ID: \(plan.id.prefix(8)) • Seal: \(shortSeal(plan))"
addFooterSeal(doc: doc, text: seal)

// PRODUCTION HARDENING: Strip PHI metadata and add audit checksums
let planHash = shortSeal(plan)
let rulesHash = "STANDALONE"  // CLI doesn't have rules engine, set placeholder
let version = "1.0.0"
stripMetadata(doc: doc, planHash: planHash, rulesHash: rulesHash, version: version)
stampAllPages(doc: doc, rulesHash: rulesHash, timestamp: ISO8601DateFormatter().string(from: Date()))

// Write
if !doc.write(to: URL(fileURLWithPath: args.out)) {
    fputs("failed to write output\n", stderr); exit(2)
}
print("ok")
