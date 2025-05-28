## This should be run from the project root directory (DiscyServer):
## ruby archive/process_archives.rb (dev or prod) /Dropbox/DiscyArchives/

#!/usr/bin/env ruby
require 'json'
require 'fileutils'
require 'open-uri'
require 'digest'


# Flag to print verbose output
V = true

# Get and validate the dev_or_prod parameter
dev_or_prod = ARGV[0]
unless dev_or_prod == "dev" || dev_or_prod == "prod"
  puts "Error: Please specify dev or prod"
  puts "Usage: ruby archive/process_archives.rb (dev or prod) (archive_parent_dir)"
  exit 1
end

# Get and validate the archive directory parameter
dir = ARGV[1]
if dir.nil? || dir.strip.empty?
  puts "Error: Please provide the archive parent dir"
  puts "Usage: ruby archive/process_archives.rb (dev or prod) (archive_parent_dir)"
  exit 1
end

COURSE_MAPS_URL="https://www.nickgeiger.com/api#{dev_or_prod == "prod" ? "" : "-wnv8FGB2ewc"}/discy/course-maps/"

# Ensure trailing slash
dir += '/' unless dir.end_with?('/')

begin
  FileUtils.mkdir_p(dir)
rescue StandardError => e
  puts "Error: Could not verify archive parent dir: #{dir}"
  puts "Details: #{e.message}"
  exit 1
end

# Base directory containing the archive structure
BASE_DIR="#{dir}archives"
PROCESSED_DIR="#{dir}archives_processed"


## Compares 2 course JSONs
# reference_course is the current accepted course
# candidate_course is the new course with changes to incorporate
# Returns: {
#   "result" => :invalid_changes, :new_course, :no_changes, :course_changed, :layout_changed, or :course_and_layout_changed
#   "diffs" => ["description of change", "another change", ...]
# }
def compare_course(reference_course, candidate_course)

  unless reference_course
    return { "result" => :new_course }
  end

  diffs = []

  # Any course info changes?
  compare_course_info(reference_course["course"], candidate_course["course"], diffs)

  # Any hole changes?
  ref_holes = reference_course["holes"]
  cand_holes = candidate_course["holes"]
  if ref_holes.length != cand_holes.length
    hc = cand_holes.length
    diffs << "New course has #{hc} hole#{hc == 1 ? '' : 's'} (vs. #{ref_holes.length})"
  else
    hole_num = 1
    ref_holes.zip(cand_holes).each do |ref_hole, cand_hole|
      compare_hole(hole_num, ref_hole, cand_hole, diffs)
      hole_num += 1
    end
  end

  # Any layout changes?
  layout_diffs = []

  ref_layouts = reference_course["layouts"] || []
  cand_layouts = candidate_course["layouts"] || []
  sel_layout_index = candidate_course["selectedLayoutIndex"] || (cand_layouts.length == 1 ? 0 : nil)
  unless cand_layouts.length > 0 && sel_layout_index && sel_layout_index < cand_layouts.length
    layout_diffs << "Candidate course does not have a valid selected layout"
    return { "result" => :invalid_changes, "diffs" => diffs + layout_diffs }
  end

  if ref_layouts.length < 1
    diffs << "Added initial layout"
  elsif ref_layouts.length != cand_layouts.length
    lc = cand_layouts.length
    diffs << "New course has #{lc} layout#{lc == 1 ? '' : 's'} (vs. #{ref_layouts.length})"
  else
    ref_layouts.each_with_index do |ref_layout, layout_index|
      prev_diff_count = layout_diffs.length
      layout_desc = "Layout '#{ ref_layout["name"] || (layout_index + 1) }'"
      compare_layout(layout_desc, ref_layout, cand_layouts[layout_index], layout_diffs)
      if layout_diffs.length > prev_diff_count && layout_index != sel_layout_index
        diffs << "Changes to unplayed #{layout_desc}"
      end
    end
  end

  return case
  when diffs.any? && layout_diffs.any?
    { "result" => :course_and_layout_changed, "diffs" => diffs + layout_diffs }
  when layout_diffs.any?
    { "result" => :layout_changed, "diffs" => layout_diffs }
  when diffs.any?
    { "result" => :course_changed, "diffs" => diffs }
  else
    { "result" => :no_changes }
  end
end

