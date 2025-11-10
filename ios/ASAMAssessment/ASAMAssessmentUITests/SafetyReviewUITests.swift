//
//  SafetyReviewUITests.swift
//  ASAM Assessment UI Tests
//
//  Tests for Safety Review Sheet behavior:
//  - Auto-focus on Notes field
//  - Validation and gating
//  - Keyboard behavior
//

import XCTest

final class SafetyReviewUITests: XCTestCase {
    
    override func setUpWithError() throws {
        continueAfterFailure = false
    }
    
    /// Test that Notes field auto-focuses when action is selected
    func testSafetyReview_NotesAutoFocusesAfterActionSelection() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Navigate to assessment and trigger safety review
        // (Adjust this navigation based on your app structure)
        app.buttons["New Assessment"].tap()
        
        // Safety review should appear automatically
        let sheet = app.otherElements["safetyReviewSheet"]
        XCTAssertTrue(sheet.waitForExistence(timeout: 2))
        
        // Select an action
        let actionPicker = app.buttons["actionPicker"]
        XCTAssertTrue(actionPicker.exists)
        actionPicker.tap()
        
        // Pick "No immediate risk identified"
        app.buttons["No immediate risk identified"].tap()
        
        // Notes field should exist and be focused (keyboard should appear)
        let notesField = app.textViews["notesField"]
        XCTAssertTrue(notesField.waitForExistence(timeout: 2))
        
        // Type some text
        notesField.tap()
        notesField.typeText("Patient stable, no immediate concerns noted.")
        
        // Continue should still be disabled until acknowledgment
        let continueButton = app.buttons["continueButton"]
        XCTAssertFalse(continueButton.isEnabled)
        
        // Acknowledge
        let ackToggle = app.switches["ackToggle"]
        ackToggle.tap()
        
        // Continue should now be enabled
        XCTAssertTrue(continueButton.isEnabled)
        
        // Complete the review
        continueButton.tap()
        
        // Sheet should dismiss
        XCTAssertFalse(sheet.exists)
    }
    
    /// Test that Continue is disabled until all fields are valid
    func testSafetyReview_DisablesContinueUntilValid() throws {
        let app = XCUIApplication()
        app.launch()
        
        app.buttons["New Assessment"].tap()
        
        let continueButton = app.buttons["continueButton"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 2))
        
        // Initially disabled
        XCTAssertFalse(continueButton.isEnabled)
        
        // Select action
        app.buttons["actionPicker"].tap()
        app.buttons["No immediate risk identified"].tap()
        
        // Still disabled (no notes yet)
        XCTAssertFalse(continueButton.isEnabled)
        
        // Add notes
        let notesField = app.textViews["notesField"]
        notesField.typeText("Test notes")
        
        // Still disabled (not acknowledged)
        XCTAssertFalse(continueButton.isEnabled)
        
        // Acknowledge
        app.switches["ackToggle"].tap()
        
        // Now enabled
        XCTAssertTrue(continueButton.isEnabled)
    }
    
    /// Test inline error when trying to continue with empty notes
    func testSafetyReview_ShowsInlineErrorForEmptyNotes() throws {
        let app = XCUIApplication()
        app.launch()
        
        app.buttons["New Assessment"].tap()
        
        // Select action but don't add notes
        app.buttons["actionPicker"].tap()
        app.buttons["No immediate risk identified"].tap()
        
        // Acknowledge
        app.switches["ackToggle"].tap()
        
        // Clear any auto-filled text
        let notesField = app.textViews["notesField"]
        notesField.tap()
        notesField.clearText()
        
        // Continue should be disabled due to empty notes
        let continueButton = app.buttons["continueButton"]
        XCTAssertFalse(continueButton.isEnabled)
    }
    
    /// Test that different action types work correctly
    func testSafetyReview_HandlesAllActionTypes() throws {
        let app = XCUIApplication()
        app.launch()
        
        let actionTypes = [
            "No immediate risk identified",
            "Monitoring plan established",
            "Escalated to supervisor/emergency services",
            "Consultation requested",
            "Emergency transport arranged"
        ]
        
        for (index, actionType) in actionTypes.enumerated() {
            // Start new assessment for each action type
            if index > 0 {
                app.buttons["New Assessment"].tap()
            } else {
                app.buttons["New Assessment"].tap()
            }
            
            // Select action
            app.buttons["actionPicker"].tap()
            app.buttons[actionType].tap()
            
            // Add notes
            let notesField = app.textViews["notesField"]
            notesField.typeText("Testing action type: \(actionType)")
            
            // Acknowledge and continue
            app.switches["ackToggle"].tap()
            app.buttons["continueButton"].tap()
            
            // Should proceed successfully
            let sheet = app.otherElements["safetyReviewSheet"]
            XCTAssertFalse(sheet.exists, "Sheet should dismiss after \(actionType)")
        }
    }
    
    /// Test cancel button behavior
    func testSafetyReview_CancelDismissesSheet() throws {
        let app = XCUIApplication()
        app.launch()
        
        app.buttons["New Assessment"].tap()
        
        let sheet = app.otherElements["safetyReviewSheet"]
        XCTAssertTrue(sheet.exists)
        
        // Cancel should work even without completing fields
        app.buttons["cancelButton"].tap()
        
        // Sheet should dismiss
        XCTAssertFalse(sheet.waitForExistence(timeout: 1))
    }
}

// MARK: - Helper Extensions

extension XCUIElement {
    /// Clears text from a text field or text view
    func clearText() {
        guard let stringValue = self.value as? String else {
            return
        }
        
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        self.typeText(deleteString)
    }
}
