#!/usr/bin/env ruby
require 'xcodeproj'

project_path = '/Users/kevindialmb/Downloads/ASAM_App/ios/ASAMAssessment/ASAMAssessment/ASAMAssessment.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.first

# Find the groups by searching through all groups
utilities_group = nil
views_group = nil

project.main_group.recursive_children.each do |child|
  if child.is_a?(Xcodeproj::Project::Object::PBXGroup)
    if child.path == 'Utilities'
      utilities_group = child
    elsif child.path == 'Views'
      views_group = child
    end
  end
end

if utilities_group.nil?
  puts "❌ Could not find Utilities group"
  exit 1
end

if views_group.nil?
  puts "❌ Could not find Views group"
  exit 1
end

# Add ColorExtensions.swift to Utilities
color_file_ref = utilities_group.new_file('ColorExtensions.swift')
target.source_build_phase.add_file_reference(color_file_ref)

# Add SeverityRatingView.swift to Views  
severity_file_ref = views_group.new_file('SeverityRatingView.swift')
target.source_build_phase.add_file_reference(severity_file_ref)

# Save the project
project.save

puts "✅ Successfully added ColorExtensions.swift and SeverityRatingView.swift to Xcode project"
