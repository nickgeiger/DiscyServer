require 'json'

coursesfile = ARGV[0]
addeditfile = ARGV[1]
unless ARGV.length == 2 && File.file?(coursesfile) && File.file?(addeditfile)
  puts "
NOTE: don't try to output over existing courses JSON file or you'll get an error
 ie: ruby addedit-course.rb JSON/courses.json addedit.json > JSON/courses.json # <-- fails
 instead: ruby addedit-course.rb JSON/courses.json addedit.json > addedcourses.json
 then move: mv addedcourses.json JSON/courses.json
 then cd JSON and follow SYNC.txt to push changes everywhere

"
  puts "Usage: ruby addedit-course.rb [courses.json] [addedit.json]"
  exit(1)
end

courses = JSON.parse(File.read(coursesfile))
addedit = JSON.parse(File.read(addeditfile))

addedit.each do |course|
  courseId = course["courseId"]
  edit_index = courses.find_index{ |c| c["courseId"] == courseId }
  newcourse = {}
  if edit_index
    newcourse = courses[edit_index]
  end
  newcourse.merge!(course)

  #puts "\nAdd/Edit Course ID: #{courseId}"
  #puts course
  #puts ">> New/Edited at? #{edit_index}"
  #puts newcourse

  if edit_index
    courses[edit_index] = newcourse
  else
    courses.append(newcourse)
  end
end

courses.sort_by! { |course| course["courseId"] }

##puts JSON.pretty_generate(courses)
puts JSON.generate(courses)
