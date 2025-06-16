The archive should be run on a dedicated "server" (mac) with ssh and github setup as follows:


# For example, to set up the archiver in /Users/nick/archiver:

mkdir -p /Users/nick/archiver
cd /users/nick/archiver
git clone git@github.com:nickgeiger/DiscyServer.git


# Then setup cron to run the archiver every minute:

nick@Nicks-Mac-mini ~ % crontab -l
* * * * * cd /Users/nick/archiver/DiscyServer && ./archive/archive.sh prod /Dropbox/DiscyArchives/

(Where the passed archive directory can be a dropbox directory so that the outputs are all archived there)



# HOWTO do development

# move to a DEV branch (archiver will do git commits)
git checkout -b archiver-devX
git push -u origin archiver-devX

# copy some dev archives to the server to test the archiver
rsync -rv ~/Dropbox/DiscyArchives/archives/archive-1748394061 nick@nickgeiger.com:/home/nick/discy-published-map-archives-DEV/

# test the archiver in dev
./archive/archive.sh dev ~/workspace/TestPublishedMapsArchive

# Do a Pull Request in GitHub to deploy: archiver-devX > main
