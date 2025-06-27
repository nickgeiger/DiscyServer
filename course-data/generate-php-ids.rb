require 'json'

rawfile = ARGV[0]
unless ARGV.length == 1 && File.file?(rawfile)
  puts "Usage: ruby php-courses.rb [courses.json]"
  exit(1)
end

raw = File.read(rawfile)
json = JSON.parse(raw)

count = 0
courseIds = Array.new
json.each do |value|
  courseId = value["courseId"]
  if courseId
    courseIds << courseId
  end

  # Limit for testing
  count += 1
  if count >= 5
##    break
  end
end

courseIds.sort!

puts "<?php\n"
puts "$sortedCourseIds = [\"" + courseIds.join("\",\"") + "\"];"
