#!/usr/bin/env ruby
# add_categorized_health_issues_view.rb
# Adds CategorizedHealthIssuesView.swift to the Xcode project

require 'xcodeproj'

project_path = 'ios/ASAMAssessment/ASAMAssessment/ASAMAssessment.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the Views group (it contains SeverityRatingView.swift)
views_group = nil
project.main_group.recursive_children.each do |child|
  if child.is_a?(Xcodeproj::Project::Object::PBXGroup)
    # Check if this group contains SeverityRatingView.swift
    if child.files.any? { |f| f.path == 'SeverityRatingView.swift' }
      views_group = child
      break
    end
  end
end

unless views_group
  puts "Error: Views group not found (looking for group containing SeverityRatingView.swift)"
  exit 1
end

puts "Found Views group: #{views_group.name || 'unnamed'}"

# Check if file already exists in project
existing_file = views_group.files.find { |f| f.path == 'CategorizedHealthIssuesView.swift' }

if existing_file
  puts "✓ CategorizedHealthIssuesView.swift already in project"
else
  # Add the file reference
  file_ref = views_group.new_file('CategorizedHealthIssuesView.swift')
  
  # Add to target
  target = project.targets.first
  target.add_file_references([file_ref])
  
  puts "✓ Added CategorizedHealthIssuesView.swift to project"
end

# Save the project
project.save

puts "✓ Project saved successfully"
