## This should be run from the project root directory (DiscyServer):
## ./deploy/deploy-course-maps.sh

# Get and validate the dev-or-prod parameter
dev_or_prod="$1"
if [ "$dev_or_prod" != "dev" ] && [ "$dev_or_prod" != "prod" ]; then
    echo "Error: Please specify dev or prod"
    echo "Usage: ./deploy/deploy-course-maps.sh (dev or prod)"
    exit 1
fi
if [ $dev_or_prod = "prod" ]; then
    dir="api"
else
    dir="api-wnv8FGB2ewc"
fi
api_dir="/home/nick/apps/nickgeiger/$dir/discy"

echo "Deploying course maps to $dev_or_prod ($api_dir)"

# Deploy all course maps
echo "rsync -rv --update app/course-maps/*.json nick@nickgeiger.com:$api_dir/course-maps/"
rsync -rv --update app/course-maps/* nick@nickgeiger.com:$api_dir/course-maps/

