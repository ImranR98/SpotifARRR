require('dotenv').config()

module.exports.getClientCreds = () => {
    if (!process.env['CLIENT_ID']) {
        throw 'CLIENT_ID environment variable not found!'
    }
    if (!process.env['CLIENT_SECRET']) {
        throw 'CLIENT_SECRET environment variable not found!'
    }
    return {
        id: process.env['CLIENT_ID'],
        secret: process.env['CLIENT_SECRET']
    }
}