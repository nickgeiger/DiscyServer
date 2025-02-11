#!/bin/bash

# Source = Published Maps Dir
#source="zsource/" # TEST
source="/home/nick/apps/nickgeiger/api/discy/publish-course-map/published-maps/" # Make sure the trailing slash is included
dest="/home/nick/discy-published-map-archives/archive-$(date +%s)/"

echo "Archiving: $source"
echo "Destination: $dest"

# Check if there are any JSON files in the source directory
if ! find "$source" -name "*.json" -print0 | grep -q .; then # grep -q suppresses output, exits with 0 if match, 1 if no match
  echo "Error: No JSON files found in source directory '$source'." >&2
  exit 1
fi

# Loop through JSON and move to an archive folder dest preserving old dir structure
find "$source" -name "*.json" -print0 | while IFS= read -r -d $'\0' file; do
  file="${file#$source}"; # Remove the leading $source using the variable directly
  new_dir="${file%/*}";
  #echo "mkdir -p \"$dest$new_dir\";"
  mkdir -p "$dest$new_dir";
  #echo "mv \"$source$file\" \"$dest$new_dir\";"
  mv "$source$file" "$dest$new_dir";
  echo "archived: $dest$file"
done

