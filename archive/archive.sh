## This should be run from the project root directory (DiscyServer):
## ./archive/archive.sh /Dropbox/DiscyArchives/

## -e Ensures the script dies if there's an error, important so we don't
## accidentally continue and nuke server archive if it wasn't backed up
set -e


# Get and validate the dev-or-prod parameter
dev_or_prod="$1"
if [ "$dev_or_prod" != "dev" ] && [ "$dev_or_prod" != "prod" ]; then
    echo "Error: Please specify dev or prod"
    echo "Usage: ./archive/archive.sh (dev or prod) (archive_parent_dir)"
    exit 1
fi
if [ $dev_or_prod = "prod" ]; then
    archive_dir="discy-published-map-archives"
else
    archive_dir="discy-published-map-archives-wnv8FGB2ewc"
fi
server_archive_dir="/home/nick/$archive_dir/"


# Get and validate the archive directory parameter
dir="$2"
if [ -z "$dir" ]; then
    echo "Error: Please provide the archive parent dir"
    echo "Usage: ./archive/archive.sh (dev or prod) (archive_parent_dir)"
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


# Deploy approved course maps

approved_courses=($(jq -r 'to_entries[] | select(.value.approved == true) | .key' archive/pending-course-maps.json))
if ruby archive/approve-course-maps.rb; then

    echo "Approved course maps, committing and publishing"

    git add .
    echo "git commit -am \"archive/archive.sh approved
$approved_courses\""
    git commit -am "archive/archive.sh approved
$approved_courses"
    git push ## or die (conflict or issue.. try again next time but don't proceed to archiving until approval succeeds)

    # Deploy the changes
    ./deploy/deploy-course-maps.sh $dev_or_prod

else
  echo "No courses approved"
fi


# Pull the archives
local_archive_dir="${dir}archives/"

echo "Archiving $dev_or_prod: $server_archive_dir"
echo "Destination: $local_archive_dir"

# Exit if no archives to process
if ! ssh nick@nickgeiger.com "ls -d ${server_archive_dir}archive-* 2>/dev/null" >/dev/null; then
    echo "No archives to process"
    exit 0
fi

mkdir -p $local_archive_dir

echo "rsync -rv --update nick@nickgeiger.com:${server_archive_dir}archive-* $local_archive_dir"
rsync -rv --update nick@nickgeiger.com:${server_archive_dir}archive-* $local_archive_dir

# Remove the archives from the server
echo "ssh nick@nickgeiger.com \"rm -rf ${server_archive_dir}archive-*\""
####ssh nick@nickgeiger.com "rm -rf ${server_archive_dir}archive-*" ##################### DEBUG #################


# Process the pulled archives
echo "Processing archives in: $dir"
files_processed=$(find $local_archive_dir* -name "*.json" -maxdepth 2 -mindepth 2 | sed "s|$local_archive_dir||g")
ruby archive/process-archives.rb $dev_or_prod $dir


# Commit and push the changes to github
git add .
echo "git commit -am \"archive/archive.sh
$files_processed\""
git commit -am "archive/archive.sh
$files_processed"
git push # Dies if there were no changes pushed, like if pending changes produced no diffs


# Deploy the changes
./deploy/deploy-course-maps.sh $dev_or_prod


# TODO: Notify of _pending_ course IDs: jq -r 'to_entries[] | .key' archive/pending-course-maps.json
new_approvals=$(echo "$files_processed" | cut -d'/' -f2 | sort -u)
echo "TODO: Notifying: New courses to approve:
${new_approvals}"
# curl -d "fyi something else pubbed - foobar-id2 or url2" ntfy.sh/foo-bar-baz


