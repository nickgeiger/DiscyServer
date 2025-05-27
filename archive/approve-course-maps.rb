## This should be run from the project root directory (DiscyServer):
## ruby archive/approve-course-maps.rb

#!/usr/bin/env ruby
require 'json'
require 'fileutils'
require 'open-uri'
require 'digest'


# Fetches latest server course and returns JSON or nil
def fetch_pending_course(course_id)
  url = "https://www.nickgeiger.com/api/discy/course-maps/_pending_/#{course_id}.json"
  begin
    response = URI.open(url).read
    return JSON.parse(response)
  rescue OpenURI::HTTPError => e
    puts "HTTP Error: #{e.message}"
    return nil
  rescue JSON::ParserError => e
    puts "JSON Parsing Error: #{e.message}"
    return nil
  rescue => e
    puts "Error: #{e.message}"
    return nil
  end
end

def parse_json_file(file_path)
  begin
    # Read the JSON file
    json_content = File.read(file_path)
    
    # Parse the JSON content
    return JSON.parse(json_content)
  rescue JSON::ParserError => e
    puts "JSON Parsing Error: #{e.message}"
    return nil
  rescue => e
    puts "Error: #{e.message}"
    return nil
  end
end


# Main function to process the approved course maps
def approve_course_maps

  pending_courses = parse_json_file("archive/pending-course-maps.json")
  unless pending_courses && pending_courses.length > 0
    puts "No pending courses to approve"
    exit 1
  end

  approved_count = 0
  pending_courses.each do |course_id, pending|
    puts "courseId: #{course_id}"
    puts "  #{pending}"
    if pending["approved"]
      puts "Approving courseId: #{course_id}"
      approved_count += 1
    end
  end

  if approved_count < 1
    puts "No pending courses were approved"
    exit 1
  end

#approved_courses=($(jq -r 'to_entries[] | select(.value.approved == true) | .key' archive/pending-course-maps.json))
#if [[ ${#approved_courses[@]} -gt 0 ]]; then

#    for course_id in "${approved_courses[@]}"; do
#        echo "Processing approved courseId: $course_id"

        # pull server to local: ng.com/api/discy/course-maps/_pending_ to app/course-maps
        # delete from _pending_ (local): rm app/course-maps/_pending_/foo.json foo.changes.json
#        echo "rsync nick@nickgeiger.com:/home/nick/api/discy/course-maps/_pending/${course_id}.json > app/course-maps"
#        echo "rm app/course-maps/_pending/${course_id}.json"
#        echo "rm app/course-maps/_pending/${course_id}.changes.json"

        ##echo "curl https://www.nickgeiger.com/api/discy/course-maps/_pending_/${course_id}.json > app/course-maps/${course_id}
#    done

# update pending-courses.json: delete pending["foo"]
# git add .
# git commit -am "archive/archive.sh approved foo,bar,..."
# git push or die (conflict or issue.. try again next time but don't proceed to archiving until approval succeeds)
# Deploy the changes
### ./deploy/deploy-course-maps-prod.sh ##################### DEBUG #################

end

# Execute the main function
approve_course_maps

