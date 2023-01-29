const express = require('express')
const https = require('https')

module.exports.generateAuthURL = (client_id, port) => {
    const state = 'anything';
    const scope = 'playlist-read-private,playlist-read-collaborative';
    const url = 'https://accounts.spotify.com/authorize?'

    const params = new URLSearchParams()
    params.set('response_type', 'code')
    params.set('client_id', client_id)
    params.set('scope', scope)
    params.set('redirect_uri', `http://localhost:${port}`)
    params.set('state', state)

    return `${url}${params.toString()}`
}

module.exports.waitForAuthCode = (port) => {
    return new Promise((resolve, reject) => {
        const app = express()
        app.get('*', (req, res) => {
            if (req.query['code']) {
                res.send('You can close this tab.')
                resolve(req.query['code'])
            } else {
                const error = req.query['error'] || 'no code recieved'
                res.status(500).send(`Error: ${error}`)
                reject(error)
            }
        })
        app.listen(port)
    })
}

const request = (hostname, path, method, body, additionalHeaders) => {
    return new Promise((resolve, reject) => {
        let options = {
            hostname: hostname,
            port: 443,
            path: path,
            method: method
        }
        if (!!body) {
            body = new URLSearchParams(body).toString()
        }
        options['headers'] = {}
        if (method == 'POST' && !!body) {
            options['headers']['Content-Type'] = 'application/x-www-form-urlencoded'
            options['headers']['Content-Length'] = body.length
        }
        if (!!additionalHeaders) {
            Object.keys(additionalHeaders).forEach(hk => {
                options['headers'][hk] = additionalHeaders[hk]
            })
        }
        const req = https.request(options, (resp) => {
            let data = ''
            resp.on('data', (chunk) => {
                data += chunk
            })
            resp.on('end', () => {
                resolve(JSON.parse(data))
            })
        }).on("error", (err) => {
            reject(err)
        })
        if (!!body) {
            req.write(body)
        }
        req.end()
    })
}

const generateAuthHeader = (client_id, client_secret) => 'Basic ' + Buffer.from(`${client_id}:${client_secret}`).toString('base64')

module.exports.getAccessToken = async (authCode, validationPort, client_id, client_secret) => {
    var token = await request('accounts.spotify.com', '/api/token', 'POST', {
        code: authCode,
        redirect_uri: `http://localhost:${validationPort}`,
        grant_type: 'authorization_code'
    }, {
        'Authorization': generateAuthHeader(client_id, client_secret)
    })
    token.expiry = new Date()
    token.expiry
    token.expiry.setSeconds(token.expiry.getSeconds() + token.expires_in);
    return token
}

module.exports.apiRequest = async (path, method, body, access_token) => {
    return await request('api.spotify.com', '/v1' + path, method, body, {
        'Authorization': 'Bearer ' + access_token
    })
}

module.exports.apiRequestGetArray = async (path, access_token) => {
    const items = []
    var query = ''
    while (true) {
        const res = await module.exports.apiRequest(path + query, 'GET', null, access_token)
        if (!res.items) {
            res.path = path
            throw res
        }
        items.push(...res.items)
        if (!res.next) {
            break
        } else {
            query = res.next.slice(res.next.indexOf('?'))
        }
    }
    return items
}