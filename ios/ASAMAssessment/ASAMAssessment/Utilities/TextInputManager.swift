//
//  TextInputManager.swift
//  ASAMAssessment
//
//  Created by Agent on 2025-01-11.
//

import SwiftUI
import Combine

/// Manager for handling text input focus and keyboard interactions
class TextInputManager: ObservableObject {
    static let shared = TextInputManager()
    
    @Published var currentFocusedField: String? = nil
    @Published var forceRefresh: Bool = false
    
    private init() {}
    
    func focusField(_ fieldId: String) {
        DispatchQueue.main.async {
            self.currentFocusedField = fieldId
            self.forceRefresh.toggle()
        }
    }
    
    func clearFocus() {
        DispatchQueue.main.async {
            self.currentFocusedField = nil
            self.forceRefresh.toggle()
        }
    }
    
    func isFocused(_ fieldId: String) -> Bool {
        return currentFocusedField == fieldId
    }
}