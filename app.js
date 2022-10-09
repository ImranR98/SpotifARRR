const env = require('./lib/env')
const api = require('./lib/api')

const PORT = 8080

const clientCreds = env.getClientCreds()

const apiRequest = (path, method, authCode, body) => api.apiRequest(path, method, authCode, body, PORT, clientCreds.id, clientCreds.secret)

const main = async () => {
    console.log('Log in at the the following URL and allow SpotifARRR to access your playlists:\n' +
        api.generateAuthURL(clientCreds.id, PORT))
    authCode = await api.waitForAuthCode(PORT)
    const myPlaylists = await apiRequest('/me/playlists', 'GET', authCode)
    console.log(myPlaylists)
}

main().catch((e) => {
    console.error(e)
    process.exit(1)
}).finally(process.exit)