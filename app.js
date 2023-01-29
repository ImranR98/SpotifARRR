const env = require('./lib/env')
const api = require('./lib/api')
const open = require('open')

const PORT = 6660
const clientCreds = env.getClientCreds()

const main = async () => {
    // Creds and helper funcs
    // const clientCreds = {}
    // if (process.argv.length != 4) {
    //     throw 'Provide client ID and secret as arguments'
    // } else {
    //     clientCreds.id = process.argv[2]
    //     clientCreds.secret = process.argv[3]
    // }
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
    }
    console.log(JSON.stringify(myPlaylists, null, '\t'))
}

main().catch((e) => {
    console.error(e)
    process.exit(1)
}).finally(process.exit)