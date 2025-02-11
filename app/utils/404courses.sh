cat ~/logs/apps/nickgeiger/apache_access.log | grep api/discy/course-maps | grep 404 | grep -o maps/.*\.json | cut -c 6- | sort | uniq
