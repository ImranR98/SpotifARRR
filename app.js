const env = require('./lib/env')
const api = require('./lib/api')
const open = require('open')
const fs = require('fs')

const PORT = 6660
const clientCreds = env.getClientCreds()

const main = async () => {
    var outputdir = process.argv[2]
    if (!outputdir) {
        throw 'Output directory not provided'
    }
    if (!(fs.existsSync(outputdir) && fs.statSync(outputdir).isDirectory())) {
        throw 'Specified output directory does not exist'
    }
    open(api.generateAuthURL(clientCreds.id, PORT))
    const authCode = await api.waitForAuthCode(PORT)
    const getAccessToken = async () => await api.getAccessToken(authCode, PORT, clientCreds.id, clientCreds.secret)
    var accessToken = await getAccessToken()
    const requestArray = async (path) => {
        if ((new Date()).valueOf() > accessToken.expiry.valueOf()) {
            accessToken = await getAccessToken()
        }
        return await api.apiRequestGetArray(path, accessToken.access_token)
    }
    // Get data
    const myPlaylists = await requestArray('/me/playlists')
    for (var i = 0; i < myPlaylists.length; i++) {
        myPlaylists[i].tracks = await requestArray(`/playlists/${myPlaylists[i].id}/tracks`)
        var result = ''
        for (var j = 0; j < myPlaylists[i].tracks.length; j++) {
            result += myPlaylists[i].tracks[j].track.id + '\n'
        }
        fs.writeFileSync(`${outputdir}/${myPlaylists[i].name}.txt`, result)
    }
    // console.log(JSON.stringify(myPlaylists, null, '\t'))
}

main().catch((e) => {
    console.error(e)
    process.exit(1)
}).finally(process.exit)