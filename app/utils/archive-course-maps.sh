#!/bin/bash

# Destination = Input
# Check if the destination directory argument is provided
if [ -z "$1" ]; then
  echo -e "Usage: ./archive-course-maps.sh [output_dir]\n - output_dir is missing" >&2  # Output error to stderr
  exit 1  # Exit with a non-zero status to indicate an error
fi
dest="$1"  # Assign the first argument to the destination variable
# Add trailing slash to destination if it's missing
if [[ ! "$dest" =~ /$ ]]; then  # Use regex to check for trailing slash. =/ is regex match
  dest+="/"
fi

# Source = Published Maps Dir
#source="zsource/" # TEST
source= "~/apps/nickgeiger/api/discy/publish-course-map/published-maps/" # Make sure the trailing slash is included

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

