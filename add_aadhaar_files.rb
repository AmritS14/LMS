require 'xcodeproj'
project = Xcodeproj::Project.open('LMS.xcodeproj')

borrower = project.targets.find { |t| t.name == 'BorrowerApp' }
staff    = project.targets.find { |t| t.name == 'StaffApp' }

# 1. Shared/Services/AadhaarKYCService.swift → both targets
svc_group = project.main_group.find_subpath('Shared/Services', true)
kyc_proto = svc_group.new_reference('AadhaarKYCService.swift')
borrower.add_file_references([kyc_proto])
staff.add_file_references([kyc_proto])

# 2. Shared/Services/Supabase/SupabaseAadhaarKYCService.swift → both targets
supa_group = project.main_group.find_subpath('Shared/Services/Supabase', true)
kyc_supa = supa_group.new_reference('SupabaseAadhaarKYCService.swift')
borrower.add_file_references([kyc_supa])
staff.add_file_references([kyc_supa])

# 3. BorrowerApp/Views/AadhaarKYCView.swift → BorrowerApp only
borrower_views = project.main_group.find_subpath('BorrowerApp/Views', true)
aadhaar_view = borrower_views.new_reference('AadhaarKYCView.swift')
borrower.add_file_references([aadhaar_view])

# 4. StaffApp/Views/LoanOfficer/AadhaarVerificationReportCard.swift → StaffApp only
lo_group = project.main_group.find_subpath('StaffApp/Views/LoanOfficer', true)
report_card = lo_group.new_reference('AadhaarVerificationReportCard.swift')
staff.add_file_references([report_card])

project.save
puts "All Aadhaar KYC files registered in Xcode project."
