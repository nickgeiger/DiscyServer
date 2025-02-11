## -e Ensures the script dies if there's an error, important so we don't
## accidentally continue and nuke server archive if it wasn't backed up
set -e


archive_dir="discy-published-map-archives/$(uuidgen)"
##echo "ARCHIVE: $archive_dir"

echo "ssh nick@nickgeiger.com \"/home/nick/apps/nickgeiger/api/discy/utils/archive-course-maps.sh $archive_dir\""
ssh nick@nickgeiger.com "/home/nick/apps/nickgeiger/api/discy/utils/archive-course-maps.sh $archive_dir"

server_archive_dir="/home/nick/$archive_dir"
local_archive_dir="archives/"

mkdir -p $local_archive_dir
echo "rsync -rv --update nick@nickgeiger.com:$server_archive_dir $local_archive_dir"
rsync -rv --update nick@nickgeiger.com:$server_archive_dir $local_archive_dir

echo "ssh nick@nickgeiger.com \"rm -rf $server_archive_dir\""
ssh nick@nickgeiger.com "rm -rf $server_archive_dir"

