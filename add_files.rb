require 'xcodeproj'
project_path = '/Users/namangupta/Desktop/LMS/LMS.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Shared/Services/Mocks
shared_group = project.main_group.find_subpath(File.join('Shared', 'Services'), true)
mocks_group = shared_group.find_subpath('Mocks', true)
mocks_group.set_source_tree('<group>')
mocks_group.set_path('Mocks')

# BorrowerApp/ViewModels
borrower_group = project.main_group.find_subpath('BorrowerApp', true)
viewmodels_group = borrower_group.find_subpath('ViewModels', true)
viewmodels_group.set_source_tree('<group>')
viewmodels_group.set_path('ViewModels')

borrower_target = project.targets.find { |t| t.name == 'BorrowerApp' }
staff_target = project.targets.find { |t| t.name == 'StaffApp' }

[
  { group: mocks_group, path: '/Users/namangupta/Desktop/LMS/Shared/Services/Mocks/MockAuthService.swift', targets: [borrower_target, staff_target] },
  { group: mocks_group, path: '/Users/namangupta/Desktop/LMS/Shared/Services/Mocks/MockLoanService.swift', targets: [borrower_target, staff_target] },
  { group: mocks_group, path: '/Users/namangupta/Desktop/LMS/Shared/Services/Mocks/MockSupportServices.swift', targets: [borrower_target, staff_target] },
  { group: viewmodels_group, path: '/Users/namangupta/Desktop/LMS/BorrowerApp/ViewModels/DashboardViewModel.swift', targets: [borrower_target] },
  { group: viewmodels_group, path: '/Users/namangupta/Desktop/LMS/BorrowerApp/ViewModels/RepaymentViewModel.swift', targets: [borrower_target] },
  { group: viewmodels_group, path: '/Users/namangupta/Desktop/LMS/BorrowerApp/ViewModels/MessagingViewModel.swift', targets: [borrower_target] }
].each do |item|
  unless item[:group].files.any? { |f| f.real_path.to_s == item[:path] }
    file_ref = item[:group].new_reference(item[:path])
    item[:targets].compact.each { |t| t.add_file_references([file_ref]) }
  end
end

project.save
puts "Added files successfully."
