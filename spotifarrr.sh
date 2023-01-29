#!/bin/bash

if [ -z "$(which node)" ]; then
    echo 'Dependency not found: node' >&2
    exit 3
fi

tempdir="$(mktemp -d)"

here="$(pwd)"
scriptdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

echo "Step 0: Getting playlist data"

cd "$scriptdir"/lib/getSpotifyPlaylistTrackIds
node app.js "$tempdir"
cd ..

for idfile in "$tempdir"/*; do
    ./spotdl-download.sh "$idfile" ~/Main/"External Media"/Music/Playlists ~/Main/"External Media"/Music/Songs 'docker run --rm -v $(pwd):/music --network=host spotdl/spotify-downloader'
done

cd "$here"