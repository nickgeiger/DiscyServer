#!/bin/bash

# For demonstration, let's create a dummy json_file
json_file="data.json"
cat <<EOF > "$json_file"
{
  "first-result": { "approved": false },
  "another-one": { "approved": false },
  "third-item": { "approved": true },
  "fourth-item": { "approved": false }
}
EOF

# Capture all lines into an array
result=($(jq -r 'to_entries[] | select(.value.approved == false) | .key' "$json_file"))

# Join the array elements with a comma
# Set IFS to the desired delimiter (comma and space in this case)
IFS=', ' # Important: The space after the comma is often desired for readability
joined_result="${result[*]}" # Use "${array[*]}" to join all elements with IFS
joined_result=${joined_result//,/, }

echo "Comma-separated result (using IFS) => '${joined_result}'"

#jmy_result=(printf $result[@] | sed 's/, $//'")
#jecho "my_result => '${my_result}'"

# Reset IFS to its default value (important for other commands)
unset IFS

# Clean up the dummy file
rm "$json_file"
