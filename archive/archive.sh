## This should be run from the project root directory (DiscyServer):
## ./archive/archive.sh /Dropbox/DiscyArchives/

## -e Ensures the script dies if there's an error, important so we don't
## accidentally continue and nuke server archive if it wasn't backed up
set -e


# Get and validate the archive directory parameter
dir="$1"
if [ -z "$dir" ]; then
    echo "Error: Please provide the archive parent dir"
    echo "Usage: ./archive/archive.sh (archive_parent_dir)"
    exit 1
fi
# Ensure trailing slash
[[ "$dir" != */ ]] && dir="$dir/"
if ! mkdir -p "$dir"; then
    echo "Error: Could not verify archive parent dir: $dir"
    exit 1
fi


# Sync with git
git pull


# TODO: Deploy approved courses
if ruby archive/approve-course-maps.rb; then

  echo "Ruby script succeeded!"
  # success commands
# update pending-courses.json: delete pending["foo"]
# git add .
# git commit -am "archive/archive.sh approved foo,bar,..."
# git push or die (conflict or issue.. try again next time but don't proceed to archiving until approval succeeds)
# Deploy the changes
### ./deploy/deploy-course-maps-prod.sh ##################### DEBUG #################
    
else
  echo "No courses to approve or error approving courses"
fi

# for approved courseID (in archive/pending-course-maps.json):

approved_courses=($(jq -r 'to_entries[] | select(.value.approved == true) | .key' archive/pending-course-maps.json))
if [[ ${#approved_courses[@]} -gt 0 ]]; then

    for course_id in "${approved_courses[@]}"; do
        echo "Processing approved courseId: $course_id"

        # pull server to local: ng.com/api/discy/course-maps/_pending_ to app/course-maps
        # delete from _pending_ (local): rm app/course-maps/_pending_/foo.json foo.changes.json
        echo "rsync nick@nickgeiger.com:/home/nick/api/discy/course-maps/_pending/${course_id}.json > app/course-maps"
        echo "rm app/course-maps/_pending/${course_id}.json"
        echo "rm app/course-maps/_pending/${course_id}.changes.json"

        ##echo "curl https://www.nickgeiger.com/api/discy/course-maps/_pending_/${course_id}.json > app/course-maps/${course_id}
    done

# update pending-courses.json: delete pending["foo"]
# git add .
# git commit -am "archive/archive.sh approved foo,bar,..."
# git push or die (conflict or issue.. try again next time but don't proceed to archiving until approval succeeds)
# Deploy the changes
### ./deploy/deploy-course-maps-prod.sh ##################### DEBUG #################
    
else
    echo "No approved courses to publish"
fi
##jq -r 'to_entries[] | select(.value.approved == true) | .key' archive/pending-course-maps.json | while read course_id; do



# Pull the archives
server_archive_dir="/home/nick/discy-published-map-archives/"
local_archive_dir="${dir}archives/"

echo "Archiving: $server_archive_dir"
echo "Destination: $local_archive_dir"

mkdir -p $local_archive_dir

echo "rsync -rv --update nick@nickgeiger.com:${server_archive_dir}archive-* $local_archive_dir"

if false; then ## TODO: REMOVE WHEN TEST RUNNING... ##################### DEBUG #################

rsync -rv --update nick@nickgeiger.com:${server_archive_dir}archive-* $local_archive_dir

echo "ssh nick@nickgeiger.com \"rm -rf ${server_archive_dir}archive-*\""
ssh nick@nickgeiger.com "rm -rf ${server_archive_dir}archive-*"

fi ## TODO: REMOVE WHEN TEST RUNNING ##################### DEBUG #################


# Process the pulled archives

# Exit if nothing to process
if [ -z "$(ls -d ${local_archive_dir}archive-* 2>/dev/null)" ]; then
    echo "No archives to process"
    exit 0
fi

echo "Processing archives in: $dir"
files_processed=$(find $local_archive_dir* -name "*.json" -maxdepth 2 -mindepth 2 | sed "s|$local_archive_dir||g")
ruby archive/process-archives.rb $dir


# Commit and push the changes to github
git add .
git commit -am "archive/archive.sh
$files_processed"
git push


# Deploy the changes
### ./deploy/deploy-course-maps-prod.sh ##################### DEBUG #################


# TODO: Notify of _pending_ course IDs: jq -r 'to_entries[] | .key' archive/pending-course-maps.json
# curl -d "fyi something else pubbed - foobar-id2 or url2" ntfy.sh/foo-bar-baz
