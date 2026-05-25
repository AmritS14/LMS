require 'xcodeproj'
project_path = 'LMS.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'BorrowerApp' }

target.source_build_phase.files.each do |build_file|
  if build_file.file_ref && (build_file.file_ref.name == 'SupabaseMessagingService.swift' || build_file.file_ref.name == 'SupabaseDocumentService.swift')
    build_file.file_ref.remove_from_project
  end
end

group = project.main_group.find_subpath('Shared/Services/Supabase', false)
if group
  file1 = group.new_file('Shared/Services/Supabase/SupabaseMessagingService.swift')
  file1.source_tree = '<group>'
  file1.set_path('Shared/Services/Supabase/SupabaseMessagingService.swift')
  
  file2 = group.new_file('Shared/Services/Supabase/SupabaseDocumentService.swift')
  file2.source_tree = '<group>'
  file2.set_path('Shared/Services/Supabase/SupabaseDocumentService.swift')

  target.add_file_references([file1, file2])
end
project.save
