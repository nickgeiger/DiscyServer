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

  echo "Approved courses, committing and publishing"

# git add .
#approved_courses=($(jq -r 'to_entries[] | select(.value.approved == true) | .key' archive/pending-course-maps.json))
# git commit -am "archive/archive.sh approved foo,bar,..."
# git push or die (conflict or issue.. try again next time but don't proceed to archiving until approval succeeds)
# Deploy the changes
### ./deploy/deploy-course-maps-prod.sh ##################### DEBUG #################
    
else
  echo "No courses approved"
fi


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
