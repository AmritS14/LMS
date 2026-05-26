require 'xcodeproj'
project = Xcodeproj::Project.open('LMS.xcodeproj')

bad_paths = [
  '/Users/namangupta/Desktop/LMS/Shared/Services/Mocks/MockAuthService.swift',
  '/Users/namangupta/Desktop/LMS/Shared/Services/Mocks/MockLoanService.swift',
  '/Users/namangupta/Desktop/LMS/Shared/Services/Mocks/MockSupportServices.swift',
  '/Users/namangupta/Desktop/LMS/BorrowerApp/ViewModels/DashboardViewModel.swift',
  '/Users/namangupta/Desktop/LMS/BorrowerApp/ViewModels/RepaymentViewModel.swift',
  '/Users/namangupta/Desktop/LMS/BorrowerApp/ViewModels/MessagingViewModel.swift'
]

# Remove bad references
project.files.each do |file|
  if bad_paths.include?(file.path)
    file.remove_from_project
  end
end

borrower_target = project.targets.find { |t| t.name == 'BorrowerApp' }
staff_target = project.targets.find { |t| t.name == 'StaffApp' }

# Function to add file properly with relative path
def add_file_to_project(project, file_path, targets)
  # Find or create group
  components = file_path.split('/')
  filename = components.pop
  
  current_group = project.main_group
  components.each do |c|
    next_group = current_group.children.find { |child| child.class == Xcodeproj::Project::Object::PBXGroup && (child.path == c || child.name == c) }
    if next_group.nil?
      next_group = current_group.new_group(c, c)
    end
    current_group = next_group
  end
  
  file_ref = current_group.new_reference(filename)
  targets.each do |t|
    t.add_file_references([file_ref])
  end
end

# Re-add the valid files
add_file_to_project(project, 'Shared/Services/Mocks/MockAuthService.swift', [borrower_target, staff_target])
add_file_to_project(project, 'Shared/Services/Mocks/MockLoanService.swift', [borrower_target, staff_target])
add_file_to_project(project, 'Shared/Services/Mocks/MockSupportServices.swift', [borrower_target, staff_target])
add_file_to_project(project, 'BorrowerApp/ViewModels/DashboardViewModel.swift', [borrower_target])
add_file_to_project(project, 'BorrowerApp/ViewModels/RepaymentViewModel.swift', [borrower_target])
add_file_to_project(project, 'BorrowerApp/ViewModels/MessagingViewModel.swift', [borrower_target])

# And add our new file
add_file_to_project(project, 'Shared/Services/Supabase/SupabaseLoanService.swift', [borrower_target, staff_target])

project.save
puts "Project fixed!"
