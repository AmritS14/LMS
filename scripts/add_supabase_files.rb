require 'xcodeproj'
project_path = 'LMS.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find Shared/Services group
shared_group = project.main_group.find_subpath(File.join('Shared', 'Services'), true)

# Create Supabase subgroup
supabase_group = shared_group.find_subpath('Supabase', true)
supabase_group.set_source_tree('<group>')
supabase_group.set_path('Supabase')

borrower_target = project.targets.find { |t| t.name == 'BorrowerApp' }
staff_target = project.targets.find { |t| t.name == 'StaffApp' }

[
  { group: supabase_group, path: 'Shared/Services/Supabase/SupabaseManager.swift', targets: [borrower_target, staff_target] },
  { group: supabase_group, path: 'Shared/Services/Supabase/SupabaseAuthService.swift', targets: [borrower_target, staff_target] }
].each do |item|
  # We should use relative path to project root
  full_path = File.expand_path(item[:path], Dir.pwd)
  
  unless item[:group].files.any? { |f| f.real_path.to_s == full_path }
    file_ref = item[:group].new_reference(item[:path])
    item[:targets].compact.each { |t| t.add_file_references([file_ref]) }
  end
end

project.save
puts "Added Supabase files to project."