def compare_course_info(ref_course, cand_course, diffs)
  ref_course = ref_course || {}
  cand_course = cand_course || {}
  ["courseId", "name"].each do |prop|
    if ref_course[prop] != cand_course[prop]
      diffs << "Course #{prop} set to #{cand_course[prop] || 'nil'} (vs. #{ref_course[prop] || 'nil'})"
    end
  end
  compare_lat_lon("Course", ref_course, cand_course, diffs)
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

  # Compare pins first as only unchanged pins are worth comparing toPinSettings
  prev_diff_count = diffs.length
  ref_pins = ref_hole["pins"]
  cand_pins = cand_hole["pins"]
  if ref_pins.length != cand_pins.length
    pc = cand_pins.length
    diffs << "Hole '#{hole_name}' has #{pc} pin#{pc == 1 ? '' : 's'} (vs. #{ref_pins.length})"
  else
    pin_num = 1
    ref_pins.zip(cand_hole["pins"]).each do |ref_pin, cand_pin|
      pin_name = ref_pin["name"] || pin_num
      compare_tee_or_pin("Hole '#{hole_name}' Pin '#{pin_name}'", ref_pin, cand_pin, diffs)
      pin_num += 1
    end
  end
  pins_changed = (prev_diff_count < diffs.length)

  # Compare tees
  ref_tees = ref_hole["tees"]
  cand_tees = cand_hole["tees"]
  if ref_tees.length != cand_tees.length
    tc = cand_tees.length
    diffs << "Hole '#{hole_name}' has #{tc} tee#{tc == 1 ? '' : 's'} (vs. #{ref_tees.length})"
  else
    tee_num = 1
    ref_tees.zip(cand_tees).each do |ref_tee, cand_tee|
      tee_name = ref_tee["name"] || tee_num
      tee_desc = "Hole '#{hole_name}' Tee '#{tee_name}'"
      compare_tee_or_pin(tee_desc, ref_tee, cand_tee, diffs)

      # Compare toPinSettings(unless pins changed, then they're expected to be off)
      unless pins_changed
        compare_tee_to_pin_settings(tee_desc, ref_tee, cand_tee, diffs)
      end

      tee_num += 1
    end
  end

end

# Compares tee or pin: name, latitude, longitude
def compare_tee_or_pin(tee_or_pin_desc, ref_tee_pin, cand_tee_pin, diffs)
  if ref_tee_pin["name"] != cand_tee_pin["name"]
    new_name = cand_tee_pin["name"]
    diffs << "#{tee_or_pin_desc} renamed to #{new_name ? "'#{new_name}'" : 'nil'}"
  end
  compare_lat_lon(tee_or_pin_desc, ref_tee_pin, cand_tee_pin, diffs)
end

def compare_lat_lon(desc, ref, cand, diffs)
  ["latitude", "longitude"].each do |prop|
    ref_val = ref[prop] ? ref[prop].round(6) : nil
    cand_val = cand[prop] ? cand[prop].round(6) : nil
    if ref_val != cand_val
      diffs << "#{desc} #{prop} set to #{cand[prop] || 'nil'} (vs. #{ref[prop] || 'nil'})"
    end
  end
end

# Compares tee to pin settings
def compare_tee_to_pin_settings(tee_desc, ref_tee, cand_tee, diffs)

  ref_to_pin_settings = ref_tee["toPinSettings"]
  cand_to_pin_settings = cand_tee["toPinSettings"] || {}

  pin_indexes = []
  if ref_to_pin_settings
    ref_to_pin_settings.each do |pin_index, ref_settings|
      pin_indexes << pin_index
      cand_settings = cand_to_pin_settings[pin_index] || {}
      setting_desc = "#{tee_desc} to 'Pin #{pin_index.to_i+1}' [#{pin_index}]"

      # name, par, distanceMeters, doglegs
      ["name", "par", "distanceMeters"].each do |prop|
        if ref_settings[prop] != cand_settings[prop]
          new_val = cand_settings[prop]
          old_val = ref_settings[prop]
          diffs << "#{setting_desc}: #{prop} set to #{new_val ? "'#{new_val}'" : 'nil'} (vs. #{old_val ? "'#{old_val}'" : 'nil'})"
        end
      end

      # doglegs...
      ref_doglegs = ref_settings["doglegs"] || []
      cand_doglegs = cand_settings["doglegs"] || []
      if ref_doglegs.length != cand_doglegs.length
        dc = cand_doglegs.length
        diffs << "#{setting_desc} has #{dc} dogleg#{dc == 1 ? '' : 's'} (vs. #{ref_doglegs.length})"
      else
        # name, par, distanceMeters, doglegs
        dogleg_index = 0
        ref_doglegs.zip(cand_doglegs) do |ref_dogleg, cand_dogleg|
          compare_lat_lon("#{setting_desc} - Dogleg[#{dogleg_index}]:", ref_dogleg, cand_dogleg, diffs)
          dogleg_index += 1
        end
      end
    end
  end
  cand_to_pin_settings.each do |pin_index, cand_settings|
    if !pin_indexes.include?(pin_index)
      ["name", "par", "distanceMeters", "doglegs"].each do |prop|
        if cand_settings[prop]
          val = " '#{cand_settings[prop]}'" unless prop == "doglegs"
          diffs << "#{tee_desc} to 'Pin #{pin_index.to_i+1}' [#{pin_index}]: added #{prop}#{val}"
        end
      end
    end
  end
end

