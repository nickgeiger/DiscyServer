#!/usr/bin/env ruby
require 'json'
require 'fileutils'

# Base directory containing the archive structure
BASE_DIR = 'archives'

# This function processes a single JSON file
def process_json_file(file_path)
  puts "Processing file: #{file_path}"
  
  begin
    # Read the JSON file
    json_content = File.read(file_path)
    
    # Parse the JSON content
    data = JSON.parse(json_content)
    
    # Here you can add your specific processing logic for each JSON file
    # For example:
    puts "  File contains #{data.keys.length} top-level keys"
    
    # Example processing - you can modify this according to your needs
    # data.each do |key, value|
    #   puts "  Key: #{key}, Type: #{value.class}"
    # end
    
    return true
  rescue JSON::ParserError => e
    puts "  ERROR: Failed to parse JSON: #{e.message}"
    return false
  rescue => e
    puts "  ERROR: Failed to process file: #{e.message}"
    return false
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
    Dir.glob("#{archive_dir}/*").select { |f| File.directory?(f) }.each do |foo_dir|
      directories_found += 1
      foo_name = File.basename(foo_dir)
      
      puts "\nProcessing directory: #{foo_dir} (timestamp: #{timestamp}, name: #{foo_name})"
      
      # Process all JSON files in this directory
      json_files = Dir.glob("#{foo_dir}/*.json")
      puts "Found #{json_files.length} JSON files"
      
      json_files.each do |json_file|
        if process_json_file(json_file)
          json_files_processed += 1
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


