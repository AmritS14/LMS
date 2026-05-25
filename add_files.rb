require 'xcodeproj'
project_path = 'LMS.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'BorrowerApp' }

group = project.main_group.find_subpath('Shared/Services/Supabase', true)

file1 = group.new_file('SupabaseMessagingService.swift')
file2 = group.new_file('SupabaseDocumentService.swift')

target.add_file_references([file1, file2])
project.save
