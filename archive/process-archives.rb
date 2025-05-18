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
# Returns: {
#   "result" => :no_changes, :holes_changed, :layout_changed, or :holes_and_layout_changed,
#   "diffs" => ["description of change"...]
# }
def compare_course(reference_course, candidate_course)
  puts "\nComparing courses" if V

  # Are there any hole changes?
  hole_diffs = []

  ref_holes = reference_course["holes"]
  cand_holes = candidate_course["holes"]
  if ref_holes.length != cand_holes.length
    hc = cand_holes.length
    puts "Hole count mismatch: reference course = #{ref_holes.length} holes; candidate course = #{hc} holes" if V
    hole_diffs << "New course has #{hc} hole#{hc == 1 ? '' : 's'} (vs. #{ref_holes.length})"
  else
    hole_num = 1
    ref_holes.zip(cand_holes).each do |ref_hole, cand_hole|
      puts "Ref Hole\n#{JSON.pretty_generate(ref_hole)}" if V && false
      puts "Cand Hole\n#{JSON.pretty_generate(cand_hole)}" if V && false
      compare_hole(hole_num, ref_hole, cand_hole, hole_diffs)
      hole_num += 1
    end
  end

  # Are there any layout changes?
  layout_diffs = []
  ## TODO - compare layouts

  return case
  when hole_diffs.any? && layout_diffs.any?
    { "result" => :holes_and_layout_changed, "diffs" => hole_diffs + layout_diffs }
  when layout_diffs.any?
    { "result" => :layout_changed, "diffs" => layout_diffs }
  when hole_diffs.any?
    { "result" => :holes_changed, "diffs" => hole_diffs }
  else
    { "result" => :no_changes }
  end
end

def compare_hole(hole_number, ref_hole, cand_hole, diffs)

  hole_name = ref_hole["name"] || hole_number

  if ref_hole["name"] != cand_hole["name"]
    diffs << "Hole '#{hole_name}' renamed to '#{cand_hole["name"]}'"
  end
  if ref_hole["par"] != cand_hole["par"]
    diffs << "Hole '#{hole_name}' par set to #{cand_hole["par"]} (vs. #{ref_hole["par"] || 'nil'})"
  end
  if ref_hole["distanceMeters"] != cand_hole["distanceMeters"]
    diffs << "Hole '#{hole_name}' distanceMeters set to #{cand_hole["distanceMeters"]} (vs. #{ref_hole["distanceMeters"] || 'nil'})"
  end

  ref_tees = ref_hole["tees"]
  cand_tees = cand_hole["tees"]
  if ref_tees.length != cand_tees.length
    tc = cand_tees.length
    puts "Hole '#{hole_name}' tee count mismatch: reference = #{ref_tees.length}, candidate = #{tc}" if V
    diffs << "Hole '#{hole_name}' has #{tc} tee#{tc == 1 ? '' : 's'} (vs. #{ref_tees.length})"
  else
    tee_num = 1
    ref_tees.zip(cand_tees).each do |ref_tee, cand_tee|
      tee_name = ref_tee["name"] || tee_num
      compare_tee_or_pin("Hole '#{hole_name}' tee '#{tee_name}'", ref_tee, cand_tee, diffs)
      #### TODO: Compare toPinSettings(if pins !matched, diff could expect to be off)
      tee_num += 1
    end
  end

  ref_pins = ref_hole["pins"]
  cand_pins = cand_hole["pins"]
  if ref_pins.length != cand_pins.length
    pc = cand_pins.length
    puts "Hole '#{hole_name}' pin count mismatch: reference = #{ref_pins.length}, candidate = #{pc}" if V
    diffs << "Hole '#{hole_name}' has #{pc} pin#{pc == 1 ? '' : 's'} (vs. #{ref_pins.length})"
  else
    pin_num = 1
    ref_pins.zip(cand_hole["pins"]).each do |ref_pin, cand_pin|
      pin_name = ref_pin["name"] || pin_num
      compare_tee_or_pin("Hole '#{hole_name}' pin '#{pin_name}'", ref_pin, cand_pin, diffs)
      pin_num += 1
    end
  end

end

# Compares tee or pin: name, latitude, longitude
def compare_tee_or_pin(tee_or_pin_desc, ref_tee_pin, cand_tee_pin, diffs)
  if ref_tee_pin["name"] != cand_tee_pin["name"]
    diffs << "#{tee_or_pin_desc} renamed to '#{cand_tee_pin["name"]}'"
  end
  ["latitude", "longitude"].each do |prop|
    if ref_tee_pin[prop].round(6) != cand_tee_pin[prop].round(6)
      diffs << "#{tee_or_pin_desc} #{prop} set to #{cand_tee_pin[prop]} (vs. #{ref_tee_pin[prop]})"
    end
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


    ############# DEBUG ###########
    ## TODO: Remove this, for debug working with 1 archive
    next unless archive_dir == "archives/archive-1747435861"
    ############# DEBUG ###########


    # Process each subdirectory (FOO) in this archive
    Dir.glob("#{archive_dir}/*").select { |f| File.directory?(f) }.each do |course_dir|
      directories_found += 1
      course_id = File.basename(course_dir)

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

	puts "\n#{'#'*60}"*10 if V ############# DEBUG ###########

        candidate_course_json = parse_json_file(json_file)
        if candidate_course_json
          puts "  File contains #{candidate_course_json.keys.length} top-level keys" if V

          result = compare_course(live_course_json, candidate_course_json)
          puts "Comparison result:\n#{JSON.pretty_generate(result)}" if V

          json_files_processed += 1
        else
          json_files_failed += 1
        end
      end

      ############# DEBUG ###########
      result = compare_course(live_course_json, {"holes" => [{"foo" => "bar"}]})
      puts "XX Comparison result:\n#{JSON.pretty_generate(result)}" if V
      ############# DEBUG ###########

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


