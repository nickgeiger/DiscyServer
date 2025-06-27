## This should be run from the project root directory (DiscyServer):
## ./course-data/update-courses.sh

courses_json="app/courses.json"
temp_courses="$HOME/Documents/courses-to-update.json"

# Apply the course changes to courses.json
cp ${courses_json} ${temp_courses}

echo "ruby course-data/addedit-course.rb ${temp_courses} course-data/course-changes.json > ${courses_json}"
ruby course-data/addedit-course.rb ${temp_courses} course-data/course-changes.json > ${courses_json}

trash ${temp_courses}

# Generate the PHP course IDs
echo "\nruby course-data/generate-php-ids.rb ${courses_json} > app/publish-course-map/course-ids.php"
ruby course-data/generate-php-ids.rb ${courses_json} > app/publish-course-map/course-ids.php

# Generate the courses.json hash
echo "\nsha256 ${courses_json} | awk '{print \$NF}' > app/courses.json.sha256"
sha256 ${courses_json} | awk '{print $NF}' > app/courses.json.sha256

