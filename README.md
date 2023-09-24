# SpotifARRR

Tool to automate the use of [spotify-downloader](https://github.com/spotDL/spotify-downloader) and enable it to work with private playlists.

For some reason, SpotDL does not currently seem to grab a user's private playlists when the `all-user-playlists` command is used, even when the user is logged in. When you manually provide the playlist ID, however, it is able to download tracks. This script grabs your private playlists independently then uses SpotDL to download them.

A separate directory is created for each playlist, along with an M3U playlist file (note this does lead to duplicate files for songs that appear in multiple playlists).

## Usage

1. Ensure Node.js and SpotDL are installed.
   - Note: As of this writing, you need to install the beta version of SpotDL. On Fedora 39, you will need to ignore Python requirements:
   
     `pip install -U --force --ignore-requires-python https://codeload.github.com/spotDL/spotify-downloader/zip/master`
2. Copy `template.env` to `.env` and fill out the `CLIENT_ID` and `CLIENT_SECRET` with your own Spotify client details.
   - Set the redirect URI to `http://127.0.0.1:8080/` (including trailing slash).
3. Run `./SpotifARRR.sh <path to destination directory>`

The script can be run regularly as it makes use of SpotDL's `sync` command.