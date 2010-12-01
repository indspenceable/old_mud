require 'rspec/core/rake_task'

task :default => :all
task :all => [:doc, :spec]

RSpec::Core::RakeTask.new do |t|
  t.rspec_opts = ["--color"]
end

task :doc do |t|
  `rdoc`
end
