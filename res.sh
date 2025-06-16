json_file="app/course-maps/pending-course-maps-FPX0fvc4zkp.json"

##COPY FROM HERE:


jq -r 'to_entries[] | select(.value.approved == false) | .key' $json_file

result=($(jq -r 'to_entries[] | select(.value.approved == false) | .key' $json_file))
echo "result=> '${result}'"




