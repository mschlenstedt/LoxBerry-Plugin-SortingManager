#!/bin/sh

# Runs as root, as the LAST of the lifecycle scripts. Creates the directories,
# fixes ownership and makes the helpers executable.
#
# Arguments: <TEMPFOLDER> <NAME> <FOLDER> <VERSION> <BASEFOLDER>

ARGV3=$3
ARGV5=$5

BINDIR="$ARGV5/bin/plugins/$ARGV3"
DATADIR="$ARGV5/data/plugins/$ARGV3"
CONFIGDIR="$ARGV5/config/plugins/$ARGV3"
LOGDIR="$ARGV5/log/plugins/$ARGV3"
RUNTIME_DIR="/var/run/shm/$ARGV3"

if [ "$(id -u)" != "0" ]; then
	echo "<ERROR> postroot.sh must run as root."
	exit 2
fi

for file in sm_cli.pl sm_backup.pl sm_job.pl sm_watch.pl; do
	[ -e "$BINDIR/$file" ] && chmod +x "$BINDIR/$file"
done
[ -e "$ARGV5/webfrontend/htmlauth/plugins/$ARGV3/ajax.cgi" ] && \
	chmod +x "$ARGV5/webfrontend/htmlauth/plugins/$ARGV3/ajax.cgi"

mkdir -p "$DATADIR/backups" "$CONFIGDIR" "$LOGDIR" "$RUNTIME_DIR"
chown -R loxberry:loxberry "$DATADIR" "$CONFIGDIR" "$LOGDIR" "$RUNTIME_DIR"
chmod 0750 "$RUNTIME_DIR"

# Backups may contain sorting data of every user - not world readable.
chmod 0700 "$DATADIR/backups"

echo "<OK> Sorting Manager installed."
exit 0
