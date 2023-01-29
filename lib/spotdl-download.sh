#!/bin/bash

# Uses spotify-downloader (https://github.com/spotDL/spotify-downloader) to download songs based on a file of Spotify song IDs
# Also generates an M3U playlist file
# Meant to be used regularly, so does not replace existing files/playlists (as long as they follow the naming format)
# Spotify Downloader command needs to be specified as an argument since there are various ways to use it 

ids_file="$1"
songs_dir="$2"
playlists_dir="$3"
spotdl_command="$4" # Like 'docker run --rm -v $(pwd):/music --network=host spotdl/spotify-downloader'

usage() {
    'Usage: command <path to file with list of Spotify track IDs for playlist> <path to songs directory> <path to playlists directory> <spotify-downloader command>'
}

# Validate args

if [ ! -f "$ids_file" ] || [ ! -d "$songs_dir" ] || [ ! -d "$playlists_dir" ] || [ -z "$spotdl_command" ]; then
    echo 'Missing argument' >&2
    usage
    exit 1
fi
if [ -z "$(which exiftool)" ]; then
    echo 'Dependency not found: exiftool' >&2
    exit 2
fi

# Prep resources

tempdir="$(mktemp -d)"
here="$(pwd)"
cd "$tempdir"

# Download songs

echo 'Step 1: Downloading songs'
while read id; do
    existingfile="$(ls "$songs_dir" | grep "$id".mp3)"
    if [ -z "$existingfile" ]; then
        result="$(eval ""$spotdl_command" download https://open.spotify.com/track/"$id"" | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2};?)?)?[mGK]//g")"
        songname="$(echo "$result" | grep 'Downloaded' | awk -F'"' '{print $2}')"
        if [ -n "$songname" ]; then
            mv "$songname".mp3 "$songs_dir"/"$songname"" - ""$id".mp3
            filename="$songname".mp3
            echo "Done: "$filename""
        else
            echo "$result" >&2
        fi
    else
        echo "Skipping "$id", file exists..."
    fi
done <"$ids_file"

# Rebuild playlist

echo 'Step 2: Building playlist'
playlist_file="${ids_file%.*}".m3u
existing_playlist="$playlists_dir"/"$(basename "$playlist_file")"
echo '#EXTM3U' >"$playlist_file"
while read id; do
    file="$(ls "$songs_dir" | grep "$id".mp3)"
    if [ -n "$file" ]; then
        if [ -f "$existing_playlist" ] && [ -n "$(grep "$id" "$existing_playlist")" ]; then
            existinglines="$(grep -B 1 "$id" "$playlist_file")"
            linea="$(echo "$existinglines" | head -1)"
            lineb="$(echo "$existinglines" | tail -1)"
            echo "Skipping "$id", entry exists..."
        else
            size="$(exiftool -s -s -s -id3size "$songs_dir"/"$file")"
            artist="$(exiftool -s -s -s -artist "$songs_dir"/"$file")"
            title="$(exiftool -s -s -s -title "$songs_dir"/"$file")"
            artisttitle="$artist"" - ""$title"
            if [ -z "$size" ]; then size='12345'; fi
            if [ -z "$artist" ] || [ -z "$title" ]; then artisttitle="${file%.*}"; fi
            linea="#EXTINF:""$size"",""$artisttitle"
            lineb="$songs_dir""$file"
        fi
        echo "$linea" >>"$playlist_file"
        echo "$lineb" >>"$playlist_file"
    else
        echo "NO FILE: "$id"" >&2
    fi
done <"$ids_file"
mv "$playlist_file" "$playlists_dir"

# Clean up

cd "$here"
rm -rf "$tempdir"
