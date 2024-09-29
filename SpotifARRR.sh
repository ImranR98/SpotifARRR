#!/bin/bash -e

# Ensure dependencies
for dep in node zotify; do
    if [ -z "$(which "$dep")" ]; then
        echo "Dependency not found: "$dep"" >&2
        exit 1
    fi
done

# Prepare directories
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
        ZOTIFY_OUTPUT="$(zotify https://open.spotify.com/playlist/"$ID" --retry-attempts 30 --root-path "$DEST_DIR" --output '{artist} - {song_name}.{ext}' --print-downloads=True | tee /dev/tty)"
        ZOTIFY_OUTPUT="$(echo "$ZOTIFY_OUTPUT" | grep -Eo '### .*### *' | grep --text -Eo '[^#][^ +].*[^ +][^#]' | awk '{$1=$1};1')"
        PLAYLIST_FILE="$DEST_DIR"/"$NAME".m3u
        echo "#EXTM3U" >"$PLAYLIST_FILE"
        SKIP_REGEX="^SKIPPING.*SONG ALREADY EXISTS"
        DL_REGEX="^Downloaded"
        ID=1
        while read -r line; do
            SONG_NAME=""
            if [[ "$line" =~ $SKIP_REGEX ]]; then
                SONG_NAME="$(echo "$(echo "$line" | tail -c +11 | head -c -23)")"
            elif [[ "$line" =~ $DL_REGEX ]]; then
                SONG_NAME="$(echo "$line" | tail -c +13 | sed 's/./&\n/g' | awk 'BEGIN {RS=""} {n=split($0, a, "\n"); for(i=1;i<=n;i++) for(j=i+1;j<=n;j++) {str=a[i]; k=1; while(a[i+k]==a[j+k]){str=str a[i+k]; k++}; if(length(str)>length(max)) max=str} } END {print max}')"
            else
                continue
            fi
            echo "#EXTINF:$ID,$SONG_NAME" >>"$PLAYLIST_FILE"
            echo "./$SONG_NAME.ogg" >>"$PLAYLIST_FILE"
            ID=$(($ID + 1))
        done < <(echo "$ZOTIFY_OUTPUT")
    fi
done <<<"$PLAYLISTS"

# Remove any song files that don't appear in at least one playlist
if [ -z "$NO_DELETE_UNLISTED" ]; then
    echo ""
    ALL_SONGS="$(cat *.m3u | grep '^\./')"
    for file in *.ogg; do
        regex_escaped_file="$(awk '{gsub(/[\[\]\\^$.|*+?(){}]/, "\\\\&"); print}' <<<"$file")"
        if [ -z "$(echo "$ALL_SONGS" | grep -E "^\./$regex_escaped_file")" ]; then
            if [ -f "$file" ]; then
                echo "Deleting unlisted song: $file"
                rm "$file"
                if [ -f "${file%.*}.lrc" ]; then
                    rm "${file%.*}.lrc"
                fi
            fi
        fi
    done
fi
