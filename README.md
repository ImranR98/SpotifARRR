# SpotifARRR

Uses the Spotify API to get a list of all songs in your playlist, then uses spotify-downloader to download all songs from all playlists into a common directory, and generates M3U files for each playlist.

Does not overwrite existing songs and playlist entries, so it can be used efficiently on a regular basis.

Requires:
- A Spotify API access ID and Token (available as environment variables - a `.env` file is an option)
- `spotify-downloader`
- Node JS
- Exiftool

Quick and dirty script meant for personal use. Messy and not well documented; may have bugs.