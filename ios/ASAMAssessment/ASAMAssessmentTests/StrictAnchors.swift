//
//  StrictAnchors.swift
//  ASAMAssessmentTests
//
//  Compile-time flag to enable strict validation in pre-push hook
//  Use: try XCTSkipUnless(StrictAnchors.enabled, "STRICT_ANCHORS not enabled")
//

import XCTest

enum StrictAnchors {
    #if STRICT_ANCHORS
    static let enabled = true
    #else
    static let enabled = false
    #endif
}
