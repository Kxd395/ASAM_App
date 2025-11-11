//
//  ProgressTrackingFix.swift
//  ASAMAssessment
//
//  Created by Agent on 2025-11-11
//  Fixes for progress bar not updating when fields are removed
//

import Foundation
import SwiftUI

// Import the main app module for access to models
// This will be resolved when added to Xcode project

// MARK: - Progress Calculation Fix

extension Domain {
    /// Calculate completion progress for this domain
    /// Returns value between 0.0 and 1.0
    func calculateProgress() -> Double {
        guard !answers.isEmpty else { return 0.0 }
        
        // Count non-empty answers
        let validAnswers = answers.filter { _, value in
            switch value {
            case .none:
                return false
            case .text(let str):
                return !str.isEmpty
            case .number(_), .bool(_), .single(_), .multi(_), .substanceGrid(_):
                return true
            }
        }
        
        // For now, use a simple ratio
        // TODO: Integrate with questionnaire to get total required questions
        let progress = Double(validAnswers.count) / Double(max(answers.count, 1))
        
        print("📊 Domain \(number) progress: \(validAnswers.count)/\(answers.count) = \(String(format: "%.0f%%", progress * 100))")
        
        return progress
    }
    
    /// Calculate completion percentage (0-100)
    var completionPercentage: Int {
        Int(calculateProgress() * 100)
    }
}

extension Assessment {
    /// Calculate overall assessment progress
    /// Returns value between 0.0 and 1.0
    func calculateOverallProgress() -> Double {
        guard !domains.isEmpty else { return 0.0 }
        
        let domainProgresses = domains.map { $0.calculateProgress() }
        let totalProgress = domainProgresses.reduce(0, +) / Double(domains.count)
        
        print("📊 Overall assessment progress: \(String(format: "%.0f%%", totalProgress * 100))")
        print("📊 Domain breakdown: \(domains.map { "D\($0.number): \($0.completionPercentage)%" }.joined(separator: ", "))")
        
        return totalProgress
    }
    
    /// Get completion percentage (0-100)
    var completionPercentage: Int {
        Int(calculateOverallProgress() * 100)
    }
    
    /// Get number of completed domains
    var completedDomainsCount: Int {
        domains.filter { $0.isComplete }.count
    }
    
    /// Get number of domains with any answers
    var startedDomainsCount: Int {
        domains.filter { !$0.answers.isEmpty }.count
    }
}

// MARK: - Progress View Component

struct AssessmentProgressView: View {
    let assessment: Assessment
    @State private var animateProgress: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Overall Progress Bar
            HStack {
                Text("Overall Progress")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(assessment.completionPercentage)%")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.blue)
            }
            
            ProgressView(value: Double(assessment.completionPercentage), total: 100)
                .tint(.blue)
                .scaleEffect(x: 1, y: 2, anchor: .center)
                .animation(.easeInOut(duration: 0.3), value: assessment.completionPercentage)
            
            // Domain Progress Details
            VStack(spacing: 4) {
                ForEach(assessment.domains) { domain in
                    DomainProgressRow(domain: domain)
                }
            }
            .padding(.top, 4)
            
            // Summary Stats
            HStack(spacing: 16) {
                Label("\(assessment.completedDomainsCount)/\(assessment.domains.count) Complete", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
                
                Label("\(assessment.startedDomainsCount) Started", systemImage: "pencil.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.blue)
            }
            .padding(.top, 4)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5).delay(0.2)) {
                animateProgress = true
            }
        }
    }
}

struct DomainProgressRow: View {
    let domain: Domain
    
    var body: some View {
        HStack(spacing: 8) {
            // Domain Label
            Text("Domain \(domain.number)")
                .font(.caption)
                .fontWeight(.medium)
                .frame(width: 70, alignment: .leading)
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                    
                    // Progress
                    RoundedRectangle(cornerRadius: 4)
                        .fill(progressColor)
                        .frame(width: geometry.size.width * domain.calculateProgress())
                        .animation(.easeInOut(duration: 0.3), value: domain.calculateProgress())
                }
            }
            .frame(height: 8)
            
            // Percentage
            Text("\(domain.completionPercentage)%")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .frame(width: 35, alignment: .trailing)
            
            // Status Icon
            Image(systemName: domain.isComplete ? "checkmark.circle.fill" : "circle")
                .font(.caption)
                .foregroundStyle(domain.isComplete ? .green : .gray)
                .frame(width: 16)
        }
    }
    
    private var progressColor: Color {
        if domain.isComplete {
            return .green
        } else if domain.answers.isEmpty {
            return .gray
        } else {
            return .blue
        }
    }
}

// MARK: - Progress Tracking Debugger

struct ProgressDebugView: View {
    let assessment: Assessment
    @State private var showingDetails = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                showingDetails.toggle()
            } label: {
                HStack {
                    Image(systemName: "chart.bar.doc.horizontal")
                        .foregroundStyle(.blue)
                    
                    Text("Progress Debug Info")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Image(systemName: showingDetails ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            
            if showingDetails {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Assessment: \(assessment.id.uuidString.prefix(8))")
                            .font(.caption)
                            .fontFamily(.monospaced)
                        
                        Divider()
                        
                        ForEach(assessment.domains) { domain in
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Domain \(domain.number): \(domain.title)")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                
                                Text("Answers: \(domain.answers.count)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                
                                Text("Complete: \(domain.isComplete ? "✅" : "❌")")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                
                                Text("Severity: \(domain.severity)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                
                                Text("Progress: \(domain.completionPercentage)%")
                                    .font(.caption2)
                                    .foregroundStyle(.blue)
                                
                                if !domain.answers.isEmpty {
                                    Text("Answer Keys: \(domain.answers.keys.sorted().joined(separator: ", "))")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
                            }
                            .padding(.vertical, 4)
                            
                            if domain.number < assessment.domains.count {
                                Divider()
                            }
                        }
                    }
                }
                .frame(maxHeight: 300)
                .padding(.vertical, 8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
