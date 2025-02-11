
# Deploy all code
rsync -v --update ../app/*.json* nick@nickgeiger.com:/home/nick/apps/nickgeiger/api/discy/
rsync -v --update ../app/utils/* nick@nickgeiger.com:/home/nick/apps/nickgeiger/api/discy/utils/
rsync -v --update ../app/publish-course-map/*.php nick@nickgeiger.com:/home/nick/apps/nickgeiger/api/discy/publish-course-map/

