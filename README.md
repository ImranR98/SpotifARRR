# SpotifARRR

Download all your Spotify playlists.

This script is thin wrapper around the incredible [Zotify](https://github.com/zotify-dev/zotify) app, which does all the heavy lifting. Zotify is currently missing 2 features that this script helps with:
- Automatically get a URL list of all of a user's playlists (as opposed to specifying them manually).
- [Generate M3U playlist files for each playlist downloaded.](https://github.com/zotify-dev/zotify/issues/65)

Songs from all playlists are downloaded into a single common directory, along with an M3U file for each playlist. Existing songs are not re-downloaded. Any existing songs in that are no longer found in any playlist are deleted.

Since this is meant as a quick workaround until Zotify adds the above features, it isn't the most user-friendly. Note that:
- Zotify authenticates with your regular Spotify username/password, but this repo needs Spotify API credentials instead. This means you'll have to setup the Spotify API and authenticate twice (both methods).
- Part of the script is written in Bash, so will not work on [Windows](https://www.reddit.com/r/WindowsSucks/).

## Usage

1. Ensure [Node.js](https://nodejs.org) and [Zotify](https://github.com/zotify-dev/zotify) are installed.
2. Copy `template.env` to `.env` and fill out the `CLIENT_ID` and `CLIENT_SECRET` with your own Spotify client details.
   - Set the redirect URI to `http://127.0.0.1:8080/` (including trailing slash).
   - You could set the environment variables in some other way if you prefer.
3. Optionally, create an `IGNORED_PLAYLISTS.txt` file in the script directory with a list of playlist names to ignore.
4. Run `./SpotifARRR.sh <path to destination directory>`

The script can be run regularly as it makes use of SpotDL's `sync` command.