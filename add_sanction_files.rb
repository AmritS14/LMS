require 'xcodeproj'
project_path = '/Users/test/Desktop/LMS/LMS.xcodeproj'
project = Xcodeproj::Project.open(project_path)

borrower_target = project.targets.find { |t| t.name == 'BorrowerApp' }
staff_target = project.targets.find { |t| t.name == 'StaffApp' }

# Get groups
shared_services_group = project.main_group.find_subpath(File.join('Shared', 'Services'), true)
shared_mocks_group = shared_services_group.find_subpath('Mocks', true)
shared_supabase_group = shared_services_group.find_subpath('Supabase', true)

borrower_group = project.main_group.find_subpath('BorrowerApp', true)
borrower_viewmodels_group = borrower_group.find_subpath('ViewModels', true)
borrower_views_group = borrower_group.find_subpath('Views', true)

files_to_add = [
  # Shared
  { group: shared_services_group, path: '/Users/test/Desktop/LMS/Shared/Services/SanctionLetterService.swift', targets: [borrower_target, staff_target] },
  { group: shared_supabase_group, path: '/Users/test/Desktop/LMS/Shared/Services/Supabase/SupabaseSanctionLetterService.swift', targets: [borrower_target, staff_target] },
  { group: shared_mocks_group, path: '/Users/test/Desktop/LMS/Shared/Services/Mocks/MockSanctionLetterService.swift', targets: [borrower_target, staff_target] },
  
  # Borrower App
  { group: borrower_viewmodels_group, path: '/Users/test/Desktop/LMS/BorrowerApp/ViewModels/SanctionLetterViewModel.swift', targets: [borrower_target] },
  { group: borrower_views_group, path: '/Users/test/Desktop/LMS/BorrowerApp/Views/SanctionLetterView.swift', targets: [borrower_target] }
]

files_to_add.each do |item|
  # Make sure we don't duplicate
  existing_ref = item[:group].files.find { |f| f.real_path.to_s == item[:path] }
  if existing_ref
    item[:targets].compact.each do |t|
      unless t.source_build_phase.files.any? { |bf| bf.file_ref == existing_ref }
        t.add_file_references([existing_ref])
      end
    end
  else
    file_ref = item[:group].new_reference(item[:path])
    item[:targets].compact.each { |t| t.add_file_references([file_ref]) }
  end
end

project.save
puts "Added sanction letter files to Xcode project successfully."