def compare_layout(layout_desc, ref_layout, cand_layout, diffs)
  if ref_layout["name"] != cand_layout["name"]
    diffs << "#{layout_desc} renamed to '#{cand_layout["name"]}'"
  end
  ref_holes = ref_layout["holes"]
  cand_holes = cand_layout["holes"]
  if ref_holes.length != cand_holes.length
    hc = cand_holes.length
    diffs << "#{layout_desc} has #{hc} hole#{hc == 1 ? '' : 's'} (vs. #{ref_holes.length})"
  else
    hole_num = 1
    ref_holes.zip(cand_holes).each do |ref_hole, cand_hole|
      ["holeIndex", "teeIndex", "pinIndex"].each do |prop|
        if ref_hole[prop] != cand_hole[prop]
          ## TODO? Dig up hole name instead of using hole_num... candidate hole? Would need holes passed in...
          diffs << "#{layout_desc} - Hole #{hole_num}: #{prop} set to #{cand_hole[prop] || 'nil'} (vs. #{ref_hole[prop] || 'nil'})"
        end
      end
      hole_num += 1
    end
  end
end

# Fetches latest server course and returns JSON or nil
def fetch_live_course(course_id)
  url = "#{COURSE_MAPS_URL}#{course_id}.json"
  puts "Live course URL: #{url}"
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

# Main function to traverse the directory structure
def process_directory_structure
  # Statistics
  directories_found = 0
  json_files_processed = 0
  json_files_failed = 0

  courses = parse_json_file("app/courses.json")
  pending_course_maps_file = "archive/pending-course-maps.json"
  pending_course_maps = parse_json_file(pending_course_maps_file) || {}

  course_maps_pending_dir = "app/course-maps/_pending_/"
  FileUtils.mkdir_p(course_maps_pending_dir)

  FileUtils.mkdir_p(PROCESSED_DIR)

  # Pattern matching archive/archives/archive-TIMESTAMP/COURSE_DIR
  Dir.glob("#{BASE_DIR}/archive-*").each do |archive_dir|

    # Extract the timestamp
    timestamp = archive_dir.split('-').last
    
    # Verify that timestamp is numeric
    next unless timestamp =~ /^\d+$/

    # Process each subdirectory (course_id) in this archive
    Dir.glob("#{archive_dir}/*").select { |f| File.directory?(f) }.each do |course_dir|
      directories_found += 1
      course_id = File.basename(course_dir)

      # TODO: _unknown courses could be new course candidates... queue for manual review
      if course_id == "_unknown"
        puts "\nSkipping unknown course(s): #{course_dir}"
        next
      end

      # Ensure courseId is valid
      course = courses.bsearch{ |course| course_id <=> course["courseId"] }
      puts "Course for #{course_id}: #{course}" if V
      unless course
        # This shouldn't really happen because the server is also validating...
        puts "\nSkipping unknown course(s): #{course_id}"
        next
      end

      live_course_json = fetch_live_course(course_id)
      unless live_course_json
        puts "  no live_course for #{course_id}" if V
      end
      
      # Process all JSON files in this directory
      json_files = Dir.glob("#{course_dir}/*.json")
      
      json_files.each do |json_file|

        candidate_course_json = parse_json_file(json_file)
        if candidate_course_json

          result = compare_course(live_course_json, candidate_course_json)

          puts "\n#{'#'*60}\nComparison result: #{json_file}\n#{JSON.pretty_generate(result)}" if V

          case result["result"]

            when :no_changes, :invalid_changes

              # Nothing to do here
              puts "No valid course changes to queue" if V

            when :layout_changed

              course_file = "app/course-maps/#{course_id}.json"
              FileUtils.cp(json_file, course_file)
              puts "Queued layout change: #{course_file}" if V

            when :new_course, :course_changed, :course_and_layout_changed

              pending_course_file = "#{course_maps_pending_dir}#{course_id}.json"
              FileUtils.cp(json_file, pending_course_file)

              pending_course_maps[course_id] = {
                :hash => Digest::MD5.file(pending_course_file).hexdigest,
                :changes => result,
                :approved => false
              }

              changes_file = "#{course_maps_pending_dir}#{course_id}.changes.json"
              File.write(changes_file, result.to_json)

              puts "Queued course change: #{pending_course_file}" if V
          else
            puts "Unknown result: '#{result["result"]}' for: #{json_file}"
          end

          json_files_processed += 1
        else
          json_files_failed += 1
        end
      end

      File.write(pending_course_maps_file, JSON.pretty_generate(pending_course_maps))
    end

    # Move the entire processed archive folder to the "done" dir

    # Generate unique processed folder in case we are "re-archiving" this
    processed_to = PROCESSED_DIR
    if File.exist?("#{PROCESSED_DIR}#{archive_dir}")
      counter = 0
      loop do
        counter += 1
        processed_to = File.join(PROCESSED_DIR, "#{archive_dir}-#{counter}")
        break unless File.exist?(processed_to)
      end
      puts "Processed to re-archived dir: #{processed_to}" if V
    end

    FileUtils.mv(archive_dir, processed_to)

  end

  # Print summary
  puts "\n=== Processing Complete ==="
  puts "Processed archive directory: #{BASE_DIR}"
  puts "Directories processed: #{directories_found}"
  puts "JSON files successfully processed: #{json_files_processed}"
  puts "JSON files failed to process: #{json_files_failed}"
end


# Execute the main function
process_directory_structure

