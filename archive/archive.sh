## -e Ensures the script dies if there's an error, important so we don't
## accidentally continue and nuke server archive if it wasn't backed up
set -e

server_archive_dir="/home/nick/discy-published-map-archives/"
local_archive_dir="archives/"

echo "Archiving: $server_archive_dir"
echo "Destination: $local_archive_dir"

mkdir -p $local_archive_dir

echo "rsync -rv --update nick@nickgeiger.com:${server_archive_dir}archive-* $local_archive_dir"
rsync -rv --update nick@nickgeiger.com:${server_archive_dir}archive-* $local_archive_dir

echo "ssh nick@nickgeiger.com \"rm -rf ${server_archive_dir}archive-*\""
echo "ssh nick@nickgeiger.com \"rm -rf ${server_archive_dir}archive-*\""

