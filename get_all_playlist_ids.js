const env = require('./lib/env')
const api = require('./lib/api')
const open = require('open')

const PORT = 8080
const clientCreds = env.getClientCreds()

const redirect_uri = `http://127.0.0.1:${PORT}/`

const main = async () => {
    open.default(api.generateAuthURL(clientCreds.id, redirect_uri))
    const authCode = await api.waitForAuthCode(PORT)
    const getAccessToken = async () => await api.getAccessToken(authCode, redirect_uri, clientCreds.id, clientCreds.secret)
    var accessToken = await getAccessToken()
    const requestArray = async (path) => {
        if ((new Date()).valueOf() > accessToken.expiry.valueOf()) {
            accessToken = await getAccessToken()
        }
        return await api.apiRequestGetArray(path, accessToken.access_token)
    }
    const myPlaylists = (await requestArray('/me/playlists')).filter(n => !!n)
    for (var i = 0; i < myPlaylists.length; i++) {
        // myPlaylists[i].tracks = await requestArray(`/playlists/${myPlaylists[i].id}/tracks`)  
        console.log(`${myPlaylists[i].id} ${myPlaylists[i].name}`)
    }
}

main().catch((e) => {
    console.error(e)
    process.exit(1)
}).finally(process.exit)