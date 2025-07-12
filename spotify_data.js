const env = require('./lib/env')
const api = require('./lib/api')
const open = require('open')

const PORT = 8080
const clientCreds = env.getClientCreds()

const redirect_uri = `http://127.0.0.1:${PORT}/`

const authenticate = async () => {
    open.default(api.generateAuthURL(clientCreds.id, redirect_uri))
    const authCode = await api.waitForAuthCode(PORT)
    const accessToken = await api.getAccessToken(authCode, redirect_uri, clientCreds.id, clientCreds.secret)
    return accessToken.access_token
}

const authenticateExternal = async () => {
    console.log(await authenticate())
}

const getPlaylistIDs = async (accessToken) => {
    const myPlaylists = (await api.apiRequestGetArray('/me/playlists', accessToken)).filter(n => !!n)
    for (var i = 0; i < myPlaylists.length; i++) {
        console.log(`${myPlaylists[i].id} ${myPlaylists[i].name}`)
    }
}

const checkPremium = async (accessToken) => {
    console.log((await api.apiRequest('/me', 'GET', undefined, accessToken)).product === 'premium')
}

const main = async () => {
    const accessToken = process.argv[2] !== 'authenticate' ? process.argv[3] || await authenticate() : undefined
    const fn2run =
        process.argv[2] === 'checkPremium' ? checkPremium :
            process.argv[2] === 'authenticate' ? authenticateExternal :
                process.argv[2] === 'getPlaylists' ? getPlaylistIDs :
                    undefined
    if (!fn2run) {
        throw 'Unrecognized command.'
    }
    await fn2run(accessToken)
}

main().catch((e) => {
    console.error(e)
    process.exit(1)
}).finally(process.exit)