require 'xcodeproj'
project_path = 'LMS.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'BorrowerApp' }

# Remove old bad references
target.source_build_phase.files.each do |build_file|
  if build_file.file_ref && (build_file.file_ref.path == 'SupabaseMessagingService.swift' || build_file.file_ref.path == 'SupabaseDocumentService.swift')
    build_file.file_ref.remove_from_project
  end
end

group = project.main_group.find_subpath('Shared/Services/Supabase', false)
if group
  file1 = group.new_file('SupabaseMessagingService.swift')
  file2 = group.new_file('SupabaseDocumentService.swift')
  target.add_file_references([file1, file2])
end
project.save
