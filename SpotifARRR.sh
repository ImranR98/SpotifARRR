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
        CLIENT_ID="$(cat .env | grep 'CLIENT_ID' | awk -F= '{print $2}')"
    fi
    if [ -z "$CLIENT_SECRET" ]; then
        CLIENT_SECRET="$(cat .env | grep 'CLIENT_SECRET' | awk -F= '{print $2}')"
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
PLAYLISTS="$(node "$SCRIPT_DIR"/get_all_playlist_ids.js)"
NODE_EXIT_CODE="$?"
if [ "$NODE_EXIT_CODE" != 0 ]; then
    exit "$NODE_EXIT_CODE"
fi

# Download each playlist into its own directory with an accompanying playlist file
mkdir -p "$DEST_DIR"
cd "$DEST_DIR"

set -e
while IFS= read -r LINE; do
    ID="$(echo "$LINE" | awk '{print $1}')"
    NAME="$(echo "$LINE" | awk '{$1=""; print $0}' | xargs)"
    mkdir -p "$NAME"
    cd "$NAME"
    spotdl sync https://open.spotify.com/playlist/"$ID" --client-id "$CLIENT_ID" --client-secret "$CLIENT_SECRET" --user-auth --m3u "$NAME".m3u --save-file "$NAME".spotdl
    cd ..
done <<<"$PLAYLISTS"
