require 'xcodeproj'

project_path = 'LMS.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# 1. Add Swift Package Reference
package_url = 'https://github.com/supabase-community/supabase-swift'
package_req = {
  'kind' => 'upToNextMajorVersion',
  'minimumVersion' => '2.0.0'
}

# Check if the package is already added
pkg_ref = project.root_object.package_references.find { |p| p.repositoryURL == package_url }

unless pkg_ref
  pkg_ref = project.new(Xcodeproj::Project::Object::XCRemoteSwiftPackageReference)
  pkg_ref.repositoryURL = package_url
  pkg_ref.requirement = package_req
  project.root_object.package_references << pkg_ref
end

# 2. Add Package Product Dependency to Targets
borrower_target = project.targets.find { |t| t.name == 'BorrowerApp' }
staff_target = project.targets.find { |t| t.name == 'StaffApp' }

[borrower_target, staff_target].each do |target|
  next unless target

  # Check if target already has the dependency
  has_dep = target.package_product_dependencies.any? { |dep| dep.product_name == 'Supabase' }
  unless has_dep
    # Add product dependency
    product_dep = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
    product_dep.product_name = 'Supabase'
    product_dep.package = pkg_ref
    
    target.package_product_dependencies << product_dep
    
    # Also add to framework build phase
    framework_phase = target.frameworks_build_phase
    
    if framework_phase
      build_file = project.new(Xcodeproj::Project::Object::PBXBuildFile)
      build_file.product_ref = product_dep
      framework_phase.files << build_file
    end
  end
end

project.save
puts "Successfully added Supabase Swift Package to LMS.xcodeproj"
