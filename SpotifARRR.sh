#!/bin/bash

# Ensure dependencies
for dep in node spotdl; do
    if [ -z "$(which "$dep")" ]; then
        echo "Dependency not found: "$dep"" >&2
        exit 1
    fi
done

# Prepare directories
TEMP_DIR="$(mktemp -d)"
HERE="$(pwd)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
DEST_DIR="$1"
if [ -z "$DEST_DIR" ]; then
    DEST_DIR=.
fi

# Ensure env. vars. exist
if [ -f "$SCRIPT_DIR"/.env ]; then
    if [ -z "$CLIENT_ID" ]; then
        CLIENT_ID="$(cat "$SCRIPT_DIR"/.env | grep 'CLIENT_ID' | awk -F= '{print $2}')"
    fi
    if [ -z "$CLIENT_SECRET" ]; then
        CLIENT_SECRET="$(cat "$SCRIPT_DIR"/.env | grep 'CLIENT_SECRET' | awk -F= '{print $2}')"
    fi
fi
if [ -z "$CLIENT_ID" ]; then
    echo 'CLIENT_ID not defined' >&2
    exit 1
fi
if [ -z "$CLIENT_SECRET" ]; then
    echo 'CLIENT_SECRET not defined' >&2
    exit 1
fi

# On exit, undo any 'cd' commands
onExit() {
    cd "$HERE"
}
trap 'onExit' EXIT

# Get all user playlists (including private ones)
cd "$SCRIPT_DIR"
PLAYLISTS="$(node "$SCRIPT_DIR"/get_all_playlist_ids.js)"
NODE_EXIT_CODE="$?"
if [ "$NODE_EXIT_CODE" != 0 ]; then
    exit "$NODE_EXIT_CODE"
fi

# Download each playlist into the target directory (existing songs are skipped) and generate a corresponding list of songs in a text file ('M3U')
mkdir -p "$DEST_DIR"
cd "$DEST_DIR"

set -e
while IFS= read -r LINE; do
    ID="$(echo "$LINE" | awk '{print $1}')"
    NAME="$(echo "$LINE" | awk '{$1=""; print $0}' | xargs)"
    if [ ! -f "$SCRIPT_DIR"/IGNORED_PLAYLISTS.txt ] || [ -z "$(grep "^$NAME$" "$SCRIPT_DIR"/IGNORED_PLAYLISTS.txt)" ]; then
        spotdl download https://open.spotify.com/playlist/"$ID" --client-id "$CLIENT_ID" --client-secret "$CLIENT_SECRET" --user-auth --m3u "$NAME".m3u --save-file "$NAME".spotdl
    fi
done <<<"$PLAYLISTS"

# Fix the formatting of the M3U files (spotdl just creates a list of file names and calls it M3U)
for file in "$DEST_DIR"/*.m3u; do
    node "$SCRIPT_DIR"/fixSpotdlM3U.js "$file"
done

# Remove any dong files that don't appear in at least one playlist
echo ""
ALL_SONGS="$(cat *.m3u | grep '^\./')"
for file in *.mp3; do
    if [ -z "$(echo "$ALL_SONGS" | grep "^\./$file")" ]; then
        echo "Deleting unlisted song: $file"
        rm "$file"
    fi
done