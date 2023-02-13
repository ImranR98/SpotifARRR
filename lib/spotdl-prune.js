// Given a directory of MP3s and another directory of M3U playlist files, deletes any MP3s not found in at least one playlist

const fs = require('fs')

const songsDir = process.argv[2]
const playlistsDir = process.argv[3]
const dryRun = !!(process.argv[4])

if (!dryRun) {
    console.log('Only dry runs allowed - uncomment related code to disable')
}

if (!songsDir || !playlistsDir || !fs.existsSync(songsDir) || !fs.existsSync(playlistsDir) || !fs.statSync(songsDir).isDirectory() || !fs.statSync(playlistsDir).isDirectory()) {
    console.error('Usage: command <path to songs directory> <path to playlists directory> <any other argument enables dry run>')
    process.exit(1)
}

const allFilesInSongsDir = fs.readdirSync(songsDir);

const existingSongsNoExt = new Set(allFilesInSongsDir.filter(e => e.toLowerCase().endsWith('.mp3')).map(e => e.slice(0, -4)))

const keeperSongsNoExt = new Set()
fs.readdirSync(playlistsDir).filter(e => e.toLowerCase().endsWith('.m3u')).forEach(playlist => {
    fs.readFileSync(playlistsDir + '/' + playlist).toString().split('\n').filter(e => e.toLowerCase().endsWith('.mp3')).map(e => e.split('/').slice(-1)[0].slice(0, -4)).forEach(e => keeperSongsNoExt.add(e))
})

fs.writeFileSync('/home/imranr/Downloads/existing.txt', Array.from(existingSongsNoExt).sort().join('\n'))
fs.writeFileSync('/home/imranr/Downloads/keeper.txt', Array.from(keeperSongsNoExt).sort().join('\n'))

const toDeleteSongsNoExt = new Set();
existingSongsNoExt.forEach(e => toDeleteSongsNoExt.add(e))
keeperSongsNoExt.forEach(e => toDeleteSongsNoExt.delete(e))

allFilesInSongsDir.forEach(f => {
    const fnNoExt = f.slice(0, f.lastIndexOf('.'))
    if (toDeleteSongsNoExt.has(fnNoExt)) {
        const fPath = `${songsDir}/${f}`
        if (dryRun) {
            console.log(`rm '${fPath}'`)
        } else {
            fs.unlinkSync(fPath)
        }
    }
})