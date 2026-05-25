require 'xcodeproj'
project_path = 'LMS.xcodeproj'
project = Xcodeproj::Project.open(project_path)

bad_manager_path = 'Shared/Services/Supabase/Shared/Services/Supabase/SupabaseManager.swift'
bad_auth_path = 'Shared/Services/Supabase/Shared/Services/Supabase/SupabaseAuthService.swift'

# Let's just fix all file references that are wrong
project.files.each do |file|
  if file.path == 'Shared/Services/Supabase/SupabaseManager.swift'
    # The group already sets its path to 'Supabase', so the file path relative to the group should just be 'SupabaseManager.swift'
    file.set_path('SupabaseManager.swift')
  elsif file.path == 'Shared/Services/Supabase/SupabaseAuthService.swift'
    file.set_path('SupabaseAuthService.swift')
  end
end

project.save
puts "Fixed paths!"
