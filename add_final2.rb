require 'xcodeproj'
project_path = 'LMS.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'BorrowerApp' }

shared = project.main_group.children.find { |c| c.path == 'Shared' }
services = shared.children.find { |c| c.path == 'Services' }

file1 = services.new_file('Supabase/SupabaseMessagingService.swift')
file2 = services.new_file('Supabase/SupabaseDocumentService.swift')

target.add_file_references([file1, file2])
puts "Added files: #{file1.real_path}"

project.save
