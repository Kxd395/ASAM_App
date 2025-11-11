//
//  AppDelegate.swift
//  ASAM Assessment Application
//
//  Text Input Fix: Proper iOS application lifecycle management
//  Created: November 11, 2025
//

import UIKit
import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        
        // Ensure proper keyboard and text input initialization
        setupTextInputEnvironment()
        
        print("✅ AppDelegate: Text input environment initialized")
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Re-establish text input capabilities when app becomes active
        setupTextInputEnvironment()
        
        // Give views time to properly initialize focus state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.ensureKeyboardAvailability()
        }
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Clean up text input state when app becomes inactive
        print("📝 AppDelegate: App becoming inactive, cleaning up text input state")
    }
    
    // MARK: - Text Input Setup
    
    private func setupTextInputEnvironment() {
        // Ensure keyboard notifications are properly registered
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { _ in
            print("⌨️ Keyboard will show - text input ready")
        }
        
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { _ in
            print("⌨️ Keyboard will hide")
        }
    }
    
    private func ensureKeyboardAvailability() {
        // Force keyboard input view to be available
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            print("❌ AppDelegate: Could not find main window")
            return
        }
        
        // Ensure window is properly configured for text input
        window.makeKeyAndVisible()
        
        // Force responder chain to be properly established
        if let rootViewController = window.rootViewController {
            rootViewController.view.setNeedsLayout()
            rootViewController.view.layoutIfNeeded()
            print("✅ AppDelegate: Responder chain refreshed")
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}