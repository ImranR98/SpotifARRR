#!/bin/bash
set -e

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
if [ -f "$SCRIPT_DIR"/ADDITIONAL_PLAYLISTS.txt ]; then
    PLAYLISTS="$PLAYLISTS
$(cat "$SCRIPT_DIR"/ADDITIONAL_PLAYLISTS.txt)"
fi
echo "$PLAYLISTS"
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
    NAME="$(echo "$LINE" | awk '{$1=""; print $0}' | awk '{$1=$1};1')"
    if [ ! -f "$SCRIPT_DIR"/IGNORED_PLAYLISTS.txt ] || [ -z "$(grep "^$NAME$" "$SCRIPT_DIR"/IGNORED_PLAYLISTS.txt)" ]; then
        ZOTIFY_OUTPUT="$(zotify https://open.spotify.com/playlist/"$ID" -o "$DEST_DIR"/'{artist} - {track}' --print-downloads --skip-duplicates --print-skips --lyrics-file 2>&1 | tee /dev/tty)"
        ZOTIFY_OUTPUT="$(echo "$ZOTIFY_OUTPUT" | grep -Eo '^\s*(Skipping|Downloaded).+' | awk '{$1=$1};1')"
        PLAYLIST_FILE="$DEST_DIR"/"$NAME".m3u
        echo "#EXTM3U" >"$PLAYLIST_FILE"
        SKIP_REGEX="^Skipping \".*\": Previously downloaded"
        DL_REGEX="^Downloaded"
        ID=1
        while read -r line; do
            SONG_NAME=""
            if [[ "$line" =~ $SKIP_REGEX ]]; then
                SONG_NAME="$(echo "$line" | tail -c +11 | head -c -25)"
            elif [[ "$line" =~ $DL_REGEX ]]; then
                SONG_NAME="$(echo "$line" | tail -c +12 | awk '{NF--; print}')"
            else
                continue
            fi
            echo "#EXTINF:$ID,$SONG_NAME" >>"$PLAYLIST_FILE"
            echo "./$SONG_NAME.ogg" >>"$PLAYLIST_FILE"
            ID=$(($ID + 1))
        done < <(echo "$ZOTIFY_OUTPUT")
    fi
done <<<"$PLAYLISTS"

# For any song files that don't appear in at least one playlist, add it to an unsorted playlist or remove it
echo ""
UNSORTED_PLAYLIST="$DEST_DIR"/SpotifARRR_Unsorted.m3u
echo "#EXTM3U" >"$UNSORTED_PLAYLIST"
ALL_SONGS="$(cat *.m3u | grep --text '^\./')"
ID=1
for file in *.ogg; do
    regex_escaped_file="$(awk '{gsub(/[\[\]\\^$.|*+?(){}]/, "\\\\&"); print}' <<<"$file")"
    if [ -z "$(echo "$ALL_SONGS" | grep -E "^\./$regex_escaped_file")" ]; then
        if [ -f "$file" ]; then
            if [ -z "$NO_DELETE_UNLISTED" ]; then
                echo "Deleting unlisted song: $file"
                rm "$file"
                if [ -f "${file%.*}.lrc" ]; then
                    rm "${file%.*}.lrc"
                fi
            else
                echo "#EXTINF:$ID,${file%.*}" >>"$UNSORTED_PLAYLIST"
                echo "./$file" >>"$UNSORTED_PLAYLIST"
                ID=$(($ID + 1))
            fi
        fi
    fi
done

# Verify that there are no non-existent files referenced in any playlists
for playlist in *.m3u; do
    cat "$playlist" | grep --text '^\./' | while read song; do
        if [ ! -f "$song" ]; then
            echo "NON-EXISTENT SONG: $song (IN PLAYLIST: $playlist)"
        fi
    done
done
