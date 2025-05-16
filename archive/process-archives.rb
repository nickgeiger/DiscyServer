#!/usr/bin/env ruby
require 'json'
require 'fileutils'
require 'open-uri'

# Flag to print verbose output
V = true

# Base directory containing the archive structure
BASE_DIR = 'archives'

## Compares 2 course JSONs
# reference_course is the current accepted course
# candidate_course is the new course with changes to incorporate
# Returns: :no_changes, :holes_changed, :layout_changed
def compare_course(reference_course, candidate_course)
  puts "Comparing courses" if V

  # Are there any hole changes?
  reference_course["holes"].each do |hole|
    puts "Hole\n #{hole}" if V
  end
end

# Fetches latest server course and returns JSON or nil
def fetch_live_course(course_id)
  url = "https://www.nickgeiger.com/api/discy/course-maps/#{course_id}.json"
  puts "Fetching live course: #{url}" if V
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
  puts "Parsing JSON file: #{file_path}" if V
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

# Main function to traverse the directory structure
def process_directory_structure
  # Statistics
  directories_found = 0
  json_files_processed = 0
  json_files_failed = 0
  
  # Pattern matching archives/archive-NUM/FOO
  Dir.glob("#{BASE_DIR}/archive-*").each do |archive_dir|

    # Extract the timestamp (NUM)
    timestamp = archive_dir.split('-').last
    
    # Verify that NUM is a timestamp (numeric)
    next unless timestamp =~ /^\d+$/
    
    # Process each subdirectory (FOO) in this archive
    Dir.glob("#{archive_dir}/*").select { |f| File.directory?(f) }.each do |course_dir|
      directories_found += 1
      course_id = File.basename(course_dir)

      ## TODO: Remove this, for debug working with 1 file
      next unless course_dir == "archives/archive-1741301581/moraga-commons-park"

      # TODO: _unknown courses could be new course candidates
      if course_id == "_unknown"
        puts "\nSkipping unknown course(s): #{course_dir}"
        next
      end

      puts "\nProcessing course directory: #{course_dir} (timestamp: #{timestamp}, courseId: #{course_id})" if V

      live_course_json = fetch_live_course(course_id)
      if live_course_json
        puts "  live_course contains #{live_course_json.keys.length} top-level keys" if V
      else
        puts "  no live_course for #{course_id}" if V
      end
      
      # Process all JSON files in this directory
      json_files = Dir.glob("#{course_dir}/*.json")
      puts "Found #{json_files.length} JSON files" if V
      
      json_files.each do |json_file|
        candidate_course_json = parse_json_file(json_file)
        if candidate_course_json
          json_files_processed += 1
          puts "  File contains #{candidate_course_json.keys.length} top-level keys" if V

          compare_course(live_course_json, candidate_course_json)
        else
          json_files_failed += 1
        end
      end
    end
  end
  
  # Print summary
  puts "\n=== Processing Complete ==="
  puts "Directories processed: #{directories_found}"
  puts "JSON files successfully processed: #{json_files_processed}"
  puts "JSON files failed to process: #{json_files_failed}"
end

# Execute the main function
process_directory_structure

# TODO:
# Type of changes: 1) none 2) layout only (teeIndex or pinIndex) 3) holes changed (add/edit/delete tee,pin,or dogleg)
# 1. processed & done, 2. layout candidate (or auto-publish) 3. course update candidate


