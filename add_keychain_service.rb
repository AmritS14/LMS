require 'xcodeproj'
project = Xcodeproj::Project.open('LMS.xcodeproj')

borrower_target = project.targets.find { |t| t.name == 'BorrowerApp' }
staff_target = project.targets.find { |t| t.name == 'StaffApp' }

# Find the group
shared_group = project.main_group.find_subpath(File.join('Shared', 'Services'), true)

# Add the file reference
file_ref = shared_group.new_reference('SecureKeychainService.swift')

# Add to targets
borrower_target.add_file_references([file_ref])
staff_target.add_file_references([file_ref])

project.save
puts "Added SecureKeychainService.swift to project targets successfully!"
