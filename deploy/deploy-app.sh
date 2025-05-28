## This should be run from the project root directory (DiscyServer):
## ./deploy/deploy-app.sh (dev or prod)

# Get and validate the dev-or-prod parameter
dev_or_prod="$1"
if [ "$dev_or_prod" != "dev" ] && [ "$dev_or_prod" != "prod" ]; then
    echo "Error: Please specify dev or prod"
    echo "Usage: ./deploy/deploy-app.sh (dev or prod)"
    exit 1
fi
if [ $dev_or_prod = "prod" ]; then
    dir="api"
else
    dir="api-wnv8FGB2ewc"
fi
api_dir="/home/nick/apps/nickgeiger/$dir/discy"

echo "Deploying app to $dev_or_prod ($api_dir)"

# Deploy all code
echo "rsync -v --update app/*.json* nick@nickgeiger.com:$api_dir/"
rsync -v --update app/*.json* nick@nickgeiger.com:$api_dir/
echo "rsync -v --update app/utils/* nick@nickgeiger.com:$api_dir/utils/"
rsync -v --update app/utils/* nick@nickgeiger.com:$api_dir/utils/
echo "rsync -v --update app/publish-course-map/*.php nick@nickgeiger.com:$api_dir/publish-course-map/"
rsync -v --update app/publish-course-map/*.php nick@nickgeiger.com:$api_dir/publish-course-map/

