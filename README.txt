# ARCHIVER
# The archiver (archive/archive.sh) should be run on a dedicated "server" (mac) with ssh and github setup as follows:


# For example, to set up the archiver in /Users/nick/archiver:

mkdir -p /Users/nick/archiver
cd /users/nick/archiver
git clone git@github.com:nickgeiger/DiscyServer.git


# Then setup cron to run the archiver every minute:

nick@Nicks-Mac-mini ~ % crontab -l
* * * * * cd /Users/nick/archiver/DiscyServer && ./archive/archive.sh prod /Dropbox/DiscyArchives/

(Where the passed archive directory can be a dropbox directory so that the outputs are all archived there)



# HOWTO do archiver development

# move to a DEV branch (archiver will do git commits)
git checkout -b archiver-devX
git push -u origin archiver-devX

# copy some dev archives to the server to test the archiver
rsync -rv ~/Dropbox/DiscyArchives/archives/archive-1748394061 nick@nickgeiger.com:/home/nick/discy-published-map-archives-DEV/

# test the archiver in dev
./archive/archive.sh dev ~/workspace/TestPublishedMapsArchive

# Do a Pull Request in GitHub to deploy: archiver-devX > main



# COURSES
# Add/Edit Course(s)

# move to main to get & deploy latest when done with add/edit
git checkout main

# edit course-data/course-changes.json with course changes (adds or edits)

# run the script to apply the changes
./course-data/update-courses.sh

# commit & deploy
git commit -am "added course XYZ"
git push
./deploy/deploy-app.sh prod

# Also, be sure to copy the latest courses.json to the iOS app!!


# DEPLOY (if deploying to prod ensure you're on main branch and up-to-date)

# Entire app
./deploy/deploy-app.sh dev|prod

# Just the course maps
./deploy/deploy-course-maps.sh dev|prod


