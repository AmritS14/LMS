require 'xcodeproj'

begin
  project = Xcodeproj::Project.open('LMS.xcodeproj')

  # 1. Add Remote Swift Package
  package_ref = project.new(Xcodeproj::Project::Object::XCRemoteSwiftPackageReference)
  package_ref.repositoryURL = 'https://github.com/supabase-community/supabase-swift.git'
  package_ref.requirement = {
    "kind" => "upToNextMajorVersion",
    "minimumVersion" => "2.0.0"
  }
  project.root_object.package_references << package_ref

  # 2. Add product dependencies to both targets
  borrower_target = project.targets.find { |t| t.name == 'BorrowerApp' }
  staff_target = project.targets.find { |t| t.name == 'StaffApp' }

  [borrower_target, staff_target].each do |target|
    product_dependency = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
    product_dependency.product_name = 'Supabase'
    product_dependency.package = package_ref
    target.package_product_dependencies << product_dependency

    # ADD THIS: Link the framework to the target!
    build_file = project.new(Xcodeproj::Project::Object::PBXBuildFile)
    build_file.product_ref = product_dependency
    target.frameworks_build_phase.files << build_file
  end

  # 3. Add the files to the project
  shared_group = project.main_group.find_subpath(File.join('Shared', 'Services'), true)

  auth_ref = shared_group.new_reference('Supabase/SupabaseAuthService.swift')
  mgr_ref = shared_group.new_reference('Supabase/SupabaseManager.swift')
  loan_ref = shared_group.new_reference('Supabase/SupabaseLoanService.swift')

  [borrower_target, staff_target].each do |target|
    target.add_file_references([auth_ref, mgr_ref, loan_ref])
  end

  project.save
  puts "Added Supabase Swift Package and files successfully!"
rescue => e
  puts "Error: #{e.message}"
  puts e.backtrace
end
