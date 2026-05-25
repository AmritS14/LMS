require 'xcodeproj'
project_path = 'LMS.xcodeproj'
project = Xcodeproj::Project.open(project_path)
shared = project.main_group.children.find { |c| c.path == 'Shared' }
services = shared.children.find { |c| c.path == 'Services' }
puts services.children.map { |c| "#{c.class.name}: #{c.path} #{c.name}" }
