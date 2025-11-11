//
//  AutofocusTextView.swift
//  ASAM Assessment Application
//
//  UIKit-backed text view for ultra-reliable auto-focus on iPad
//  Use this in place of TextEditor if SwiftUI focus is flaky
//

import SwiftUI
import UIKit

/// UIKit-backed text view with reliable auto-focus behavior
struct AutofocusTextView: UIViewRepresentable {
    @Binding var text: String
    var shouldFocus: Bool
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.font = .preferredFont(forTextStyle: .body)
        textView.isScrollEnabled = true
        textView.backgroundColor = .clear
        textView.delegate = context.coordinator
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        textView.autocapitalizationType = .sentences
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        // Update text only if different to avoid cursor jumping
        if uiView.text != text {
            uiView.text = text
        }
        
        // Auto-focus when shouldFocus is true
        if shouldFocus, uiView.window != nil, !uiView.isFirstResponder {
            uiView.becomeFirstResponder()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: AutofocusTextView
        
        init(_ parent: AutofocusTextView) {
            self.parent = parent
        }
        
        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
        }
    }
}

// MARK: - Preview
#Preview {
    struct PreviewWrapper: View {
        @State private var text = ""
        @State private var shouldFocus = false
        
        var body: some View {
            VStack(spacing: 16) {
                AutofocusTextView(text: $text, shouldFocus: shouldFocus)
                    .frame(minHeight: 120)
                    .padding(12)
                    .background(.background, in: .rect(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12).stroke(.quaternary, lineWidth: 1)
                    )
                
                Toggle("Auto Focus", isOn: $shouldFocus)
                    .padding()
                
                Button("Clear Text") {
                    text = ""
                }
                .padding()
            }
            .padding()
        }
    }
    
    return PreviewWrapper()
}
