#!/bin/bash

# Runs BEFORE purge_installation() deletes config/ and data/ of this plugin.
# Moves both aside into sibling directories, which the purge does not touch.
# mv, not cp: /tmp is a tmpfs on LoxBerry and backups can be large.
#
# Arguments: <TEMPFOLDER> <NAME> <FOLDER> <VERSION> <BASEFOLDER> <TEMPDIR>

ARGV3=$3
ARGV5=$5

for part in config data; do
	SRC="$ARGV5/$part/plugins/$ARGV3"
	STASH="$ARGV5/$part/plugins/.$ARGV3.upgrade"
	if [ -d "$SRC" ]; then
		rm -rf "$STASH"
		mv "$SRC" "$STASH" && echo "<INFO> $part saved for the upgrade."
	fi
done

exit 0
