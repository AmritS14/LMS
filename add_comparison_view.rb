require 'xcodeproj'
project_path = 'LMS.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'BorrowerApp' }

# Find the BorrowerApp/Views group
group = project.main_group.find_subpath('BorrowerApp/Views', true)

# Add the file reference (relative path inside project group)
file_ref = group.new_reference('ProductComparisonView.swift')

# Add to target
target.add_file_references([file_ref])

project.save
puts "Added ProductComparisonView.swift successfully to BorrowerApp target!"
