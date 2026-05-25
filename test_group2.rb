require 'xcodeproj'
project_path = 'LMS.xcodeproj'
project = Xcodeproj::Project.open(project_path)
puts project.main_group.children.map(&:path)
