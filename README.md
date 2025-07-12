# SpotifARRR

Download all your Spotify playlists.

This script is thin wrapper around the incredible [Zotify](https://github.com/DraftKinner/zotify) app, which does all the heavy lifting. Zotify is currently missing 2 features that this script helps with:
- Automatically get a URL list of all of a user's playlists (as opposed to specifying them manually).
- Generate M3U playlist files for each playlist downloaded.
- For premium users, ensure low-bitrate files are replaced with 320 Kbps versions when possible

Songs from all playlists are downloaded into a single common directory, along with an M3U file for each playlist. Existing songs are not re-downloaded. Any existing songs that are no longer found in any playlist are deleted.

Since this is meant as a quick workaround until Zotify adds the above features, it isn't the most user-friendly. Note that:
- Zotify authenticates with your regular Spotify username/password, but this repo needs Spotify API credentials instead. This means you'll have to setup the Spotify API and authenticate twice (both methods).
- Part of the script is written in Bash, so will not work on [Windows](https://www.reddit.com/r/WindowsSucks/).

## Usage

1. Ensure [Node.js](https://nodejs.org), [ExifTool](https://exiftool.org/), and [Zotify](https://github.com/DraftKinner/zotify) are installed.
   - Note: This is a fork of the original Zotify repo, which is unmaintained.
2. Copy `template.env` to `.env` and fill out the `CLIENT_ID` and `CLIENT_SECRET` with your own Spotify client details.
   - Set the redirect URI to `http://127.0.0.1:8080/` (including trailing slash).
   - You could set the environment variables in some other way if you prefer.
3. Optionally, create an `IGNORED_PLAYLISTS.txt` file in the script directory with a list of playlist names to ignore. You can also add a `ADDITIONAL_PLAYLISTS.txt` containing a list of playlist IDs and names to include even if they are not found in your profile.
4. Run `./SpotifARRR.sh <path to destination directory>`