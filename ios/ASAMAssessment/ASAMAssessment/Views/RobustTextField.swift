//
//  RobustTextField.swift
//  ASAMAssessment
//
//  Created by Agent on 2025-11-11.
//

import SwiftUI

/// A more robust text field implementation that handles focus issues better
struct RobustTextField: View {
    let placeholder: String
    @Binding var text: String
    let onCommit: () -> Void
    
    @State private var internalText: String = ""
    @FocusState private var isFocused: Bool
    @State private var hasInitialized = false
    
    init(
        _ placeholder: String,
        text: Binding<String>,
        onCommit: @escaping () -> Void = {}
    ) {
        self.placeholder = placeholder
        self._text = text
        self.onCommit = onCommit
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                TextField(placeholder, text: $internalText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($isFocused)
                    .onSubmit {
                        text = internalText
                        onCommit()
                    }
                    .onChange(of: internalText) { _, newValue in
                        text = newValue
                    }
                    .onChange(of: text) { _, newValue in
                        if newValue != internalText {
                            internalText = newValue
                        }
                    }
                    .onTapGesture {
                        // Force focus on tap
                        isFocused = true
                    }
                
                // Focus debug button
                Button("📝") {
                    isFocused = true
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .help("Tap to focus text field")
            }
            
            // Status indicator
            HStack {
                Circle()
                    .fill(isFocused ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)
                
                Text(isFocused ? "Ready for input" : "Tap to focus")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
        }
        .onAppear {
            if !hasInitialized {
                internalText = text
                hasInitialized = true
            }
        }
    }
}

/// Alternative number field with the same robust approach
struct RobustNumberField: View {
    let placeholder: String
    @Binding var value: Double
    let onCommit: () -> Void
    
    @State private var internalValue: Double = 0
    @FocusState private var isFocused: Bool
    @State private var hasInitialized = false
    
    init(
        _ placeholder: String,
        value: Binding<Double>,
        onCommit: @escaping () -> Void = {}
    ) {
        self.placeholder = placeholder
        self._value = value
        self.onCommit = onCommit
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                TextField(placeholder, value: $internalValue, format: .number)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.decimalPad)
                    .focused($isFocused)
                    .onSubmit {
                        value = internalValue
                        onCommit()
                    }
                    .onChange(of: internalValue) { _, newValue in
                        value = newValue
                    }
                    .onChange(of: value) { _, newValue in
                        if newValue != internalValue {
                            internalValue = newValue
                        }
                    }
                    .onTapGesture {
                        // Force focus on tap
                        isFocused = true
                    }
                
                // Focus debug button
                Button("🔢") {
                    isFocused = true
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .help("Tap to focus number field")
            }
            
            // Status indicator
            HStack {
                Circle()
                    .fill(isFocused ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)
                
                Text(isFocused ? "Ready for input" : "Tap to focus")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
        }
        .onAppear {
            if !hasInitialized {
                internalValue = value
                hasInitialized = true
            }
        }
    }
}