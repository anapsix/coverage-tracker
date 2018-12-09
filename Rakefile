require 'rake/testtask'

# Rake::TestTask.new do |t|
#   t.pattern = 'tests/*_test.rb'
# end

task :test do
  Dir.glob('./tests/*_test.rb').each do |file|
    puts "Running tests from: #{file}"
    require file
  end
end