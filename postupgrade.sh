#!/bin/bash

# Runs after the files have been copied. Moves config/ and data/ back in.
# Entries are moved one by one because the core has recreated the target
# directory in the meantime and may have put archive files into it. The glob
# includes dotfiles, otherwise a generated file starting with a dot stays behind.
#
# Arguments: <TEMPFOLDER> <NAME> <FOLDER> <VERSION> <BASEFOLDER>

ARGV3=$3
ARGV5=$5

for part in config data; do
	DEST="$ARGV5/$part/plugins/$ARGV3"
	STASH="$ARGV5/$part/plugins/.$ARGV3.upgrade"
	[ -d "$STASH" ] || continue
	mkdir -p "$DEST"
	for entry in "$STASH"/* "$STASH"/.[!.]*; do
		[ -e "$entry" ] || continue
		rm -rf "$DEST/$(basename "$entry")"
		mv "$entry" "$DEST/" || true
	done
	rm -rf "$STASH"
	echo "<INFO> $part restored after the upgrade."
done

exit 0
